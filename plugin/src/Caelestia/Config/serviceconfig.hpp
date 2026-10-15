#pragma once

#include <qstring.h>
#include <qvariantlist.h>

#include "settings/objectnode.hpp"
#include "common.hpp"
#include "enums.hpp"

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;
using settings::vmap;

class PlayerAlias : public settings::ObjectNode {
    CONFIG_NODE(PlayerAlias, settings::ObjectNode)

    CONFIG_PROPERTY(QString, from, {})
    CONFIG_PROPERTY(QString, to, {})
};
CONFIG_LIST_TYPE(PlayerAlias, PlayerAliasList)

class ServiceConfig : public settings::ObjectNode {
    CONFIG_NODE(ServiceConfig, settings::ObjectNode)

    CONFIG_GLOBAL_PROPERTY(QString, weatherLocation, {})
    // Auto guesses based on locale
    CONFIG_GLOBAL_ENUM_PROPERTY(TemperatureUnit, weatherUnits, TemperatureUnit::Auto)
    // Always Celsius by default cause apparently even imperial system users don't use Fahrenheit for perf temps?
    CONFIG_GLOBAL_ENUM_PROPERTY(TemperatureUnit, sensorUnits, TemperatureUnit::Celsius)
    // Binary (KiB/MiB/GiB) or decimal (KB/MB/GB) data sizes
    CONFIG_GLOBAL_ENUM_PROPERTY(DataUnit, dataUnits, DataUnit::Binary)
    CONFIG_GLOBAL_ENUM_PROPERTY(ClockFormat, clockFormat, ClockFormat::Auto)
    CONFIG_GLOBAL_ENUM_PROPERTY(GpuType, gpuType, GpuType::Auto)
    CONFIG_GLOBAL_PROPERTY(int, visualiserBars, 60)
    CONFIG_GLOBAL_PROPERTY(qreal, audioIncrement, 0.1)
    CONFIG_GLOBAL_PROPERTY(qreal, brightnessIncrement, 0.1)
    CONFIG_GLOBAL_PROPERTY(qreal, maxVolume, 1.0)
    CONFIG_GLOBAL_PROPERTY(bool, smartScheme, true)
    CONFIG_GLOBAL_PROPERTY(QString, defaultPlayer, u"Spotify"_s)
    CONFIG_GLOBAL_LIST(PlayerAliasList, playerAliases,
        DEFAULT_ARG({
            vmap({ { u"from"_s, u"com.github.th_ch.youtube_music"_s }, { u"to"_s, u"YT Music"_s } }),
        }))
    CONFIG_GLOBAL_ENUM_PROPERTY(LyricsBackend, lyricsBackend, LyricsBackend::Auto)
};

} // namespace caelestia::config
