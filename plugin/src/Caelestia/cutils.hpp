#pragma once

#include <QtQuick/QQuickItem>
#include <qobject.h>
#include <qqmlintegration.h>

class CUtils : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    Q_INVOKABLE void saveItem(QQuickItem* target, const QUrl& path);
    Q_INVOKABLE void saveItem(QQuickItem* target, const QUrl& path, const QRect& rect);
    Q_INVOKABLE void saveItem(QQuickItem* target, const QUrl& path, QJSValue onSaved);
    Q_INVOKABLE void saveItem(QQuickItem* target, const QUrl& path, QJSValue onSaved, QJSValue onFailed);
    Q_INVOKABLE void saveItem(QQuickItem* target, const QUrl& path, const QRect& rect, QJSValue onSaved);
    Q_INVOKABLE void saveItem(
        QQuickItem* target, const QUrl& path, const QRect& rect, QJSValue onSaved, QJSValue onFailed);

    Q_INVOKABLE bool copyFile(const QUrl& source, const QUrl& target) const;
    Q_INVOKABLE bool copyFile(const QUrl& source, const QUrl& target, bool overwrite) const;

    Q_INVOKABLE void getDominantColour(QQuickItem* item, QJSValue callback);
    Q_INVOKABLE void getDominantColour(QQuickItem* item, int rescaleSize, QJSValue callback);
    Q_INVOKABLE void getDominantColour(const QString& path, QJSValue callback);
    Q_INVOKABLE void getDominantColour(const QString& path, int rescaleSize, QJSValue callback);

    Q_INVOKABLE void getAverageLuminance(QQuickItem* item, QJSValue callback);
    Q_INVOKABLE void getAverageLuminance(QQuickItem* item, int rescaleSize, QJSValue callback);
    Q_INVOKABLE void getAverageLuminance(const QString& path, QJSValue callback);
    Q_INVOKABLE void getAverageLuminance(const QString& path, int rescaleSize, QJSValue callback);

private:
    QColor findDominantColour(const QImage& image, int rescaleSize) const;
    qreal findAverageLuminance(const QImage& image, int rescaleSize) const;
};
