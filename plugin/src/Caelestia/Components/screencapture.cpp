#include "screencapture.hpp"

#include <qbuffer.h>
#include <qpainter.h>
#include <qprocess.h>
#include <qquickwindow.h>
#include <qscreen.h>

#include <caelestia/screenshot/screenshot.hpp>

#include <algorithm>

namespace caelestia::shell::components {

using Qt::StringLiterals::operator""_s;

CaptureSession::CaptureSession(QObject* parent)
    : QObject(parent)
    , m_document(new AnnotationDocument(this)) {}

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
    if (image.isNull()) {
        emit saveFailed();
        return;
    }

    screenshot::cache(image).then(this, [this](const QString& path) {
        if (path.isEmpty())
            emit saveFailed();
        else
            emit saved(path);
    });
}

void CaptureSession::copy(const QRect& region) {
    const auto image = compose(region);
    if (image.isNull()) {
        emit copyFailed();
        return;
    }

    QtFuture::makeReadyValueFuture(image)
        .then(QtFuture::Launch::Async,
            [](const QImage& img) {
                QByteArray png;
                QBuffer buffer(&png);
                buffer.open(QIODevice::WriteOnly);
                img.save(&buffer, "PNG");
                return png;
            })
        .then(this, [this, image](const QByteArray& png) {
            pipeToClipboard(image, png);
        });
}

AnnotationDocument* CaptureSession::document() const {
    return m_document;
}

void CaptureSession::pipeToClipboard(const QImage& image, const QByteArray& png) {
    auto* const proc = new QProcess(this);
    QObject::connect(proc, &QProcess::errorOccurred, this, [this, proc](QProcess::ProcessError error) {
        if (error != QProcess::FailedToStart)
            return;

        emit copyFailed();
        proc->deleteLater();
    });
    QObject::connect(proc, &QProcess::finished, this, [this, proc, image](int code, QProcess::ExitStatus status) {
        if (status == QProcess::NormalExit && code == 0) {
            screenshot::cache(image).then(this, [this](const QString& path) {
                if (path.isEmpty())
                    emit copyFailed();
                else
                    emit copied(path);
            });
        } else {
            emit copyFailed();
        }
        proc->deleteLater();
    });

    proc->start(u"wl-copy"_s, { u"--type"_s, u"image/png"_s });
    proc->write(png);
    proc->closeWriteChannel();
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

    painter.scale(scale, scale);
    painter.translate(-region.topLeft());
    m_document->render(painter);

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

QImage ScreenCapture::image() const {
    return m_image;
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
            emit imageChanged();
        });
}

} // namespace caelestia::shell::components
