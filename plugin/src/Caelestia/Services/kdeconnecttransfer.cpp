#include "kdeconnecttransfer.hpp"

#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>
#include <QDir>
#include <QElapsedTimer>
#include <QFile>
#include <QFileInfo>
#include <QMetaObject>
#include <QPointer>
#include <QStandardPaths>
#include <QStringList>
#include <QThread>
#include <QUrl>

#include <algorithm>
#include <functional>

namespace {

constexpr qint64 CHUNK_SIZE = 1024 * 1024;

enum class CopyResult {
    Success,
    Cancelled,
    Failed
};

QString sftpObjectPath(const QString& deviceId)
{
    return QStringLiteral("/modules/kdeconnect/devices/%1/sftp")
        .arg(deviceId);
}

bool readMountState(
    const QString& deviceId,
    bool* mounted,
    QString* mountPoint,
    QVariantMap* directories,
    QString* error
)
{
    QDBusInterface sftp(
        QStringLiteral("org.kde.kdeconnect"),
        sftpObjectPath(deviceId),
        QStringLiteral("org.kde.kdeconnect.device.sftp"),
        QDBusConnection::sessionBus()
    );

    if (!sftp.isValid()) {
        *error = sftp.lastError().message();

        if (error->isEmpty())
            *error = QStringLiteral("KDE Connect SFTP interface is unavailable");

        return false;
    }

    const QDBusReply<bool> mountedReply =
        sftp.call(QStringLiteral("isMounted"));

    if (!mountedReply.isValid()) {
        *error = mountedReply.error().message();
        return false;
    }

    *mounted = mountedReply.value();

    if (!*mounted) {
        mountPoint->clear();
        directories->clear();
        return true;
    }

    const QDBusReply<QString> mountPointReply =
        sftp.call(QStringLiteral("mountPoint"));

    if (!mountPointReply.isValid()) {
        *error = mountPointReply.error().message();
        return false;
    }

    const QDBusReply<QVariantMap> directoriesReply =
        sftp.call(QStringLiteral("getDirectories"));

    if (!directoriesReply.isValid()) {
        *error = directoriesReply.error().message();
        return false;
    }

    *mountPoint = mountPointReply.value();
    *directories = directoriesReply.value();

    return true;
}

bool waitForMountReady(
    const QVariantMap& directories,
    QString* error
)
{
    QElapsedTimer timer;
    timer.start();

    while (timer.elapsed() < 5000) {
        for (auto it = directories.cbegin(); it != directories.cend(); ++it) {
            const QFileInfo info(it.key());

            if (info.exists() && info.isDir())
                return true;
        }

        QThread::msleep(50);
    }

    *error = QStringLiteral("Mounted filesystem did not become ready");
    return false;
}

bool ensureDeviceMounted(
    const QString& deviceId,
    QVariantMap* directories,
    QString* error
)
{
    QDBusInterface sftp(
        QStringLiteral("org.kde.kdeconnect"),
        sftpObjectPath(deviceId),
        QStringLiteral("org.kde.kdeconnect.device.sftp"),
        QDBusConnection::sessionBus()
    );

    if (!sftp.isValid()) {
        *error = sftp.lastError().message();

        if (error->isEmpty())
            *error = QStringLiteral("KDE Connect SFTP interface is unavailable");

        return false;
    }

    const QDBusReply<bool> mountReply =
        sftp.call(QStringLiteral("mountAndWait"));

    if (!mountReply.isValid()) {
        *error = mountReply.error().message();
        return false;
    }

    if (!mountReply.value()) {
        const QDBusReply<QString> mountError =
            sftp.call(QStringLiteral("getMountError"));

        if (mountError.isValid() && !mountError.value().isEmpty())
            *error = mountError.value();
        else
            *error = QStringLiteral("Failed to mount the device filesystem");

        return false;
    }

    const QDBusReply<QVariantMap> directoriesReply =
        sftp.call(QStringLiteral("getDirectories"));

    if (!directoriesReply.isValid()) {
        *error = directoriesReply.error().message();
        return false;
    }

    *directories = directoriesReply.value();

    return waitForMountReady(*directories, error);
}

QString findDownloadDirectory(const QVariantMap& directories)
{
    QStringList roots = directories.keys();

    std::sort(roots.begin(), roots.end(), [](const QString& lhs, const QString& rhs) {
        return lhs.size() < rhs.size();
    });

    for (const QString& root : roots) {
        const QDir directory(root);

        for (const QString& name : {
                 QStringLiteral("Download"),
                 QStringLiteral("Downloads")
             }) {
            const QString candidate = directory.filePath(name);
            const QFileInfo info(candidate);

            if (info.exists() && info.isDir())
                return info.absoluteFilePath();
        }
    }

    return {};
}

bool pathInsideDirectories(
    const QString& path,
    const QVariantMap& directories
)
{
    const QString cleanedPath = QDir::cleanPath(path);

    for (auto it = directories.cbegin(); it != directories.cend(); ++it) {
        const QString rootPath = QDir::cleanPath(it.key());

        if (cleanedPath == rootPath)
            return true;

        const QString prefix = rootPath.endsWith(QLatin1Char('/'))
            ? rootPath
            : rootPath + QLatin1Char('/');

        if (cleanedPath.startsWith(prefix))
            return true;
    }

    return false;
}

QString uniqueDestinationPath(
    const QString& directory,
    const QString& fileName
)
{
    const QDir dir(directory);

    QString candidate = dir.filePath(fileName);

    if (!QFileInfo::exists(candidate))
        return candidate;

    const qsizetype dot =
        fileName.lastIndexOf(QLatin1Char('.'));

    const QString stem =
        dot > 0 ? fileName.left(dot) : fileName;

    const QString extension =
        dot > 0 ? fileName.mid(dot) : QString();

    for (int index = 1; index < 10000; ++index) {
        candidate = dir.filePath(
            QStringLiteral("%1 (%2)%3")
                .arg(stem, QString::number(index), extension)
        );

        if (!QFileInfo::exists(candidate))
            return candidate;
    }

    return {};
}

bool mountDownloadDirectory(
    const QString& deviceId,
    QString* downloadDirectory,
    QString* error
)
{
    QVariantMap directories;

    if (!ensureDeviceMounted(
            deviceId,
            &directories,
            error
        )) {
        return false;
    }

    const QString directory =
        findDownloadDirectory(directories);

    if (directory.isEmpty()) {
        *error = QStringLiteral(
            "Could not find a Download directory on the device"
        );

        return false;
    }

    *downloadDirectory = directory;
    return true;
}

CopyResult copyFiles(
    const QStringList& paths,
    const QString& destinationDirectory,
    qint64 totalBytes,
    const std::shared_ptr<std::atomic_bool>& cancelToken,
    const std::function<void(qreal)>& reportProgress,
    QString* error,
    QStringList* copiedPaths = nullptr
)
{
    qint64 copiedBytes = 0;

    QByteArray buffer;
    buffer.resize(static_cast<qsizetype>(CHUNK_SIZE));

    const auto isCancelled = [&cancelToken]() {
        return cancelToken->load(std::memory_order_relaxed);
    };

    for (const QString& sourcePath : paths) {
        if (isCancelled())
            return CopyResult::Cancelled;

        QFile source(sourcePath);

        if (!source.open(QIODevice::ReadOnly)) {
            *error = QStringLiteral("Failed to open %1: %2")
                         .arg(sourcePath, source.errorString());

            return CopyResult::Failed;
        }

        const QFileInfo sourceInfo(sourcePath);

        const QString destinationPath =
            uniqueDestinationPath(
                destinationDirectory,
                sourceInfo.fileName()
            );

        if (destinationPath.isEmpty()) {
            *error = QStringLiteral(
                "Could not create a unique destination name for %1"
            ).arg(sourceInfo.fileName());

            return CopyResult::Failed;
        }

        QFile destination(destinationPath);

        if (!destination.open(
                QIODevice::WriteOnly
                | QIODevice::Truncate
            )) {
            *error = QStringLiteral("Failed to create %1: %2")
                         .arg(
                             destinationPath,
                             destination.errorString()
                         );

            return CopyResult::Failed;
        }

        while (!source.atEnd()) {
            if (isCancelled()) {
                destination.close();
                QFile::remove(destinationPath);
                return CopyResult::Cancelled;
            }

            const qint64 bytesRead =
                source.read(
                    buffer.data(),
                    CHUNK_SIZE
                );

            if (bytesRead < 0) {
                *error = QStringLiteral("Failed to read %1: %2")
                             .arg(
                                 sourcePath,
                                 source.errorString()
                             );

                destination.close();
                QFile::remove(destinationPath);
                return CopyResult::Failed;
            }

            if (bytesRead == 0)
                break;

            qint64 offset = 0;

            while (offset < bytesRead) {
                if (isCancelled()) {
                    destination.close();
                    QFile::remove(destinationPath);
                    return CopyResult::Cancelled;
                }

                const qint64 bytesWritten =
                    destination.write(
                        buffer.constData()
                            + static_cast<qsizetype>(offset),
                        bytesRead - offset
                    );

                if (bytesWritten <= 0) {
                    *error = QStringLiteral(
                        "Failed to write %1: %2"
                    ).arg(
                        destinationPath,
                        destination.errorString()
                    );

                    destination.close();
                    QFile::remove(destinationPath);
                    return CopyResult::Failed;
                }

                offset += bytesWritten;
                copiedBytes += bytesWritten;

                if (totalBytes > 0) {
                    const qreal progress =
                        std::min(
                            qreal(1.0),
                            static_cast<qreal>(copiedBytes)
                                / static_cast<qreal>(totalBytes)
                        );

                    reportProgress(progress);
                }
            }
        }

        if (isCancelled()) {
            destination.close();
            QFile::remove(destinationPath);
            return CopyResult::Cancelled;
        }

        if (!destination.flush()) {
            *error = QStringLiteral("Failed to flush %1: %2")
                         .arg(
                             destinationPath,
                             destination.errorString()
                         );

            destination.close();
            QFile::remove(destinationPath);
            return CopyResult::Failed;
        }

        if (copiedPaths)
            copiedPaths->append(destinationPath);
    }

    if (isCancelled())
        return CopyResult::Cancelled;

    return CopyResult::Success;
}

void sendCompletionNotification(
    const QString& deviceId,
    int count
)
{
    QDBusInterface ping(
        QStringLiteral("org.kde.kdeconnect"),
        QStringLiteral(
            "/modules/kdeconnect/devices/%1/ping"
        ).arg(deviceId),
        QStringLiteral(
            "org.kde.kdeconnect.device.ping"
        ),
        QDBusConnection::sessionBus()
    );

    if (!ping.isValid())
        return;

    const QString message = count == 1
        ? QStringLiteral("File received from Caelestia")
        : QStringLiteral("%1 files received from Caelestia")
              .arg(count);

    ping.asyncCall(
        QStringLiteral("sendPing"),
        message
    );
}

} // namespace

