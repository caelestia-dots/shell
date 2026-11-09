#include "annotationcanvas.hpp"

#include <qpainter.h>
#include <qpen.h>
#include <qquickwindow.h>
#include <qscreen.h>

namespace caelestia::shell::components {

AnnotationCanvas::AnnotationCanvas(QQuickItem* parent)
    : QQuickPaintedItem(parent) {
    QObject::connect(this, &AnnotationCanvas::windowChanged, this, &AnnotationCanvas::invalidateCache);
}

void AnnotationCanvas::paint(QPainter* painter) {
    if (!m_document)
        return;

    const auto offset = -origin();
    const auto dpr = window() ? window()->devicePixelRatio() : 1.0;
    if (m_cacheDirty || m_cache.size() != (size() * dpr).toSize()) {
        m_cache = QImage((size() * dpr).toSize(), QImage::Format_ARGB32_Premultiplied);
        m_cache.setDevicePixelRatio(dpr);
        m_cache.fill(Qt::transparent);

        QPainter cachePainter(&m_cache);
        if (!m_base.isNull())
            cachePainter.drawImage(boundingRect(), m_base);

        cachePainter.translate(offset);
        m_document->render(cachePainter);
        m_cacheDirty = false;
    }

    painter->drawImage(QPointF(0, 0), m_cache);
    painter->translate(offset);
    m_document->renderPreview(*painter, m_cache);

    const auto selection = m_document->selectedBounds();
    if (selection.isEmpty())
        return;

    painter->setRenderHint(QPainter::Antialiasing);
    QPen pen(m_selectionColor, 1.5);
    pen.setStyle(Qt::DashLine);
    painter->setPen(pen);
    painter->setBrush(Qt::NoBrush);
    painter->drawRect(selection);
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
            invalidateCache();
        });
        QObject::connect(m_document, &AnnotationDocument::changed, this, &AnnotationCanvas::invalidateCache);
        QObject::connect(m_document, &AnnotationDocument::previewChanged, this, [this] {
            update();
        });
        QObject::connect(m_document, &AnnotationDocument::selectedChanged, this, [this] {
            update();
        });
    }

    invalidateCache();
    emit documentChanged();
}

QImage AnnotationCanvas::base() const {
    return m_base;
}

void AnnotationCanvas::setBase(const QImage& base) {
    if (m_base.cacheKey() == base.cacheKey())
        return;

    m_base = base;
    invalidateCache();
    emit baseChanged();
}

QColor AnnotationCanvas::selectionColor() const {
    return m_selectionColor;
}

void AnnotationCanvas::setSelectionColor(const QColor& color) {
    if (m_selectionColor == color)
        return;

    m_selectionColor = color;
    update();
    emit selectionColorChanged();
}

void AnnotationCanvas::geometryChange(const QRectF& newGeometry, const QRectF& oldGeometry) {
    QQuickPaintedItem::geometryChange(newGeometry, oldGeometry);
    invalidateCache();
}

QPointF AnnotationCanvas::origin() const {
    const auto* w = window();
    return w && w->screen() ? QPointF(w->screen()->geometry().topLeft()) : QPointF();
}

void AnnotationCanvas::invalidateCache() {
    m_cacheDirty = true;
    update();
}

} // namespace caelestia::shell::components
