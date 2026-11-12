#include "annotationcanvas.hpp"

#include <qpainter.h>
#include <qquickwindow.h>

#include <cmath>

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
        m_canvas->drawLayer(*painter, image);
        return;
    }

    painter->translate(-position());
    if (m_canvas->magnified()) {
        auto& preview = m_canvas->scratchLayer();
        preview.fill(Qt::transparent);
        QPainter previewPainter(&preview);
        m_canvas->applyView(previewPainter);
        document->renderPreview(previewPainter, m_canvas->effectBase(), m_canvas->layer(), QPoint());
        m_canvas->drawLayer(*painter, preview);
        return;
    }

    const auto dpr = m_canvas->layer().devicePixelRatio();
    m_canvas->applyView(*painter);
    document->renderPreview(*painter, m_canvas->effectBase(), m_canvas->layer(), (position() * dpr).toPoint());
}

AnnotationCanvas::AnnotationCanvas(QQuickItem* parent)
    : QQuickPaintedItem(parent)
    , m_preview(new AnnotationPreview(this)) {
    QObject::connect(this, &AnnotationCanvas::windowChanged, this, &AnnotationCanvas::invalidateLayer);
}

void AnnotationCanvas::paint(QPainter* painter) {
    if (!m_document)
        return;

    if (m_layer.size() != layerSize()) {
        m_layer = newLayer();
        m_scaledBase = QImage();
        m_layerDirty = true;
    }

    if (m_layerDirty) {
        m_layer.fill(Qt::transparent);
        QPainter layerPainter(&m_layer);
        applyView(layerPainter);
        m_document->render(layerPainter, effectBase());
        m_layerDirty = false;
    }

    drawLayer(*painter, m_layer);
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
    setImplicitSize(m_base.deviceIndependentSize().width(), m_base.deviceIndependentSize().height());
    invalidateLayer();
    emit baseChanged();
}

const QImage& AnnotationCanvas::layer() const {
    return m_layer;
}

const QImage& AnnotationCanvas::previewImage() const {
    return m_previewImage;
}

QImage& AnnotationCanvas::scratchLayer() {
    if (m_scratch.size() != layerSize())
        m_scratch = newLayer();
    return m_scratch;
}

const QImage& AnnotationCanvas::effectBase() {
    if (m_scaledBase.isNull() && !m_base.isNull() && !m_layer.isNull() && m_document->hasEffects()) {
        m_scaledBase = newLayer();
        m_scaledBase.fill(Qt::transparent);
        QPainter painter(&m_scaledBase);
        painter.setRenderHint(QPainter::SmoothPixmapTransform);
        applyView(painter);
        painter.drawImage(effectiveBaseRect(), m_base);
    }
    return m_scaledBase;
}

QPointF AnnotationCanvas::origin() const {
    return m_origin;
}

void AnnotationCanvas::setOrigin(const QPointF& origin) {
    if (m_origin == origin)
        return;

    m_origin = origin;
    m_scaledBase = QImage();
    invalidateLayer();
    updatePreview();
    emit originChanged();
}

QRectF AnnotationCanvas::baseRect() const {
    return m_baseRect;
}

void AnnotationCanvas::setBaseRect(const QRectF& baseRect) {
    if (m_baseRect == baseRect)
        return;

    m_baseRect = baseRect;
    m_scaledBase = QImage();
    invalidateLayer();
    emit baseRectChanged();
}

qreal AnnotationCanvas::zoom() const {
    return m_zoom;
}

void AnnotationCanvas::setZoom(qreal zoom) {
    if (qFuzzyCompare(m_zoom, zoom))
        return;

    m_zoom = zoom;
    m_scaledBase = QImage();
    invalidateLayer();
    updatePreview();
    emit zoomChanged();
}

void AnnotationCanvas::applyView(QPainter& painter) const {
    if (!magnified())
        painter.scale(m_zoom, m_zoom);
    painter.translate(-layerOrigin());
}

void AnnotationCanvas::drawLayer(QPainter& painter, const QImage& layer) const {
    if (!magnified()) {
        painter.drawImage(QPointF(0, 0), layer);
        return;
    }

    painter.setRenderHint(QPainter::SmoothPixmapTransform, false);
    painter.drawImage(QRectF((layerOrigin() - m_origin) * m_zoom, layer.size() * m_zoom), layer);
}

bool AnnotationCanvas::magnified() const {
    return m_zoom > 1.0;
}

QRectF AnnotationCanvas::effectiveBaseRect() const {
    return m_baseRect.isEmpty() ? QRectF(m_origin, size() / m_zoom) : m_baseRect;
}

QRectF AnnotationCanvas::toView(const QRectF& rect) const {
    const auto topLeft = (rect.topLeft() - m_origin) * m_zoom;
    return { topLeft, rect.size() * m_zoom };
}

QImage AnnotationCanvas::composite() const {
    if (!m_document || m_base.isNull())
        return {};

    auto result = m_base.convertToFormat(QImage::Format_ARGB32_Premultiplied);
    result.setDevicePixelRatio(1);

    const auto rect = effectiveBaseRect();
    QPainter painter(&result);
    painter.scale(result.width() / rect.width(), result.height() / rect.height());
    painter.translate(-rect.topLeft());
    m_document->render(painter, result);
    return result;
}

void AnnotationCanvas::geometryChange(const QRectF& newGeometry, const QRectF& oldGeometry) {
    QQuickPaintedItem::geometryChange(newGeometry, oldGeometry);
    invalidateLayer();
}

QImage AnnotationCanvas::newLayer() const {
    QImage layer(layerSize(), QImage::Format_ARGB32_Premultiplied);
    if (!magnified() && window())
        layer.setDevicePixelRatio(window()->devicePixelRatio());
    return layer;
}

QSize AnnotationCanvas::layerSize() const {
    if (magnified())
        return { static_cast<int>(std::ceil(width() / m_zoom)) + 1,
            static_cast<int>(std::ceil(height() / m_zoom)) + 1 };

    const auto dpr = window() ? window()->devicePixelRatio() : 1.0;
    return (size() * dpr).toSize();
}

QPointF AnnotationCanvas::layerOrigin() const {
    return magnified() ? QPointF(std::floor(m_origin.x()), std::floor(m_origin.y())) : m_origin;
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
        applyView(painter);
        stroke->renderOpaque(painter);

        m_preview->setPosition(QPointF(0, 0));
        m_preview->setSize(size());
        m_preview->setOpacity(stroke->opacity());
        m_preview->setVisible(true);
        m_preview->update();
        return;
    }

    m_previewImage = QImage();
    const auto rect =
        toView(*bounds).adjusted(-k_previewMargin, -k_previewMargin, k_previewMargin, k_previewMargin).toAlignedRect();
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
    applyView(painter);
    const auto rect = stroke->renderSegment(painter);
    if (rect.isNull())
        return;

    m_preview->update(
        toView(rect).adjusted(-k_previewMargin, -k_previewMargin, k_previewMargin, k_previewMargin).toAlignedRect());
}

} // namespace caelestia::shell::components
