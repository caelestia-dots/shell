#include "videothumbnailer.hpp"
#include <QFileInfo>
#include <QDir>
#include <QCryptographicHash>
#include <QProcess>
#include <QtConcurrent/QtConcurrent>

namespace caelestia::internal {

VideoThumbnailer::VideoThumbnailer(QObject* parent)
    : QObject(parent)
{}

QString VideoThumbnailer::path() const { return m_path; }
void VideoThumbnailer::setPath(const QString& path) {
    if (m_path == path) return;
    m_path = path;
    emit pathChanged();

    if (m_path.isEmpty() || m_cacheDir.isEmpty())
        return;

    // Save a local copy of the path for this task
    const QString taskPath = m_path;

    QtConcurrent::run([this, taskPath]() {
        QString sha = sha256sum(taskPath);
        QString filename = QString("%1@280x158.png").arg(sha);
        QString fullCache = QDir(m_cacheDir.toLocalFile()).filePath(filename);

        QFileInfo fi(fullCache);
        if (!fi.exists()) {
            generateThumbnail(taskPath, fullCache);
        }

        // Check if this task is still relevant
        if (taskPath != m_path) return;  // <-- ignore if user changed path

        m_cachePath = QUrl::fromLocalFile(fullCache);
        m_ready = true;

        // Emit signals on main thread
        QMetaObject::invokeMethod(this, [this]() {
            emit cachePathChanged();
            emit readyChanged();
        });
    });
};



QUrl VideoThumbnailer::cacheDir() const { return m_cacheDir; }
void VideoThumbnailer::setCacheDir(const QUrl& dir) {
    if (m_cacheDir == dir) return;
    m_cacheDir = dir;
    if (!m_cacheDir.path().endsWith('/'))
        m_cacheDir.setPath(m_cacheDir.path() + '/');
    emit cacheDirChanged();
}

QUrl VideoThumbnailer::cachePath() const { return m_cachePath; }
bool VideoThumbnailer::ready() const { return m_ready; }

void VideoThumbnailer::generateThumbnail(const QString& path, const QString& cacheFile) {
    QDir().mkpath(QFileInfo(cacheFile).absolutePath());

    // Use ffmpeg to extract the first frame
    QStringList args{
        "-y",           // overwrite
        "-i", path,
        "-vf", "scale=280:158:force_original_aspect_ratio=increase,crop=280:158",
        "-vframes", "1",
        cacheFile
    };

    QProcess ffmpeg;
    ffmpeg.start("ffmpeg", args);
    ffmpeg.waitForFinished(-1);
}

QString VideoThumbnailer::sha256sum(const QString& path) const {
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly))
        return QString::number(qHash(path));

    QCryptographicHash hash(QCryptographicHash::Sha256);
    hash.addData(&file);
    file.close();
    return hash.result().toHex();
}

} // namespace caelestia::internal
