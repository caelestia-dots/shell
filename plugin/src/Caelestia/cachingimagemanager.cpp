#include "cachingimagemanager.hpp"

#include <qobject.h>
#include <QtQuick/QQuickItem>
#include <QtQuick/QQuickWindow>
#include <QCryptographicHash>
#include <QThreadPool>
#include <QFile>
#include <QDir>
#include <QPainter>

qreal CachingImageManager::effectiveScale() const {
    if (m_item && m_item->window()) {
        return m_item->window()->devicePixelRatio();
    }

    return 1.0;
}

int CachingImageManager::effectiveWidth() const {
    if (!m_item) {
        return 0;
    }

    int width = std::ceil(m_item->width() * effectiveScale());
    m_item->setProperty("sourceWidth", width);
    return width;
}

int CachingImageManager::effectiveHeight() const {
    if (!m_item) {
        return 0;
    }

    int height = std::ceil(m_item->height() * effectiveScale());
    m_item->setProperty("sourceHeight", height);
    return height;
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
        m_widthConn = connect(item, &QQuickItem::widthChanged, this, [this]() { updateSource(); });
        m_heightConn = connect(item, &QQuickItem::heightChanged, this, [this]() { updateSource(); });
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

    QPointer<CachingImageManager> self(this);
    QThreadPool::globalInstance()->start([path, self] {
        const QString sha = self->sha256sum(path);

        QMetaObject::invokeMethod(self, [path, sha, self]() {
            if (!self || self->m_path != path) {
                // Object is destroyed or path has changed, ignore
                return;
            }

            int width = self->effectiveWidth();
            int height = self->effectiveHeight();

            if (!self->m_item || !width || !height) {
                return;
            }

            const QString fillMode = self->m_item->property("fillMode").toString();
            const QString filename = QString("%1@%2x%3-%4.png")
                .arg(sha).arg(width).arg(height)
                .arg(fillMode == "PreserveAspectCrop" ? "crop" : fillMode == "PreserveAspectFit" ? "fit" : "stretch");

            const QUrl cache = self->m_cacheDir.resolved(QUrl(filename));
            if (self->m_cachePath == cache) {
                return;
            }

            self->m_cachePath = cache;
            emit self->cachePathChanged();

            if (!cache.isLocalFile()) {
                qWarning() << "CachingImageManager::updateSource: cachePath" << cache << "is not a local file";
                return;
            }

            bool cacheExists = QFile::exists(cache.toLocalFile());

            if (cacheExists) {
                self->m_item->setProperty("source", cache);
            } else {
                self->m_item->setProperty("source", QUrl::fromLocalFile(path));
                self->createCache(path, cache.toLocalFile(), fillMode, QSize(width, height));
            }

            // Clear current running sha if same
            if (self->m_shaPath == path) {
                self->m_shaPath = QString();
            }
        }, Qt::QueuedConnection);
    });
}

QUrl CachingImageManager::cachePath() const {
    return m_cachePath;
}

void CachingImageManager::createCache(const QString& path, const QString& cache, const QString& fillMode, const QSize& size) const {
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

QString CachingImageManager::sha256sum(const QString& path) const {
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
