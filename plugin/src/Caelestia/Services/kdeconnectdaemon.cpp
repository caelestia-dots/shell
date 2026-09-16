#include "kdeconnectdaemon.hpp"

#include <qbytearray.h>
#include <qdbusargument.h>
#include <qdbusconnection.h>
#include <qdbuserror.h>
#include <qdbusmessage.h>
#include <qdbuspendingcall.h>
#include <qdbuspendingreply.h>
#include <qdbusreply.h>
#include <qdbusservicewatcher.h>
#include <qdir.h>
#include <qelapsedtimer.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qfuturewatcher.h>
#include <qmap.h>
#include <qpromise.h>
#include <qstandardpaths.h>
#include <qtconcurrentrun.h>
#include <qthread.h>
#include <qtimer.h>
#include <qurl.h>

#include <algorithm>
#include <filesystem>
#include <system_error>

namespace caelestia::services {

using Qt::StringLiterals::operator""_s;

namespace {

const QString k_service = u"org.kde.kdeconnect"_s;
const QString k_daemonPath = u"/modules/kdeconnect"_s;
const QString k_daemonIface = u"org.kde.kdeconnect.daemon"_s;
const QString k_deviceIface = u"org.kde.kdeconnect.device"_s;
const QString k_propertiesIface = u"org.freedesktop.DBus.Properties"_s;
const QString k_sftpIface = u"org.kde.kdeconnect.device.sftp"_s;
const QString k_shareIface = u"org.kde.kdeconnect.device.share"_s;

constexpr qsizetype k_chunkSize = static_cast<qsizetype>(1024) * 1024;
constexpr int k_progressRange = 1000;
constexpr qint64 k_mountReadyTimeoutMs = 5000;
constexpr unsigned long k_mountReadyPollMs = 50;
constexpr int k_mountCheckTimeoutMs = 3000;
constexpr int k_probeThreads = 2;

enum class Outcome : quint8 {
    Success,
    Cancelled,
    Failed
};

// detail is the destination path on success and the error message on failure.
struct TransferResult {
    Outcome outcome = Outcome::Failed;
    QString detail;
};

enum class ProbeResult : quint8 {
    Reachable,
    Missing,
    Dead
};

struct MountResult {
    bool ok = false;
    bool mounted = false;
    QString mountPoint;
    QVariantMap directories;
    QString error;
};

TransferResult transferFailure(const QString& error) {
    return { .outcome = Outcome::Failed, .detail = error };
}

TransferResult transferCancelled() {
    return { .outcome = Outcome::Cancelled, .detail = QString() };
}

MountResult mountFailure(const QString& error) {
    MountResult result;
    result.error = error;
    return result;
}

QString deviceObjectPath(const QString& deviceId) {
    return u"/modules/kdeconnect/devices/%1"_s.arg(deviceId);
}

QString devicePath(const QString& deviceId, const QString& plugin) {
    return u"/modules/kdeconnect/devices/%1/%2"_s.arg(deviceId, plugin);
}

// kdeconnectd is D-Bus activatable, so never let a call start it. The shell must
// not launch KDE Connect for users who do not run it.
QDBusMessage methodCall(const QString& path, const QString& iface, const QString& method) {
    auto message = QDBusMessage::createMethodCall(k_service, path, iface, method);
    message.setAutoStartService(false);
    return message;
}

QString errorText(const QDBusError& error) {
    return error.message().isEmpty() ? u"KDE Connect SFTP interface is unavailable"_s : error.message();
}

// Blocking call, only used from worker threads.
QDBusMessage callSftp(const QString& deviceId, const QString& method) {
    return QDBusConnection::sessionBus().call(methodCall(devicePath(deviceId, u"sftp"_s), k_sftpIface, method));
}

MountResult readMountState(const QString& deviceId) {
    const QDBusReply<bool> mounted = callSftp(deviceId, u"isMounted"_s);
    if (!mounted.isValid())
        return mountFailure(errorText(mounted.error()));

    MountResult result;
    result.ok = true;
    result.mounted = mounted.value();
    if (!result.mounted)
        return result;

    const QDBusReply<QString> mountPoint = callSftp(deviceId, u"mountPoint"_s);
    if (!mountPoint.isValid())
        return mountFailure(errorText(mountPoint.error()));

    const QDBusReply<QVariantMap> directories = callSftp(deviceId, u"getDirectories"_s);
    if (!directories.isValid())
        return mountFailure(errorText(directories.error()));

    result.mountPoint = mountPoint.value();
    result.directories = directories.value();
    return result;
}

// sshfs reports the mount before the directories are reachable, so wait until
// at least one of them exists.
bool waitForMountReady(const QVariantMap& directories) {
    QElapsedTimer timer;
    timer.start();

    while (timer.elapsed() < k_mountReadyTimeoutMs) {
        for (auto it = directories.cbegin(); it != directories.cend(); ++it) {
            if (QFileInfo(it.key()).isDir())
                return true;
        }

        QThread::msleep(k_mountReadyPollMs);
    }

    return false;
}

MountResult mountDevice(const QString& deviceId) {
    const QDBusReply<bool> mounted = callSftp(deviceId, u"mountAndWait"_s);
    if (!mounted.isValid())
        return mountFailure(errorText(mounted.error()));

    if (!mounted.value()) {
        const QDBusReply<QString> mountError = callSftp(deviceId, u"getMountError"_s);
        if (mountError.isValid() && !mountError.value().isEmpty())
            return mountFailure(mountError.value());
        return mountFailure(u"Failed to mount the device filesystem"_s);
    }

    auto result = readMountState(deviceId);
    if (result.ok && !waitForMountReady(result.directories))
        return mountFailure(u"Mounted filesystem did not become ready"_s);

    return result;
}

struct DeviceList {
    bool available = false;
    QVariantList devices;
};

// Blocking calls, only used from worker threads
DeviceList readDevices() {
    const auto bus = QDBusConnection::sessionBus();

    // Reachable devices, paired or not, so unpaired ones can be offered for pairing
    auto namesCall = methodCall(k_daemonPath, k_daemonIface, u"deviceNames"_s);
    namesCall << true << false;

    const auto namesReply = bus.call(namesCall);
    if (namesReply.type() != QDBusMessage::ReplyMessage || namesReply.arguments().isEmpty())
        return {};

    QMap<QString, QString> names;
    namesReply.arguments().constFirst().value<QDBusArgument>() >> names;

    DeviceList result;
    result.available = true;

    for (auto it = names.cbegin(); it != names.cend(); ++it) {
        auto propertiesCall = methodCall(deviceObjectPath(it.key()), k_propertiesIface, u"GetAll"_s);
        propertiesCall << k_deviceIface;

        // A device which vanished in between is left out
        const QDBusReply<QVariantMap> properties = bus.call(propertiesCall);
        if (!properties.isValid())
            continue;

        const auto& values = properties.value();
        result.devices << QVariantMap{
            { u"id"_s, it.key() },
            { u"name"_s, it.value() },
            { u"paired"_s, values.value(u"isPaired"_s).toBool() },
            { u"pairState"_s, values.value(u"pairState"_s).toInt() },
            { u"verificationKey"_s, values.value(u"verificationKey"_s).toString() },
        };
    }

    return result;
}

// Once the phone drops off the network, sshfs fails requests with connection
// errors, or blocks them until it gives up. Only those errors mean the mount is
// dead; anything else just means the path is not a usable folder.
ProbeResult probePath(const QString& path) {
    std::error_code error;
    const auto status = std::filesystem::status(QFile::encodeName(path).toStdString(), error);

    if (!error)
        return std::filesystem::is_directory(status) ? ProbeResult::Reachable : ProbeResult::Missing;

    if (error == std::errc::not_connected || error == std::errc::io_error || error == std::errc::timed_out ||
        error == std::errc::connection_aborted || error == std::errc::connection_reset ||
        error == std::errc::host_unreachable || error == std::errc::network_unreachable)
        return ProbeResult::Dead;

    return ProbeResult::Missing;
}

bool pathInsideDirectories(const QString& path, const QVariantMap& directories) {
    const auto cleanedPath = QDir::cleanPath(path);

    for (auto it = directories.cbegin(); it != directories.cend(); ++it) {
        const auto rootPath = QDir::cleanPath(it.key());
        if (cleanedPath == rootPath || cleanedPath.startsWith(rootPath + u'/'))
            return true;
    }

    return false;
}

QString uniqueDestinationPath(const QString& directory, const QString& fileName) {
    const QDir dir(directory);

    auto candidate = dir.filePath(fileName);
    if (!QFileInfo::exists(candidate))
        return candidate;

    const auto dot = fileName.lastIndexOf(u'.');
    const auto stem = dot > 0 ? fileName.left(dot) : fileName;
    const auto extension = dot > 0 ? fileName.mid(dot) : QString();

    for (int i = 1; i < 10000; ++i) {
        candidate = dir.filePath(u"%1 (%2)%3"_s.arg(stem, QString::number(i), extension));
        if (!QFileInfo::exists(candidate))
            return candidate;
    }

    return {};
}

TransferResult copyFile(
    const QString& sourcePath, const QString& destinationDirectory, QPromise<TransferResult>& promise) {
    QFile source(sourcePath);
    if (!source.open(QIODevice::ReadOnly))
        return transferFailure(u"Failed to open %1: %2"_s.arg(sourcePath, source.errorString()));

    const auto destinationPath = uniqueDestinationPath(destinationDirectory, QFileInfo(sourcePath).fileName());
    if (destinationPath.isEmpty())
        return transferFailure(u"Could not create a unique destination name for %1"_s.arg(sourcePath));

    QFile destination(destinationPath);
    if (!destination.open(QIODevice::WriteOnly | QIODevice::NewOnly))
        return transferFailure(u"Failed to create %1: %2"_s.arg(destinationPath, destination.errorString()));

    // Never leave a partial file behind.
    const auto discard = [&destination](const TransferResult& result) {
        destination.remove();
        return result;
    };

    const auto totalBytes = source.size();
    qint64 copiedBytes = 0;
    QByteArray buffer(k_chunkSize, Qt::Uninitialized);

    while (!source.atEnd()) {
        if (promise.isCanceled())
            return discard(transferCancelled());

        const auto bytesRead = source.read(buffer.data(), buffer.size());
        if (bytesRead < 0)
            return discard(transferFailure(u"Failed to read %1: %2"_s.arg(sourcePath, source.errorString())));
        if (bytesRead == 0)
            break;

        if (destination.write(buffer.constData(), bytesRead) != bytesRead)
            return discard(
                transferFailure(u"Failed to write %1: %2"_s.arg(destinationPath, destination.errorString())));

        copiedBytes += bytesRead;
        if (totalBytes > 0)
            promise.setProgressValue(
                static_cast<int>(std::min(copiedBytes, totalBytes) * k_progressRange / totalBytes));
    }

    if (promise.isCanceled())
        return discard(transferCancelled());

    if (!destination.flush())
        return discard(transferFailure(u"Failed to flush %1: %2"_s.arg(destinationPath, destination.errorString())));

    return { .outcome = Outcome::Success, .detail = destinationPath };
}

void downloadFile(QPromise<TransferResult>& promise, const QString& deviceId, const QString& sourcePath) {
    promise.setProgressRange(0, k_progressRange);

    const auto mount = mountDevice(deviceId);
    if (promise.isCanceled())
        return;

    if (!mount.ok) {
        promise.addResult(transferFailure(mount.error));
        return;
    }

    if (!pathInsideDirectories(sourcePath, mount.directories)) {
        promise.addResult(transferFailure(u"The selected file is outside the mounted phone storage"_s));
        return;
    }

    if (!QFileInfo(sourcePath).isFile()) {
        promise.addResult(transferFailure(u"%1 is not a regular file"_s.arg(sourcePath)));
        return;
    }

    auto destinationDirectory = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
    if (destinationDirectory.isEmpty())
        destinationDirectory = QDir::home().filePath(u"Downloads"_s);

    if (!QDir().mkpath(destinationDirectory)) {
        promise.addResult(transferFailure(u"Failed to create download directory: %1"_s.arg(destinationDirectory)));
        return;
    }

    promise.addResult(copyFile(sourcePath, destinationDirectory, promise));
}

} // namespace

KdeConnectDaemon::KdeConnectDaemon(QObject* parent)
    : QObject(parent) {
    m_probePool.setMaxThreadCount(k_probeThreads);

    auto bus = QDBusConnection::sessionBus();

    // Refresh when the daemon starts or stops, and whenever it reports a device
    // being added, removed or changing reachability
    auto* serviceWatcher = new QDBusServiceWatcher(k_service, bus, QDBusServiceWatcher::WatchForOwnerChange, this);
    connect(serviceWatcher, &QDBusServiceWatcher::serviceOwnerChanged, this, &KdeConnectDaemon::refresh);
    bus.connect(k_service, k_daemonPath, k_daemonIface, u"deviceListChanged"_s, this, SLOT(refresh()));

    // Device signals, matched on every device path. Pairing changes are not part of
    // deviceListChanged.
    bus.connect(k_service, QString(), k_deviceIface, u"pairStateChanged"_s, this, SLOT(refresh()));
    bus.connect(k_service, QString(), k_deviceIface, u"nameChanged"_s, this, SLOT(refresh()));
    bus.connect(
        k_service, QString(), k_deviceIface, u"pairingFailed"_s, this, SLOT(onPairingFailed(QString, QDBusMessage)));

    refresh();
}

bool KdeConnectDaemon::available() const {
    return m_available;
}

QVariantList KdeConnectDaemon::devices() const {
    return m_devices;
}

bool KdeConnectDaemon::downloading() const {
    return m_downloading;
}

qreal KdeConnectDaemon::downloadProgress() const {
    return m_downloadProgress;
}

QString KdeConnectDaemon::downloadDevice() const {
    return m_downloadDevice;
}

void KdeConnectDaemon::refresh() {
    const auto generation = ++m_refreshGeneration;

    QtConcurrent::run(readDevices).then(this, [this, generation](const DeviceList& result) {
        if (generation != m_refreshGeneration)
            return;

        setAvailable(result.available);
        setDevices(result.devices);
    });
}

void KdeConnectDaemon::requestPairing(const QString& deviceId) {
    callDevice(deviceId, u"requestPairing"_s);
}

void KdeConnectDaemon::acceptPairing(const QString& deviceId) {
    callDevice(deviceId, u"acceptPairing"_s);
}

void KdeConnectDaemon::cancelPairing(const QString& deviceId) {
    callDevice(deviceId, u"cancelPairing"_s);
}

void KdeConnectDaemon::unpair(const QString& deviceId) {
    callDevice(deviceId, u"unpair"_s);
}

void KdeConnectDaemon::callDevice(const QString& deviceId, const QString& method) {
    if (deviceId.isEmpty())
        return;

    // The outcome arrives through pairStateChanged or pairingFailed
    auto* watcher = new QDBusPendingCallWatcher(
        QDBusConnection::sessionBus().asyncCall(methodCall(deviceObjectPath(deviceId), k_deviceIface, method)), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, deviceId](QDBusPendingCallWatcher* call) {
        call->deleteLater();
        if (call->isError())
            emit pairingFailed(deviceId, call->error().message());
    });
    // NOLINTNEXTLINE(clang-analyzer-cplusplus.NewDeleteLeaks) watcher is parented and self-deletes
}

