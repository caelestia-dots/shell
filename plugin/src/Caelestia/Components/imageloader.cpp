#include "imageloader.hpp"

#include <qfuture.h>
#include <qimagereader.h>
#include <qpainter.h>

namespace caelestia::shell::components {

ImageLoader::ImageLoader(QQuickItem* parent)
    : QQuickPaintedItem(parent) {}

void ImageLoader::paint(QPainter* painter) {
    if (!m_image.isNull())
        painter->drawImage(boundingRect(), m_image);
}

QString ImageLoader::source() const {
    return m_source;
}

void ImageLoader::setSource(const QString& source) {
    if (m_source == source)
        return;

    m_source = source;
    emit sourceChanged();

    const auto size = QImageReader(source).size();
    setImplicitSize(size.width(), size.height());

    const auto generation = ++m_generation;
    QtFuture::makeReadyValueFuture(source)
        .then(QtFuture::Launch::Async,
            [](const QString& path) {
                return QImage(path);
            })
        .then(this, [this, generation](const QImage& image) {
            if (generation != m_generation)
                return;

            m_image = image;
            update();
            emit imageChanged();
        });
}

QImage ImageLoader::image() const {
    return m_image;
}

} // namespace caelestia::shell::components
