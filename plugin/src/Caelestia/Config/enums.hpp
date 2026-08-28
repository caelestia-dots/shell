#pragma once

#include <qqmlintegration.h>

namespace caelestia::config {

#define ENUM(Name, ...)                                                                                                \
    namespace Name {                                                                                                   \
                                                                                                                       \
    Q_NAMESPACE                                                                                                        \
    QML_ELEMENT                                                                                                        \
                                                                                                                       \
    enum Enum {                                                                                                        \
        __VA_ARGS__                                                                                                    \
    };                                                                                                                 \
    Q_ENUM_NS(Enum)                                                                                                    \
                                                                                                                       \
    };

ENUM(BarWorkspaceDisplay, Shapes, Text)
ENUM(BarWorkspaceCapitalisation, Preserve, Upper, Lower)
ENUM(LyricsBackend, Auto, Local, LRCLIB, NetEase)

#undef ENUM

} // namespace caelestia::config