void KdeConnectDaemon::onPairingFailed(const QString& error, const QDBusMessage& message) {
    // The device id is the last element of the signal's object path
    emit pairingFailed(message.path().section(u'/', -1), error);
}

void KdeConnectDaemon::share(const QString& deviceId, const QVariantList& urls) {
    if (deviceId.isEmpty() || urls.isEmpty())
        return;

    QStringList fileUrls;
    fileUrls.reserve(urls.size());

    for (const auto& value : urls) {
        const auto url = value.toUrl();
        if (!url.isValid() || !url.isLocalFile()) {
            emit shareFailed(deviceId, u"Only local files can be shared"_s);
            return;
        }

        const QFileInfo info(url.toLocalFile());
        if (!info.isFile() || !info.isReadable()) {
            emit shareFailed(deviceId, u"%1 is not a readable file"_s.arg(info.filePath()));
            return;
        }

        fileUrls << url.toString(QUrl::FullyEncoded);
    }

    // Hand the files to KDE Connect's own share plugin, so the phone gets its usual
    // incoming file notification and indexes the files. The reply only means the
    // daemon queued them, as the plugin exposes no progress for outgoing transfers.
    auto message = methodCall(devicePath(deviceId, u"share"_s), k_shareIface, u"shareUrls"_s);
    message << fileUrls;

    const auto count = static_cast<int>(fileUrls.size());
    auto* watcher = new QDBusPendingCallWatcher(QDBusConnection::sessionBus().asyncCall(message), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, deviceId, count](QDBusPendingCallWatcher* call) {
        const QDBusPendingReply<> reply = *call;
        if (reply.isError())
            emit shareFailed(deviceId, reply.error().message());
        else
            emit shared(deviceId, count);
        call->deleteLater();
    });
    // NOLINTNEXTLINE(clang-analyzer-cplusplus.NewDeleteLeaks) watcher is parented and self-deletes
}

