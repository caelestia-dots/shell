#pragma once

#include <qobject.h>
#include <qqmlintegration.h>

namespace caelestia::shaders {

class Shaders : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QUrl crossfade READ crossfade CONSTANT)

public:
    explicit Shaders(QObject* parent = nullptr)
        : QObject(parent) {};

    [[nodiscard]] static QUrl crossfade();
};

} // namespace caelestia::shaders
