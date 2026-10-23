#pragma once

#include <qeasingcurve.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qurl.h>

#include "config/anim.hpp"
#include "config/rootnodes.hpp"

namespace caelestia::shell::shaders {

struct TransitionShader {
    Q_GADGET
    QML_VALUE_TYPE(transitionShader)

    Q_PROPERTY(QUrl url MEMBER url CONSTANT)
    Q_PROPERTY(int duration MEMBER duration CONSTANT)
    Q_PROPERTY(QEasingCurve easing MEMBER easing CONSTANT)

public:
    QUrl url;
    int duration;
    QEasingCurve easing;
};

class Shaders : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

#define TRANSITION(name, file, durationName, easingCurve)                                                              \
    Q_PROPERTY(caelestia::shell::shaders::TransitionShader name READ name CONSTANT)                                    \
                                                                                                                       \
public:                                                                                                                \
    [[nodiscard]] static TransitionShader name() {                                                                     \
        return {                                                                                                       \
            .url = QStringLiteral("qrc:/shaders/" file ".frag.qsb"),                                                   \
            .duration = config::TokensSingleton::instance()->appearance()->animDurations()->durationName(),            \
            .easing = easingCurve,                                                                                     \
        };                                                                                                             \
    }                                                                                                                  \
                                                                                                                       \
private:

    TRANSITION(chromaticBloom, "chromatic-bloom", large, QEasingCurve::Linear)
    TRANSITION(colourDistance, "colour-distance", large, config::AnimTokens::instance()->expressiveSlowEffects())
    TRANSITION(crossfade, "crossfade", large, config::AnimTokens::instance()->expressiveSlowEffects())
    TRANSITION(crosshatch, "crosshatch", large, QEasingCurve::Linear)
    TRANSITION(crosswarp, "crosswarp", large, QEasingCurve::Linear)
    TRANSITION(
        directional, "directional", expressiveSlowEffects, config::AnimTokens::instance()->expressiveSlowEffects())
    TRANSITION(directionalWipe, "directional-wipe", large, QEasingCurve::Linear)
    TRANSITION(fadeColour, "fade-colour", large, QEasingCurve::Linear)
    TRANSITION(glitch, "glitch", large, QEasingCurve::Linear)
    TRANSITION(glitchDisplace, "glitch-displace", large, QEasingCurve::Linear)
    TRANSITION(heatMelt, "heat-melt", large, QEasingCurve::Linear)
    TRANSITION(inkSplash, "ink-splash", large, QEasingCurve::Linear)
    TRANSITION(inkwellDrop, "inkwell-drop", large, QEasingCurve::Linear)
    TRANSITION(iris, "iris", normal, config::AnimTokens::instance()->emphasizedAccel())
    TRANSITION(morph, "morph", large, config::AnimTokens::instance()->expressiveSlowEffects())
    TRANSITION(parametricGlitch, "parametric-glitch", large, QEasingCurve::Linear)
    TRANSITION(perlin, "perlin", normal, QEasingCurve::Linear)
    TRANSITION(pixelate, "pixelate", large, QEasingCurve::Linear)
    TRANSITION(pixelfadeWave, "pixelfade-wave", large, QEasingCurve::Linear)
    TRANSITION(plasmaFlow, "plasma-flow", large, QEasingCurve::Linear)
    TRANSITION(polkaDotsCurtain, "polka-dots-curtain", large, QEasingCurve::Linear)
    TRANSITION(puzzleRight, "puzzle-right", large, QEasingCurve::Linear)
    TRANSITION(randomSquares, "random-squares", large, QEasingCurve::Linear)
    TRANSITION(smoke, "smoke", large, QEasingCurve::Linear)
    TRANSITION(softWarpFade, "soft-warp-fade", large, QEasingCurve::Linear)
    TRANSITION(voronoiShatter, "voronoi-shatter", large, QEasingCurve::Linear)
    TRANSITION(zoomBlurPull, "zoom-blur-pull", large, QEasingCurve::Linear)

#undef TRANSITION

public:
    explicit Shaders(QObject* parent = nullptr)
        : QObject(parent) {};
};

} // namespace caelestia::shell::shaders