void KdeConnectDaemon::download(const QString& deviceId, const QString& sourcePath) {
    if (deviceId.isEmpty() || sourcePath.isEmpty())
        return;

    if (m_downloading) {
        emit downloadFailed(deviceId, u"A file transfer is already in progress"_s);
        return;
    }

    setDownloadDevice(deviceId);
    setDownloadProgress(0.0);
    setDownloading(true);

    // The worker captures only values, so it is safe if this object goes away first.
    // The watcher is a child, so its signals stop with it.
    auto* watcher = new QFutureWatcher<TransferResult>(this);

    connect(watcher, &QFutureWatcher<TransferResult>::progressValueChanged, this, [this](int value) {
        setDownloadProgress(static_cast<qreal>(value) / k_progressRange);
    });

    connect(watcher, &QFutureWatcher<TransferResult>::finished, this, [this, watcher, deviceId]() {
        const auto future = watcher->future();
        const auto cancelled = future.isCanceled() || future.resultCount() == 0;
        const auto result = cancelled ? transferCancelled() : future.result();

        m_download = {};
        setDownloadProgress(result.outcome == Outcome::Success ? 1.0 : 0.0);
        setDownloading(false);

        switch (result.outcome) {
        case Outcome::Success:
            emit downloaded(deviceId, result.detail);
            break;
        case Outcome::Cancelled:
            emit downloadCancelled(deviceId);
            break;
        case Outcome::Failed:
            emit downloadFailed(deviceId, result.detail);
            break;
        }

        watcher->deleteLater();
    });

    const auto future = QtConcurrent::run(downloadFile, deviceId, sourcePath);
    m_download = QFuture<void>(future);
    watcher->setFuture(future);
    // NOLINTNEXTLINE(clang-analyzer-cplusplus.NewDeleteLeaks) watcher is parented and self-deletes
}

