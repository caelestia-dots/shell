#pragma once

#include "rootconfig.hpp"

#include <limits>
#include <qlist.h>
#include <qqmlengine.h>

namespace caelestia::config {

class AnimCurves : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(QList<qreal>, emphasized)
    CONFIG_GLOBAL_PROPERTY(QList<qreal>, emphasizedAccel)
    CONFIG_GLOBAL_PROPERTY(QList<qreal>, emphasizedDecel)
    CONFIG_GLOBAL_PROPERTY(QList<qreal>, standard)
    CONFIG_GLOBAL_PROPERTY(QList<qreal>, standardAccel)
    CONFIG_GLOBAL_PROPERTY(QList<qreal>, standardDecel)
    CONFIG_GLOBAL_PROPERTY(QList<qreal>, expressiveFastSpatial)
    CONFIG_GLOBAL_PROPERTY(QList<qreal>, expressiveDefaultSpatial)
    CONFIG_GLOBAL_PROPERTY(QList<qreal>, expressiveSlowSpatial)
    CONFIG_GLOBAL_PROPERTY(QList<qreal>, expressiveFastEffects)
    CONFIG_GLOBAL_PROPERTY(QList<qreal>, expressiveDefaultEffects)
    CONFIG_GLOBAL_PROPERTY(QList<qreal>, expressiveSlowEffects)

public:
    explicit AnimCurves(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_emphasized({ 0.05, 0, 2.0 / 15.0, 0.06, 1.0 / 6.0, 0.4, 5.0 / 24.0, 0.82, 0.25, 1, 1, 1 })
        , m_emphasizedAccel({ 0.3, 0, 0.8, 0.15, 1, 1 })
        , m_emphasizedDecel({ 0.05, 0.7, 0.1, 1, 1, 1 })
        , m_standard({ 0.2, 0, 0, 1, 1, 1 })
        , m_standardAccel({ 0.3, 0, 1, 1, 1, 1 })
        , m_standardDecel({ 0, 0, 0, 1, 1, 1 })
        , m_expressiveFastSpatial({ 0.42, 1.67, 0.21, 0.9, 1, 1 })
        , m_expressiveDefaultSpatial({ 0.38, 1.21, 0.22, 1, 1, 1 })
        , m_expressiveSlowSpatial({ 0.39, 1.29, 0.35, 0.98, 1, 1 })
        , m_expressiveFastEffects({ 0.31, 0.94, 0.34, 1, 1, 1 })
        , m_expressiveDefaultEffects({ 0.34, 0.8, 0.34, 1, 1, 1 })
        , m_expressiveSlowEffects({ 0.34, 0.88, 0.34, 1, 1, 1 }) {}
};

class RoundingTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(int, extraSmall, 4)
    CONFIG_PROPERTY(int, small, 8)
    CONFIG_PROPERTY(int, medium, 12)
    CONFIG_PROPERTY(int, large, 16)
    CONFIG_PROPERTY(int, largeIncreased, 20)
    CONFIG_PROPERTY(int, extraLarge, 28)
    CONFIG_PROPERTY(int, extraLargeIncreased, 32)
    CONFIG_PROPERTY(int, extraExtraLarge, 48)
    CONFIG_PROPERTY(int, full, std::numeric_limits<int>::max())

public:
    explicit RoundingTokens(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class SpacingTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(int, extraSmall, 4)
    CONFIG_PROPERTY(int, small, 8)
    CONFIG_PROPERTY(int, medium, 12)
    CONFIG_PROPERTY(int, large, 16)
    CONFIG_PROPERTY(int, largeIncreased, 20)
    CONFIG_PROPERTY(int, extraLarge, 28)
    CONFIG_PROPERTY(int, extraLargeIncreased, 32)
    CONFIG_PROPERTY(int, extraExtraLarge, 48)

public:
    explicit SpacingTokens(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class PaddingTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(int, extraSmall, 4)
    CONFIG_PROPERTY(int, small, 8)
    CONFIG_PROPERTY(int, medium, 12)
    CONFIG_PROPERTY(int, large, 16)
    CONFIG_PROPERTY(int, largeIncreased, 20)
    CONFIG_PROPERTY(int, extraLarge, 28)
    CONFIG_PROPERTY(int, extraLargeIncreased, 32)
    CONFIG_PROPERTY(int, extraExtraLarge, 48)

public:
    explicit PaddingTokens(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class FontSizeTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(int, small, 11)
    CONFIG_PROPERTY(int, smaller, 12)
    CONFIG_PROPERTY(int, normal, 13)
    CONFIG_PROPERTY(int, larger, 15)
    CONFIG_PROPERTY(int, large, 18)
    CONFIG_PROPERTY(int, extraLarge, 28)

public:
    explicit FontSizeTokens(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class AnimDurationTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

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

public:
    explicit AnimDurationTokens(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class AppearanceTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_SUBOBJECT(AnimCurves, curves)
    CONFIG_SUBOBJECT(RoundingTokens, rounding)
    CONFIG_SUBOBJECT(SpacingTokens, spacing)
    CONFIG_SUBOBJECT(PaddingTokens, padding)
    CONFIG_SUBOBJECT(FontSizeTokens, fontSize)
    CONFIG_SUBOBJECT(AnimDurationTokens, animDurations)

public:
    explicit AppearanceTokens(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_curves(new AnimCurves(this))
        , m_rounding(new RoundingTokens(this))
        , m_spacing(new SpacingTokens(this))
        , m_padding(new PaddingTokens(this))
        , m_fontSize(new FontSizeTokens(this))
        , m_animDurations(new AnimDurationTokens(this)) {}
};

class BarTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(int, innerWidth, 40)
    CONFIG_PROPERTY(int, windowPreviewSize, 400)
    CONFIG_PROPERTY(int, trayMenuWidth, 300)
    CONFIG_PROPERTY(int, batteryWidth, 250)
    CONFIG_PROPERTY(int, networkWidth, 320)
    CONFIG_PROPERTY(int, kbLayoutWidth, 320)

public:
    explicit BarTokens(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class DashboardTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

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

public:
    explicit DashboardTokens(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class LauncherTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(int, itemWidth, 600)
    CONFIG_PROPERTY(int, itemHeight, 57)
    CONFIG_PROPERTY(int, wallpaperWidth, 280)
    CONFIG_PROPERTY(int, wallpaperHeight, 200)

public:
    explicit LauncherTokens(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class NotifsTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(int, width, 430)
    CONFIG_GLOBAL_PROPERTY(int, image, 42)
    CONFIG_PROPERTY(int, badge, 20)

public:
    explicit NotifsTokens(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class OsdTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(int, sliderWidth, 30)
    CONFIG_PROPERTY(int, sliderHeight, 150)

public:
    explicit OsdTokens(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class SessionTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(int, button, 80)

public:
    explicit SessionTokens(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class SidebarTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(int, width, 430)

public:
    explicit SidebarTokens(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class UtilitiesTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(int, width, 430)
    CONFIG_PROPERTY(int, toastWidth, 430)

public:
    explicit UtilitiesTokens(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class LockTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

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

public:
    explicit LockTokens(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class WInfoTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(qreal, heightMult, 0.7)
    CONFIG_PROPERTY(qreal, detailsWidth, 500)

public:
    explicit WInfoTokens(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class NexusTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(qreal, heightMult, 0.7)
    CONFIG_PROPERTY(qreal, ratio, 16.0 / 9.0)
    CONFIG_PROPERTY(int, minWidth, 800)
    CONFIG_PROPERTY(int, minHeight, 500)
    CONFIG_PROPERTY(int, maxNavWidth, 600)
    CONFIG_PROPERTY(int, maxContentWidth, 800)
    CONFIG_PROPERTY(int, popupWidth, 300)
    CONFIG_PROPERTY(int, minPopupHeight, 200)
    CONFIG_PROPERTY(int, maxPopupHeight, 800)

public:
    explicit NexusTokens(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class SizeTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

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

public:
    explicit SizeTokens(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_bar(new BarTokens(this))
        , m_dashboard(new DashboardTokens(this))
        , m_launcher(new LauncherTokens(this))
        , m_notifs(new NotifsTokens(this))
        , m_osd(new OsdTokens(this))
        , m_session(new SessionTokens(this))
        , m_sidebar(new SidebarTokens(this))
        , m_utilities(new UtilitiesTokens(this))
        , m_lock(new LockTokens(this))
        , m_winfo(new WInfoTokens(this))
        , m_nexus(new NexusTokens(this)) {}
};

class TokenConfig : public RootConfig {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    CONFIG_SUBOBJECT(AppearanceTokens, appearance)
    CONFIG_SUBOBJECT(SizeTokens, sizes)

public:
    static TokenConfig* instance();
    [[nodiscard]] Q_INVOKABLE TokenConfig* defaults();
    [[nodiscard]] Q_INVOKABLE static TokenConfig* forScreen(const QString& screen);
    static TokenConfig* create(QQmlEngine*, QJSEngine*);

private:
    friend class MonitorConfigManager;
    explicit TokenConfig(QObject* parent = nullptr);
    explicit TokenConfig(
        TokenConfig* fallback, const QString& filePath, const QString& screen = {}, QObject* parent = nullptr);

    TokenConfig* m_defaults = nullptr;
};

} // namespace caelestia::config
