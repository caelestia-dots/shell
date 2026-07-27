#pragma once

#include <qobject.h>
#include <qqmlintegration.h>
#include <qurl.h>

namespace caelestia::images {

class IUtils : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    static IUtils* create(QQmlEngine* engine, QJSEngine* jsEngine);

    Q_INVOKABLE static QUrl urlForPath(const QString& path, int fillMode);

private:
    explicit IUtils(QObject* parent = nullptr)
        : QObject(parent) {};
};

} // namespace caelestia::images