void KdeConnectDaemon::cancelDownload() {
    if (m_downloading)
        m_download.cancel();
}

void KdeConnectDaemon::mount(const QString& deviceId) {
    if (deviceId.isEmpty())
        return;

    if (m_downloading) {
        emit mountFailed(deviceId, u"Cannot mount storage while a download is in progress"_s);
        return;
    }

    QtConcurrent::run(mountDevice, deviceId).then(this, [this, deviceId](const MountResult& result) {
        if (result.ok)
            emit mountStateChanged(deviceId, result.mounted, result.mountPoint, result.directories);
        else
            emit mountFailed(deviceId, result.error);
    });
}

void KdeConnectDaemon::unmount(const QString& deviceId) {
    if (deviceId.isEmpty())
        return;

    if (m_downloading) {
        emit mountFailed(deviceId, u"Cannot unmount storage while a download is in progress"_s);
        return;
    }

    startUnmount(deviceId);
}

void KdeConnectDaemon::startUnmount(const QString& deviceId) {
    QtConcurrent::run([deviceId] {
        const auto reply = callSftp(deviceId, u"unmount"_s);
        return reply.type() == QDBusMessage::ErrorMessage ? errorText(QDBusError(reply)) : QString();
    }).then(this, [this, deviceId](const QString& error) {
        if (error.isEmpty())
            emit mountStateChanged(deviceId, false, QString(), QVariantMap());
        else
            emit mountFailed(deviceId, error);
    });
}