KdeConnectTransfer::KdeConnectTransfer(QObject* parent)
    : QObject(parent)
{
}

bool KdeConnectTransfer::running() const
{
    return m_running;
}

bool KdeConnectTransfer::receiving() const
{
    return m_receiving;
}

qreal KdeConnectTransfer::progress() const
{
    return m_progress;
}

QString KdeConnectTransfer::deviceId() const
{
    return m_deviceId;
}

void KdeConnectTransfer::share(
    const QString& deviceId,
    const QVariantList& urls
)
{
    if (m_running) {
        emit failed(
            deviceId,
            QStringLiteral(
                "A file transfer is already in progress"
            )
        );

        return;
    }

    if (deviceId.isEmpty() || urls.isEmpty())
        return;

    QStringList paths;
    qint64 totalBytes = 0;

    for (const QVariant& value : urls) {
        const QUrl url = value.toUrl();

        if (!url.isValid() || !url.isLocalFile()) {
            emit failed(
                deviceId,
                QStringLiteral(
                    "Only local files can be transferred"
                )
            );

            return;
        }

        const QString path = url.toLocalFile();
        const QFileInfo info(path);

        if (!info.exists() || !info.isFile()) {
            emit failed(
                deviceId,
                QStringLiteral(
                    "%1 is not a regular file"
                ).arg(path)
            );

            return;
        }

        paths.append(path);
        totalBytes += info.size();
    }

    if (paths.isEmpty())
        return;

    auto cancelToken =
        std::make_shared<std::atomic_bool>(false);

    m_cancelToken = cancelToken;

    setDeviceId(deviceId);
    setReceiving(false);
    setProgress(0.0);
    setRunning(true);

    const int count =
        static_cast<int>(paths.size());

    QPointer<KdeConnectTransfer> self(this);

    auto* thread = QThread::create(
        [self,
         deviceId,
         paths,
         totalBytes,
         count,
         cancelToken]() {
            QString destinationDirectory;
            QString error;

            if (!mountDownloadDirectory(
                    deviceId,
                    &destinationDirectory,
                    &error
                )) {
                if (!self)
                    return;

                QMetaObject::invokeMethod(
                    self.data(),
                    [self,
                     deviceId,
                     error,
                     cancelToken]() {
                        if (!self)
                            return;

                        self->m_cancelToken.reset();
                        self->setProgress(0.0);
                        self->setRunning(false);

                        if (cancelToken->load(
                                std::memory_order_relaxed
                            )) {
                            emit self->cancelled(deviceId);
                        } else {
                            emit self->failed(
                                deviceId,
                                error
                            );
                        }
                    },
                    Qt::QueuedConnection
                );

                return;
            }

            if (cancelToken->load(
                    std::memory_order_relaxed
                )) {
                if (!self)
                    return;

                QMetaObject::invokeMethod(
                    self.data(),
                    [self, deviceId]() {
                        if (!self)
                            return;

                        self->m_cancelToken.reset();
                        self->setProgress(0.0);
                        self->setRunning(false);
                        emit self->cancelled(deviceId);
                    },
                    Qt::QueuedConnection
                );

                return;
            }

            const auto reportProgress =
                [self](qreal progress) {
                    if (!self)
                        return;

                    QMetaObject::invokeMethod(
                        self.data(),
                        [self, progress]() {
                            if (self)
                                self->setProgress(progress);
                        },
                        Qt::QueuedConnection
                    );
                };

            const CopyResult result =
                copyFiles(
                    paths,
                    destinationDirectory,
                    totalBytes,
                    cancelToken,
                    reportProgress,
                    &error
                );

            if (result == CopyResult::Cancelled) {
                if (!self)
                    return;

                QMetaObject::invokeMethod(
                    self.data(),
                    [self, deviceId]() {
                        if (!self)
                            return;

                        self->m_cancelToken.reset();
                        self->setProgress(0.0);
                        self->setRunning(false);
                        emit self->cancelled(deviceId);
                    },
                    Qt::QueuedConnection
                );

                return;
            }

            if (result == CopyResult::Failed) {
                if (!self)
                    return;

                QMetaObject::invokeMethod(
                    self.data(),
                    [self, deviceId, error]() {
                        if (!self)
                            return;

                        self->m_cancelToken.reset();
                        self->setProgress(0.0);
                        self->setRunning(false);
                        emit self->failed(
                            deviceId,
                            error
                        );
                    },
                    Qt::QueuedConnection
                );

                return;
            }

            if (cancelToken->load(
                    std::memory_order_relaxed
                )) {
                if (!self)
                    return;

                QMetaObject::invokeMethod(
                    self.data(),
                    [self, deviceId]() {
                        if (!self)
                            return;

                        self->m_cancelToken.reset();
                        self->setProgress(0.0);
                        self->setRunning(false);
                        emit self->cancelled(deviceId);
                    },
                    Qt::QueuedConnection
                );

                return;
            }

            sendCompletionNotification(
                deviceId,
                count
            );

            if (!self)
                return;

            QMetaObject::invokeMethod(
                self.data(),
                [self, deviceId, count]() {
                    if (!self)
                        return;

                    self->m_cancelToken.reset();
                    self->setProgress(1.0);
                    self->setRunning(false);
                    emit self->shared(
                        deviceId,
                        count
                    );
                },
                Qt::QueuedConnection
            );
        }
    );

    connect(
        thread,
        &QThread::finished,
        thread,
        &QObject::deleteLater
    );

    thread->start();
}

