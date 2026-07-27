#pragma once

#include "configobject.hpp"

namespace caelestia::config {

class OsdConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(int, hideDelay, 2000)
    CONFIG_PROPERTY(bool, enableBrightness, true)
    CONFIG_PROPERTY(bool, enableMicrophone, false)

public:
    explicit OsdConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

} // namespace caelestia::config
