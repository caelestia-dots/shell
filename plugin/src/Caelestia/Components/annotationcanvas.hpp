#pragma once

#include <qimage.h>
#include <qqmlintegration.h>
#include <qquickpainteditem.h>

#include "annotationdocument.hpp"

namespace caelestia::shell::components {

class AnnotationCanvas;

class AnnotationPreview : public QQuickPaintedItem {
public:
    explicit AnnotationPreview(AnnotationCanvas* canvas);

    void paint(QPainter* painter) override;

private:
    AnnotationCanvas* m_canvas;
};

class AnnotationCanvas : public QQuickPaintedItem {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(caelestia::shell::components::AnnotationDocument* document READ document WRITE setDocument NOTIFY
            documentChanged REQUIRED)
    Q_PROPERTY(QImage base READ base WRITE setBase NOTIFY baseChanged FINAL)

public:
    explicit AnnotationCanvas(QQuickItem* parent = nullptr);

    void paint(QPainter* painter) override;

    [[nodiscard]] AnnotationDocument* document() const;
    void setDocument(AnnotationDocument* document);

    [[nodiscard]] QImage base() const;
    void setBase(const QImage& base);

    [[nodiscard]] const QImage& layer() const;
    [[nodiscard]] const QImage& previewImage() const;
    [[nodiscard]] const QImage& scaledBase();
    [[nodiscard]] QPointF origin() const;

signals:
    void documentChanged();
    void baseChanged();

protected:
    void geometryChange(const QRectF& newGeometry, const QRectF& oldGeometry) override;

private:
    [[nodiscard]] QImage newLayer() const;
    void invalidateLayer();
    void updatePreview();
    void extendPreview();

    AnnotationDocument* m_document = nullptr;
    QImage m_base;
    QImage m_scaledBase;
    QImage m_layer;
    QImage m_previewImage;
    bool m_layerDirty = true;
    AnnotationPreview* m_preview;
};

} // namespace caelestia::shell::components
