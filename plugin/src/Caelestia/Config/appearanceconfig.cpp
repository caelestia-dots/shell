#include "appearanceconfig.hpp"
#include "tokens.hpp"

#include <qmetaobject.h>

namespace caelestia::config {

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

int AppearanceRounding::normal() const {
    return m_tokens ? static_cast<int>(m_tokens->normal() * m_scale) : 0;
}

int AppearanceRounding::large() const {
    return m_tokens ? static_cast<int>(m_tokens->large() * m_scale) : 0;
}

int AppearanceRounding::full() const {
    return m_tokens ? static_cast<int>(m_tokens->full() * m_scale) : 0;
}

// AppearanceSpacing

void AppearanceSpacing::bindTokens(SpacingTokens* tokens) {
    m_tokens = tokens;
    connectTokenSignals(tokens, this);
}

int AppearanceSpacing::small() const {
    return m_tokens ? static_cast<int>(m_tokens->small() * m_scale) : 0;
}

int AppearanceSpacing::smaller() const {
    return m_tokens ? static_cast<int>(m_tokens->smaller() * m_scale) : 0;
}

int AppearanceSpacing::normal() const {
    return m_tokens ? static_cast<int>(m_tokens->normal() * m_scale) : 0;
}

int AppearanceSpacing::larger() const {
    return m_tokens ? static_cast<int>(m_tokens->larger() * m_scale) : 0;
}

int AppearanceSpacing::large() const {
    return m_tokens ? static_cast<int>(m_tokens->large() * m_scale) : 0;
}

// AppearancePadding

void AppearancePadding::bindTokens(PaddingTokens* tokens) {
    m_tokens = tokens;
    connectTokenSignals(tokens, this);
}

int AppearancePadding::small() const {
    return m_tokens ? static_cast<int>(m_tokens->small() * m_scale) : 0;
}

int AppearancePadding::smaller() const {
    return m_tokens ? static_cast<int>(m_tokens->smaller() * m_scale) : 0;
}

int AppearancePadding::normal() const {
    return m_tokens ? static_cast<int>(m_tokens->normal() * m_scale) : 0;
}

int AppearancePadding::larger() const {
    return m_tokens ? static_cast<int>(m_tokens->larger() * m_scale) : 0;
}

int AppearancePadding::large() const {
    return m_tokens ? static_cast<int>(m_tokens->large() * m_scale) : 0;
}

// FontSize

void FontSize::bindTokens(FontSizeTokens* tokens) {
    m_tokens = tokens;
    connectTokenSignals(tokens, this);
}

int FontSize::small() const {
    return m_tokens ? static_cast<int>(m_tokens->small() * m_scale) : 0;
}

int FontSize::smaller() const {
    return m_tokens ? static_cast<int>(m_tokens->smaller() * m_scale) : 0;
}

int FontSize::normal() const {
    return m_tokens ? static_cast<int>(m_tokens->normal() * m_scale) : 0;
}

int FontSize::larger() const {
    return m_tokens ? static_cast<int>(m_tokens->larger() * m_scale) : 0;
}

int FontSize::large() const {
    return m_tokens ? static_cast<int>(m_tokens->large() * m_scale) : 0;
}

int FontSize::extraLarge() const {
    return m_tokens ? static_cast<int>(m_tokens->extraLarge() * m_scale) : 0;
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
