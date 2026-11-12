#pragma once

#include <qimage.h>
#include <qqmlintegration.h>
#include <qquickitem.h>
#include <qrect.h>

namespace caelestia::shell::components {

class ImageLoader : public QQuickItem {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString source READ source WRITE setSource NOTIFY sourceChanged FINAL)
    Q_PROPERTY(QImage image READ image NOTIFY imageChanged FINAL)
    Q_PROPERTY(QRectF sourceRect READ sourceRect WRITE setSourceRect NOTIFY sourceRectChanged FINAL)

public:
    explicit ImageLoader(QQuickItem* parent = nullptr);

    [[nodiscard]] QString source() const;
    void setSource(const QString& source);

    [[nodiscard]] QImage image() const;

    [[nodiscard]] QRectF sourceRect() const;
    void setSourceRect(const QRectF& sourceRect);

signals:
    void sourceChanged();
    void imageChanged();
    void sourceRectChanged();

protected:
    QSGNode* updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData* data) override;

private:
    QString m_source;
    QImage m_image;
    QRectF m_sourceRect;
    int m_generation = 0;
    bool m_textureDirty = false;
};

} // namespace caelestia::shell::components
