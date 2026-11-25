#pragma once

#include <qfuture.h>
#include <qhash.h>
#include <qimage.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qquickpainteditem.h>
#include <qrect.h>

#include "annotationdocument.hpp"
#include "imageexporter.hpp"

class QScreen;

namespace caelestia::shell::components {

class CaptureSession : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(caelestia::shell::components::AnnotationDocument* document READ document CONSTANT FINAL)

public:
    explicit CaptureSession(QObject* parent = nullptr);

    [[nodiscard]] QFuture<QImage> capture(const QScreen* screen);

    Q_INVOKABLE void save(const QRect& region);
    Q_INVOKABLE void copy(const QRect& region);

    [[nodiscard]] AnnotationDocument* document() const;

signals:
    void unsupported();
    void saved(const QString& path);
    void saveFailed();
    void copied(const QString& path);
    void copyFailed();

private:
    [[nodiscard]] QImage compose(const QRect& region) const;

    QHash<const QScreen*, QImage> m_images;
    AnnotationDocument* m_document;
    ImageExporter* m_exporter;
    bool m_unsupportedEmitted = false;
};

class ScreenCapture : public QQuickPaintedItem {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(caelestia::shell::components::CaptureSession* session READ session WRITE setSession NOTIFY sessionChanged
            REQUIRED)
    Q_PROPERTY(QImage image READ image NOTIFY imageChanged FINAL)

public:
    explicit ScreenCapture(QQuickItem* parent = nullptr);

    void paint(QPainter* painter) override;

    [[nodiscard]] CaptureSession* session() const;
    void setSession(CaptureSession* session);

    [[nodiscard]] QImage image() const;

signals:
    void sessionChanged();
    void imageChanged();

protected:
    void componentComplete() override;

private:
    CaptureSession* m_session = nullptr;
    QImage m_image;
    bool m_captureDone = false;

    void tryCapture();
};

} // namespace caelestia::shell::components
