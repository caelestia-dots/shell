#pragma once

#include <qobject.h>
#include <qqmlintegration.h>

namespace caelestia::shell::multimedia {

class MediaUtils : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    using QObject::QObject;

    Q_INVOKABLE static bool isSupported(const QString& path);
};

} // namespace caelestia::shell::multimedia
