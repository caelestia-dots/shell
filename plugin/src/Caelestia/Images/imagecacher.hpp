#pragma once

#include <qmutex.h>
#include <qobject.h>
#include <qset.h>
#include <qsize.h>
#include <qstring.h>

namespace caelestia::images {

class ImageCacher : public QObject {
    Q_OBJECT

public:
    enum class FillMode {
        Crop,
        Fit,
        Stretch,
    };

    static ImageCacher* instance();

    static const QString& cacheDir();
    static QString cachePathFor(const QString& sourcePath, const QSize& size, FillMode fillMode);

    void schedule(const QString& sourcePath, const QSize& size, FillMode fillMode);
    void schedule(const QString& sourcePath, const QString& cachePath, const QSize& size, FillMode fillMode);

    static bool isVideoLike(const QString& path);

    // Run the cache-generation job synchronously. Already-safe to call
    // from worker threads (the image provider does this on its QRunnable).
    // Used when the caller can't tolerate the round-trip latency of
    // schedule() + file-watcher, e.g. for the first request of a video
    // thumbnail where QImage("path") would otherwise return null.
    static void runJob(const QString& sourcePath, const QString& cachePath, const QSize& size, FillMode fillMode);

private:
    explicit ImageCacher(QObject* parent = nullptr);

    static bool runFfmpegJob(const QString& sourcePath, const QString& cachePath, const QSize& size);

    QMutex m_mutex;
    QSet<QString> m_inflight;
};

} // namespace caelestia::images
