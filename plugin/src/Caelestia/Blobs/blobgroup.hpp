#pragma once

#include <qcolor.h>
#include <qlist.h>
#include <qobject.h>
#include <qqmlengine.h>

namespace caelestia::blobs {

class BlobShape;
class BlobInvertedRect;

class BlobGroup : public QObject {
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(qreal smoothing READ smoothing WRITE setSmoothing NOTIFY smoothingChanged)
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged)
    Q_PROPERTY(bool cornerFill READ cornerFill WRITE setCornerFill NOTIFY cornerFillChanged)

public:
    explicit BlobGroup(QObject* parent = nullptr);
    ~BlobGroup() override;

    [[nodiscard]] qreal smoothing() const;
    void setSmoothing(qreal s);

    [[nodiscard]] QColor color() const;
    void setColor(const QColor& c);

    [[nodiscard]] bool cornerFill() const;
    void setCornerFill(bool e);

    void addShape(BlobShape* shape);
    void removeShape(BlobShape* shape);

    void setInvertedRect(BlobInvertedRect* rect);
    void clearInvertedRect(BlobInvertedRect* rect);

    [[nodiscard]] const QList<BlobShape*>& shapes() const;
    [[nodiscard]] BlobInvertedRect* invertedRect() const;

    void markDirty();
    void markShapeDirty(BlobShape* source);
    void ensurePhysicsUpdated();

signals:
    void smoothingChanged();
    void colorChanged();
    void cornerFillChanged();

private:
    qreal m_smoothing = 32.0;
    QColor m_color{ 0x44, 0x88, 0xff };
    bool m_cornerFill = true;
    QList<BlobShape*> m_shapes;
    BlobInvertedRect* m_invertedRect = nullptr;
    bool m_physicsUpdated = false;
};

} // namespace caelestia::blobs
