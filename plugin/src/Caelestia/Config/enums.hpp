#pragma once

#include <qqmlintegration.h>

namespace caelestia::config {

namespace bar {

Q_NAMESPACE
QML_NAMED_ELEMENT(BarEnums)

enum WorkspaceDisplay {
    Shapes,
    Text
};
Q_ENUM_NS(WorkspaceDisplay)

} // namespace bar

} // namespace caelestia::config
