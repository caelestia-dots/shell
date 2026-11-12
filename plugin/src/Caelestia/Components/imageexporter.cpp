#include "imageexporter.hpp"

#include <qbuffer.h>
#include <qprocess.h>

#include <caelestia/screenshot/screenshot.hpp>

namespace caelestia::shell::components {

using Qt::StringLiterals::operator""_s;

ImageExporter::ImageExporter(QObject* parent)
    : QObject(parent) {}

void ImageExporter::save(const QImage& image) {
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

void ImageExporter::copy(const QImage& image) {
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
                if (!img.save(&buffer, "PNG"))
                    png.clear();
                return png;
            })
        .then(this, [this, image](const QByteArray& png) {
            if (png.isEmpty())
                emit copyFailed();
            else
                pipeToClipboard(image, png);
        });
}

void ImageExporter::pipeToClipboard(const QImage& image, const QByteArray& png) {
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

} // namespace caelestia::shell::components
