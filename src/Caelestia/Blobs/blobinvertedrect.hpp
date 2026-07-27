#pragma once

#include "blobshape.hpp"

#include <qqmlengine.h>

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

    qreal borderLeft() const { return m_borderLeft; }

    void setBorderLeft(qreal v);

    qreal borderRight() const { return m_borderRight; }

    void setBorderRight(qreal v);

    qreal borderTop() const { return m_borderTop; }

    void setBorderTop(qreal v);

    qreal borderBottom() const { return m_borderBottom; }

    void setBorderBottom(qreal v);

signals:
    void borderLeftChanged();
    void borderRightChanged();
    void borderTopChanged();
    void borderBottomChanged();

protected:
    bool isInvertedRect() const override { return true; }

    QSGNode* updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData*) override;

    void registerWithGroup() override;
    void unregisterFromGroup() override;

private:
    qreal m_borderLeft = 0;
    qreal m_borderRight = 0;
    qreal m_borderTop = 0;
    qreal m_borderBottom = 0;
};
