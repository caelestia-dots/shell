#include "screencapture.hpp"

#include <qpainter.h>
#include <qquickwindow.h>
#include <qscreen.h>

#include <caelestia/screenshot/screenshot.hpp>

#include <algorithm>

namespace caelestia::shell::components {

CaptureSession::CaptureSession(QObject* parent)
    : QObject(parent) {}

QFuture<QImage> CaptureSession::capture(const QScreen* screen) {
    if (!screenshot::isSupported()) {
        if (!m_unsupportedEmitted) {
            m_unsupportedEmitted = true;
            emit unsupported();
        }
        return {};
    }

    return screenshot::capture(screen).then(this, [this, screen](QImage image) {
        m_images.insert(screen, image);
        return image;
    });
}

void CaptureSession::save(const QRect& region) {
    const auto image = compose(region);
    if (image.isNull())
        return;

    screenshot::cache(image).then(this, [this](const QString& path) {
        emit saved(path);
    });
}

QImage CaptureSession::compose(const QRect& region) const {
    qreal scale = 0.0;
    for (auto it = m_images.cbegin(); it != m_images.cend(); ++it) {
        if (it.key()->geometry().intersects(region))
            scale = std::max(scale, it.key()->devicePixelRatio());
    }
    if (scale <= 0.0)
        return {};

    QImage result(region.size() * scale, QImage::Format_ARGB32_Premultiplied);
    result.fill(Qt::transparent);

    QPainter painter(&result);
    for (auto it = m_images.cbegin(); it != m_images.cend(); ++it) {
        const auto geometry = it.key()->geometry();
        const auto part = geometry.intersected(region);
        if (part.isEmpty())
            continue;

        const auto srcScale = static_cast<qreal>(it.value().width()) / geometry.width();
        const QRectF source(
            QRectF(part.translated(-geometry.topLeft())).topLeft() * srcScale, QSizeF(part.size()) * srcScale);
        const QRectF target(QRectF(part.translated(-region.topLeft())).topLeft() * scale, QSizeF(part.size()) * scale);
        painter.drawImage(target, it.value(), source);
    }

    return result;
}

ScreenCapture::ScreenCapture(QQuickItem* parent)
    : QQuickPaintedItem(parent) {
    QObject::connect(this, &ScreenCapture::windowChanged, this, &ScreenCapture::tryCapture);
}

void ScreenCapture::paint(QPainter* painter) {
    if (!m_image.isNull())
        painter->drawImage(boundingRect(), m_image);
}

CaptureSession* ScreenCapture::session() const {
    return m_session;
}

void ScreenCapture::setSession(CaptureSession* session) {
    if (m_session == session)
        return;

    m_session = session;
    emit sessionChanged();
}

void ScreenCapture::componentComplete() {
    QQuickPaintedItem::componentComplete();
    tryCapture();
}

void ScreenCapture::tryCapture() {
    if (!m_session || m_captureDone)
        return;

    if (const auto* w = window())
        m_session->capture(w->screen()).then(this, [this](QImage image) {
            m_image = std::move(image);
            update();
        });
}

} // namespace caelestia::shell::components
