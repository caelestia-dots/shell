#pragma once

#include <qobject.h>
#include <qqmlintegration.h>
#include <QtQuick/QQuickItem>

class CachingImageManager : public QObject {
    Q_OBJECT;
    QML_ELEMENT;

    Q_PROPERTY(QQuickItem* item READ item WRITE setItem NOTIFY itemChanged REQUIRED);
    Q_PROPERTY(QUrl cacheDir READ cacheDir WRITE setCacheDir NOTIFY cacheDirChanged REQUIRED);

    Q_PROPERTY(QString path READ path WRITE setPath NOTIFY pathChanged);
    Q_PROPERTY(QUrl cachePath READ cachePath NOTIFY cachePathChanged);
    Q_PROPERTY(bool usingCache READ usingCache NOTIFY usingCacheChanged);

public:
    explicit CachingImageManager(QObject* parent = nullptr): QObject(parent) {};

    [[nodiscard]] QQuickItem* item() const;
    void setItem(QQuickItem* item);

    [[nodiscard]] QUrl cacheDir() const;
    void setCacheDir(const QUrl& cacheDir);

    [[nodiscard]] QString path() const;
    void setPath(const QString& path);

    [[nodiscard]] QUrl cachePath() const;
    [[nodiscard]] bool usingCache() const;

    Q_INVOKABLE void updateSource();
    Q_INVOKABLE void updateSource(const QString& path);

signals:
    void itemChanged();
    void cacheDirChanged();

    void pathChanged();
    void cachePathChanged();
    void usingCacheChanged();

private:
    QQuickItem* m_item;
    QUrl m_cacheDir;

    QString m_path;
    QUrl m_cachePath;
    bool m_usingCache;

    QMetaObject::Connection m_widthConn;
    QMetaObject::Connection m_heightConn;

    [[nodiscard]] qreal effectiveScale() const;
    [[nodiscard]] int effectiveWidth() const;
    [[nodiscard]] int effectiveHeight() const;

    [[nodiscard]] QString sha256sum(const QString& path) const;
};
