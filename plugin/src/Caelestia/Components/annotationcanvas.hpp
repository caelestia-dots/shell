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
    Q_PROPERTY(QPointF origin READ origin WRITE setOrigin NOTIFY originChanged FINAL)
    Q_PROPERTY(QRectF baseRect READ baseRect WRITE setBaseRect NOTIFY baseRectChanged FINAL)

public:
    explicit AnnotationCanvas(QQuickItem* parent = nullptr);

    void paint(QPainter* painter) override;

    [[nodiscard]] AnnotationDocument* document() const;
    void setDocument(AnnotationDocument* document);

    [[nodiscard]] QImage base() const;
    void setBase(const QImage& base);

    [[nodiscard]] QPointF origin() const;
    void setOrigin(const QPointF& origin);

    [[nodiscard]] QRectF baseRect() const;
    void setBaseRect(const QRectF& baseRect);

    Q_INVOKABLE [[nodiscard]] QImage composite() const;

    [[nodiscard]] const QImage& layer() const;
    [[nodiscard]] const QImage& previewImage() const;
    [[nodiscard]] const QImage& scaledBase();

signals:
    void documentChanged();
    void baseChanged();
    void originChanged();
    void baseRectChanged();

protected:
    void geometryChange(const QRectF& newGeometry, const QRectF& oldGeometry) override;

private:
    [[nodiscard]] QImage newLayer() const;
    [[nodiscard]] QRectF effectiveBaseRect() const;
    void invalidateLayer();
    void updatePreview();
    void extendPreview();

    AnnotationDocument* m_document = nullptr;
    QImage m_base;
    QPointF m_origin;
    QRectF m_baseRect;
    QImage m_scaledBase;
    QImage m_layer;
    QImage m_previewImage;
    bool m_layerDirty = true;
    AnnotationPreview* m_preview;
};

} // namespace caelestia::shell::components