void KdeConnectDaemon::refreshMount(const QString& deviceId) {
    if (deviceId.isEmpty())
        return;

    QtConcurrent::run(readMountState, deviceId).then(this, [this, deviceId](const MountResult& result) {
        // A failed refresh does not mean the device got unmounted, so keep the
        // last known state and only report the failure
        if (result.ok)
            emit mountStateChanged(deviceId, result.mounted, result.mountPoint, result.directories);
        else
            emit mountFailed(deviceId, result.error);
    });
}

void KdeConnectDaemon::checkMount(const QString& deviceId, const QString& path) {
    if (deviceId.isEmpty() || path.isEmpty())
        return;

    // A hung probe is reported as dead once the timeout fires. Its worker stays
    // blocked until the unmount stops sshfs, then finishes and cleans up.
    auto* watcher = new QFutureWatcher<ProbeResult>(this);
    auto* timeout = new QTimer(watcher);
    timeout->setSingleShot(true);

    connect(timeout, &QTimer::timeout, this, [this, deviceId, path] {
        emit mountChecked(deviceId, path, false);
        dropDeadMount(deviceId);
    });

    connect(watcher, &QFutureWatcher<ProbeResult>::finished, this, [this, watcher, timeout, deviceId, path] {
        watcher->deleteLater();

        if (!timeout->isActive())
            return;

        timeout->stop();
        const auto result = watcher->result();
        emit mountChecked(deviceId, path, result == ProbeResult::Reachable);

        if (result == ProbeResult::Dead)
            dropDeadMount(deviceId);
    });

    watcher->setFuture(QtConcurrent::run(&m_probePool, probePath, path));
    timeout->start(k_mountCheckTimeoutMs);
    // NOLINTNEXTLINE(clang-analyzer-cplusplus.NewDeleteLeaks) watcher is parented and self-deletes
}

