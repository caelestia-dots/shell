#pragma once

#include "configobject.hpp"

namespace caelestia::config {

// WInfoConfig has no serialized properties (serializer returns {})
// All properties are in AdvancedConfig.winfo
class WInfoConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

public:
    explicit WInfoConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

} // namespace caelestia::config
