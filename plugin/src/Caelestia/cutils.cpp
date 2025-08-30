#include "cutils.hpp"

#include <qobject.h>
#include <QtQuick/QQuickWindow>
#include <QtQuick/QQuickItem>
#include <QtQuick/QQuickItemGrabResult>
#include <QThreadPool>
#include <QQmlEngine>
#include <QDir>

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

    auto scaledRect = rect;
    if (rect.isValid()) {
        qreal scale = target->window()->devicePixelRatio();
        scaledRect = QRect(rect.left() * scale, rect.top() * scale, rect.width() * scale, rect.height() * scale);
    }

    QSharedPointer<QQuickItemGrabResult> grabResult = target->grabToImage();

    QObject::connect(grabResult.data(), &QQuickItemGrabResult::ready, this,
        [grabResult, scaledRect, path, onSaved, onFailed, this]() {
            QThreadPool::globalInstance()->start([grabResult, scaledRect, path, onSaved, onFailed, this] {
                QImage image = grabResult->image();

                if (scaledRect.isValid()) {
                    image = image.copy(scaledRect);
                }

                const QString file = path.toLocalFile();
                const QString parent = QFileInfo(file).absolutePath();
                bool success = QDir().mkpath(parent) && image.save(file);

                QMetaObject::invokeMethod(this, [file, success, path, onSaved, onFailed, this]() {
                    if (success) {
                        if (onSaved.isCallable()) {
                            onSaved.call({ QJSValue(file), qmlEngine(this)->toScriptValue(QVariant::fromValue(path)) });
                        }
                    } else {
                        qWarning() << "CUtils::saveItem: failed to save" << path;
                        if (onFailed.isCallable()) {
                            onFailed.call({ qmlEngine(this)->toScriptValue(QVariant::fromValue(path)) });
                        }
                    }
                }, Qt::QueuedConnection);
            });
        }
    );
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

void CUtils::getDominantColour(QQuickItem* item, QJSValue callback) const {
    this->getDominantColour(item, 128, 128, callback);
}

void CUtils::getDominantColour(QQuickItem* item, int targetWidth, int targetHeight, QJSValue callback) const {
    if (!item) {
        qWarning() << "CUtils::getDominantColour: an item is required";
        return;
    }

    if (!item->window()) {
        // Fail silently to avoid warning
        return;
    }

    QSharedPointer<QQuickItemGrabResult> grabResult = item->grabToImage();

    QObject::connect(grabResult.data(), &QQuickItemGrabResult::ready, this,
        [grabResult, item, targetWidth, targetHeight, callback, this]() {
            QImage image = grabResult->image();

            if (image.width() > targetWidth && image.height() > targetHeight) {
                image = image.scaled(targetWidth, targetHeight);
            } else if (image.width() > targetWidth) {
                image = image.scaledToWidth(targetWidth);
            } else if (image.height() > targetHeight) {
                image = image.scaledToHeight(targetHeight);
            }

            if (image.format() != QImage::Format_ARGB32) {
                image = image.convertToFormat(QImage::Format_ARGB32);
            }

            std::unordered_map<uint32_t, int> colours;
            const uchar* data = image.bits();
            int width = image.width();
            int height = image.height();
            int bytesPerLine = image.bytesPerLine();

            for (int y = 0; y < height; ++y) {
                const uchar* line = data + y * bytesPerLine;
                for (int x = 0; x < width; ++x) {
                    const uchar* pixel = line + x * 4;
                    uchar r = pixel[0];
                    uchar g = pixel[1];
                    uchar b = pixel[2];
                    uchar a = pixel[3];

                    if (a == 0) {
                        continue;
                    }

                    r &= 0xF8;
                    g &= 0xF8;
                    b &= 0xF8;

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

            const QColor colour = QColor((0xFF << 24) | dominantColour);
            if (callback.isCallable()) {
                QMetaObject::invokeMethod(item, [item, callback, colour, this]() {
                    callback.call({ qmlEngine(this)->toScriptValue(QVariant::fromValue(colour)) });
                }, Qt::QueuedConnection);
            }
        }
    );
}
