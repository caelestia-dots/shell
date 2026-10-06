#pragma once

#include <qlist.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qquickitem.h>
#include <qvariant.h>

namespace caelestia {

class CUtils : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString version READ version CONSTANT)
    Q_PROPERTY(QString qtVersion READ qtVersion CONSTANT)

public:
    Q_INVOKABLE void saveItem(
        QQuickItem* target, const QUrl& path, const QJSValue& onSaved = {}, const QJSValue& onFailed = {});
    Q_INVOKABLE void saveItem(QQuickItem* target, const QUrl& path, const QRect& rect, const QJSValue& onSaved = {},
        const QJSValue& onFailed = {});

    Q_INVOKABLE static bool copyFile(const QUrl& source, const QUrl& target, bool overwrite = true);
    Q_INVOKABLE static bool deleteFile(const QUrl& path);
    Q_INVOKABLE static QString toLocalFile(const QUrl& url);

    Q_INVOKABLE static qreal clamp(qreal value, qreal min, qreal max);

    Q_INVOKABLE static QString enumToString(QObject* target, const QString& property, const QVariant& value = {});

    Q_INVOKABLE static QQuickItem* findChild(QQuickItem* root, const QString& name);
    Q_INVOKABLE static QList<QQuickItem*> findChildren(QQuickItem* root, const QString& name);
    Q_INVOKABLE static QList<QQuickItem*> findChildrenMatching(QQuickItem* root, const QString& pattern);

    [[nodiscard]] static QString version();
    [[nodiscard]] static QString qtVersion();
};

} // namespace caelestia
