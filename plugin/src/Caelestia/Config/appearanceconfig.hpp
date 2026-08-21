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

namespace detail {

struct FontConfig {
    QString family = QString();
    int size;
    int weight = QFont::Normal;
    bool italic = false;
    QVariantMap vaxes = { { u"ROND"_s, 25 } };
};

} // namespace detail

#define ARG(...) __VA_ARGS__
#define FONT(...) detail::FontConfig __VA_ARGS__
#define FONT_CONFIG(Style, Size, props)                                                                                \
    class FontConfig##Style##Size : public settings::ObjectNode {                                                      \
        CONFIG_NODE(FontConfig##Style##Size, settings::ObjectNode)                                                     \
                                                                                                                       \
        CONFIG_PROPERTY(QString, family, ARG([](const settings::Node* self) {                                          \
            const auto family = ARG(props).family;                                                                     \
            return family.isEmpty() ? self->parentNode()->value(u"family"_s).toString() : family;                      \
        }))                                                                                                            \
        CONFIG_PROPERTY(int, size, ARG(props).size)                                                                    \
        CONFIG_PROPERTY(int, weight, ARG(props).weight)                                                                \
        CONFIG_PROPERTY(bool, italic, ARG(props).italic)                                                               \
        CONFIG_PROPERTY(QVariantMap, vaxes, ARG(props).vaxes)                                                          \
    };
#define FONT_STYLE(Style, family_, large_, medium_, small_)                                                            \
    FONT_CONFIG(Style, Large, ARG(large_))                                                                             \
    FONT_CONFIG(Style, Medium, ARG(medium_))                                                                           \
    FONT_CONFIG(Style, Small, ARG(small_))                                                                             \
                                                                                                                       \
    class FontStyle##Style : public settings::ObjectNode {                                                             \
        CONFIG_NODE(FontStyle##Style, settings::ObjectNode)                                                            \
                                                                                                                       \
        CONFIG_PROPERTY(QString, family, family_)                                                                      \
        CONFIG_SUBOBJECT(FontConfig##Style##Large, large)                                                              \
        CONFIG_SUBOBJECT(FontConfig##Style##Medium, medium)                                                            \
        CONFIG_SUBOBJECT(FontConfig##Style##Small, small)                                                              \
    };

// clang-format off
FONT_STYLE(Headline, u"GoogleSansFlex"_s,
    FONT({ .size = 32, .weight = QFont::Medium }),
    FONT({ .size = 28, .weight = QFont::Medium }),
    FONT({ .size = 24, .weight = QFont::Medium })
)
FONT_STYLE(Title, u"GoogleSansFlex"_s,
    FONT({ .size = 22, .weight = QFont::Medium }),
    FONT({ .size = 16, .weight = QFont::Medium }),
    FONT({ .size = 14, .weight = QFont::Medium })
)
FONT_STYLE(Body, u"GoogleSansFlex"_s,
    FONT({ .size = 16 }),
    FONT({ .size = 14 }),
    FONT({ .size = 12 })
)
FONT_STYLE(Label, u"GoogleSansFlex"_s,
    FONT({ .size = 14, .weight = QFont::Medium }),
    FONT({ .size = 12, .weight = QFont::Medium }),
    FONT({ .size = 11 })
)
FONT_STYLE(Mono, u"CaskaydiaCove NF"_s,
    FONT({ .size = 16, .vaxes = {} }),
    FONT({ .size = 14, .vaxes = {} }),
    FONT({ .size = 12, .vaxes = {} })
)
// clang-format on

FONT_CONFIG(Icon, ExtraLarge, FONT({ .size = static_cast<int>(48 / 1.33) }))
FONT_CONFIG(Icon, Large, FONT({ .size = static_cast<int>(32 / 1.33) }))
FONT_CONFIG(Icon, Medium, FONT({ .size = static_cast<int>(24 / 1.33) }))
FONT_CONFIG(Icon, Small, FONT({ .size = static_cast<int>(20 / 1.33) }))

class FontStyleIcon : public settings::ObjectNode {
    CONFIG_NODE(FontStyleIcon, settings::ObjectNode)

    CONFIG_PROPERTY(QString, family, u"Material Symbols Rounded"_s)
    CONFIG_SUBOBJECT(FontConfigIconExtraLarge, extraLarge)
    CONFIG_SUBOBJECT(FontConfigIconLarge, large)
    CONFIG_SUBOBJECT(FontConfigIconMedium, medium)
    CONFIG_SUBOBJECT(FontConfigIconSmall, small)
};

#undef ARG
#undef FONT
#undef FONT_CONFIG
#undef FONT_STYLE

class AppearanceFont : public settings::ObjectNode {
    CONFIG_NODE(AppearanceFont, settings::ObjectNode)

    CONFIG_PROPERTY(qreal, scale, 1)
    CONFIG_SUBOBJECT(FontStyleHeadline, headline)
    CONFIG_SUBOBJECT(FontStyleTitle, title)
    CONFIG_SUBOBJECT(FontStyleBody, body)
    CONFIG_SUBOBJECT(FontStyleLabel, label)
    CONFIG_SUBOBJECT(FontStyleMono, mono)
    CONFIG_SUBOBJECT(FontStyleIcon, icon)
    CONFIG_PROPERTY(QString, clock, u"Rubik"_s)
    // Google Sans Flex doesn't play well with unicode symbols apparently, so use Rubik instead
    CONFIG_PROPERTY(QString, workspaces, u"Rubik"_s)
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