void KdeConnectTransfer::download(
    const QString& deviceId,
    const QString& sourcePath
)
{
    if (m_running) {
        emit downloadFailed(
            deviceId,
            QStringLiteral(
                "A file transfer is already in progress"
            )
        );

        return;
    }

    if (deviceId.isEmpty() || sourcePath.isEmpty())
        return;

    auto cancelToken =
        std::make_shared<std::atomic_bool>(false);

    m_cancelToken = cancelToken;

    setDeviceId(deviceId);
    setReceiving(true);
    setProgress(0.0);
    setRunning(true);

    QPointer<KdeConnectTransfer> self(this);

    auto* thread = QThread::create(
        [self,
         deviceId,
         sourcePath,
         cancelToken]() {
            QString error;
            QVariantMap directories;

            if (!ensureDeviceMounted(
                    deviceId,
                    &directories,
                    &error
                )) {
                if (!self)
                    return;

                QMetaObject::invokeMethod(
                    self.data(),
                    [self,
                     deviceId,
                     error,
                     cancelToken]() {
                        if (!self)
                            return;

                        self->m_cancelToken.reset();
                        self->setProgress(0.0);
                        self->setRunning(false);
                        self->setReceiving(false);

                        if (cancelToken->load(
                                std::memory_order_relaxed
                            )) {
                            emit self->downloadCancelled(
                                deviceId
                            );
                        } else {
                            emit self->downloadFailed(
                                deviceId,
                                error
                            );
                        }
                    },
                    Qt::QueuedConnection
                );

                return;
            }

            if (cancelToken->load(
                    std::memory_order_relaxed
                )) {
                if (!self)
                    return;

                QMetaObject::invokeMethod(
                    self.data(),
                    [self, deviceId]() {
                        if (!self)
                            return;

                        self->m_cancelToken.reset();
                        self->setProgress(0.0);
                        self->setRunning(false);
                        self->setReceiving(false);

                        emit self->downloadCancelled(
                            deviceId
                        );
                    },
                    Qt::QueuedConnection
                );

                return;
            }

            if (!pathInsideDirectories(
                    sourcePath,
                    directories
                )) {
                error = QStringLiteral(
                    "The selected file is outside the mounted phone storage"
                );

                if (!self)
                    return;

                QMetaObject::invokeMethod(
                    self.data(),
                    [self, deviceId, error]() {
                        if (!self)
                            return;

                        self->m_cancelToken.reset();
                        self->setProgress(0.0);
                        self->setRunning(false);
                        self->setReceiving(false);

                        emit self->downloadFailed(
                            deviceId,
                            error
                        );
                    },
                    Qt::QueuedConnection
                );

                return;
            }

            const QFileInfo sourceInfo(sourcePath);

            if (!sourceInfo.exists()
                    || !sourceInfo.isFile()) {
                error = QStringLiteral(
                    "%1 is not a regular file"
                ).arg(sourcePath);

                if (!self)
                    return;

                QMetaObject::invokeMethod(
                    self.data(),
                    [self, deviceId, error]() {
                        if (!self)
                            return;

                        self->m_cancelToken.reset();
                        self->setProgress(0.0);
                        self->setRunning(false);
                        self->setReceiving(false);

                        emit self->downloadFailed(
                            deviceId,
                            error
                        );
                    },
                    Qt::QueuedConnection
                );

                return;
            }

            QString destinationDirectory =
                QStandardPaths::writableLocation(
                    QStandardPaths::DownloadLocation
                );

            if (destinationDirectory.isEmpty()) {
                destinationDirectory =
                    QDir::home().filePath(
                        QStringLiteral("Downloads")
                    );
            }

            if (!QDir().mkpath(
                    destinationDirectory
                )) {
                error = QStringLiteral(
                    "Failed to create download directory: %1"
                ).arg(destinationDirectory);

                if (!self)
                    return;

                QMetaObject::invokeMethod(
                    self.data(),
                    [self, deviceId, error]() {
                        if (!self)
                            return;

                        self->m_cancelToken.reset();
                        self->setProgress(0.0);
                        self->setRunning(false);
                        self->setReceiving(false);

                        emit self->downloadFailed(
                            deviceId,
                            error
                        );
                    },
                    Qt::QueuedConnection
                );

                return;
            }

            const auto reportProgress =
                [self](qreal progress) {
                    if (!self)
                        return;

                    QMetaObject::invokeMethod(
                        self.data(),
                        [self, progress]() {
                            if (self)
                                self->setProgress(progress);
                        },
                        Qt::QueuedConnection
                    );
                };

            QStringList copiedPaths;

            const CopyResult result =
                copyFiles(
                    QStringList {sourcePath},
                    destinationDirectory,
                    sourceInfo.size(),
                    cancelToken,
                    reportProgress,
                    &error,
                    &copiedPaths
                );

            if (result == CopyResult::Cancelled) {
                if (!self)
                    return;

                QMetaObject::invokeMethod(
                    self.data(),
                    [self, deviceId]() {
                        if (!self)
                            return;

                        self->m_cancelToken.reset();
                        self->setProgress(0.0);
                        self->setRunning(false);
                        self->setReceiving(false);

                        emit self->downloadCancelled(
                            deviceId
                        );
                    },
                    Qt::QueuedConnection
                );

                return;
            }

            if (result == CopyResult::Failed) {
                if (!self)
                    return;

                QMetaObject::invokeMethod(
                    self.data(),
                    [self, deviceId, error]() {
                        if (!self)
                            return;

                        self->m_cancelToken.reset();
                        self->setProgress(0.0);
                        self->setRunning(false);
                        self->setReceiving(false);

                        emit self->downloadFailed(
                            deviceId,
                            error
                        );
                    },
                    Qt::QueuedConnection
                );

                return;
            }

            if (copiedPaths.isEmpty()) {
                error = QStringLiteral(
                    "The downloaded file path is unavailable"
                );

                if (!self)
                    return;

                QMetaObject::invokeMethod(
                    self.data(),
                    [self, deviceId, error]() {
                        if (!self)
                            return;

                        self->m_cancelToken.reset();
                        self->setProgress(0.0);
                        self->setRunning(false);
                        self->setReceiving(false);

                        emit self->downloadFailed(
                            deviceId,
                            error
                        );
                    },
                    Qt::QueuedConnection
                );

                return;
            }

            const QString destinationPath =
                copiedPaths.constFirst();

            if (!self)
                return;

            QMetaObject::invokeMethod(
                self.data(),
                [self,
                 deviceId,
                 destinationPath]() {
                    if (!self)
                        return;

                    self->m_cancelToken.reset();
                    self->setProgress(1.0);
                    self->setRunning(false);
                    self->setReceiving(false);

                    emit self->downloaded(
                        deviceId,
                        destinationPath
                    );
                },
                Qt::QueuedConnection
            );
        }
    );

    connect(
        thread,
        &QThread::finished,
        thread,
        &QObject::deleteLater
    );

    thread->start();
}

