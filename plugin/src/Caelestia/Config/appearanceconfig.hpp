#pragma once

#include "configobject.hpp"

#include <qstring.h>

namespace caelestia::config {

// Forward declare token types from advancedconfig.hpp
class RoundingTokens;
class SpacingTokens;
class PaddingTokens;
class FontSizeTokens;
class AnimDurationTokens;

class AppearanceRounding : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(qreal, scale, 1)

    Q_PROPERTY(int extraSmall READ extraSmall NOTIFY valuesChanged)
    Q_PROPERTY(int small READ small NOTIFY valuesChanged)
    Q_PROPERTY(int normal READ normal NOTIFY valuesChanged)
    Q_PROPERTY(int large READ large NOTIFY valuesChanged)
    Q_PROPERTY(int full READ full NOTIFY valuesChanged)

public:
    explicit AppearanceRounding(QObject* parent = nullptr)
        : ConfigObject(parent) {}

    void bindTokens(RoundingTokens* tokens);

    [[nodiscard]] int extraSmall() const;
    [[nodiscard]] int small() const;
    [[nodiscard]] int normal() const;
    [[nodiscard]] int large() const;
    [[nodiscard]] int full() const;

signals:
    void valuesChanged();

private:
    RoundingTokens* m_tokens = nullptr;
};

class AppearanceSpacing : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(qreal, scale, 1)

    Q_PROPERTY(int small READ small NOTIFY valuesChanged)
    Q_PROPERTY(int smaller READ smaller NOTIFY valuesChanged)
    Q_PROPERTY(int normal READ normal NOTIFY valuesChanged)
    Q_PROPERTY(int larger READ larger NOTIFY valuesChanged)
    Q_PROPERTY(int large READ large NOTIFY valuesChanged)

public:
    explicit AppearanceSpacing(QObject* parent = nullptr)
        : ConfigObject(parent) {}

    void bindTokens(SpacingTokens* tokens);

    [[nodiscard]] int small() const;
    [[nodiscard]] int smaller() const;
    [[nodiscard]] int normal() const;
    [[nodiscard]] int larger() const;
    [[nodiscard]] int large() const;

signals:
    void valuesChanged();

private:
    SpacingTokens* m_tokens = nullptr;
};

class AppearancePadding : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(qreal, scale, 1)

    Q_PROPERTY(int small READ small NOTIFY valuesChanged)
    Q_PROPERTY(int smaller READ smaller NOTIFY valuesChanged)
    Q_PROPERTY(int normal READ normal NOTIFY valuesChanged)
    Q_PROPERTY(int larger READ larger NOTIFY valuesChanged)
    Q_PROPERTY(int large READ large NOTIFY valuesChanged)

public:
    explicit AppearancePadding(QObject* parent = nullptr)
        : ConfigObject(parent) {}

    void bindTokens(PaddingTokens* tokens);

    [[nodiscard]] int small() const;
    [[nodiscard]] int smaller() const;
    [[nodiscard]] int normal() const;
    [[nodiscard]] int larger() const;
    [[nodiscard]] int large() const;

signals:
    void valuesChanged();

private:
    PaddingTokens* m_tokens = nullptr;
};

class FontFamily : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(QString, sans, QStringLiteral("Rubik"))
    CONFIG_PROPERTY(QString, mono, QStringLiteral("CaskaydiaCove NF"))
    CONFIG_PROPERTY(QString, material, QStringLiteral("Material Symbols Rounded"))
    CONFIG_PROPERTY(QString, clock, QStringLiteral("Rubik"))

