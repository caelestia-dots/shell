#include "cachingimagemanager.hpp"

#include <QtQuick/qquickwindow.h>
#include <qcryptographichash.h>
#include <qdir.h>
#include <qfileinfo.h>
#include <qfuturewatcher.h>
#include <qimagereader.h>
#include <qpainter.h>
#include <qtconcurrentrun.h>

namespace caelestia::internal {

qreal CachingImageManager::effectiveScale() const {
    if (m_item && m_item->window()) {
        return m_item->window()->devicePixelRatio();
    }

    return 1.0;
}

QSize CachingImageManager::effectiveSize() const {
    if (!m_item) {
        return QSize();
    }

    const qreal scale = effectiveScale();
    const QSize size = QSizeF(m_item->width() * scale, m_item->height() * scale).toSize();
    m_item->setProperty("sourceSize", size);
    return size;
}

QQuickItem* CachingImageManager::item() const {
    return m_item;
}

void CachingImageManager::setItem(QQuickItem* item) {
    if (m_item == item) {
        return;
    }

    if (m_widthConn) {
        disconnect(m_widthConn);
    }
    if (m_heightConn) {
        disconnect(m_heightConn);
    }

    m_item = item;
    emit itemChanged();

    if (item) {
        m_widthConn = connect(item, &QQuickItem::widthChanged, this, [this]() {
            updateSource();
        });
        m_heightConn = connect(item, &QQuickItem::heightChanged, this, [this]() {
            updateSource();
        });
        updateSource();
    }
}

QUrl CachingImageManager::cacheDir() const {
    return m_cacheDir;
}

void CachingImageManager::setCacheDir(const QUrl& cacheDir) {
    if (m_cacheDir == cacheDir) {
        return;
    }

    m_cacheDir = cacheDir;
    if (!m_cacheDir.path().endsWith("/")) {
        m_cacheDir.setPath(m_cacheDir.path() + "/");
    }
    emit cacheDirChanged();
}

QString CachingImageManager::path() const {
    return m_path;
}

void CachingImageManager::setPath(const QString& path) {
    if (m_path == path) {
        return;
    }

    m_path = path;
    emit pathChanged();

    if (!path.isEmpty()) {
        updateSource(path);
    }
}

void CachingImageManager::updateSource() {
    updateSource(m_path);
}

void CachingImageManager::updateSource(const QString& path) {
    if (path.isEmpty() || path == m_shaPath) {
        // Path is empty or already calculating sha for path
        return;
    }

    m_shaPath = path;

    const auto future = QtConcurrent::run(&CachingImageManager::sha256sum, path);

    const auto watcher = new QFutureWatcher<QString>(this);

    connect(watcher, &QFutureWatcher<QString>::finished, this, [watcher, path, this]() {
        if (m_path != path) {
            // Object is destroyed or path has changed, ignore
            watcher->deleteLater();
            return;
        }

        const QSize size = effectiveSize();

        if (!m_item || !size.width() || !size.height()) {
            watcher->deleteLater();
            return;
        }

        const QString fillMode = m_item->property("fillMode").toString();
        // clang-format off
        const QString filename = QString("%1@%2x%3-%4.png")
            .arg(watcher->result()).arg(size.width()).arg(size.height())
            .arg(fillMode == "PreserveAspectCrop" ? "crop" : fillMode == "PreserveAspectFit" ? "fit" : "stretch");
        // clang-format on

        const QUrl cache = m_cacheDir.resolved(QUrl(filename));
        if (m_cachePath == cache) {
            watcher->deleteLater();
            return;
        }

        m_cachePath = cache;
        emit cachePathChanged();

        if (!cache.isLocalFile()) {
            qWarning() << "CachingImageManager::updateSource: cachePath" << cache << "is not a local file";
            watcher->deleteLater();
            return;
        }

        const QImageReader reader(cache.toLocalFile());
        if (reader.canRead()) {
            m_item->setProperty("source", cache);
        } else {
            m_item->setProperty("source", QUrl::fromLocalFile(path));
            createCache(path, cache.toLocalFile(), fillMode, size);
        }

        // Clear current running sha if same
        if (m_shaPath == path) {
            m_shaPath = QString();
        }

        watcher->deleteLater();
    });

    watcher->setFuture(future);
}

QUrl CachingImageManager::cachePath() const {
    return m_cachePath;
}

void CachingImageManager::createCache(
    const QString& path, const QString& cache, const QString& fillMode, const QSize& size) const {
    QThreadPool::globalInstance()->start([path, cache, fillMode, size] {
        QImage image(path);

        if (image.isNull()) {
            qWarning() << "CachingImageManager::createCache: failed to read" << path;
            return;
        }

        image.convertTo(QImage::Format_ARGB32);

        if (fillMode == "PreserveAspectCrop") {
            image = image.scaled(size, Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation);
        } else if (fillMode == "PreserveAspectFit") {
            image = image.scaled(size, Qt::KeepAspectRatio, Qt::SmoothTransformation);
        } else {
            image = image.scaled(size, Qt::IgnoreAspectRatio, Qt::SmoothTransformation);
        }

        if (fillMode == "PreserveAspectCrop" || fillMode == "PreserveAspectFit") {
            QImage canvas(size, QImage::Format_ARGB32);
            canvas.fill(Qt::transparent);

            QPainter painter(&canvas);
            painter.drawImage((size.width() - image.width()) / 2, (size.height() - image.height()) / 2, image);
            painter.end();

            image = canvas;
        }

        const QString parent = QFileInfo(cache).absolutePath();
        if (!QDir().mkpath(parent) || !image.save(cache)) {
            qWarning() << "CachingImageManager::createCache: failed to save to" << cache;
        }
    });
}

QString CachingImageManager::sha256sum(const QString& path) {
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "CachingImageManager::sha256sum: failed to open" << path;
        return "";
    }

    QCryptographicHash hash(QCryptographicHash::Sha256);
    hash.addData(&file);
    file.close();

    return hash.result().toHex();
}

} // namespace caelestia::internal
