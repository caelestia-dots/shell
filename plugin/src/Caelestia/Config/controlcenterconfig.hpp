#pragma once

#include "configobject.hpp"

namespace caelestia::config {

// ControlCenterConfig has no serialized properties (serializer returns {})
// All properties are in AdvancedConfig.controlCenter
class ControlCenterConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

public:
    explicit ControlCenterConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

} // namespace caelestia::config
