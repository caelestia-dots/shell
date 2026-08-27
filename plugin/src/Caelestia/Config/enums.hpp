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

enum WorkspaceCapitalisation {
    Preserve,
    Upper,
    Lower
};
Q_ENUM_NS(WorkspaceCapitalisation)

} // namespace bar

} // namespace caelestia::config
