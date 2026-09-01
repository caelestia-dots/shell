#include "kdeconnecttransfer.hpp"

#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QMetaObject>
#include <QPointer>
#include <QThread>
#include <QUrl>

#include <algorithm>
#include <functional>

namespace {

constexpr qint64 CHUNK_SIZE = 1024 * 1024;

QString findDownloadDirectory(const QVariantMap& directories)
{
    QStringList roots = directories.keys();

    std::sort(roots.begin(), roots.end(), [](const QString& lhs, const QString& rhs) {
        return lhs.size() < rhs.size();
    });

    for (const QString& root : roots) {
        const QDir directory(root);

        for (const QString& name : {QStringLiteral("Download"), QStringLiteral("Downloads")}) {
            const QString candidate = directory.filePath(name);
            const QFileInfo info(candidate);

            if (info.exists() && info.isDir())
                return info.absoluteFilePath();
        }
    }

    return {};
}

QString uniqueDestinationPath(const QString& directory, const QString& fileName)
{
    const QDir dir(directory);

    QString candidate = dir.filePath(fileName);

    if (!QFileInfo::exists(candidate))
        return candidate;

    const qsizetype dot = fileName.lastIndexOf(QLatin1Char('.'));

    const QString stem = dot > 0 ? fileName.left(dot) : fileName;
    const QString extension = dot > 0 ? fileName.mid(dot) : QString();

    for (int index = 1; index < 10000; ++index) {
        candidate = dir.filePath(
            QStringLiteral("%1 (%2)%3").arg(stem, QString::number(index), extension)
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
    const QString objectPath =
        QStringLiteral("/modules/kdeconnect/devices/%1/sftp").arg(deviceId);

    QDBusInterface sftp(
        QStringLiteral("org.kde.kdeconnect"),
        objectPath,
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

    const QString directory =
        findDownloadDirectory(directoriesReply.value());

    if (directory.isEmpty()) {
        *error = QStringLiteral("Could not find a Download directory on the device");
        return false;
    }

    *downloadDirectory = directory;
    return true;
}

bool copyFiles(
    const QStringList& paths,
    const QString& destinationDirectory,
    qint64 totalBytes,
    const std::function<void(qreal)>& reportProgress,
    QString* error
)
{
    qint64 copiedBytes = 0;

    QByteArray buffer;
    buffer.resize(static_cast<qsizetype>(CHUNK_SIZE));

    for (const QString& sourcePath : paths) {
        QFile source(sourcePath);

        if (!source.open(QIODevice::ReadOnly)) {
            *error = QStringLiteral("Failed to open %1: %2")
                         .arg(sourcePath, source.errorString());
            return false;
        }

        const QFileInfo sourceInfo(sourcePath);
        const QString destinationPath =
            uniqueDestinationPath(destinationDirectory, sourceInfo.fileName());

        if (destinationPath.isEmpty()) {
            *error = QStringLiteral("Could not create a unique destination name for %1")
                         .arg(sourceInfo.fileName());
            return false;
        }

        QFile destination(destinationPath);

        if (!destination.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
            *error = QStringLiteral("Failed to create %1: %2")
                         .arg(destinationPath, destination.errorString());
            return false;
        }

        while (!source.atEnd()) {
            const qint64 bytesRead =
                source.read(buffer.data(), CHUNK_SIZE);

            if (bytesRead < 0) {
                *error = QStringLiteral("Failed to read %1: %2")
                             .arg(sourcePath, source.errorString());

                destination.close();
                QFile::remove(destinationPath);
                return false;
            }

            if (bytesRead == 0)
                break;

            qint64 offset = 0;

            while (offset < bytesRead) {
                const qint64 bytesWritten = destination.write(
                    buffer.constData() + static_cast<qsizetype>(offset),
                    bytesRead - offset
                );

                if (bytesWritten <= 0) {
                    *error = QStringLiteral("Failed to write %1: %2")
                                 .arg(destinationPath, destination.errorString());

                    destination.close();
                    QFile::remove(destinationPath);
                    return false;
                }

                offset += bytesWritten;
                copiedBytes += bytesWritten;

                if (totalBytes > 0) {
                    const qreal progress = std::min(
                        qreal(1.0),
                        static_cast<qreal>(copiedBytes)
                            / static_cast<qreal>(totalBytes)
                    );

                    reportProgress(progress);
                }
            }
        }

        if (!destination.flush()) {
            *error = QStringLiteral("Failed to flush %1: %2")
                         .arg(destinationPath, destination.errorString());

            destination.close();
            QFile::remove(destinationPath);
            return false;
        }
    }

    return true;
}

void sendCompletionNotification(const QString& deviceId, int count)
{
    QDBusInterface ping(
        QStringLiteral("org.kde.kdeconnect"),
        QStringLiteral("/modules/kdeconnect/devices/%1/ping").arg(deviceId),
        QStringLiteral("org.kde.kdeconnect.device.ping"),
        QDBusConnection::sessionBus()
    );

    if (!ping.isValid())
        return;

    const QString message = count == 1
        ? QStringLiteral("File received from Caelestia")
        : QStringLiteral("%1 files received from Caelestia").arg(count);

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
            QStringLiteral("A file transfer is already in progress")
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
                QStringLiteral("Only local files can be transferred")
            );
            return;
        }

        const QString path = url.toLocalFile();
        const QFileInfo info(path);

        if (!info.exists() || !info.isFile()) {
            emit failed(
                deviceId,
                QStringLiteral("%1 is not a regular file").arg(path)
            );
            return;
        }

        paths.append(path);
        totalBytes += info.size();
    }

    if (paths.isEmpty())
        return;

    setDeviceId(deviceId);
    setProgress(0.0);
    setRunning(true);

    const int count = static_cast<int>(paths.size());
    QPointer<KdeConnectTransfer> self(this);

    auto* thread = QThread::create(
        [self, deviceId, paths, totalBytes, count]() {
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
                    [self, deviceId, error]() {
                        if (!self)
                            return;

                        self->setProgress(0.0);
                        self->setRunning(false);
                        emit self->failed(deviceId, error);
                    },
                    Qt::QueuedConnection
                );

                return;
            }

            const auto reportProgress = [self](qreal progress) {
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

            if (!copyFiles(
                    paths,
                    destinationDirectory,
                    totalBytes,
                    reportProgress,
                    &error
                )) {
                if (!self)
                    return;

                QMetaObject::invokeMethod(
                    self.data(),
                    [self, deviceId, error]() {
                        if (!self)
                            return;

                        self->setProgress(0.0);
                        self->setRunning(false);
                        emit self->failed(deviceId, error);
                    },
                    Qt::QueuedConnection
                );

                return;
            }

            sendCompletionNotification(deviceId, count);

            if (!self)
                return;

            QMetaObject::invokeMethod(
                self.data(),
                [self, deviceId, count]() {
                    if (!self)
                        return;

                    self->setProgress(1.0);
                    self->setRunning(false);
                    emit self->shared(deviceId, count);
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

void KdeConnectTransfer::setRunning(bool running)
{
    if (m_running == running)
        return;

    m_running = running;
    emit runningChanged();
}

void KdeConnectTransfer::setProgress(qreal progress)
{
    if (qFuzzyCompare(m_progress + 1.0, progress + 1.0))
        return;

    m_progress = progress;
    emit progressChanged();
}

void KdeConnectTransfer::setDeviceId(const QString& deviceId)
{
    if (m_deviceId == deviceId)
        return;

    m_deviceId = deviceId;
    emit deviceIdChanged();
}
