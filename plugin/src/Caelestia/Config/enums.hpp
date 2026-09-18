#pragma once

#include <qobject.h>
#include <qqmlintegration.h>

namespace caelestia::config {

#define ENUM(Name, ...)                                                                                                \
    namespace Name {                                                                                                   \
                                                                                                                       \
    Q_NAMESPACE                                                                                                        \
    QML_ELEMENT                                                                                                        \
                                                                                                                       \
    enum Enum : quint8 {                                                                                               \
        __VA_ARGS__                                                                                                    \
    };                                                                                                                 \
    Q_ENUM_NS(Enum)                                                                                                    \
                                                                                                                       \
    };

ENUM(BarWorkspaceDisplay, Shapes, Text, Icons)
ENUM(BarWorkspaceCapitalisation, Preserve, Upper, Lower)
ENUM(LyricsBackend, Auto, Local, LRCLIB, NetEase)
ENUM(GpuType, Auto, Nvidia, Generic, None)
ENUM(NotifsFullscreen, On, Off)
ENUM(TemperatureUnit, Auto, Celsius, Fahrenheit, Kelvin)
ENUM(DataUnit, Binary, Decimal)
ENUM(ClockFormat, Auto, TwelveHour, TwentyFourHour)

#undef ENUM

} // namespace caelestia::config
