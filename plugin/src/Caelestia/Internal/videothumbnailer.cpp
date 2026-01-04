#include "videothumbnailer.hpp"
#include <QFileInfo>
#include <QDir>
#include <QCryptographicHash>
#include <QProcess>
#include <QtConcurrent/QtConcurrent>
#include <QDebug>

namespace caelestia::internal {


inline bool isVideoFile(const QString& path) {
    static const QStringList videoExtensions = { ".mp4", ".mkv", ".mov", ".avi", ".flv", ".webm", ".wmv" };
    QString ext = "." + QFileInfo(path).suffix().toLower();
    return videoExtensions.contains(ext);
}

VideoThumbnailer::VideoThumbnailer(QObject* parent)
    : QObject(parent)
{
    QThreadPool::globalInstance()->setMaxThreadCount(10);

    m_debounceTimer.setSingleShot(true);
    m_debounceTimer.setInterval(200);

    connect(&m_debounceTimer, &QTimer::timeout, this, [this]() {
        if (m_path.isEmpty() || m_cacheDir.isEmpty())
            return;

        const quint64 taskId   = ++m_taskId;
        const QString taskPath = m_path;
        const QString cacheDir = m_cacheDir.toLocalFile();

        (void)QtConcurrent::run([this, taskId, taskPath, cacheDir]() {

            if (taskId != m_taskId.loadAcquire())
                return;
        
            if (!isVideoFile(taskPath)) {
                QMetaObject::invokeMethod(this, [this, taskPath]() {
                    if (taskPath != m_path) return;
                    m_cachePath = taskPath;
                    if (!m_ready) {
                        m_ready = true;
                        emit cachePathChanged();
                        emit readyChanged();
                    }
                });
                return;
            }
        

            const QString sha      = sha256sum(taskPath);
            const QString filename = QStringLiteral("%1@280x158.png").arg(sha);
            const QString fullCache = QDir(cacheDir).filePath(filename);
        
            if (!QFileInfo::exists(fullCache)) {
                generateThumbnail(taskPath, fullCache);
            }
        
            QMetaObject::invokeMethod(this, [this, taskId, taskPath, fullCache]() {
                if (taskId != m_taskId.loadAcquire() || taskPath != m_path)
                    return;
            
                if (m_cachePath != fullCache) {
                    m_cachePath = fullCache;
                    emit cachePathChanged();
                }
            
                if (!m_ready) {
                    m_ready = true;
                    emit readyChanged();
                }
            });
        });
    });
}

QString VideoThumbnailer::path() const { return m_path; }

void VideoThumbnailer::setPath(const QString& path)
{
    if (m_path == path)
        return;

    m_path = path;
    emit pathChanged();

    m_ready = false;
    emit readyChanged();

    m_debounceTimer.start(); 
}

QUrl VideoThumbnailer::cacheDir() const { return m_cacheDir; }

void VideoThumbnailer::setCacheDir(const QUrl& dir)
{
    if (!dir.isValid())
        return;

    QUrl normalized = dir.isLocalFile() ? QUrl::fromLocalFile(dir.toLocalFile())
                                        : (dir.scheme().isEmpty() ? QUrl::fromLocalFile(dir.toString()) : m_cacheDir);

    if (normalized == m_cacheDir)
        return;

    m_cacheDir = normalized;
    emit cacheDirChanged();
}

QString VideoThumbnailer::cachePath() const { return m_cachePath; }
bool VideoThumbnailer::ready() const { return m_ready; }

void VideoThumbnailer::generateThumbnail(const QString& path, const QString& cacheFile)
{
    QFileInfo fileInfo(cacheFile);
    QDir().mkpath(fileInfo.absolutePath());

    const QStringList args{
        "-y",
        "-loglevel", "error",
        "-i", path,
        "-vframes", "1",
        cacheFile
    };

    QProcess ffmpeg;
    ffmpeg.start("ffmpeg", args);

    if (!ffmpeg.waitForStarted(2000)) {
        qWarning() << "Failed to start ffmpeg for" << path;
        return;
    }

    if (!ffmpeg.waitForFinished(4000)) {
        ffmpeg.kill();
        ffmpeg.waitForFinished();
    }
}

QString VideoThumbnailer::sha256sum(const QString& path) const
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "Failed to open file for hashing:" << path;
        return QString::number(qHash(path));
    }

    QCryptographicHash hash(QCryptographicHash::Sha256);

    constexpr qint64 bufferSize = 1024 * 1024; // 1 MB
    QByteArray buffer;
    buffer.resize(bufferSize);

    while (!file.atEnd()) {
        qint64 readBytes = file.read(buffer.data(), buffer.size());
        if (readBytes > 0)
            hash.addData(QByteArrayView(buffer.constData(), readBytes));
    }

    file.close();
    return hash.result().toHex();
}

} // namespace caelestia::internal
