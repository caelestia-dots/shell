#include "videothumbnailer.hpp"
#include <QCryptographicHash>
#include <QDebug>
#include <QDir>
#include <QFileInfo>
#include <QProcess>
#include <QThread>

namespace caelestia::internal {

QHash<QString, QString> VideoThumbnailer::s_memoryCache;

class VideoThumbnailer::Worker : public QObject {
    Q_OBJECT

public:
    QString path;
    QString cacheDir;

signals:
    void finished(const QString& cachePath);

public slots:

    void process() {
        static const QStringList videoExtensions = { ".mp4", ".mkv", ".mov", ".avi", ".flv", ".webm", ".wmv" };

        QString ext = "." + QFileInfo(path).suffix().toLower();
        if (!videoExtensions.contains(ext)) {
            emit finished(path);
            return;
        }

        QFileInfo info(path);
        QByteArray key;
        key.reserve(256);

        key.append(info.absoluteFilePath().toUtf8());
        key.append('|');
        key.append(QByteArray::number(info.size()));
        key.append('|');
        key.append(QByteArray::number(info.lastModified().toSecsSinceEpoch()));

        QString hash = QString::number(qHash(key), 16);

        QString filename = QStringLiteral("%1@280x158.png").arg(hash);
        QString fullCache = QDir(cacheDir).filePath(filename);

        if (!QFileInfo::exists(fullCache)) {
            QDir().mkpath(QFileInfo(fullCache).absolutePath());

            QProcess ffmpeg;
            const QStringList args{ "-y", "-loglevel", "error", "-ss", "1", "-i", path, "-frames:v", "1", fullCache };
            ffmpeg.start("ffmpeg", args);

            if (!ffmpeg.waitForStarted(2000)) {
                qWarning() << "Failed to start ffmpeg for" << path;
                emit finished(path);
                return;
            }

            ffmpeg.waitForFinished(-1);

            if (ffmpeg.exitStatus() != QProcess::NormalExit || ffmpeg.exitCode() != 0) {
                qWarning() << "ffmpeg failed for" << path;
                emit finished(path);
                return;
            }
        }

        emit finished(fullCache);
    }
};

VideoThumbnailer::VideoThumbnailer(QObject* parent)
    : QObject(parent) {
    m_debounceTimer.setSingleShot(true);
    m_debounceTimer.setInterval(150);
    connect(&m_debounceTimer, &QTimer::timeout, this, &VideoThumbnailer::startProcessing);
}

VideoThumbnailer::~VideoThumbnailer() {
    if (m_workerThread) {
        m_workerThread->quit();
        m_workerThread->wait();
        delete m_workerThread;
        m_workerThread = nullptr;
    }
}

QString VideoThumbnailer::path() const {
    return m_path;
}

void VideoThumbnailer::setPath(const QString& path) {
    if (m_path == path)
        return;

    m_path = path;
    emit pathChanged();

    m_ready = false;
    emit readyChanged();

    if (s_memoryCache.contains(path)) {
        QString cachedPath = s_memoryCache.value(path);
        if (QFileInfo::exists(cachedPath)) {
            m_cachePath = cachedPath;
            emit cachePathChanged();

            m_ready = true;
            emit readyChanged();
            return;
        } else {
            s_memoryCache.remove(path);
        }
    }

    m_debounceTimer.start();
}

QUrl VideoThumbnailer::cacheDir() const {
    return m_cacheDir;
}

void VideoThumbnailer::setCacheDir(const QUrl& dir) {
    if (!dir.isValid())
        return;

    QUrl normalized = dir.isLocalFile() ? QUrl::fromLocalFile(dir.toLocalFile())
                                        : (dir.scheme().isEmpty() ? QUrl::fromLocalFile(dir.toString()) : m_cacheDir);

    if (normalized == m_cacheDir)
        return;

    m_cacheDir = normalized;
    emit cacheDirChanged();
}

QString VideoThumbnailer::cachePath() const {
    return m_cachePath;
}

bool VideoThumbnailer::ready() const {
    return m_ready;
}

void VideoThumbnailer::startProcessing() {
    if (m_path.isEmpty() || m_cacheDir.isEmpty())
        return;

    if (m_workerThread) {
        m_workerThread->quit();
        m_workerThread->wait();
        delete m_workerThread;
        m_workerThread = nullptr;
    }

    m_workerThread = new QThread(this);

    Worker* worker = new Worker;
    worker->path = m_path;
    worker->cacheDir = m_cacheDir.toLocalFile();

    worker->moveToThread(m_workerThread);

    connect(m_workerThread, &QThread::started, worker, &Worker::process);

    connect(worker, &Worker::finished, this, &VideoThumbnailer::handleWorkerFinished, Qt::QueuedConnection);

    connect(worker, &Worker::finished, m_workerThread, &QThread::quit);

    connect(m_workerThread, &QThread::finished, m_workerThread, &QObject::deleteLater);

    m_workerThread->start();
}

void VideoThumbnailer::handleWorkerFinished(const QString& cachePath) {
    m_cachePath = cachePath;
    emit cachePathChanged();

    m_ready = true;
    emit readyChanged();

    // Store in memory cache for instant future lookups
    s_memoryCache.insert(m_path, cachePath);

    m_workerThread = nullptr;
}

} // namespace caelestia::internal

#include "videothumbnailer.moc"