public:
    explicit FontFamily(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class FontSize : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(qreal, scale, 1)

    Q_PROPERTY(int small READ small NOTIFY valuesChanged)
    Q_PROPERTY(int smaller READ smaller NOTIFY valuesChanged)
    Q_PROPERTY(int normal READ normal NOTIFY valuesChanged)
    Q_PROPERTY(int larger READ larger NOTIFY valuesChanged)
    Q_PROPERTY(int large READ large NOTIFY valuesChanged)
    Q_PROPERTY(int extraLarge READ extraLarge NOTIFY valuesChanged)

public:
    explicit FontSize(QObject* parent = nullptr)
        : ConfigObject(parent) {}

    void bindTokens(FontSizeTokens* tokens);

    [[nodiscard]] int small() const;
    [[nodiscard]] int smaller() const;
    [[nodiscard]] int normal() const;
    [[nodiscard]] int larger() const;
    [[nodiscard]] int large() const;
    [[nodiscard]] int extraLarge() const;

signals:
    void valuesChanged();

private:
    FontSizeTokens* m_tokens = nullptr;
};

class AppearanceFont : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_SUBOBJECT(FontFamily, family)
    CONFIG_SUBOBJECT(FontSize, size)

public:
    explicit AppearanceFont(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_family(new FontFamily(this))
        , m_size(new FontSize(this)) {}
};

class AnimDurations : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(qreal, scale, 1)

    Q_PROPERTY(int small READ small NOTIFY valuesChanged)
    Q_PROPERTY(int normal READ normal NOTIFY valuesChanged)
    Q_PROPERTY(int large READ large NOTIFY valuesChanged)
    Q_PROPERTY(int extraLarge READ extraLarge NOTIFY valuesChanged)
    Q_PROPERTY(int expressiveFastSpatial READ expressiveFastSpatial NOTIFY valuesChanged)
    Q_PROPERTY(int expressiveDefaultSpatial READ expressiveDefaultSpatial NOTIFY valuesChanged)
    Q_PROPERTY(int expressiveSlowSpatial READ expressiveSlowSpatial NOTIFY valuesChanged)
    Q_PROPERTY(int expressiveFastEffects READ expressiveFastEffects NOTIFY valuesChanged)
    Q_PROPERTY(int expressiveDefaultEffects READ expressiveDefaultEffects NOTIFY valuesChanged)
    Q_PROPERTY(int expressiveSlowEffects READ expressiveSlowEffects NOTIFY valuesChanged)

public:
    explicit AnimDurations(QObject* parent = nullptr)
        : ConfigObject(parent) {}

    void bindTokens(AnimDurationTokens* tokens);

    [[nodiscard]] int small() const;
    [[nodiscard]] int normal() const;
    [[nodiscard]] int large() const;
    [[nodiscard]] int extraLarge() const;
    [[nodiscard]] int expressiveFastSpatial() const;
    [[nodiscard]] int expressiveDefaultSpatial() const;
    [[nodiscard]] int expressiveSlowSpatial() const;
    [[nodiscard]] int expressiveFastEffects() const;
    [[nodiscard]] int expressiveDefaultEffects() const;
    [[nodiscard]] int expressiveSlowEffects() const;

signals:
    void valuesChanged();

private:
    AnimDurationTokens* m_tokens = nullptr;
};

class AppearanceAnim : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_SUBOBJECT(AnimDurations, durations)

public:
    explicit AppearanceAnim(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_durations(new AnimDurations(this)) {}
};

class AppearanceTransparency : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, enabled, false)
    CONFIG_GLOBAL_PROPERTY(qreal, base, 0.85)
    CONFIG_GLOBAL_PROPERTY(qreal, layers, 0.4)

public:
    explicit AppearanceTransparency(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class AppearanceConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(qreal, deformScale, 1)
    CONFIG_SUBOBJECT(AppearanceRounding, rounding)
    CONFIG_SUBOBJECT(AppearanceSpacing, spacing)
    CONFIG_SUBOBJECT(AppearancePadding, padding)
    CONFIG_SUBOBJECT(AppearanceFont, font)
    CONFIG_SUBOBJECT(AppearanceAnim, anim)
    CONFIG_SUBOBJECT(AppearanceTransparency, transparency)

public:
    explicit AppearanceConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_rounding(new AppearanceRounding(this))
        , m_spacing(new AppearanceSpacing(this))
        , m_padding(new AppearancePadding(this))
        , m_font(new AppearanceFont(this))
        , m_anim(new AppearanceAnim(this))
        , m_transparency(new AppearanceTransparency(this)) {}
};

} // namespace caelestia::config
