#pragma once

#include <qlist.h>

#include <limits>

#include "settings/objectnode.hpp"
#include "common.hpp"

namespace caelestia::config {

class AnimCurves : public settings::ObjectNode {
    CONFIG_NODE(AnimCurves, settings::ObjectNode)

    CONFIG_GLOBAL_PROPERTY(QList<qreal>, emphasized,
        DEFAULT_ARG({ 0.05, 0, 2.0 / 15.0, 0.06, 1.0 / 6.0, 0.4, 5.0 / 24.0, 0.82, 0.25, 1, 1, 1 }))
    CONFIG_GLOBAL_PROPERTY(QList<qreal>, emphasizedAccel, DEFAULT_ARG({ 0.3, 0, 0.8, 0.15, 1, 1 }))
    CONFIG_GLOBAL_PROPERTY(QList<qreal>, emphasizedDecel, DEFAULT_ARG({ 0.05, 0.7, 0.1, 1, 1, 1 }))
    CONFIG_GLOBAL_PROPERTY(QList<qreal>, standard, DEFAULT_ARG({ 0.2, 0, 0, 1, 1, 1 }))
    CONFIG_GLOBAL_PROPERTY(QList<qreal>, standardAccel, DEFAULT_ARG({ 0.3, 0, 1, 1, 1, 1 }))
    CONFIG_GLOBAL_PROPERTY(QList<qreal>, standardDecel, DEFAULT_ARG({ 0, 0, 0, 1, 1, 1 }))
    CONFIG_GLOBAL_PROPERTY(QList<qreal>, expressiveFastSpatial, DEFAULT_ARG({ 0.42, 1.67, 0.21, 0.9, 1, 1 }))
    CONFIG_GLOBAL_PROPERTY(QList<qreal>, expressiveDefaultSpatial, DEFAULT_ARG({ 0.38, 1.21, 0.22, 1, 1, 1 }))
    CONFIG_GLOBAL_PROPERTY(QList<qreal>, expressiveSlowSpatial, DEFAULT_ARG({ 0.39, 1.29, 0.35, 0.98, 1, 1 }))
    CONFIG_GLOBAL_PROPERTY(QList<qreal>, expressiveFastEffects, DEFAULT_ARG({ 0.31, 0.94, 0.34, 1, 1, 1 }))
    CONFIG_GLOBAL_PROPERTY(QList<qreal>, expressiveDefaultEffects, DEFAULT_ARG({ 0.34, 0.8, 0.34, 1, 1, 1 }))
    CONFIG_GLOBAL_PROPERTY(QList<qreal>, expressiveSlowEffects, DEFAULT_ARG({ 0.34, 0.88, 0.34, 1, 1, 1 }))
};

class RoundingTokens : public settings::ObjectNode {
    CONFIG_NODE(RoundingTokens, settings::ObjectNode)

    CONFIG_PROPERTY(int, extraSmall, 4)
    CONFIG_PROPERTY(int, small, 8)
    CONFIG_PROPERTY(int, medium, 12)
    CONFIG_PROPERTY(int, large, 16)
    CONFIG_PROPERTY(int, largeIncreased, 20)
    CONFIG_PROPERTY(int, extraLarge, 28)
    CONFIG_PROPERTY(int, extraLargeIncreased, 32)
    CONFIG_PROPERTY(int, extraExtraLarge, 48)
    CONFIG_PROPERTY(int, full, std::numeric_limits<int>::max())
};

class SpacingTokens : public settings::ObjectNode {
    CONFIG_NODE(SpacingTokens, settings::ObjectNode)

    CONFIG_PROPERTY(int, extraSmall, 4)
    CONFIG_PROPERTY(int, small, 8)
    CONFIG_PROPERTY(int, medium, 12)
    CONFIG_PROPERTY(int, large, 16)
    CONFIG_PROPERTY(int, largeIncreased, 20)
    CONFIG_PROPERTY(int, extraLarge, 28)
    CONFIG_PROPERTY(int, extraLargeIncreased, 32)
    CONFIG_PROPERTY(int, extraExtraLarge, 48)
};

class PaddingTokens : public settings::ObjectNode {
    CONFIG_NODE(PaddingTokens, settings::ObjectNode)

    CONFIG_PROPERTY(int, extraSmall, 4)
    CONFIG_PROPERTY(int, small, 8)
    CONFIG_PROPERTY(int, medium, 12)
    CONFIG_PROPERTY(int, large, 16)
    CONFIG_PROPERTY(int, largeIncreased, 20)
    CONFIG_PROPERTY(int, extraLarge, 28)
    CONFIG_PROPERTY(int, extraLargeIncreased, 32)
    CONFIG_PROPERTY(int, extraExtraLarge, 48)
};

class FontSizeTokens : public settings::ObjectNode {
    CONFIG_NODE(FontSizeTokens, settings::ObjectNode)

