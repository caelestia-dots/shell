#include "imageloader.hpp"

#include <qfuture.h>
#include <qimagereader.h>
#include <qquickwindow.h>
#include <qsgsimpletexturenode.h>
#include <qsgtexturematerial.h>

namespace caelestia::shell::components {

ImageLoader::ImageLoader(QQuickItem* parent)
    : QQuickItem(parent) {
    setFlag(ItemHasContents);
}

QSGNode* ImageLoader::updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData*) {
    auto* node = static_cast<QSGSimpleTextureNode*>(oldNode);
    if (m_image.isNull()) {
        delete node;
        return nullptr;
    }

    if (!node) {
        node = new QSGSimpleTextureNode;
        node->setOwnsTexture(true);
        node->setFiltering(QSGTexture::Linear);
        static_cast<QSGTextureMaterial*>(node->material())->setMipmapFiltering(QSGTexture::Linear);
        static_cast<QSGOpaqueTextureMaterial*>(node->opaqueMaterial())->setMipmapFiltering(QSGTexture::Linear);
        m_textureDirty = true;
    }

    if (m_textureDirty) {
        node->setTexture(window()->createTextureFromImage(m_image));
        m_textureDirty = false;
    }

    const auto source = m_sourceRect.isEmpty() ? QRectF(m_image.rect()) : m_sourceRect;
    const auto visible = source.intersected(QRectF(m_image.rect()));
    const auto sx = width() / source.width();
    const auto sy = height() / source.height();
    node->setRect(
        (visible.x() - source.x()) * sx, (visible.y() - source.y()) * sy, visible.width() * sx, visible.height() * sy);
    node->setSourceRect(visible);
    return node;
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
                return QImage(path).convertToFormat(QImage::Format_ARGB32_Premultiplied);
            })
        .then(this, [this, generation](const QImage& image) {
            if (generation != m_generation)
                return;

            m_image = image;
            m_textureDirty = true;
            update();
            emit imageChanged();
        });
}

QImage ImageLoader::image() const {
    return m_image;
}

QRectF ImageLoader::sourceRect() const {
    return m_sourceRect;
}

void ImageLoader::setSourceRect(const QRectF& sourceRect) {
    if (m_sourceRect == sourceRect)
        return;

    m_sourceRect = sourceRect;
    update();
    emit sourceRectChanged();
}

} // namespace caelestia::shell::components
