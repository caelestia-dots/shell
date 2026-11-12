#pragma once

#include <qimage.h>
#include <qqmlintegration.h>
#include <qquickpainteditem.h>

namespace caelestia::shell::components {

class ImageLoader : public QQuickPaintedItem {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString source READ source WRITE setSource NOTIFY sourceChanged FINAL)
    Q_PROPERTY(QImage image READ image NOTIFY imageChanged FINAL)

public:
    explicit ImageLoader(QQuickItem* parent = nullptr);

    void paint(QPainter* painter) override;

    [[nodiscard]] QString source() const;
    void setSource(const QString& source);

    [[nodiscard]] QImage image() const;

signals:
    void sourceChanged();
    void imageChanged();

private:
    QString m_source;
    QImage m_image;
    int m_generation = 0;
};

} // namespace caelestia::shell::components