void KdeConnectDaemon::dropDeadMount(const QString& deviceId) {
    // A download from the dead mount cannot finish either. Cancelling lets its
    // worker stop as soon as the unmount unblocks it.
    if (m_downloading && m_downloadDevice == deviceId)
        m_download.cancel();

    startUnmount(deviceId);
}

void KdeConnectDaemon::setAvailable(bool available) {
    if (m_available == available)
        return;

    m_available = available;
    emit availableChanged();
}

void KdeConnectDaemon::setDevices(const QVariantList& devices) {
    if (m_devices == devices)
        return;

    m_devices = devices;
    emit devicesChanged();
}

void KdeConnectDaemon::setDownloading(bool downloading) {
    if (m_downloading == downloading)
        return;

    m_downloading = downloading;
    emit downloadingChanged();
}

void KdeConnectDaemon::setDownloadProgress(qreal progress) {
    if (qFuzzyCompare(m_downloadProgress + 1.0, progress + 1.0))
        return;

    m_downloadProgress = progress;
    emit downloadProgressChanged();
}

void KdeConnectDaemon::setDownloadDevice(const QString& deviceId) {
    if (m_downloadDevice == deviceId)
        return;

    m_downloadDevice = deviceId;
    emit downloadDeviceChanged();
}

} // namespace caelestia::services