    CONFIG_PROPERTY(int, small, 11)
    CONFIG_PROPERTY(int, smaller, 12)
    CONFIG_PROPERTY(int, normal, 13)
    CONFIG_PROPERTY(int, larger, 15)
    CONFIG_PROPERTY(int, large, 18)
    CONFIG_PROPERTY(int, extraLarge, 28)
};

class AnimDurationTokens : public settings::ObjectNode {
    CONFIG_NODE(AnimDurationTokens, settings::ObjectNode)

    CONFIG_GLOBAL_PROPERTY(int, small, 200)
    CONFIG_GLOBAL_PROPERTY(int, normal, 400)
    CONFIG_GLOBAL_PROPERTY(int, large, 600)
    CONFIG_GLOBAL_PROPERTY(int, extraLarge, 1000)
    CONFIG_GLOBAL_PROPERTY(int, expressiveFastSpatial, 350)
    CONFIG_GLOBAL_PROPERTY(int, expressiveDefaultSpatial, 500)
    CONFIG_GLOBAL_PROPERTY(int, expressiveSlowSpatial, 650)
    CONFIG_GLOBAL_PROPERTY(int, expressiveFastEffects, 150)
    CONFIG_GLOBAL_PROPERTY(int, expressiveDefaultEffects, 200)
    CONFIG_GLOBAL_PROPERTY(int, expressiveSlowEffects, 300)
};

class AppearanceTokens : public settings::ObjectNode {
    CONFIG_NODE(AppearanceTokens, settings::ObjectNode)

    CONFIG_SUBOBJECT(AnimCurves, curves)
    CONFIG_SUBOBJECT(RoundingTokens, rounding)
    CONFIG_SUBOBJECT(SpacingTokens, spacing)
    CONFIG_SUBOBJECT(PaddingTokens, padding)
    CONFIG_SUBOBJECT(FontSizeTokens, fontSize)
    CONFIG_SUBOBJECT(AnimDurationTokens, animDurations)
};

class BarTokens : public settings::ObjectNode {
    CONFIG_NODE(BarTokens, settings::ObjectNode)

    CONFIG_PROPERTY(int, innerWidth, 40)
    CONFIG_PROPERTY(int, windowPreviewSize, 400)
    CONFIG_PROPERTY(int, trayMenuWidth, 300)
    CONFIG_PROPERTY(int, batteryWidth, 250)
    CONFIG_PROPERTY(int, networkWidth, 320)
    CONFIG_PROPERTY(int, kbLayoutWidth, 320)
};

class DashboardTokens : public settings::ObjectNode {
    CONFIG_NODE(DashboardTokens, settings::ObjectNode)

    CONFIG_PROPERTY(int, tabIndicatorHeight, 3)
    CONFIG_PROPERTY(int, tabIndicatorSpacing, 5)
    CONFIG_PROPERTY(int, userWidth, 340)
    CONFIG_PROPERTY(int, logoSize, 30)
    CONFIG_PROPERTY(int, uptimeSize, 30)
    CONFIG_PROPERTY(int, dateTimeWidth, 110)
    CONFIG_PROPERTY(int, mediaWidth, 200)
    CONFIG_PROPERTY(int, mediaProgressSweep, 180)
    CONFIG_PROPERTY(int, mediaProgressThickness, 6)
    CONFIG_PROPERTY(int, resourceProgressThickness, 6)
    CONFIG_PROPERTY(int, weatherWidth, 275)
    CONFIG_PROPERTY(int, mediaCoverArtSize, 200)
    CONFIG_PROPERTY(int, mediaTabWidth, 1000)
    CONFIG_PROPERTY(int, mediaTabHeight, 320)
    CONFIG_PROPERTY(int, mediaSectionWidth, 300)
    CONFIG_PROPERTY(int, perfHeroCardWidth, 400)
    CONFIG_PROPERTY(int, perfUsageShapeSize, 100)
    CONFIG_PROPERTY(int, perfStorageTextWidth, 160)
    CONFIG_PROPERTY(int, perfNetworkCardWidth, 390)
    CONFIG_PROPERTY(int, perfNetworkCardHeight, 220)
    CONFIG_PROPERTY(int, perfBattWidth, 150)
    CONFIG_PROPERTY(int, perfBattWidthSingle, 400)
    CONFIG_PROPERTY(int, perfBattHeight, 160)
    CONFIG_PROPERTY(int, perfPlaceholderWidth, 700)
};

class LauncherTokens : public settings::ObjectNode {
    CONFIG_NODE(LauncherTokens, settings::ObjectNode)

