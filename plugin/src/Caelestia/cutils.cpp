#include "cutils.hpp"

#include <QtConcurrent/qtconcurrentrun.h>
#include <QtQuick/qquickitemgrabresult.h>
#include <QtQuick/qquickwindow.h>
#include <qdir.h>
#include <qfileinfo.h>
#include <qfuturewatcher.h>
#include <qqmlengine.h>

namespace caelestia {

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
    if (rect.isValid() && !qFuzzyCompare(scale + 1.0, 2.0)) {
        scaledRect =
            QRectF(rect.left() * scale, rect.top() * scale, rect.width() * scale, rect.height() * scale).toRect();
    }

    const QSharedPointer<const QQuickItemGrabResult> grabResult = target->grabToImage();

    QObject::connect(grabResult.data(), &QQuickItemGrabResult::ready, this,
        [grabResult, scaledRect, path, onSaved, onFailed, this]() {
            const auto future = QtConcurrent::run([=]() {
                QImage image = grabResult->image();

                if (scaledRect.isValid()) {
                    image = image.copy(scaledRect);
                }

                const QString file = path.toLocalFile();
                const QString parent = QFileInfo(file).absolutePath();
                return QDir().mkpath(parent) && image.save(file);
            });

            auto* watcher = new QFutureWatcher<bool>(this);
            auto* engine = qmlEngine(this);

            QObject::connect(watcher, &QFutureWatcher<bool>::finished, this, [=]() {
                if (watcher->result()) {
                    if (onSaved.isCallable()) {
                        onSaved.call(
                            { QJSValue(path.toLocalFile()), engine->toScriptValue(QVariant::fromValue(path)) });
                    }
                } else {
                    qWarning() << "CUtils::saveItem: failed to save" << path;
                    if (onFailed.isCallable()) {
                        onFailed.call({ engine->toScriptValue(QVariant::fromValue(path)) });
                    }
                }
                watcher->deleteLater();
            });
            watcher->setFuture(future);
        });
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

bool CUtils::deleteFile(const QUrl& path) const {
    if (!path.isLocalFile()) {
        qWarning() << "CUtils::deleteFile: path" << path << "is not a local file";
        return false;
    }

    return QFile::remove(path.toLocalFile());
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
            const auto future = QtConcurrent::run(&CUtils::findDominantColour, this, grabResult->image(), rescaleSize);
            auto* watcher = new QFutureWatcher<QColor>(this);
            auto* engine = qmlEngine(this);

            QObject::connect(watcher, &QFutureWatcher<QColor>::finished, this, [=]() {
                if (callback.isCallable()) {
                    callback.call({ engine->toScriptValue(QVariant::fromValue(watcher->result())) });
                }
                watcher->deleteLater();
            });
            watcher->setFuture(future);
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

    const auto future = QtConcurrent::run([=, this]() {
        const QImage image(path);

        if (image.isNull()) {
            qWarning() << "CUtils::getDominantColour: failed to load image" << path;
            return QColor();
        }

        return findDominantColour(image, rescaleSize);
    });
    auto* watcher = new QFutureWatcher<QColor>(this);
    auto* engine = qmlEngine(this);

    QObject::connect(watcher, &QFutureWatcher<QColor>::finished, this, [=]() {
        if (watcher->result().isValid() && callback.isCallable()) {
            callback.call({ engine->toScriptValue(QVariant::fromValue(watcher->result())) });
        }
        watcher->deleteLater();
    });
    watcher->setFuture(future);
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

    std::unordered_map<quint32, int> colours;
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

            quint32 r = static_cast<quint32>(pixel[0] & 0xF8);
            quint32 g = static_cast<quint32>(pixel[1] & 0xF8);
            quint32 b = static_cast<quint32>(pixel[2] & 0xF8);

            quint32 colour = (r << 16) | (g << 8) | b;
            ++colours[colour];
        }
    }

    quint32 dominantColour = 0;
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
            const auto future =
                QtConcurrent::run(&CUtils::findAverageLuminance, this, grabResult->image(), rescaleSize);
            auto* watcher = new QFutureWatcher<qreal>(this);

            QObject::connect(watcher, &QFutureWatcher<qreal>::finished, this, [=]() {
                if (callback.isCallable()) {
                    callback.call({ QJSValue(watcher->result()) });
                }
                watcher->deleteLater();
            });
            watcher->setFuture(future);
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

    const auto future = QtConcurrent::run([=, this]() {
        const QImage image(path);

        if (image.isNull()) {
            qWarning() << "CUtils::getAverageLuminance: failed to load image" << path;
            return 0.0;
        }

        return findAverageLuminance(image, rescaleSize);
    });
    auto* watcher = new QFutureWatcher<qreal>(this);

    QObject::connect(watcher, &QFutureWatcher<qreal>::finished, this, [=]() {
        if (callback.isCallable()) {
            callback.call({ QJSValue(watcher->result()) });
        }
        watcher->deleteLater();
    });
    watcher->setFuture(future);
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

QString CUtils::toLocalFile(const QUrl& url) const {
    if (!url.isLocalFile()) {
        qWarning() << "CUtils::toLocalFile: given url is not a local file" << url;
        return QString();
    }

    return url.toLocalFile();
}

} // namespace caelestia
