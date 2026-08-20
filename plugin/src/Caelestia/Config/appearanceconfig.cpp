#include "appearanceconfig.hpp"
#include "tokens.hpp"

#include <qmetaobject.h>

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

// Helper: connect all changed signals from a token object to a single valuesChanged signal,
// plus connect the local scaleChanged signal.
template <typename Source, typename Target> static void connectTokenSignals(Source* source, Target* target) {
    const auto* meta = source->metaObject();

    for (int i = meta->propertyOffset(); i < meta->propertyCount(); ++i) {
        auto prop = meta->property(i);

        if (prop.hasNotifySignal())
            QObject::connect(source, prop.notifySignal(), target,
                target->metaObject()->method(target->metaObject()->indexOfSignal("valuesChanged()")));
    }

    QObject::connect(target, &Target::scaleChanged, target, &Target::valuesChanged);
}

// AppearanceRounding

void AppearanceRounding::bindTokens(RoundingTokens* tokens) {
    m_tokens = tokens;
    connectTokenSignals(tokens, this);
}

int AppearanceRounding::extraSmall() const {
    return m_tokens ? static_cast<int>(m_tokens->extraSmall() * m_scale) : 0;
}

int AppearanceRounding::small() const {
    return m_tokens ? static_cast<int>(m_tokens->small() * m_scale) : 0;
}

int AppearanceRounding::medium() const {
    return m_tokens ? static_cast<int>(m_tokens->medium() * m_scale) : 0;
}

int AppearanceRounding::large() const {
    return m_tokens ? static_cast<int>(m_tokens->large() * m_scale) : 0;
}

int AppearanceRounding::largeIncreased() const {
    return m_tokens ? static_cast<int>(m_tokens->largeIncreased() * m_scale) : 0;
}

int AppearanceRounding::extraLarge() const {
    return m_tokens ? static_cast<int>(m_tokens->extraLarge() * m_scale) : 0;
}

int AppearanceRounding::extraLargeIncreased() const {
    return m_tokens ? static_cast<int>(m_tokens->extraLargeIncreased() * m_scale) : 0;
}

int AppearanceRounding::extraExtraLarge() const {
    return m_tokens ? static_cast<int>(m_tokens->extraExtraLarge() * m_scale) : 0;
}

int AppearanceRounding::full() const {
    return m_tokens ? static_cast<int>(m_tokens->full()) : 0;
}

// AppearanceSpacing

void AppearanceSpacing::bindTokens(SpacingTokens* tokens) {
    m_tokens = tokens;
    connectTokenSignals(tokens, this);
}

int AppearanceSpacing::extraSmall() const {
    return m_tokens ? static_cast<int>(m_tokens->extraSmall() * m_scale) : 0;
}

int AppearanceSpacing::small() const {
    return m_tokens ? static_cast<int>(m_tokens->small() * m_scale) : 0;
}

int AppearanceSpacing::medium() const {
    return m_tokens ? static_cast<int>(m_tokens->medium() * m_scale) : 0;
}

int AppearanceSpacing::large() const {
    return m_tokens ? static_cast<int>(m_tokens->large() * m_scale) : 0;
}

int AppearanceSpacing::largeIncreased() const {
    return m_tokens ? static_cast<int>(m_tokens->largeIncreased() * m_scale) : 0;
}

int AppearanceSpacing::extraLarge() const {
    return m_tokens ? static_cast<int>(m_tokens->extraLarge() * m_scale) : 0;
}

int AppearanceSpacing::extraLargeIncreased() const {
    return m_tokens ? static_cast<int>(m_tokens->extraLargeIncreased() * m_scale) : 0;
}

int AppearanceSpacing::extraExtraLarge() const {
    return m_tokens ? static_cast<int>(m_tokens->extraExtraLarge() * m_scale) : 0;
}

// AppearancePadding

void AppearancePadding::bindTokens(PaddingTokens* tokens) {
    m_tokens = tokens;
    connectTokenSignals(tokens, this);
}

