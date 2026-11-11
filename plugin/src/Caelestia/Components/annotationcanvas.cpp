#include "annotationcanvas.hpp"

#include <qpainter.h>
#include <qquickwindow.h>
#include <qscreen.h>

namespace caelestia::shell::components {

namespace {

constexpr int k_previewMargin = 4;

} // namespace

AnnotationPreview::AnnotationPreview(AnnotationCanvas* canvas)
    : QQuickPaintedItem(canvas)
    , m_canvas(canvas) {
    setVisible(false);
}

void AnnotationPreview::paint(QPainter* painter) {
    const auto* document = m_canvas->document();
    if (!document)
        return;

    const auto& image = m_canvas->previewImage();
    if (!image.isNull()) {
        painter->setCompositionMode(QPainter::CompositionMode_Source);
        painter->drawImage(QPointF(0, 0), image);
        return;
    }

    const auto dpr = m_canvas->layer().devicePixelRatio();
    painter->translate(-(position() + m_canvas->origin()));
    document->renderPreview(*painter, m_canvas->scaledBase(), m_canvas->layer(), (position() * dpr).toPoint());
}

AnnotationCanvas::AnnotationCanvas(QQuickItem* parent)
    : QQuickPaintedItem(parent)
    , m_preview(new AnnotationPreview(this)) {
    QObject::connect(this, &AnnotationCanvas::windowChanged, this, &AnnotationCanvas::invalidateLayer);
}

void AnnotationCanvas::paint(QPainter* painter) {
    if (!m_document)
        return;

    const auto dpr = window() ? window()->devicePixelRatio() : 1.0;
    if (m_layer.size() != (size() * dpr).toSize()) {
        m_layer = newLayer();
        m_scaledBase = QImage();
        m_layerDirty = true;
    }

    if (m_layerDirty) {
        m_layer.fill(Qt::transparent);
        QPainter layerPainter(&m_layer);
        layerPainter.translate(-origin());
        m_document->render(layerPainter, scaledBase());
        m_layerDirty = false;
    }

    painter->drawImage(QPointF(0, 0), m_layer);
}

AnnotationDocument* AnnotationCanvas::document() const {
    return m_document;
}

void AnnotationCanvas::setDocument(AnnotationDocument* document) {
    if (m_document == document)
        return;

    if (m_document)
        QObject::disconnect(m_document, nullptr, this, nullptr);

    m_document = document;
    if (m_document) {
        QObject::connect(m_document, &QObject::destroyed, this, [this] {
            m_document = nullptr;
            invalidateLayer();
            updatePreview();
        });
        QObject::connect(m_document, &AnnotationDocument::changed, this, &AnnotationCanvas::invalidateLayer);
        QObject::connect(m_document, &AnnotationDocument::previewChanged, this, &AnnotationCanvas::updatePreview);
        QObject::connect(m_document, &AnnotationDocument::previewExtended, this, &AnnotationCanvas::extendPreview);
    }

    invalidateLayer();
    updatePreview();
    emit documentChanged();
}

QImage AnnotationCanvas::base() const {
    return m_base;
}

void AnnotationCanvas::setBase(const QImage& base) {
    if (m_base.cacheKey() == base.cacheKey())
        return;

    m_base = base;
    m_scaledBase = QImage();
    invalidateLayer();
    emit baseChanged();
}

const QImage& AnnotationCanvas::layer() const {
    return m_layer;
}

const QImage& AnnotationCanvas::previewImage() const {
    return m_previewImage;
}

const QImage& AnnotationCanvas::scaledBase() {
    if (m_scaledBase.isNull() && !m_base.isNull() && !m_layer.isNull()) {
        m_scaledBase = m_base.scaled(m_layer.size(), Qt::IgnoreAspectRatio, Qt::SmoothTransformation);
        m_scaledBase.setDevicePixelRatio(m_layer.devicePixelRatio());
    }
    return m_scaledBase;
}

QPointF AnnotationCanvas::origin() const {
    const auto* w = window();
    return w && w->screen() ? QPointF(w->screen()->geometry().topLeft()) : QPointF();
}

void AnnotationCanvas::geometryChange(const QRectF& newGeometry, const QRectF& oldGeometry) {
    QQuickPaintedItem::geometryChange(newGeometry, oldGeometry);
    invalidateLayer();
}

QImage AnnotationCanvas::newLayer() const {
    const auto dpr = window() ? window()->devicePixelRatio() : 1.0;
    QImage layer((size() * dpr).toSize(), QImage::Format_ARGB32_Premultiplied);
    layer.setDevicePixelRatio(dpr);
    return layer;
}

void AnnotationCanvas::invalidateLayer() {
    m_layerDirty = true;
    update();
}

void AnnotationCanvas::updatePreview() {
    const auto bounds = m_document ? m_document->previewBounds() : std::nullopt;
    if (!bounds) {
        m_previewImage = QImage();
        m_preview->setVisible(false);
        return;
    }

    if (const auto* stroke = m_document->previewStroke()) {
        m_previewImage = newLayer();
        m_previewImage.fill(Qt::transparent);
        QPainter painter(&m_previewImage);
        painter.setRenderHint(QPainter::Antialiasing);
        painter.translate(-origin());
        stroke->renderOpaque(painter);

        m_preview->setPosition(QPointF(0, 0));
        m_preview->setSize(size());
        m_preview->setOpacity(stroke->opacity());
        m_preview->setVisible(true);
        m_preview->update();
        return;
    }

    m_previewImage = QImage();
    const auto rect = bounds->translated(-origin())
                          .adjusted(-k_previewMargin, -k_previewMargin, k_previewMargin, k_previewMargin)
                          .toAlignedRect();
    m_preview->setPosition(rect.topLeft());
    m_preview->setSize(rect.size());
    m_preview->setOpacity(1.0);
    m_preview->setVisible(true);
    m_preview->update();
}

void AnnotationCanvas::extendPreview() {
    const auto* stroke = m_document ? m_document->previewStroke() : nullptr;
    if (!stroke || m_previewImage.isNull())
        return;

    // The press dot overshoots the flat start, so redraw it once
    if (stroke->isFirstSegment()) {
        updatePreview();
        return;
    }

    QPainter painter(&m_previewImage);
    painter.setRenderHint(QPainter::Antialiasing);
    painter.translate(-origin());
    const auto rect = stroke->renderSegment(painter);
    if (rect.isNull())
        return;

    m_preview->update(rect.translated(-origin())
            .adjusted(-k_previewMargin, -k_previewMargin, k_previewMargin, k_previewMargin)
            .toAlignedRect());
}

} // namespace caelestia::shell::components
