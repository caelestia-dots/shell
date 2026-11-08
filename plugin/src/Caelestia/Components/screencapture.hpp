#pragma once

#include <qfuture.h>
#include <qhash.h>
#include <qimage.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qquickpainteditem.h>
#include <qrect.h>

class QScreen;

namespace caelestia::shell::components {

class CaptureSession : public QObject {
    Q_OBJECT
    QML_ELEMENT

public:
    explicit CaptureSession(QObject* parent = nullptr);

    [[nodiscard]] QFuture<QImage> capture(const QScreen* screen);

    Q_INVOKABLE void save(const QRect& region);

signals:
    void unsupported();
    void saved(const QString& path);

private:
    [[nodiscard]] QImage compose(const QRect& region) const;

    QHash<const QScreen*, QImage> m_images;
    bool m_unsupportedEmitted = false;
};

class ScreenCapture : public QQuickPaintedItem {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(CaptureSession* session READ session WRITE setSession NOTIFY sessionChanged REQUIRED)

public:
    explicit ScreenCapture(QQuickItem* parent = nullptr);

    void paint(QPainter* painter) override;

    [[nodiscard]] CaptureSession* session() const;
    void setSession(CaptureSession* session);

signals:
    void sessionChanged();

protected:
    void componentComplete() override;

private:
    CaptureSession* m_session = nullptr;
    QImage m_image;
    bool m_captureDone = false;

    void tryCapture();
};

} // namespace caelestia::shell::components