void KdeConnectTransfer::cancel()
{
    if (!m_running || !m_cancelToken)
        return;

    m_cancelToken->store(
        true,
        std::memory_order_relaxed
    );
}

void KdeConnectTransfer::mount(
    const QString& deviceId
)
{
    if (deviceId.isEmpty())
        return;

    if (m_running) {
        emit mountFailed(
            deviceId,
            QStringLiteral(
                "Cannot mount storage while a transfer is in progress"
            )
        );

        return;
    }

    QPointer<KdeConnectTransfer> self(this);

    auto* thread = QThread::create(
        [self, deviceId]() {
            QString error;
            QVariantMap directories;

            if (!ensureDeviceMounted(
                    deviceId,
                    &directories,
                    &error
                )) {
                if (!self)
                    return;

                QMetaObject::invokeMethod(
                    self.data(),
                    [self, deviceId, error]() {
                        if (self) {
                            emit self->mountFailed(
                                deviceId,
                                error
                            );
                        }
                    },
                    Qt::QueuedConnection
                );

                return;
            }

            bool mounted = false;
            QString mountPoint;
            QVariantMap stateDirectories;

            if (!readMountState(
                    deviceId,
                    &mounted,
                    &mountPoint,
                    &stateDirectories,
                    &error
                )) {
                if (!self)
                    return;

                QMetaObject::invokeMethod(
                    self.data(),
                    [self, deviceId, error]() {
                        if (self) {
                            emit self->mountFailed(
                                deviceId,
                                error
                            );
                        }
                    },
                    Qt::QueuedConnection
                );

                return;
            }

            if (!self)
                return;

            QMetaObject::invokeMethod(
                self.data(),
                [self,
                 deviceId,
                 mounted,
                 mountPoint,
                 stateDirectories]() {
                    if (!self)
                        return;

                    emit self->mountStateChanged(
                        deviceId,
                        mounted,
                        mountPoint,
                        stateDirectories
                    );
                },
                Qt::QueuedConnection
            );
        }
    );

    connect(
        thread,
        &QThread::finished,
        thread,
        &QObject::deleteLater
    );

    thread->start();
}

