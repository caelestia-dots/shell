#pragma once

#include "configobject.hpp"

#include <qfont.h>
#include <qstring.h>
#include <qvariant.h>

namespace caelestia::config {

// Forward declare token types from advancedconfig.hpp
class RoundingTokens;
class SpacingTokens;
class PaddingTokens;
class AnimDurationTokens;

class AppearanceRounding : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(qreal, scale, 1)

    Q_PROPERTY(int extraSmall READ extraSmall NOTIFY valuesChanged)
    Q_PROPERTY(int small READ small NOTIFY valuesChanged)
    Q_PROPERTY(int medium READ medium NOTIFY valuesChanged)
    Q_PROPERTY(int large READ large NOTIFY valuesChanged)
    Q_PROPERTY(int largeIncreased READ largeIncreased NOTIFY valuesChanged)
    Q_PROPERTY(int extraLarge READ extraLarge NOTIFY valuesChanged)
    Q_PROPERTY(int extraLargeIncreased READ extraLargeIncreased NOTIFY valuesChanged)
    Q_PROPERTY(int extraExtraLarge READ extraExtraLarge NOTIFY valuesChanged)
    Q_PROPERTY(int full READ full NOTIFY valuesChanged)

public:
    explicit AppearanceRounding(QObject* parent = nullptr)
        : ConfigObject(parent) {}

    void bindTokens(RoundingTokens* tokens);

    [[nodiscard]] int extraSmall() const;
    [[nodiscard]] int small() const;
    [[nodiscard]] int medium() const;
    [[nodiscard]] int large() const;
    [[nodiscard]] int largeIncreased() const;
    [[nodiscard]] int extraLarge() const;
    [[nodiscard]] int extraLargeIncreased() const;
    [[nodiscard]] int extraExtraLarge() const;
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

    Q_PROPERTY(int extraSmall READ extraSmall NOTIFY valuesChanged)
    Q_PROPERTY(int small READ small NOTIFY valuesChanged)
    Q_PROPERTY(int medium READ medium NOTIFY valuesChanged)
    Q_PROPERTY(int large READ large NOTIFY valuesChanged)
    Q_PROPERTY(int largeIncreased READ largeIncreased NOTIFY valuesChanged)
    Q_PROPERTY(int extraLarge READ extraLarge NOTIFY valuesChanged)
    Q_PROPERTY(int extraLargeIncreased READ extraLargeIncreased NOTIFY valuesChanged)
    Q_PROPERTY(int extraExtraLarge READ extraExtraLarge NOTIFY valuesChanged)

public:
    explicit AppearanceSpacing(QObject* parent = nullptr)
        : ConfigObject(parent) {}

    void bindTokens(SpacingTokens* tokens);

    [[nodiscard]] int extraSmall() const;
    [[nodiscard]] int small() const;
    [[nodiscard]] int medium() const;
    [[nodiscard]] int large() const;
    [[nodiscard]] int largeIncreased() const;
    [[nodiscard]] int extraLarge() const;
    [[nodiscard]] int extraLargeIncreased() const;
    [[nodiscard]] int extraExtraLarge() const;

signals:
    void valuesChanged();

private:
    SpacingTokens* m_tokens = nullptr;
};

class AppearancePadding : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(qreal, scale, 1)

    Q_PROPERTY(int extraSmall READ extraSmall NOTIFY valuesChanged)
    Q_PROPERTY(int small READ small NOTIFY valuesChanged)
    Q_PROPERTY(int medium READ medium NOTIFY valuesChanged)
    Q_PROPERTY(int large READ large NOTIFY valuesChanged)
    Q_PROPERTY(int largeIncreased READ largeIncreased NOTIFY valuesChanged)
    Q_PROPERTY(int extraLarge READ extraLarge NOTIFY valuesChanged)
    Q_PROPERTY(int extraLargeIncreased READ extraLargeIncreased NOTIFY valuesChanged)
    Q_PROPERTY(int extraExtraLarge READ extraExtraLarge NOTIFY valuesChanged)

public:
    explicit AppearancePadding(QObject* parent = nullptr)
        : ConfigObject(parent) {}

    void bindTokens(PaddingTokens* tokens);

    [[nodiscard]] int extraSmall() const;
    [[nodiscard]] int small() const;
    [[nodiscard]] int medium() const;
    [[nodiscard]] int large() const;
    [[nodiscard]] int largeIncreased() const;
    [[nodiscard]] int extraLarge() const;
    [[nodiscard]] int extraLargeIncreased() const;
    [[nodiscard]] int extraExtraLarge() const;

signals:
    void valuesChanged();

