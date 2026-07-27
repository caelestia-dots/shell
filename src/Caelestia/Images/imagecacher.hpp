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

private:
    explicit ImageCacher(QObject* parent = nullptr);

    static void runJob(const QString& sourcePath, const QString& cachePath, const QSize& size, FillMode fillMode);

    QMutex m_mutex;
    QSet<QString> m_inflight;
};

} // namespace caelestia::images
