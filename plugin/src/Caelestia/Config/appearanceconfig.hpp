#pragma once

#include <qfont.h>
#include <qstring.h>
#include <qvariantmap.h>

#include "common.hpp"
#include "settings/objectnode.hpp"

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

// Forward declare token types from tokens.hpp
class RoundingTokens;
class SpacingTokens;
class PaddingTokens;
class AnimDurationTokens;

class AppearanceRounding : public settings::ObjectNode {
    CONFIG_NODE(AppearanceRounding, settings::ObjectNode)

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

class AppearanceSpacing : public settings::ObjectNode {
    CONFIG_NODE(AppearanceSpacing, settings::ObjectNode)

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

class AppearancePadding : public settings::ObjectNode {
    CONFIG_NODE(AppearancePadding, settings::ObjectNode)

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

class FontConfig : public settings::ObjectNode {
    CONFIG_NODE(FontConfig, settings::ObjectNode)

    // Empty family inherits from the parent FontStyleConfig.
    CONFIG_PROPERTY(QString, family, QString())
    CONFIG_PROPERTY(int, size, 14)
    CONFIG_PROPERTY(int, weight, QFont::Normal)
    CONFIG_PROPERTY(bool, italic, false)
    CONFIG_PROPERTY(QVariantMap, vaxes, {})

public:
    void setDefaults(int size, int weight = QFont::Normal, const QVariantMap& vaxes = {});
};

class FontStyleConfig : public settings::ObjectNode {
    CONFIG_NODE(FontStyleConfig, settings::ObjectNode)

    CONFIG_PROPERTY(QString, family, u"GoogleSansFlex"_s)
    CONFIG_SUBOBJECT(FontConfig, large)
    CONFIG_SUBOBJECT(FontConfig, medium)
    CONFIG_SUBOBJECT(FontConfig, small)

public:
    void setDefaultFamily(const QString& family);
};

// The schema base is ObjectNode, not FontStyleConfig, so the inherited styles stay in the schema
class IconFontStyleConfig : public FontStyleConfig {
    CONFIG_NODE_NO_CTOR(IconFontStyleConfig, settings::ObjectNode)
    QML_ANONYMOUS

    CONFIG_SUBOBJECT(FontConfig, extraLarge)

public:
    explicit IconFontStyleConfig(
        IconFontStyleConfig* fallback = nullptr, QObject* parent = nullptr, bool globalOnly = false)
        : FontStyleConfig(fallback, parent, globalOnly) {}
};

class AppearanceFont : public settings::ObjectNode {
    CONFIG_NODE_NO_CTOR(AppearanceFont, settings::ObjectNode)
    QML_ANONYMOUS

    CONFIG_PROPERTY(qreal, scale, 1)
    CONFIG_SUBOBJECT(FontStyleConfig, headline)
    CONFIG_SUBOBJECT(FontStyleConfig, title)
    CONFIG_SUBOBJECT(FontStyleConfig, body)
    CONFIG_SUBOBJECT(FontStyleConfig, label)
    CONFIG_SUBOBJECT(FontStyleConfig, mono)
    CONFIG_SUBOBJECT(IconFontStyleConfig, icon)
    CONFIG_PROPERTY(QString, clock, u"Rubik"_s)
    // Google Sans Flex doesn't play well with unicode symbols apparently, so use Rubik instead
    CONFIG_PROPERTY(QString, workspaces, u"Rubik"_s)

public:
    explicit AppearanceFont(AppearanceFont* fallback = nullptr, QObject* parent = nullptr, bool globalOnly = false);
};

class AnimDurations : public settings::ObjectNode {
    CONFIG_NODE(AnimDurations, settings::ObjectNode)

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

class AppearanceAnim : public settings::ObjectNode {
    CONFIG_NODE(AppearanceAnim, settings::ObjectNode)

    CONFIG_SUBOBJECT(AnimDurations, durations)
};

class AppearanceTransparency : public settings::ObjectNode {
    CONFIG_NODE(AppearanceTransparency, settings::ObjectNode)

    CONFIG_GLOBAL_PROPERTY(bool, enabled, false)
    CONFIG_GLOBAL_PROPERTY(qreal, base, 0.85)
    CONFIG_GLOBAL_PROPERTY(qreal, layers, 0.4)
};

class AppearanceConfig : public settings::ObjectNode {
    CONFIG_NODE(AppearanceConfig, settings::ObjectNode)

    CONFIG_PROPERTY(qreal, deformScale, 1)
    CONFIG_SUBOBJECT(AppearanceRounding, rounding)
    CONFIG_SUBOBJECT(AppearanceSpacing, spacing)
    CONFIG_SUBOBJECT(AppearancePadding, padding)
    CONFIG_SUBOBJECT(AppearanceFont, font)
    CONFIG_SUBOBJECT(AppearanceAnim, anim)
    CONFIG_SUBOBJECT(AppearanceTransparency, transparency)
};

} // namespace caelestia::config
