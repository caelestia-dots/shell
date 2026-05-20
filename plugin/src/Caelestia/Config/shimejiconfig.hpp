#pragma once

#include "configobject.hpp"

#include <qstring.h>

namespace caelestia::config {

class ShimejiConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(bool, autoHide, true)
    CONFIG_PROPERTY(QString, path, QStringLiteral("root:/assets/shimeji/pusheen/"))
    CONFIG_PROPERTY(QStringList, excludedScreens)
    CONFIG_PROPERTY(int, count, 1)
    CONFIG_PROPERTY(QVariantMap, screenCounts)

public:
    explicit ShimejiConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

} // namespace caelestia::config
