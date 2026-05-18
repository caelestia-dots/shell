#pragma once

#include "configobject.hpp"

#include <qstring.h>

namespace caelestia::config {

class ShimejiConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(bool, autoHide, true)
    CONFIG_PROPERTY(QString, path, QString())
    CONFIG_PROPERTY(QStringList, excludedScreens)

public:
    explicit ShimejiConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

} // namespace caelestia::config