void KdeConnectTransfer::unmount(
    const QString& deviceId
)
{
    if (deviceId.isEmpty())
        return;

    if (m_running) {
        emit mountFailed(
            deviceId,
            QStringLiteral(
                "Cannot unmount storage while a transfer is in progress"
            )
        );

        return;
    }

    QPointer<KdeConnectTransfer> self(this);

    auto* thread = QThread::create(
        [self, deviceId]() {
            QDBusInterface sftp(
                QStringLiteral("org.kde.kdeconnect"),
                sftpObjectPath(deviceId),
                QStringLiteral(
                    "org.kde.kdeconnect.device.sftp"
                ),
                QDBusConnection::sessionBus()
            );

            QString error;

            if (!sftp.isValid()) {
                error = sftp.lastError().message();

                if (error.isEmpty()) {
                    error = QStringLiteral(
                        "KDE Connect SFTP interface is unavailable"
                    );
                }
            } else {
                const QDBusReply<void> reply =
                    sftp.call(
                        QStringLiteral("unmount")
                    );

                if (!reply.isValid())
                    error = reply.error().message();
            }

            if (!self)
                return;

            QMetaObject::invokeMethod(
                self.data(),
                [self, deviceId, error]() {
                    if (!self)
                        return;

                    if (!error.isEmpty()) {
                        emit self->mountFailed(
                            deviceId,
                            error
                        );

                        return;
                    }

                    emit self->mountStateChanged(
                        deviceId,
                        false,
                        QString(),
                        QVariantMap()
                    );
                },
                Qt::QueuedConnection
            );
        }
    );

    connect(
        thread,
        &QThread::finished,
        thread,
        &QObject::deleteLater
    );

    thread->start();
}

