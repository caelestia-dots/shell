#pragma once

#include <qqmlengine.h>

#include "blobshape.hpp"

namespace caelestia::blobs {

class BlobInvertedRect : public BlobShape {
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(qreal borderLeft READ borderLeft WRITE setBorderLeft NOTIFY borderLeftChanged)
    Q_PROPERTY(qreal borderRight READ borderRight WRITE setBorderRight NOTIFY borderRightChanged)
    Q_PROPERTY(qreal borderTop READ borderTop WRITE setBorderTop NOTIFY borderTopChanged)
    Q_PROPERTY(qreal borderBottom READ borderBottom WRITE setBorderBottom NOTIFY borderBottomChanged)

public:
    explicit BlobInvertedRect(QQuickItem* parent = nullptr);
    ~BlobInvertedRect() override;

    [[nodiscard]] qreal borderLeft() const;
    void setBorderLeft(qreal v);

    [[nodiscard]] qreal borderRight() const;
    void setBorderRight(qreal v);

    [[nodiscard]] qreal borderTop() const;
    void setBorderTop(qreal v);

    [[nodiscard]] qreal borderBottom() const;
    void setBorderBottom(qreal v);

signals:
    void borderLeftChanged();
    void borderRightChanged();
    void borderTopChanged();
    void borderBottomChanged();

protected:
    [[nodiscard]] bool isInvertedRect() const override;

    QSGNode* updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData* data) override;

    void registerWithGroup() override;
    void unregisterFromGroup() override;

private:
    qreal m_borderLeft = 0;
    qreal m_borderRight = 0;
    qreal m_borderTop = 0;
    qreal m_borderBottom = 0;
};

} // namespace caelestia::blobs