int AppearancePadding::extraSmall() const {
    return m_tokens ? static_cast<int>(m_tokens->extraSmall() * m_scale) : 0;
}

int AppearancePadding::small() const {
    return m_tokens ? static_cast<int>(m_tokens->small() * m_scale) : 0;
}

int AppearancePadding::medium() const {
    return m_tokens ? static_cast<int>(m_tokens->medium() * m_scale) : 0;
}

int AppearancePadding::large() const {
    return m_tokens ? static_cast<int>(m_tokens->large() * m_scale) : 0;
}

int AppearancePadding::largeIncreased() const {
    return m_tokens ? static_cast<int>(m_tokens->largeIncreased() * m_scale) : 0;
}

int AppearancePadding::extraLarge() const {
    return m_tokens ? static_cast<int>(m_tokens->extraLarge() * m_scale) : 0;
}

int AppearancePadding::extraLargeIncreased() const {
    return m_tokens ? static_cast<int>(m_tokens->extraLargeIncreased() * m_scale) : 0;
}

int AppearancePadding::extraExtraLarge() const {
    return m_tokens ? static_cast<int>(m_tokens->extraExtraLarge() * m_scale) : 0;
}

// FontConfig

// Defaults are per style, so they are applied after construction. The fallback layer still wins.
void FontConfig::setDefaults(int size, int weight, const QVariantMap& vaxes) {
    m_size = fallbackValue(&FontConfig::m_size, size);
    m_weight = fallbackValue(&FontConfig::m_weight, weight);
    m_vaxes = fallbackValue(&FontConfig::m_vaxes, vaxes);
}

// FontStyleConfig

void FontStyleConfig::setDefaultFamily(const QString& family) {
    m_family = fallbackValue(&FontStyleConfig::m_family, family);
}

// AppearanceFont

AppearanceFont::AppearanceFont(AppearanceFont* fallback, QObject* parent, bool globalOnly)
    : settings::ObjectNode(fallback, parent, globalOnly) {
    const auto sans = u"GoogleSansFlex"_s;
    const auto mono = u"CaskaydiaCove NF"_s;
    const auto icons = u"Material Symbols Rounded"_s;
    const QVariantMap vaxes = { { u"ROND"_s, 25 } };

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

// AnimDurations

void AnimDurations::bindTokens(AnimDurationTokens* tokens) {
    m_tokens = tokens;
    connectTokenSignals(tokens, this);
}

int AnimDurations::small() const {
    return m_tokens ? static_cast<int>(m_tokens->small() * m_scale) : 0;
}

int AnimDurations::normal() const {
    return m_tokens ? static_cast<int>(m_tokens->normal() * m_scale) : 0;
}

int AnimDurations::large() const {
    return m_tokens ? static_cast<int>(m_tokens->large() * m_scale) : 0;
}

int AnimDurations::extraLarge() const {
    return m_tokens ? static_cast<int>(m_tokens->extraLarge() * m_scale) : 0;
}

int AnimDurations::expressiveFastSpatial() const {
    return m_tokens ? static_cast<int>(m_tokens->expressiveFastSpatial() * m_scale) : 0;
}

int AnimDurations::expressiveDefaultSpatial() const {
    return m_tokens ? static_cast<int>(m_tokens->expressiveDefaultSpatial() * m_scale) : 0;
}

int AnimDurations::expressiveSlowSpatial() const {
    return m_tokens ? static_cast<int>(m_tokens->expressiveSlowSpatial() * m_scale) : 0;
}

int AnimDurations::expressiveFastEffects() const {
    return m_tokens ? static_cast<int>(m_tokens->expressiveFastEffects() * m_scale) : 0;
}

int AnimDurations::expressiveDefaultEffects() const {
    return m_tokens ? static_cast<int>(m_tokens->expressiveDefaultEffects() * m_scale) : 0;
}

int AnimDurations::expressiveSlowEffects() const {
    return m_tokens ? static_cast<int>(m_tokens->expressiveSlowEffects() * m_scale) : 0;
}

} // namespace caelestia::config
