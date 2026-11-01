#pragma once

// Material You colour generation: a port of the dynamic colour engine of materialyoucolor 3.0.2
// (the library the caelestia CLI uses). Palettes, the 2021 and 2025 colour specs, and the tone
// resolution are ported here. Colour math (HCT, CAM16, luminance, quantisation) comes from the
// vendored material-color-utilities.

#include <cstdint>
#include <functional>
#include <optional>
#include <string>
#include <vector>

#include "cpp/cam/hct.h"

namespace caelestia::material {

using material_color_utilities::Argb;
using material_color_utilities::Hct;

enum class Variant : std::uint8_t {
    Content,
    Expressive,
    Fidelity,
    FruitSalad,
    Monochrome,
    Neutral,
    Rainbow,
    TonalSpot,
    Vibrant,
};
enum class SpecVersion : std::uint8_t {
    V2021,
    V2025,
};
enum class Polarity : std::uint8_t {
    Darker,
    Lighter,
    Nearer,
    Farther,
    RelativeDarker,
    RelativeLighter,
};
enum class Constraint : std::uint8_t {
    Exact,
    Nearer,
    Farther,
};

// Hue and tone helpers, matching the Python implementation
double sanitizeDegrees(double degrees);
double rotatedHue(const Hct& source, const std::vector<double>& breakpoints, const std::vector<double>& rotations);
double piecewiseHue(const Hct& source, const std::vector<double>& breakpoints, const std::vector<double>& hues);
bool isYellow(double hue);
bool isBlue(double hue);
bool isCyan(double hue);
double roundHalfEven(double value);

// Python DislikeAnalyzer.fix_if_disliked
Hct dislikeFixed(const Hct& hct);

// A tonal palette: the tones of one hue and chroma, with the key colour it was built from
class TonalPalette {
public:
    static TonalPalette fromHueAndChroma(double hue, double chroma);
    static TonalPalette fromHct(const Hct& hct);

    [[nodiscard]] double hue() const { return m_hue; }

    [[nodiscard]] double chroma() const { return m_chroma; }

    [[nodiscard]] const Hct& keyColor() const { return m_keyColor; }

    [[nodiscard]] Argb tone(double tone) const;
    [[nodiscard]] Hct hctFor(double tone) const;

private:
    TonalPalette(double hue, double chroma, Hct keyColor);
    double m_hue;
    double m_chroma;
    Hct m_keyColor;
};

struct ContrastCurve {
    double low;
    double normal;
    double medium;
    double high;
    [[nodiscard]] double get(double contrastLevel) const;
};

// Python get_curve: the contrast curve for a default contrast ratio
ContrastCurve getCurve(double defaultContrast);

class Scheme;
struct Color;
struct ToneDeltaPair;

using PaletteFn = std::function<TonalPalette(const Scheme&)>;
using ToneFn = std::function<double(const Scheme&)>;
using ColorFn = std::function<std::optional<Color>(const Scheme&)>;
using CurveFn = std::function<std::optional<ContrastCurve>(const Scheme&)>;
using PairFn = std::function<std::optional<ToneDeltaPair>(const Scheme&)>;

// A colour role (Python DynamicColor): the palette and tone it takes, and any background,
// contrast or tone-pairing constraints that move it. The tone is always set; a role without an
// explicit tone takes its background's tone, as from_palette does.
struct Color {
    std::string name;
    PaletteFn palette;
    ToneFn tone;
    ToneFn chromaMultiplier;
    bool isBackground = false;
    ColorFn background;
    ColorFn secondBackground;
    CurveFn contrastCurve;
    PairFn toneDeltaPair;

    // Resolved colour in HCT, from the palette, the resolved tone and (2025) the chroma multiplier
    [[nodiscard]] Hct hct(const Scheme& scheme) const;
    // Resolved tone, after the background and pairing constraints
    [[nodiscard]] double toneOf(const Scheme& scheme) const;
    // Resolved colour as ARGB
    [[nodiscard]] Argb argb(const Scheme& scheme) const;
};

struct ToneDeltaPair {
    Color roleA;
    Color roleB;
    double delta;
    Polarity polarity;
    bool stayTogether;
    Constraint constraint;
};

// The variables a colour is resolved against, and the six palettes built from the source colour
class Scheme {
public:
    // requested is the spec the caller wants; variants that don't use the 2025 spec fall back to 2021
    Scheme(Hct sourceColorHct, Variant variant, double contrastLevel, bool isDark, SpecVersion requested);

    Hct sourceColorHct;
    Variant variant;
    double contrastLevel;
    bool isDark;
    SpecVersion specVersion;

    TonalPalette primaryPalette;
    TonalPalette secondaryPalette;
    TonalPalette tertiaryPalette;
    TonalPalette neutralPalette;
    TonalPalette neutralVariantPalette;
    TonalPalette errorPalette;

    // The spec in effect for a variant: only some variants use the 2025 spec
    static SpecVersion specFor(Variant variant, SpecVersion requested);
};

// Resolves a colour's tone in a scheme, with the calculation engine of the scheme's spec
double resolveTone(const Scheme& scheme, const Color& color);

double foregroundTone(double bgTone, double ratio);
bool tonePrefersLightForeground(double tone);

// Python t_max_c / t_min_c: the tone where a palette reaches its chroma (clamped to the bounds)
double tMaxC(const TonalPalette& palette, double lowerBound = 0, double upperBound = 100, double chromaMultiplier = 1);
double tMinC(const TonalPalette& palette, double lowerBound = 0, double upperBound = 100);

// Python find_desired_chroma_by_tone (the 2021 fidelity secondary container)
double findDesiredChromaByTone(double hue, double chroma, double tone, bool byDecreasingTone);

} // namespace caelestia::material
