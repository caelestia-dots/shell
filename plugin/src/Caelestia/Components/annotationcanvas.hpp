#pragma once

#include <qcolor.h>
#include <qimage.h>
#include <qqmlintegration.h>
#include <qquickpainteditem.h>

#include "annotationdocument.hpp"

namespace caelestia::shell::components {

class AnnotationCanvas : public QQuickPaintedItem {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(caelestia::shell::components::AnnotationDocument* document READ document WRITE setDocument NOTIFY
            documentChanged REQUIRED)
    Q_PROPERTY(QImage base READ base WRITE setBase NOTIFY baseChanged FINAL)
    Q_PROPERTY(QColor selectionColor READ selectionColor WRITE setSelectionColor NOTIFY selectionColorChanged FINAL)

public:
    explicit AnnotationCanvas(QQuickItem* parent = nullptr);

    void paint(QPainter* painter) override;

    [[nodiscard]] AnnotationDocument* document() const;
    void setDocument(AnnotationDocument* document);

    [[nodiscard]] QImage base() const;
    void setBase(const QImage& base);

    [[nodiscard]] QColor selectionColor() const;
    void setSelectionColor(const QColor& color);

signals:
    void documentChanged();
    void baseChanged();
    void selectionColorChanged();

protected:
    void geometryChange(const QRectF& newGeometry, const QRectF& oldGeometry) override;

private:
    [[nodiscard]] QPointF origin() const;
    void invalidateCache();

    AnnotationDocument* m_document = nullptr;
    QImage m_base;
    QColor m_selectionColor = Qt::white;
    QImage m_cache;
    bool m_cacheDirty = true;
};

} // namespace caelestia::shell::components
