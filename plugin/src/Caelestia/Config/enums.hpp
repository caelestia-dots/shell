#pragma once

#include <qobject.h>
#include <qqmlintegration.h>

namespace caelestia::config {

#define ENUM(Name, ...)                                                                                                \
    namespace Name {                                                                                                   \
                                                                                                                       \
    Q_NAMESPACE                                                                                                        \
    QML_NAMED_ELEMENT(Name)                                                                                            \
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
ENUM(WallpaperTransition,
    // clang-format off
    ChromaticBloom,
    ColourDistance,
    Crossfade,
    Crosshatch,
    Crosswarp,
    Directional,
    DirectionalWipe,
    FadeColour,
    Glitch,
    GlitchDisplace,
    HeatMelt,
    InkSplash,
    InkwellDrop,
    Iris,
    Morph,
    ParametricGlitch,
    Perlin,
    Pixelate,
    PixelfadeWave,
    PlasmaFlow,
    PolkaDotsCurtain,
    PuzzleRight,
    RandomSquares,
    Smoke,
    SoftWarpFade,
    VoronoiShatter,
    ZoomBlurPull,
    // clang-format on
)

#undef ENUM

} // namespace caelestia::config