private:
    PaddingTokens* m_tokens = nullptr;
};

class FontConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    // Empty family inherits from the parent FontStyleConfig.
    CONFIG_PROPERTY(QString, family, {})
    CONFIG_PROPERTY(int, size, 14)
    CONFIG_PROPERTY(int, weight, QFont::Normal)
    CONFIG_PROPERTY(bool, italic, false)
    CONFIG_PROPERTY(QVariantMap, vaxes, {})

public:
    explicit FontConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}

    void setDefaults(int size, int weight = QFont::Normal, const QVariantMap& vaxes = {});
};

class FontStyleConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(QString, family, QStringLiteral("GoogleSansFlex"))
    CONFIG_SUBOBJECT(FontConfig, large)
    CONFIG_SUBOBJECT(FontConfig, medium)
    CONFIG_SUBOBJECT(FontConfig, small)

public:
    explicit FontStyleConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_large(new FontConfig(this))
        , m_medium(new FontConfig(this))
        , m_small(new FontConfig(this)) {}

    void setDefaultFamily(const QString& family);
};

class IconFontStyleConfig : public FontStyleConfig {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_SUBOBJECT(FontConfig, extraLarge)

public:
    explicit IconFontStyleConfig(QObject* parent = nullptr)
        : FontStyleConfig(parent)
        , m_extraLarge(new FontConfig(this)) {}
};

class AppearanceFont : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(qreal, scale, 1)
    CONFIG_SUBOBJECT(FontStyleConfig, headline)
    CONFIG_SUBOBJECT(FontStyleConfig, title)
    CONFIG_SUBOBJECT(FontStyleConfig, body)
    CONFIG_SUBOBJECT(FontStyleConfig, label)
    CONFIG_SUBOBJECT(FontStyleConfig, mono)
    CONFIG_SUBOBJECT(IconFontStyleConfig, icon)
    CONFIG_PROPERTY(QString, clock, QStringLiteral("Rubik"))
    // Google Sans Flex doesn't play well with unicode symbols apparently, so use Rubik instead
    CONFIG_PROPERTY(QString, workspaces, QStringLiteral("Rubik"))

public:
    explicit AppearanceFont(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_headline(new FontStyleConfig(this))
        , m_title(new FontStyleConfig(this))
        , m_body(new FontStyleConfig(this))
        , m_label(new FontStyleConfig(this))
        , m_mono(new FontStyleConfig(this))
        , m_icon(new IconFontStyleConfig(this)) {
        const auto sans = QStringLiteral("GoogleSansFlex");
        const auto mono = QStringLiteral("CaskaydiaCove NF");
        const auto icons = QStringLiteral("Material Symbols Rounded");
        const QVariantMap vaxes = { { "ROND", 25 } };

        m_headline->setDefaultFamily(sans);
        m_headline->large()->setDefaults(32, QFont::Medium, vaxes);
        m_headline->medium()->setDefaults(28, QFont::Medium, vaxes);
        m_headline->small()->setDefaults(24, QFont::Medium, vaxes);

        m_title->setDefaultFamily(sans);
        m_title->large()->setDefaults(22, QFont::Medium, vaxes);
        m_title->medium()->setDefaults(16, QFont::Medium, vaxes);
        m_title->small()->setDefaults(14, QFont::Medium, vaxes);

        m_body->setDefaultFamily(sans);
        m_body->large()->setDefaults(16, QFont::Normal, vaxes);
        m_body->medium()->setDefaults(14, QFont::Normal, vaxes);
        m_body->small()->setDefaults(12, QFont::Normal, vaxes);

        m_label->setDefaultFamily(sans);
        m_label->large()->setDefaults(14, QFont::Medium, vaxes);
        m_label->medium()->setDefaults(12, QFont::Medium, vaxes);
        m_label->small()->setDefaults(11, QFont::Normal, vaxes);

        m_mono->setDefaultFamily(mono);
        m_mono->large()->setDefaults(16, QFont::Normal);
        m_mono->medium()->setDefaults(14, QFont::Normal);
        m_mono->small()->setDefaults(12, QFont::Normal);

        m_icon->setDefaultFamily(icons);
        m_icon->extraLarge()->setDefaults(static_cast<int>(48 / 1.33), QFont::Normal);
        m_icon->large()->setDefaults(static_cast<int>(32 / 1.33), QFont::Normal);
        m_icon->medium()->setDefaults(static_cast<int>(24 / 1.33), QFont::Normal);
        m_icon->small()->setDefaults(static_cast<int>(20 / 1.33), QFont::Normal);
    }
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
