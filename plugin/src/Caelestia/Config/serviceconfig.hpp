#pragma once

#include <qlocale.h>
#include <qstring.h>
#include <qvariantlist.h>

#include "common.hpp"
#include "settings/objectnode.hpp"

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
    CONFIG_GLOBAL_PROPERTY(QString, gpuType, QString())
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
    CONFIG_GLOBAL_PROPERTY(QString, lyricsBackend, u"Auto"_s)
    CONFIG_GLOBAL_PROPERTY(bool, bluetoothBatteryIcon, true)
    CONFIG_GLOBAL_PROPERTY(bool, bluetoothBatteryText, false)
    CONFIG_GLOBAL_PROPERTY(bool, bluetoothBatterySwapIconText, false)
    CONFIG_GLOBAL_PROPERTY(int, bluetoothBatteryIndicatorType, 2)
    CONFIG_GLOBAL_PROPERTY(bool, bluetoothBatteryRing, true)
    CONFIG_GLOBAL_PROPERTY(bool, bluetoothBatteryPopupInQuickSettings, false)
    CONFIG_GLOBAL_PROPERTY(bool, bluetoothBatterySortByHistory, false)
    CONFIG_GLOBAL_PROPERTY(int, bluetoothBatteryHideIndicatorMode, 0)
    CONFIG_GLOBAL_PROPERTY(int, bluetoothBatteryIndicatorStyle, 1)
    CONFIG_GLOBAL_PROPERTY(bool, bluetoothBatteryMultiIndicator, false)
    CONFIG_GLOBAL_PROPERTY(bool, bluetoothBatteryHoverMode, true)
    CONFIG_GLOBAL_PROPERTY(int, bluetoothBatteryHoverDelay, 1000)
    CONFIG_GLOBAL_PROPERTY(bool, bluetoothBatteryTooltips, true)
    CONFIG_GLOBAL_PROPERTY(bool, bluetoothBatteryPerDeviceDefaults, true)
    CONFIG_GLOBAL_PROPERTY(bool, bluetoothBatteryUpowerSupport, false)
    CONFIG_GLOBAL_PROPERTY(int, bluetoothBatteryLevelIndicatorType, 0)
    CONFIG_GLOBAL_PROPERTY(bool, bluetoothBatteryUseCustomColors, false)
    CONFIG_GLOBAL_PROPERTY(int, bluetoothBatteryColorScheme, 0)
    CONFIG_GLOBAL_PROPERTY(QStringList, bluetoothBatteryColors,
        { u"#4ade80"_s, u"#4ade80"_s, u"#65d66d"_s, u"#8ae06d"_s, u"#b7db6d"_s,
            u"#facc15"_s, u"#f59e0b"_s, u"#fb923c"_s, u"#f87171"_s, u"#ef4444"_s })
};

} // namespace caelestia::config
