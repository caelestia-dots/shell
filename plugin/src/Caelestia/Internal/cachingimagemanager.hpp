#pragma once

#include <QtQuick/qquickitem.h>
#include <qobject.h>
#include <qqmlintegration.h>

namespace caelestia::internal {

class CachingImageManager : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QQuickItem* item READ item WRITE setItem NOTIFY itemChanged REQUIRED)
    Q_PROPERTY(QUrl cacheDir READ cacheDir WRITE setCacheDir NOTIFY cacheDirChanged REQUIRED)

    Q_PROPERTY(QString path READ path WRITE setPath NOTIFY pathChanged)
    Q_PROPERTY(QUrl cachePath READ cachePath NOTIFY cachePathChanged)

public:
    explicit CachingImageManager(QObject* parent = nullptr)
        : QObject(parent)
        , m_item(nullptr) {}

    [[nodiscard]] QQuickItem* item() const;
    void setItem(QQuickItem* item);

    [[nodiscard]] QUrl cacheDir() const;
    void setCacheDir(const QUrl& cacheDir);

    [[nodiscard]] QString path() const;
    void setPath(const QString& path);

    [[nodiscard]] QUrl cachePath() const;

    Q_INVOKABLE void updateSource();
    Q_INVOKABLE void updateSource(const QString& path);

signals:
    void itemChanged();
    void cacheDirChanged();

    void pathChanged();
    void cachePathChanged();
    void usingCacheChanged();

private:
    QString m_shaPath;

    QQuickItem* m_item;
    QUrl m_cacheDir;

    QString m_path;
    QUrl m_cachePath;

    QMetaObject::Connection m_widthConn;
    QMetaObject::Connection m_heightConn;

    [[nodiscard]] qreal effectiveScale() const;
    [[nodiscard]] QSize effectiveSize() const;

    void createCache(const QString& path, const QString& cache, const QString& fillMode, const QSize& size) const;
    [[nodiscard]] static QString sha256sum(const QString& path);
};

} // namespace caelestia::internal
