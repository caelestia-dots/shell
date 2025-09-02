#include "cutils.hpp"

#include <QDir>
#include <QObject>
#include <QQmlEngine>
#include <QThreadPool>
#include <QtQuick/QQuickItem>
#include <QtQuick/QQuickItemGrabResult>
#include <QtQuick/QQuickWindow>

void CUtils::saveItem(QQuickItem* target, const QUrl& path) {
    this->saveItem(target, path, QRect(), QJSValue(), QJSValue());
}

void CUtils::saveItem(QQuickItem* target, const QUrl& path, const QRect& rect) {
    this->saveItem(target, path, rect, QJSValue(), QJSValue());
}

void CUtils::saveItem(QQuickItem* target, const QUrl& path, QJSValue onSaved) {
    this->saveItem(target, path, QRect(), onSaved, QJSValue());
}

void CUtils::saveItem(QQuickItem* target, const QUrl& path, QJSValue onSaved, QJSValue onFailed) {
    this->saveItem(target, path, QRect(), onSaved, onFailed);
}

void CUtils::saveItem(QQuickItem* target, const QUrl& path, const QRect& rect, QJSValue onSaved) {
    this->saveItem(target, path, rect, onSaved, QJSValue());
}

void CUtils::saveItem(QQuickItem* target, const QUrl& path, const QRect& rect, QJSValue onSaved, QJSValue onFailed) {
    if (!target) {
        qWarning() << "CUtils::saveItem: a target is required";
        return;
    }

    if (!path.isLocalFile()) {
        qWarning() << "CUtils::saveItem:" << path << "is not a local file";
        return;
    }

    if (!target->window()) {
        qWarning() << "CUtils::saveItem: unable to save target" << target << "without a window";
        return;
    }

    auto scaledRect = rect;
    const qreal scale = target->window()->devicePixelRatio();
    if (rect.isValid() && scale != 1.0) {
        scaledRect =
            QRectF(rect.left() * scale, rect.top() * scale, rect.width() * scale, rect.height() * scale).toRect();
    }

    const QSharedPointer<const QQuickItemGrabResult> grabResult = target->grabToImage();

    QObject::connect(grabResult.data(), &QQuickItemGrabResult::ready, this,
        [grabResult, scaledRect, path, onSaved, onFailed, this]() {
            QThreadPool::globalInstance()->start([grabResult, scaledRect, path, onSaved, onFailed, this] {
                QImage image = grabResult->image();

                if (scaledRect.isValid()) {
                    image = image.copy(scaledRect);
                }

                const QString file = path.toLocalFile();
                const QString parent = QFileInfo(file).absolutePath();
                const bool success = QDir().mkpath(parent) && image.save(file);

                QMetaObject::invokeMethod(
                    this,
                    [file, success, path, onSaved, onFailed, this]() {
                        if (success) {
                            if (onSaved.isCallable()) {
                                onSaved.call(
                                    { QJSValue(file), qmlEngine(this)->toScriptValue(QVariant::fromValue(path)) });
                            }
                        } else {
                            qWarning() << "CUtils::saveItem: failed to save" << path;
                            if (onFailed.isCallable()) {
                                onFailed.call({ qmlEngine(this)->toScriptValue(QVariant::fromValue(path)) });
                            }
                        }
                    },
                    Qt::QueuedConnection);
            });
        });
}

bool CUtils::copyFile(const QUrl& source, const QUrl& target) const {
    return this->copyFile(source, target, true);
}

bool CUtils::copyFile(const QUrl& source, const QUrl& target, bool overwrite) const {
    if (!source.isLocalFile()) {
        qWarning() << "CUtils::copyFile: source" << source << "is not a local file";
        return false;
    }
    if (!target.isLocalFile()) {
        qWarning() << "CUtils::copyFile: target" << target << "is not a local file";
        return false;
    }

    if (overwrite) {
        QFile::remove(target.toLocalFile());
    }

    return QFile::copy(source.toLocalFile(), target.toLocalFile());
}

void CUtils::getDominantColour(QQuickItem* item, QJSValue callback) {
    this->getDominantColour(item, 128, callback);
}

void CUtils::getDominantColour(QQuickItem* item, int rescaleSize, QJSValue callback) {
    if (!item) {
        qWarning() << "CUtils::getDominantColour: an item is required";
        return;
    }

    if (!item->window()) {
        // Fail silently to avoid warning
        return;
    }

    const QSharedPointer<const QQuickItemGrabResult> grabResult = item->grabToImage();

    QObject::connect(
        grabResult.data(), &QQuickItemGrabResult::ready, this, [grabResult, rescaleSize, callback, this]() {
            const QImage image = grabResult->image();

            QThreadPool::globalInstance()->start([grabResult, image, rescaleSize, callback, this]() {
                const QColor color = this->findDominantColour(image, rescaleSize);

                if (callback.isCallable()) {
                    QMetaObject::invokeMethod(
                        this,
                        [color, callback, this]() {
                            callback.call({ qmlEngine(this)->toScriptValue(QVariant::fromValue(color)) });
                        },
                        Qt::QueuedConnection);
                }
            });
        });
}

void CUtils::getDominantColour(const QString& path, QJSValue callback) {
    this->getDominantColour(path, 128, callback);
}

