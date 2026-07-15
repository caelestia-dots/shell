#pragma once

#include "configobject.hpp"

namespace caelestia::config {

class SidebarConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(bool, showOnHover, false)
    CONFIG_PROPERTY(int, minHoverThreshold, 200)
    CONFIG_PROPERTY(int, dragThreshold, 80)

public:
    explicit SidebarConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

} // namespace caelestia::config