    CONFIG_PROPERTY(int, itemWidth, 600)
    CONFIG_PROPERTY(int, itemHeight, 57)
    CONFIG_PROPERTY(int, wallpaperWidth, 280)
    CONFIG_PROPERTY(int, wallpaperHeight, 200)
};

class NotifsTokens : public settings::ObjectNode {
    CONFIG_NODE(NotifsTokens, settings::ObjectNode)

    CONFIG_PROPERTY(int, width, 430)
    CONFIG_GLOBAL_PROPERTY(int, image, 42)
    CONFIG_PROPERTY(int, badge, 20)
};

class OsdTokens : public settings::ObjectNode {
    CONFIG_NODE(OsdTokens, settings::ObjectNode)

    CONFIG_PROPERTY(int, sliderWidth, 30)
    CONFIG_PROPERTY(int, sliderHeight, 150)
};

class SessionTokens : public settings::ObjectNode {
    CONFIG_NODE(SessionTokens, settings::ObjectNode)

    CONFIG_PROPERTY(int, button, 80)
};

class SidebarTokens : public settings::ObjectNode {
    CONFIG_NODE(SidebarTokens, settings::ObjectNode)

    CONFIG_PROPERTY(int, width, 430)
};

class UtilitiesTokens : public settings::ObjectNode {
    CONFIG_NODE(UtilitiesTokens, settings::ObjectNode)

    CONFIG_PROPERTY(int, width, 430)
    CONFIG_PROPERTY(int, toastWidth, 430)
};

class LockTokens : public settings::ObjectNode {
    CONFIG_NODE(LockTokens, settings::ObjectNode)

    CONFIG_PROPERTY(qreal, heightMult, 0.7)
    CONFIG_PROPERTY(qreal, ratio, 16.0 / 9.0)
    CONFIG_PROPERTY(int, centerWidth, 600)
    CONFIG_PROPERTY(int, showWeatherDetailsHeight, 550)
    CONFIG_PROPERTY(int, showForecastHeight, 975)
    CONFIG_PROPERTY(int, forecastItemWidth, 51)
    CONFIG_PROPERTY(int, largeLogoWidth, 320)
    CONFIG_PROPERTY(int, largeFontWidth, 400)
    CONFIG_PROPERTY(int, fetch4LinesHeight, 600)
    CONFIG_PROPERTY(int, fetch3LinesHeight, 500)
    CONFIG_PROPERTY(int, showColourBoxRowHeight, 570)
};

class WInfoTokens : public settings::ObjectNode {
    CONFIG_NODE(WInfoTokens, settings::ObjectNode)

    CONFIG_PROPERTY(qreal, heightMult, 0.7)
    CONFIG_PROPERTY(qreal, detailsWidth, 500)
};

class NexusTokens : public settings::ObjectNode {
    CONFIG_NODE(NexusTokens, settings::ObjectNode)

    CONFIG_PROPERTY(qreal, heightMult, 0.7)
    CONFIG_PROPERTY(qreal, ratio, 16.0 / 9.0)
    CONFIG_PROPERTY(int, minWidth, 800)
    CONFIG_PROPERTY(int, minHeight, 500)
    CONFIG_PROPERTY(int, maxNavWidth, 600)
    CONFIG_PROPERTY(int, maxContentWidth, 800)
    CONFIG_PROPERTY(int, popupWidth, 300)
    CONFIG_PROPERTY(int, minPopupHeight, 200)
    CONFIG_PROPERTY(int, maxPopupHeight, 800)
    CONFIG_PROPERTY(int, networkShowEthDetailWidth, 620)
    CONFIG_PROPERTY(int, networkShowVpnDetailWidth, 620)
    CONFIG_PROPERTY(int, maxDialogWidth, 400)
    CONFIG_PROPERTY(int, maxDialogHeight, 600)
    CONFIG_PROPERTY(int, textFieldWidth, 250)
    CONFIG_PROPERTY(int, smallTextFieldWidth, 100)
};

class SizeTokens : public settings::ObjectNode {
    CONFIG_NODE(SizeTokens, settings::ObjectNode)

    CONFIG_SUBOBJECT(BarTokens, bar)
    CONFIG_SUBOBJECT(DashboardTokens, dashboard)
    CONFIG_SUBOBJECT(LauncherTokens, launcher)
    CONFIG_SUBOBJECT(NotifsTokens, notifs)
    CONFIG_SUBOBJECT(OsdTokens, osd)
    CONFIG_SUBOBJECT(SessionTokens, session)
    CONFIG_SUBOBJECT(SidebarTokens, sidebar)
    CONFIG_SUBOBJECT(UtilitiesTokens, utilities)
    CONFIG_SUBOBJECT(LockTokens, lock)
    CONFIG_SUBOBJECT(WInfoTokens, winfo)
    CONFIG_SUBOBJECT(NexusTokens, nexus)
};

} // namespace caelestia::config