void CUtils::getDominantColour(const QString& path, int rescaleSize, QJSValue callback) {
    if (path.isEmpty()) {
        qWarning() << "CUtils::getDominantColour: given path is empty";
        return;
    }

    QThreadPool::globalInstance()->start([path, rescaleSize, callback, this]() {
        const QImage image(path);

        if (image.isNull()) {
            qWarning() << "CUtils::getDominantColour: failed to load image" << path;
            return;
        }

        const QColor color = this->findDominantColour(image, rescaleSize);

        if (callback.isCallable()) {
            QMetaObject::invokeMethod(
                this,
                [color, callback, this]() {
                    callback.call({ qmlEngine(this)->toScriptValue(QVariant::fromValue(color)) });
                },
                Qt::QueuedConnection);
        }
    });
}

QColor CUtils::findDominantColour(const QImage& image, int rescaleSize) const {
    if (image.isNull()) {
        qWarning() << "CUtils::findDominantColour: image is null";
        return QColor();
    }

    QImage img = image;

    if (rescaleSize > 0 && (img.width() > rescaleSize || img.height() > rescaleSize)) {
        img = img.scaled(rescaleSize, rescaleSize, Qt::KeepAspectRatio, Qt::FastTransformation);
    }

    if (img.format() != QImage::Format_ARGB32) {
        img = img.convertToFormat(QImage::Format_ARGB32);
    }

    std::unordered_map<uint32_t, int> colours;
    const uchar* data = img.bits();
    const int width = img.width();
    const int height = img.height();
    const qsizetype bytesPerLine = img.bytesPerLine();

    for (int y = 0; y < height; ++y) {
        const uchar* line = data + y * bytesPerLine;
        for (int x = 0; x < width; ++x) {
            const uchar* pixel = line + x * 4;

            if (pixel[3] == 0) {
                continue;
            }

            uint32_t r = static_cast<uint32_t>(pixel[0] & 0xF8);
            uint32_t g = static_cast<uint32_t>(pixel[1] & 0xF8);
            uint32_t b = static_cast<uint32_t>(pixel[2] & 0xF8);

            uint32_t colour = (r << 16) | (g << 8) | b;
            ++colours[colour];
        }
    }

    uint32_t dominantColour = 0;
    int maxCount = 0;
    for (const auto& [colour, count] : colours) {
        if (count > maxCount) {
            dominantColour = colour;
            maxCount = count;
        }
    }

    return QColor((0xFFu << 24) | dominantColour);
}

void CUtils::getAverageLuminance(QQuickItem* item, QJSValue callback) {
    this->getAverageLuminance(item, 128, callback);
}

void CUtils::getAverageLuminance(QQuickItem* item, int rescaleSize, QJSValue callback) {
    if (!item) {
        qWarning() << "CUtils::getAverageLuminance: an item is required";
        return;
    }

    if (!item->window()) {
        // Fail silently to avoid warning
        return;
    }

    const QSharedPointer<const QQuickItemGrabResult> grabResult = item->grabToImage();

    QObject::connect(
        grabResult.data(), &QQuickItemGrabResult::ready, this, [grabResult, rescaleSize, callback, this]() {
            const QImage image = grabResult->image();

            QThreadPool::globalInstance()->start([grabResult, image, rescaleSize, callback, this]() {
                const qreal luminance = this->findAverageLuminance(image, rescaleSize);

                if (callback.isCallable()) {
                    QMetaObject::invokeMethod(
                        this,
                        [luminance, callback]() {
                            callback.call({ QJSValue(luminance) });
                        },
                        Qt::QueuedConnection);
                }
            });
        });
}

void CUtils::getAverageLuminance(const QString& path, QJSValue callback) {
    this->getAverageLuminance(path, 128, callback);
}

void CUtils::getAverageLuminance(const QString& path, int rescaleSize, QJSValue callback) {
    if (path.isEmpty()) {
        qWarning() << "CUtils::getAverageLuminance: given path is empty";
        return;
    }

    QThreadPool::globalInstance()->start([path, rescaleSize, callback, this]() {
        const QImage image(path);

        if (image.isNull()) {
            qWarning() << "CUtils::getAverageLuminance: failed to load image" << path;
            return;
        }

        const qreal luminance = this->findAverageLuminance(image, rescaleSize);

        if (callback.isCallable()) {
            QMetaObject::invokeMethod(
                this,
                [luminance, callback]() {
                    callback.call({ QJSValue(luminance) });
                },
                Qt::QueuedConnection);
        }
    });
}

qreal CUtils::findAverageLuminance(const QImage& image, int rescaleSize) const {
    if (image.isNull()) {
        qWarning() << "CUtils::findAverageLuminance: image is null";
        return 0.0;
    }

    QImage img = image;

    if (rescaleSize > 0 && (img.width() > rescaleSize || img.height() > rescaleSize)) {
        img = img.scaled(rescaleSize, rescaleSize, Qt::KeepAspectRatio, Qt::FastTransformation);
    }

    if (img.format() != QImage::Format_ARGB32) {
        img = img.convertToFormat(QImage::Format_ARGB32);
    }

    const uchar* data = img.bits();
    const int width = img.width();
    const int height = img.height();
    const qsizetype bytesPerLine = img.bytesPerLine();

    qreal totalLuminance = 0.0;
    int count = 0;

    for (int y = 0; y < height; ++y) {
        const uchar* line = data + y * bytesPerLine;
        for (int x = 0; x < width; ++x) {
            const uchar* pixel = line + x * 4;

            if (pixel[3] == 0) {
                continue;
            }

            const qreal r = pixel[0] / 255.0;
            const qreal g = pixel[1] / 255.0;
            const qreal b = pixel[2] / 255.0;

            totalLuminance += std::sqrt(0.299 * r * r + 0.587 * g * g + 0.114 * b * b);
            ++count;
        }
    }

    return count == 0 ? 0.0 : totalLuminance / count;
}