void KdeConnectTransfer::refreshMount(
    const QString& deviceId
)
{
    if (deviceId.isEmpty())
        return;

    QPointer<KdeConnectTransfer> self(this);

    auto* thread = QThread::create(
        [self, deviceId]() {
            bool mounted = false;
            QString mountPoint;
            QVariantMap directories;
            QString error;

            if (!readMountState(
                    deviceId,
                    &mounted,
                    &mountPoint,
                    &directories,
                    &error
                )) {
                //
                // IMPORTANT:
                //
                // A failed refresh does NOT mean the device
                // became unmounted.
                //
                // Preserve the last known mount state and only
                // report the refresh failure.
                //
                if (!self)
                    return;

                QMetaObject::invokeMethod(
                    self.data(),
                    [self, deviceId, error]() {
                        if (!self)
                            return;

                        emit self->mountFailed(
                            deviceId,
                            error
                        );
                    },
                    Qt::QueuedConnection
                );

                return;
            }

            if (!self)
                return;

            QMetaObject::invokeMethod(
                self.data(),
                [self,
                 deviceId,
                 mounted,
                 mountPoint,
                 directories]() {
                    if (!self)
                        return;

                    emit self->mountStateChanged(
                        deviceId,
                        mounted,
                        mountPoint,
                        directories
                    );
                },
                Qt::QueuedConnection
            );
        }
    );

    connect(
        thread,
        &QThread::finished,
        thread,
        &QObject::deleteLater
    );

    thread->start();
}

void KdeConnectTransfer::setRunning(
    bool running
)
{
    if (m_running == running)
        return;

    m_running = running;
    emit runningChanged();
}

void KdeConnectTransfer::setReceiving(
    bool receiving
)
{
    if (m_receiving == receiving)
        return;

    m_receiving = receiving;
    emit receivingChanged();
}

void KdeConnectTransfer::setProgress(
    qreal progress
)
{
    if (qFuzzyCompare(
            m_progress + 1.0,
            progress + 1.0
        )) {
        return;
    }

    m_progress = progress;
    emit progressChanged();
}

void KdeConnectTransfer::setDeviceId(
    const QString& deviceId
)
{
    if (m_deviceId == deviceId)
        return;

    m_deviceId = deviceId;
    emit deviceIdChanged();
}
