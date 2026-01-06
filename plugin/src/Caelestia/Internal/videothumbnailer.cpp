#include "videothumbnailer.hpp"
#include <QCryptographicHash>
#include <QDebug>
#include <QDir>
#include <QFileInfo>
#include <QProcess>

namespace caelestia::internal {

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

        QFile file(path);
        QString sha;
        if (file.open(QIODevice::ReadOnly)) {
            QCryptographicHash hash(QCryptographicHash::Sha256);
            constexpr qint64 bufferSize = 1024 * 1024;
            QByteArray buffer(bufferSize, Qt::Uninitialized);
            while (!file.atEnd()) {
                qint64 readBytes = file.read(buffer.data(), buffer.size());
                if (readBytes > 0)
                    hash.addData(QByteArrayView(buffer.constData(), readBytes));
            }
            sha = hash.result().toHex();
        } else {
            qWarning() << "Failed to open video for hashing:" << path;
            sha = QString::number(qHash(path));
        }

        QString filename = QStringLiteral("%1@280x158.png").arg(sha);
        QString fullCache = QDir(cacheDir).filePath(filename);

        if (!QFileInfo::exists(fullCache)) {
            QDir().mkpath(QFileInfo(fullCache).absolutePath());
            QProcess ffmpeg;
            const QStringList args{ "-y", "-loglevel", "error", "-i", path, "-vframes", "1", fullCache };
            ffmpeg.start("ffmpeg", args);
            if (!ffmpeg.waitForStarted(2000)) {
                qWarning() << "Failed to start ffmpeg for" << path;
            } else if (!ffmpeg.waitForFinished(4000)) {
                ffmpeg.kill();
                ffmpeg.waitForFinished();
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
    }

    m_workerThread = new QThread(this);
    Worker* worker = new Worker;
    worker->path = m_path;
    worker->cacheDir = m_cacheDir.toLocalFile();
    worker->moveToThread(m_workerThread);

    connect(m_workerThread, &QThread::started, worker, &Worker::process);
    connect(worker, &Worker::finished, this, &VideoThumbnailer::handleWorkerFinished);
    connect(worker, &Worker::finished, worker, &QObject::deleteLater);
    connect(m_workerThread, &QThread::finished, m_workerThread, &QObject::deleteLater);

    m_workerThread->start();
}

void VideoThumbnailer::handleWorkerFinished(const QString& cachePath) {
    m_cachePath = cachePath;
    emit cachePathChanged();

    m_ready = true;
    emit readyChanged();

    if (m_workerThread) {
        m_workerThread->quit();
        m_workerThread = nullptr;
    }
}

} // namespace caelestia::internal

#include "videothumbnailer.moc"
