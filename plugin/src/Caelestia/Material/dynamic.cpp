#include "dynamic.hpp"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdlib>
#include <vector>

#include "color_utils.hpp"
#include "temperature.hpp"

namespace caelestia::material {

using material_color_utilities::Hct;

namespace {

// Python's round(): halves go to the nearest even integer
double pyRound(double value) {
    return std::nearbyint(value);
}

double clampDouble(double min, double max, double input) {
    if (input < min)
        return min;
    if (input > max)
        return max;
    return input;
}

// Python lerp (materialyoucolor utils.math_utils)
double lerpPy(double start, double stop, double amount) {
    return (1.0 - amount) * start + amount * stop;
}

// Python Contrast class
double ratioOfYs(double y1, double y2) {
    const double lighter = std::max(y1, y2);
    const double darker = exactlyEqual(lighter, y2) ? y1 : y2;
    return (lighter + 5.0) / (darker + 5.0);
}

double ratioOfTones(double toneA, double toneB) {
    toneA = clampDouble(0.0, 100.0, toneA);
    toneB = clampDouble(0.0, 100.0, toneB);
    return ratioOfYs(yFromLstar(toneA), yFromLstar(toneB));
}

// Contrast.lighter: the tone that reaches `ratio` against `tone`, or -1
double lighterTone(double tone, double ratio) {
    if (tone < 0.0 || tone > 100.0)
        return -1.0;
    const double darkY = yFromLstar(tone);
    const double lightY = ratio * (darkY + 5.0) - 5.0;
    const double realContrast = ratioOfYs(lightY, darkY);
    const double delta = std::fabs(realContrast - ratio);
    if (realContrast < ratio && delta > 0.04)
        return -1.0;
    const double returnValue = lstarFromY(lightY) + 0.4;
    if (returnValue < 0 || returnValue > 100)
        return -1.0;
    return returnValue;
}

// Contrast.darker: the tone that reaches `ratio` against `tone`, or -1
double darkerTone(double tone, double ratio) {
    if (tone < 0.0 || tone > 100.0)
        return -1.0;
    const double lightY = yFromLstar(tone);
    const double darkY = ((lightY + 5.0) / ratio) - 5.0;
    const double realContrast = ratioOfYs(lightY, darkY);
    const double delta = std::fabs(realContrast - ratio);
    if (realContrast < ratio && delta > 0.04)
        return -1.0;
    const double returnValue = lstarFromY(darkY) - 0.4;
    if (returnValue < 0.0 || returnValue > 100.0)
        return -1.0;
    return returnValue;
}

double lighterUnsafe(double tone, double ratio) {
    const double safe = lighterTone(tone, ratio);
    return safe < 0.0 ? 100.0 : safe;
}

double darkerUnsafe(double tone, double ratio) {
    const double safe = darkerTone(tone, ratio);
    return safe < 0.0 ? 0.0 : safe;
}

// Python KeyColor.create: the tone where the hue reaches the requested chroma
Hct keyColorFor(double hue, double requestedChroma) {
    const int pivotTone = 50;
    const int toneStepSize = 1;
    const double epsilon = 0.01;
    int lower = 0;
    int upper = 100;
    auto const maxChroma = [hue](int tone) {
        return Hct(hue, 200.0, static_cast<double>(tone)).get_chroma();
    };

    while (lower < upper) {
        const int mid = (lower + upper) / 2;
        const bool isAscending = maxChroma(mid) < maxChroma(mid + toneStepSize);
        const bool sufficientChroma = maxChroma(mid) >= requestedChroma - epsilon;

        if (sufficientChroma) {
            if (std::abs(lower - pivotTone) < std::abs(upper - pivotTone)) {
                upper = mid;
            } else {
                if (lower == mid)
                    return { hue, requestedChroma, static_cast<double>(lower) };
                lower = mid;
            }
        } else {
            if (isAscending) {
                lower = mid + toneStepSize;
            } else {
                upper = mid;
            }
        }
    }
    return { hue, requestedChroma, static_cast<double>(lower) };
}

// Python TonalPalette.average_argb
Argb averageArgb(Argb a, Argb b) {
    const auto channel = [](Argb pixel, unsigned shift) {
        return static_cast<double>((pixel >> shift) & 0xFFu);
    };
    const auto red = pyRound((channel(a, 16) + channel(b, 16)) / 2.0);
    const auto green = pyRound((channel(a, 8) + channel(b, 8)) / 2.0);
    const auto blue = pyRound((channel(a, 0) + channel(b, 0)) / 2.0);
    return 0xFF000000u | (static_cast<Argb>(red) << 16u) | (static_cast<Argb>(green) << 8u) | static_cast<Argb>(blue);
}

// Python DislikeAnalyzer.is_disliked
bool isDisliked(const Hct& hct) {
    const bool huePasses = pyRound(hct.get_hue()) >= 90.0 && pyRound(hct.get_hue()) <= 111.0;
    const bool chromaPasses = pyRound(hct.get_chroma()) > 16.0;
    const bool tonePasses = pyRound(hct.get_tone()) < 65.0;
    return huePasses && chromaPasses && tonePasses;
}

// Python find_best_tone_for_chroma (colour_spec_2025)
double findBestToneForChroma(double hue, double chroma, double tone, bool byDecreasingTone) {
    double answer = tone;
    Hct best(hue, chroma, answer);
    while (best.get_chroma() < chroma) {
        if (tone < 0 || tone > 100)
            break;
        tone += byDecreasingTone ? -1.0 : 1.0;
        const Hct candidate(hue, chroma, tone);
        if (best.get_chroma() < candidate.get_chroma()) {
            best = candidate;
            answer = tone;
        }
    }
    return answer;
}

} // namespace

// --- Hue, tone and dislike helpers -----------------------------------------------------------

Hct dislikeFixed(const Hct& hct) {
    if (isDisliked(hct))
        return { hct.get_hue(), hct.get_chroma(), 70.0 };
    return hct;
}

double sanitizeDegrees(double degrees) {
    degrees = std::fmod(degrees, 360.0);
    if (degrees < 0)
        degrees += 360.0;
    return degrees;
}

double roundHalfEven(double value) {
    return pyRound(value);
}

bool isYellow(double hue) {
    return 105 <= hue && hue < 125;
}

bool isBlue(double hue) {
    return 250 <= hue && hue < 270;
}

bool isCyan(double hue) {
    return 170 <= hue && hue < 207;
}

double piecewiseHue(const Hct& source, const std::vector<double>& breakpoints, const std::vector<double>& hues) {
    const auto size = std::min(breakpoints.size() - 1, hues.size());
    const double sourceHue = source.get_hue();
    for (size_t i = 0; i < size; ++i) {
        if (sourceHue >= breakpoints[i] && sourceHue < breakpoints[i + 1])
            return sanitizeDegrees(hues[i]);
    }
    return sourceHue;
}

double rotatedHue(const Hct& source, const std::vector<double>& breakpoints, const std::vector<double>& rotations) {
    double rotation = piecewiseHue(source, breakpoints, rotations);
    if (std::min(breakpoints.size() - 1, rotations.size()) <= 0)
        rotation = 0;
    return sanitizeDegrees(source.get_hue() + rotation);
}

// --- TonalPalette ----------------------------------------------------------------------------

TonalPalette::TonalPalette(double hue, double chroma, Hct keyColor)
    : m_hue(hue)
    , m_chroma(chroma)
    , m_keyColor(keyColor) {}

TonalPalette TonalPalette::fromHueAndChroma(double hue, double chroma) {
    return { hue, chroma, keyColorFor(hue, chroma) };
}

TonalPalette TonalPalette::fromHct(const Hct& hct) {
    return { hct.get_hue(), hct.get_chroma(), hct };
}

Argb TonalPalette::tone(double tone) const {
    if (exactlyEqual(tone, 99.0) && isYellow(m_hue)) {
        return averageArgb(this->tone(98), this->tone(100));
    }
    return Hct(m_hue, m_chroma, tone).ToInt();
}

Hct TonalPalette::hctFor(double tone) const {
    return Hct(this->tone(tone));
}

// --- Contrast curves -------------------------------------------------------------------------

double ContrastCurve::get(double contrastLevel) const {
    if (contrastLevel <= -1.0)
        return low;
    if (contrastLevel < 0.0)
        return lerpPy(low, normal, contrastLevel + 1.0);
    if (contrastLevel < 0.5)
        return lerpPy(normal, medium, contrastLevel / 0.5);
    if (contrastLevel < 1.0)
        return lerpPy(medium, high, (contrastLevel - 0.5) / 0.5);
    return high;
}

ContrastCurve getCurve(double defaultContrast) {
    if (exactlyEqual(defaultContrast, 1.5))
        return { .low = 1.5, .normal = 1.5, .medium = 3, .high = 5.5 };
    if (exactlyEqual(defaultContrast, 3))
        return { .low = 3, .normal = 3, .medium = 4.5, .high = 7 };
    if (exactlyEqual(defaultContrast, 4.5))
        return { .low = 4.5, .normal = 4.5, .medium = 7, .high = 11 };
    if (exactlyEqual(defaultContrast, 6))
        return { .low = 6, .normal = 6, .medium = 7, .high = 11 };
    if (exactlyEqual(defaultContrast, 7))
        return { .low = 7, .normal = 7, .medium = 11, .high = 21 };
    if (exactlyEqual(defaultContrast, 9))
        return { .low = 9, .normal = 9, .medium = 11, .high = 21 };
    if (exactlyEqual(defaultContrast, 11))
        return { .low = 11, .normal = 11, .medium = 21, .high = 21 };
    if (exactlyEqual(defaultContrast, 21))
        return { .low = 21, .normal = 21, .medium = 21, .high = 21 };
    return { .low = defaultContrast, .normal = defaultContrast, .medium = 7, .high = 21 };
}

// --- Tone helpers ----------------------------------------------------------------------------

bool tonePrefersLightForeground(double tone) {
    return pyRound(tone) < 60.0;
}

// Python DynamicColor.foreground_tone
double foregroundTone(double bgTone, double ratio) {
    const double lighterT = lighterUnsafe(bgTone, ratio);
    const double darkerT = darkerUnsafe(bgTone, ratio);
    const double lighterRatio = ratioOfTones(lighterT, bgTone);
    const double darkerRatio = ratioOfTones(darkerT, bgTone);

    if (tonePrefersLightForeground(bgTone)) {
        const bool negligibleDifference =
            std::fabs(lighterRatio - darkerRatio) < 0.1 && lighterRatio < ratio && darkerRatio < ratio;
        return lighterRatio >= ratio || lighterRatio >= darkerRatio || negligibleDifference ? lighterT : darkerT;
    }
    return darkerRatio >= ratio || darkerRatio >= lighterRatio ? darkerT : lighterT;
}

// Python t_max_c and t_min_c (colour_spec_2025)
double tMaxC(const TonalPalette& palette, double lowerBound, double upperBound, double chromaMultiplier) {
    const double answer = findBestToneForChroma(palette.hue(), palette.chroma() * chromaMultiplier, 100, true);
    return clampDouble(lowerBound, upperBound, answer);
}

double tMinC(const TonalPalette& palette, double lowerBound, double upperBound) {
    const double answer = findBestToneForChroma(palette.hue(), palette.chroma(), 0, false);
    return clampDouble(lowerBound, upperBound, answer);
}

// Python find_desired_chroma_by_tone (colour_spec_2021)
double findDesiredChromaByTone(double hue, double chroma, double tone, bool byDecreasingTone) {
    double answer = tone;
    Hct closest(hue, chroma, tone);
    if (closest.get_chroma() < chroma) {
        double peak = closest.get_chroma();
        while (closest.get_chroma() < chroma) {
            answer += byDecreasingTone ? -1.0 : 1.0;
            const Hct potential(hue, chroma, answer);
            if (peak > potential.get_chroma())
                break;
            if (std::fabs(potential.get_chroma() - chroma) < 0.4)
                break;
            if (std::fabs(potential.get_chroma() - chroma) < std::fabs(closest.get_chroma() - chroma)) {
                closest = potential;
            }
            peak = std::max(peak, potential.get_chroma());
        }
    }
    return answer;
}

// --- Scheme palettes -------------------------------------------------------------------------

namespace {

using TP = TonalPalette;

// Python DynamicSchemePalettesDelegateImpl2021
TP primary2021(Variant v, const Hct& src) {
    switch (v) {
    case Variant::Content:
    case Variant::Fidelity:
        return TP::fromHueAndChroma(src.get_hue(), src.get_chroma());
    case Variant::FruitSalad:
        return TP::fromHueAndChroma(sanitizeDegrees(src.get_hue() - 50.0), 48.0);
    case Variant::Monochrome:
        return TP::fromHueAndChroma(src.get_hue(), 0.0);
    case Variant::Neutral:
        return TP::fromHueAndChroma(src.get_hue(), 12.0);
    case Variant::Rainbow:
        return TP::fromHueAndChroma(src.get_hue(), 48.0);
    case Variant::TonalSpot:
        return TP::fromHueAndChroma(src.get_hue(), 36.0);
    case Variant::Expressive:
        return TP::fromHueAndChroma(sanitizeDegrees(src.get_hue() + 240), 40);
    case Variant::Vibrant:
        return TP::fromHueAndChroma(src.get_hue(), 200.0);
    }
    return TP::fromHueAndChroma(src.get_hue(), src.get_chroma());
}

TP secondary2021(Variant v, const Hct& src) {
    switch (v) {
    case Variant::Content:
    case Variant::Fidelity:
        return TP::fromHueAndChroma(src.get_hue(), std::max(src.get_chroma() - 32.0, src.get_chroma() * 0.5));
    case Variant::FruitSalad:
        return TP::fromHueAndChroma(sanitizeDegrees(src.get_hue() - 50.0), 36.0);
    case Variant::Monochrome:
        return TP::fromHueAndChroma(src.get_hue(), 0.0);
    case Variant::Neutral:
        return TP::fromHueAndChroma(src.get_hue(), 8.0);
    case Variant::Rainbow:
    case Variant::TonalSpot:
        return TP::fromHueAndChroma(src.get_hue(), 16.0);
    case Variant::Expressive:
        return TP::fromHueAndChroma(
            rotatedHue(src, { 0, 21, 51, 121, 151, 191, 271, 321, 360 }, { 45, 95, 45, 20, 45, 90, 45, 45, 45 }), 24.0);
    case Variant::Vibrant:
        return TP::fromHueAndChroma(
            rotatedHue(src, { 0, 41, 61, 101, 131, 181, 251, 301, 360 }, { 18, 15, 10, 12, 15, 18, 15, 12, 12 }), 24.0);
    }
    return TP::fromHueAndChroma(src.get_hue(), src.get_chroma());
}

TP tertiary2021(Variant v, const Hct& src, TemperatureCache& temperature) {
    switch (v) {
    case Variant::Content:
        return TP::fromHct(dislikeFixed(temperature.analogous(3, 6)[2]));
    case Variant::Fidelity:
        return TP::fromHct(dislikeFixed(temperature.complement()));
    case Variant::FruitSalad:
        return TP::fromHueAndChroma(src.get_hue(), 36.0);
    case Variant::Monochrome:
        return TP::fromHueAndChroma(src.get_hue(), 0.0);
    case Variant::Neutral:
        return TP::fromHueAndChroma(src.get_hue(), 16.0);
    case Variant::Rainbow:
    case Variant::TonalSpot:
        return TP::fromHueAndChroma(sanitizeDegrees(src.get_hue() + 60.0), 24.0);
    case Variant::Expressive:
        return TP::fromHueAndChroma(
            rotatedHue(src, { 0, 21, 51, 121, 151, 191, 271, 321, 360 }, { 120, 120, 20, 45, 20, 15, 20, 120, 120 }),
            32.0);
    case Variant::Vibrant:
        return TP::fromHueAndChroma(
            rotatedHue(src, { 0, 41, 61, 101, 131, 181, 251, 301, 360 }, { 35, 30, 20, 25, 30, 35, 30, 25, 25 }), 32.0);
    }
    return TP::fromHueAndChroma(src.get_hue(), src.get_chroma());
}

TP neutral2021(Variant v, const Hct& src) {
    switch (v) {
    case Variant::Content:
    case Variant::Fidelity:
        return TP::fromHueAndChroma(src.get_hue(), src.get_chroma() / 8.0);
    case Variant::FruitSalad:
        return TP::fromHueAndChroma(src.get_hue(), 10.0);
    case Variant::Monochrome:
        return TP::fromHueAndChroma(src.get_hue(), 0.0);
    case Variant::Neutral:
        return TP::fromHueAndChroma(src.get_hue(), 2.0);
    case Variant::Rainbow:
        return TP::fromHueAndChroma(src.get_hue(), 0.0);
    case Variant::TonalSpot:
        return TP::fromHueAndChroma(src.get_hue(), 6.0);
    case Variant::Expressive:
        return TP::fromHueAndChroma(sanitizeDegrees(src.get_hue() + 15), 8);
    case Variant::Vibrant:
        return TP::fromHueAndChroma(src.get_hue(), 10);
    }
    return TP::fromHueAndChroma(src.get_hue(), src.get_chroma());
}

TP neutralVariant2021(Variant v, const Hct& src) {
    switch (v) {
    case Variant::Content:
    case Variant::Fidelity:
        return TP::fromHueAndChroma(src.get_hue(), (src.get_chroma() / 8.0) + 4.0);
    case Variant::FruitSalad:
        return TP::fromHueAndChroma(src.get_hue(), 16.0);
    case Variant::Monochrome:
        return TP::fromHueAndChroma(src.get_hue(), 0.0);
    case Variant::Neutral:
        return TP::fromHueAndChroma(src.get_hue(), 2.0);
    case Variant::Rainbow:
        return TP::fromHueAndChroma(src.get_hue(), 0.0);
    case Variant::TonalSpot:
        return TP::fromHueAndChroma(src.get_hue(), 8.0);
    case Variant::Expressive:
        return TP::fromHueAndChroma(sanitizeDegrees(src.get_hue() + 15), 12);
    case Variant::Vibrant:
        return TP::fromHueAndChroma(src.get_hue(), 12);
    }
    return TP::fromHueAndChroma(src.get_hue(), src.get_chroma());
}

// Python DynamicSchemePalettesDelegateImpl2025 (the palettes of the four variants that use it)
TP primary2025(Variant v, const Hct& src, bool isDark) {
    switch (v) {
    case Variant::Neutral:
        return TP::fromHueAndChroma(src.get_hue(), isBlue(src.get_hue()) ? 12 : 8);
    case Variant::TonalSpot:
        return TP::fromHueAndChroma(src.get_hue(), isDark ? 26 : 32);
    case Variant::Expressive:
        return TP::fromHueAndChroma(src.get_hue(), isDark ? 36 : 48);
    case Variant::Vibrant:
        return TP::fromHueAndChroma(src.get_hue(), 74);
    default:
        return primary2021(v, src);
    }
}

TP secondary2025(Variant v, const Hct& src, bool isDark) {
    switch (v) {
    case Variant::Neutral:
        return TP::fromHueAndChroma(src.get_hue(), isBlue(src.get_hue()) ? 6 : 4);
    case Variant::TonalSpot:
        return TP::fromHueAndChroma(src.get_hue(), 16);
    case Variant::Expressive:
        return TP::fromHueAndChroma(rotatedHue(src, { 0, 105, 140, 204, 253, 278, 300, 333, 360 },
                                        { -160, 155, -100, 96, -96, -156, -165, -160 }),
            isDark ? 16 : 24);
    case Variant::Vibrant:
        return TP::fromHueAndChroma(rotatedHue(src, { 0, 38, 105, 140, 333, 360 }, { -14, 10, -14, 10, -14 }), 56);
    default:
        return secondary2021(v, src);
    }
}

TP tertiary2025(Variant v, const Hct& src) {
    switch (v) {
    case Variant::Neutral:
        return TP::fromHueAndChroma(
            rotatedHue(src, { 0, 38, 105, 161, 204, 278, 333, 360 }, { -32, 26, 10, -39, 24, -15, -32 }), 20);
    case Variant::TonalSpot:
        return TP::fromHueAndChroma(rotatedHue(src, { 0, 20, 71, 161, 333, 360 }, { -40, 48, -32, 40, -32 }), 28);
    case Variant::Expressive:
        return TP::fromHueAndChroma(rotatedHue(src, { 0, 105, 140, 204, 253, 278, 300, 333, 360 },
                                        { -165, 160, -105, 101, -101, -160, -170, -165 }),
            48);
    case Variant::Vibrant:
        return TP::fromHueAndChroma(
            rotatedHue(src, { 0, 38, 71, 105, 140, 161, 253, 333, 360 }, { -72, 35, 24, -24, 62, 50, 62, -72 }), 56);
    default:
        return TP::fromHueAndChroma(src.get_hue(), src.get_chroma());
    }
}

double expressiveNeutralHue(const Hct& src) {
    return rotatedHue(src, { 0, 71, 124, 253, 278, 300, 360 }, { 10, 0, 10, 0, 10, 0 });
}

double expressiveNeutralChroma(const Hct& src, bool isDark) {
    const double neutralHue = expressiveNeutralHue(src);
    if (isDark && isYellow(neutralHue))
        return 6;
    if (isDark)
        return 14;
    return 18;
}

double vibrantNeutralHue(const Hct& src) {
    return rotatedHue(src, { 0, 38, 105, 140, 333, 360 }, { -14, 10, -14, 10, -14 });
}

TP neutral2025(Variant v, const Hct& src, bool isDark) {
    switch (v) {
    case Variant::Neutral:
        return TP::fromHueAndChroma(src.get_hue(), 1.4);
    case Variant::TonalSpot:
        return TP::fromHueAndChroma(src.get_hue(), 5);
    case Variant::Expressive:
        return TP::fromHueAndChroma(expressiveNeutralHue(src), expressiveNeutralChroma(src, isDark));
    case Variant::Vibrant:
        return TP::fromHueAndChroma(vibrantNeutralHue(src), 28);
    default:
        return neutral2021(v, src);
    }
}

TP neutralVariant2025(Variant v, const Hct& src, bool isDark) {
    switch (v) {
    case Variant::Neutral:
        return TP::fromHueAndChroma(src.get_hue(), 1.4 * 2.2);
    case Variant::TonalSpot:
        return TP::fromHueAndChroma(src.get_hue(), 5 * 1.7);
    case Variant::Expressive: {
        const double hue = expressiveNeutralHue(src);
        const double chroma = expressiveNeutralChroma(src, isDark);
        return TP::fromHueAndChroma(hue, chroma * (hue >= 105 && hue < 125 ? 1.6 : 2.3));
    }
    case Variant::Vibrant:
        return TP::fromHueAndChroma(vibrantNeutralHue(src), 28 * 1.29);
    default:
        return neutralVariant2021(v, src);
    }
}

TP error2025(Variant v, const Hct& src) {
    const double errorHue =
        piecewiseHue(src, { 0, 3, 13, 23, 33, 43, 153, 273, 360 }, { 12, 22, 32, 12, 22, 32, 22, 12 });
    switch (v) {
    case Variant::Neutral:
        return TP::fromHueAndChroma(errorHue, 50);
    case Variant::TonalSpot:
        return TP::fromHueAndChroma(errorHue, 60);
    case Variant::Expressive:
        return TP::fromHueAndChroma(errorHue, 64);
    case Variant::Vibrant:
        return TP::fromHueAndChroma(errorHue, 80);
    default:
        return TP::fromHueAndChroma(25.0, 84.0);
    }
}

// The error palette when the spec gives none (Python falls back to 25/84)
TP defaultError() {
    return TP::fromHueAndChroma(25.0, 84.0);
}

} // namespace

// --- Scheme ----------------------------------------------------------------------------------

SpecVersion Scheme::specFor(Variant variant, SpecVersion requested) {
    switch (variant) {
    case Variant::Expressive:
    case Variant::Vibrant:
    case Variant::TonalSpot:
    case Variant::Neutral:
        return requested;
    default:
        return SpecVersion::V2021;
    }
}

Scheme::Scheme(Hct source, Variant variantArg, double contrast, bool dark, SpecVersion requested)
    : sourceColorHct(source)
    , variant(variantArg)
    , contrastLevel(contrast)
    , isDark(dark)
    , specVersion(specFor(variantArg, requested))
    , primaryPalette(TP::fromHct(source))
    , secondaryPalette(TP::fromHct(source))
    , tertiaryPalette(TP::fromHct(source))
    , neutralPalette(TP::fromHct(source))
    , neutralVariantPalette(TP::fromHct(source))
    , errorPalette(defaultError()) {
    if (specVersion == SpecVersion::V2025) {
        primaryPalette = primary2025(variant, sourceColorHct, isDark);
        secondaryPalette = secondary2025(variant, sourceColorHct, isDark);
        tertiaryPalette = tertiary2025(variant, sourceColorHct);
        neutralPalette = neutral2025(variant, sourceColorHct, isDark);
        neutralVariantPalette = neutralVariant2025(variant, sourceColorHct, isDark);
        errorPalette = error2025(variant, sourceColorHct);
    } else {
        TemperatureCache temperature(sourceColorHct);
        primaryPalette = primary2021(variant, sourceColorHct);
        secondaryPalette = secondary2021(variant, sourceColorHct);
        tertiaryPalette = tertiary2021(variant, sourceColorHct, temperature);
        neutralPalette = neutral2021(variant, sourceColorHct);
        neutralVariantPalette = neutralVariant2021(variant, sourceColorHct);
    }
}

// --- Colour resolution -----------------------------------------------------------------------

namespace {

// Python ColorCalculationDelegateImpl2021.get_tone
// Mirrors the Python function line for line, so it can be checked against it. Splitting it would
// spread the spec's branches across helpers, which is harder to verify than one long function.
double tone2021(const Scheme& scheme, const Color& color) { // NOLINT(readability-function-cognitive-complexity)
    const bool decreasingContrast = scheme.contrastLevel < 0;
    const auto pairOpt = color.toneDeltaPair ? color.toneDeltaPair(scheme) : std::nullopt;

    if (pairOpt) {
        const ToneDeltaPair& pair = *pairOpt;
        const double delta = pair.delta;
        const bool aIsNearer = pair.polarity == Polarity::Nearer ||
                               (pair.polarity == Polarity::Lighter && !scheme.isDark) ||
                               (pair.polarity == Polarity::Darker && scheme.isDark);
        const Color& nearer = aIsNearer ? pair.roleA : pair.roleB;
        const Color& farther = aIsNearer ? pair.roleB : pair.roleA;
        const bool amNearer = color.name == nearer.name;
        const double expansionDir = scheme.isDark ? 1 : -1;
        double nTone = nearer.tone(scheme);
        double fTone = farther.tone(scheme);

        if (color.background && nearer.contrastCurve && farther.contrastCurve) {
            const auto bg = color.background(scheme);
            const auto nCurve = nearer.contrastCurve(scheme);
            const auto fCurve = farther.contrastCurve(scheme);
            if (bg && nCurve && fCurve) {
                const double bgTone = bg->toneOf(scheme);
                const double nContrast = nCurve->get(scheme.contrastLevel);
                const double fContrast = fCurve->get(scheme.contrastLevel);
                if (ratioOfTones(bgTone, nTone) < nContrast)
                    nTone = foregroundTone(bgTone, nContrast);
                if (ratioOfTones(bgTone, fTone) < fContrast)
                    fTone = foregroundTone(bgTone, fContrast);
                if (decreasingContrast) {
                    nTone = foregroundTone(bgTone, nContrast);
                    fTone = foregroundTone(bgTone, fContrast);
                }
            }
        }

        if ((fTone - nTone) * expansionDir < delta) {
            fTone = clampDouble(0, 100, nTone + delta * expansionDir);
            if ((fTone - nTone) * expansionDir < delta) {
                nTone = clampDouble(0, 100, fTone - delta * expansionDir);
            }
        }

        if (50 <= nTone && nTone < 60) {
            if (expansionDir > 0) {
                nTone = 60;
                fTone = std::max(fTone, nTone + delta * expansionDir);
            } else {
                nTone = 49;
                fTone = std::min(fTone, nTone + delta * expansionDir);
            }
        } else if (50 <= fTone && fTone < 60) {
            if (pair.stayTogether) {
                if (expansionDir > 0) {
                    nTone = 60;
                    fTone = std::max(fTone, nTone + delta * expansionDir);
                } else {
                    nTone = 49;
                    fTone = std::min(fTone, nTone + delta * expansionDir);
                }
            } else {
                fTone = expansionDir > 0 ? 60 : 49;
            }
        }
        return amNearer ? nTone : fTone;
    }

    double answer = color.tone(scheme);
    const auto bg = color.background ? color.background(scheme) : std::nullopt;
    const auto curve = color.contrastCurve ? color.contrastCurve(scheme) : std::nullopt;
    if (!bg || !curve)
        return answer;

    const double bgTone = bg->toneOf(scheme);
    const double desiredRatio = curve->get(scheme.contrastLevel);

    if (ratioOfTones(bgTone, answer) < desiredRatio)
        answer = foregroundTone(bgTone, desiredRatio);
    if (decreasingContrast)
        answer = foregroundTone(bgTone, desiredRatio);

    if (color.isBackground && 50 <= answer && answer < 60) {
        answer = ratioOfTones(49, bgTone) >= desiredRatio ? 49 : 60;
    }

    const auto second = color.secondBackground ? color.secondBackground(scheme) : std::nullopt;
    if (!second)
        return answer;

    const double bgTone1 = bgTone;
    const double bgTone2 = second->toneOf(scheme);
    const double upper = std::max(bgTone1, bgTone2);
    const double lower = std::min(bgTone1, bgTone2);

    if (ratioOfTones(upper, answer) >= desiredRatio && ratioOfTones(lower, answer) >= desiredRatio)
        return answer;

    const double lightOption = lighterTone(upper, desiredRatio);
    const double darkOption = darkerTone(lower, desiredRatio);

    std::vector<double> availables;
    if (!exactlyEqual(lightOption, -1.0))
        availables.push_back(lightOption);
    if (!exactlyEqual(darkOption, -1.0))
        availables.push_back(darkOption);

    const bool prefersLight = tonePrefersLightForeground(bgTone1) || tonePrefersLightForeground(bgTone2);
    if (prefersLight)
        return lightOption < 0 ? 100 : lightOption;
    if (availables.size() == 1)
        return availables[0];
    return darkOption < 0 ? 0 : darkOption;
}

bool isFixedDimName(const std::string& name) {
    std::string lowered = name;
    std::ranges::transform(lowered, lowered.begin(), [](unsigned char c) {
        return static_cast<char>(std::tolower(c));
    });
    return lowered.ends_with("_fixed_dim") || lowered.ends_with("fixeddim");
}

// Python ColorCalculationDelegateImpl2025.get_tone
// Mirrors the Python function line for line (see tone2021)
double tone2025(const Scheme& scheme, const Color& color) { // NOLINT(readability-function-cognitive-complexity)
    const auto pairOpt = color.toneDeltaPair ? color.toneDeltaPair(scheme) : std::nullopt;

    if (pairOpt) {
        const ToneDeltaPair& pair = *pairOpt;
        const bool darkerLike = pair.polarity == Polarity::Darker ||
                                (pair.polarity == Polarity::RelativeLighter && scheme.isDark) ||
                                (pair.polarity == Polarity::RelativeDarker && !scheme.isDark);
        const double absoluteDelta = darkerLike ? -pair.delta : pair.delta;
        const bool amRoleA = color.name == pair.roleA.name;
        const Color& selfRole = amRoleA ? pair.roleA : pair.roleB;
        const Color& refRole = amRoleA ? pair.roleB : pair.roleA;
        double selfTone = selfRole.tone(scheme);
        const double refTone = refRole.toneOf(scheme);
        const double relativeDelta = absoluteDelta * (amRoleA ? 1 : -1);

        if (pair.constraint == Constraint::Exact) {
            selfTone = clampDouble(0, 100, refTone + relativeDelta);
        } else if (pair.constraint == Constraint::Nearer) {
            if (relativeDelta > 0) {
                selfTone = clampDouble(0, 100, clampDouble(refTone, refTone + relativeDelta, selfTone));
            } else {
                selfTone = clampDouble(0, 100, clampDouble(refTone + relativeDelta, refTone, selfTone));
            }
        } else if (pair.constraint == Constraint::Farther) {
            if (relativeDelta > 0) {
                selfTone = clampDouble(refTone + relativeDelta, 100, selfTone);
            } else {
                selfTone = clampDouble(0, refTone + relativeDelta, selfTone);
            }
        }

        if (color.background && color.contrastCurve) {
            const auto bg = color.background(scheme);
            const auto curve = color.contrastCurve(scheme);
            if (bg && curve) {
                const double bgTone = bg->toneOf(scheme);
                const double selfContrast = curve->get(scheme.contrastLevel);
                const bool keep = ratioOfTones(bgTone, selfTone) >= selfContrast && scheme.contrastLevel >= 0;
                selfTone = keep ? selfTone : foregroundTone(bgTone, selfContrast);
            }
        }

        if (color.isBackground && !isFixedDimName(color.name)) {
            selfTone = selfTone >= 57 ? clampDouble(65, 100, selfTone) : clampDouble(0, 49, selfTone);
        }
        return selfTone;
    }

    double answer = color.tone(scheme);
    const auto bg = color.background ? color.background(scheme) : std::nullopt;
    const auto curve = color.contrastCurve ? color.contrastCurve(scheme) : std::nullopt;
    if (!bg || !curve)
        return answer;

    const double bgTone = bg->toneOf(scheme);
    const double desiredRatio = curve->get(scheme.contrastLevel);

    const bool keep = ratioOfTones(bgTone, answer) >= desiredRatio && scheme.contrastLevel >= 0;
    answer = keep ? answer : foregroundTone(bgTone, desiredRatio);

    if (color.isBackground && !isFixedDimName(color.name)) {
        answer = answer >= 57 ? clampDouble(65, 100, answer) : clampDouble(0, 49, answer);
    }

    const auto second = color.secondBackground ? color.secondBackground(scheme) : std::nullopt;
    if (!second)
        return answer;

    const double bgTone1 = bgTone;
    const double bgTone2 = second->toneOf(scheme);
    const double upper = std::max(bgTone1, bgTone2);
    const double lower = std::min(bgTone1, bgTone2);

    if (ratioOfTones(upper, answer) >= desiredRatio && ratioOfTones(lower, answer) >= desiredRatio)
        return answer;

    const double lightOption = lighterTone(upper, desiredRatio);
    const double darkOption = darkerTone(lower, desiredRatio);

    std::vector<double> availables;
    if (!exactlyEqual(lightOption, -1.0))
        availables.push_back(lightOption);
    if (!exactlyEqual(darkOption, -1.0))
        availables.push_back(darkOption);

    const bool prefersLight = tonePrefersLightForeground(bgTone1) || tonePrefersLightForeground(bgTone2);
    if (prefersLight)
        return lightOption < 0 ? 100 : lightOption;
    if (availables.size() == 1)
        return availables[0];
    return darkOption < 0 ? 0 : darkOption;
}

} // namespace

double resolveTone(const Scheme& scheme, const Color& color) {
    return scheme.specVersion == SpecVersion::V2025 ? tone2025(scheme, color) : tone2021(scheme, color);
}

double Color::toneOf(const Scheme& scheme) const {
    return resolveTone(scheme, *this);
}

Hct Color::hct(const Scheme& scheme) const {
    const TonalPalette pal = palette(scheme);
    const double resolved = toneOf(scheme);
    if (scheme.specVersion == SpecVersion::V2025) {
        const double multiplier = chromaMultiplier ? chromaMultiplier(scheme) : 1.0;
        return { pal.hue(), pal.chroma() * multiplier, resolved };
    }
    return pal.hctFor(resolved);
}

Argb Color::argb(const Scheme& scheme) const {
    return hct(scheme).ToInt();
}

} // namespace caelestia::material
