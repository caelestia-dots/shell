#pragma once

#include <qlocale.h>
#include <qstring.h>
#include <qvariantlist.h>

#include "settings/objectnode.hpp"
#include "common.hpp"
#include "enums.hpp"

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;
using settings::vmap;

class ServiceConfig : public settings::ObjectNode {
    CONFIG_NODE(ServiceConfig, settings::ObjectNode)

    CONFIG_GLOBAL_PROPERTY(QString, weatherLocation, QString())
    // Guess based on locale
    CONFIG_GLOBAL_PROPERTY(bool, useFahrenheit,
        QLocale().measurementSystem() == QLocale::ImperialUSSystem ||
            QLocale().measurementSystem() == QLocale::ImperialUKSystem)
    // This is always false by default cause apparently even imperial system users don't use it for perf temps?
    CONFIG_GLOBAL_PROPERTY(bool, useFahrenheitPerformance, false)
    // Attempt to guess based on locale
    CONFIG_GLOBAL_PROPERTY(
        bool, useTwelveHourClock, QLocale().timeFormat(QLocale::ShortFormat).toLower().contains(u"a"_s))
    CONFIG_GLOBAL_ENUM_PROPERTY(GpuType, gpuType, GpuType::Auto)
    CONFIG_GLOBAL_PROPERTY(int, visualiserBars, 60)
    CONFIG_GLOBAL_PROPERTY(qreal, audioIncrement, 0.1)
    CONFIG_GLOBAL_PROPERTY(qreal, brightnessIncrement, 0.1)
    CONFIG_GLOBAL_PROPERTY(qreal, maxVolume, 1.0)
    CONFIG_GLOBAL_PROPERTY(bool, smartScheme, true)
    CONFIG_GLOBAL_PROPERTY(QString, defaultPlayer, u"Spotify"_s)
    CONFIG_GLOBAL_PROPERTY(QVariantList, playerAliases,
        DEFAULT_ARG({
            vmap({ { u"from"_s, u"com.github.th_ch.youtube_music"_s }, { u"to"_s, u"YT Music"_s } }),
        }))
    CONFIG_GLOBAL_ENUM_PROPERTY(LyricsBackend, lyricsBackend, LyricsBackend::Auto)
};

} // namespace caelestia::config
