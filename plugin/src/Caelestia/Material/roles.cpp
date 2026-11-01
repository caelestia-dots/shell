#include "roles.hpp"

#include <optional>
#include <utility>

namespace caelestia::material::roles {

namespace {

using std::nullopt;
using std::optional;

// Scheme predicates from the Python colour specs
bool isFidelity(const Scheme& s) {
    return s.variant == Variant::Fidelity || s.variant == Variant::Content;
}

bool isMonochrome(const Scheme& s) {
    return s.variant == Variant::Monochrome;
}

// The 2025 spec is only reached on the phone platform (materialyoucolor's default), so its
// watch branches are left out.

// ContrastCurve(a, b, c, d).get(contrast_level), as the 2021 tones use it
double curveTone(double a, double b, double c, double d, const Scheme& s) {
    return ContrastCurve{ .low = a, .normal = b, .medium = c, .high = d }.get(s.contrastLevel);
}

// A palette taken from one of the scheme's six palettes
PaletteFn pal(TonalPalette Scheme::* member) {
    return [member](const Scheme& s) {
        return s.*member;
    };
}

ContrastCurve curveFor(double a, double b, double c, double d) {
    return ContrastCurve{ .low = a, .normal = b, .medium = c, .high = d };
}

CurveFn curve(double a, double b, double c, double d) {
    return [=](const Scheme&) {
        return optional<ContrastCurve>(curveFor(a, b, c, d));
    };
}

// get_curve(x) of the 2025 spec
CurveFn curveOf(double defaultContrast) {
    return [=](const Scheme&) {
        return optional<ContrastCurve>(getCurve(defaultContrast));
    };
}

// get_curve(x) only when the contrast level is above zero, otherwise no curve (2025 containers)
CurveFn curveWhenContrast(double defaultContrast) {
    return [=](const Scheme& s) -> optional<ContrastCurve> {
        if (s.contrastLevel > 0)
            return getCurve(defaultContrast);
        return nullopt;
    };
}

ColorFn roleFn(Color (*role)()) {
    return [role](const Scheme&) {
        return optional<Color>(role());
    };
}

ColorFn highestSurfaceFn() {
    return [](const Scheme& s) {
        return optional<Color>(highestSurface(s));
    };
}

PairFn pairOf(Color (*a)(), Color (*b)(), double delta, Polarity polarity, bool stayTogether,
    Constraint constraint = Constraint::Exact) {
    return [=](const Scheme&) {
        return optional<ToneDeltaPair>(ToneDeltaPair{
            .roleA = a(),
            .roleB = b(),
            .delta = delta,
            .polarity = polarity,
            .stayTogether = stayTogether,
            .constraint = constraint,
        });
    };
}

// The arguments of a role's definition, in the order the Python from_palette takes them
struct Def {
    const char* name;
    PaletteFn palette;
    ToneFn tone = nullptr;
    bool isBackground = false;
    ToneFn chroma = nullptr;
    ColorFn background = nullptr;
    ColorFn secondBackground = nullptr;
    CurveFn contrast = nullptr;
    PairFn pair = nullptr;
};

// Python DynamicColor.from_palette: without a tone, the role takes its background's tone (or 50)
Color make(Def d) {
    Color c;
    c.name = d.name;
    c.palette = std::move(d.palette);
    c.isBackground = d.isBackground;
    c.chromaMultiplier = std::move(d.chroma);
    c.background = d.background;
    c.secondBackground = std::move(d.secondBackground);
    c.contrastCurve = std::move(d.contrast);
    c.toneDeltaPair = std::move(d.pair);
    if (d.tone) {
        c.tone = std::move(d.tone);
    } else {
        c.tone = [background = c.background](const Scheme& s) -> double {
            if (!background)
                return 50.0;
            const auto bg = background(s);
            return bg ? bg->toneOf(s) : 50.0;
        };
    }
    return c;
}

// Python extend_spec_version: the 2025 colour replaces the 2021 one wherever the scheme's spec is
// 2025. Each field follows the chosen colour, with the Python defaults for missing ones (no
// background, no curve or pair, a chroma multiplier of 1, and the 2021 tone if the 2025 one has
// none).
Color extend(const Color& orig, const Color& ext) {
    const auto pick = [orig, ext](const Scheme& s) -> const Color* {
        return s.specVersion == SpecVersion::V2025 ? &ext : &orig;
    };

    Color out;
    out.name = orig.name;
    out.isBackground = orig.isBackground;
    out.palette = [pick](const Scheme& s) {
        return pick(s)->palette(s);
    };
    out.tone = [pick, orig](const Scheme& s) -> double {
        const Color* c = pick(s);
        return c->tone ? c->tone(s) : orig.tone(s);
    };
    out.chromaMultiplier = [pick](const Scheme& s) -> double {
        const Color* c = pick(s);
        return c->chromaMultiplier ? c->chromaMultiplier(s) : 1.0;
    };
    out.background = [pick](const Scheme& s) -> optional<Color> {
        const Color* c = pick(s);
        if (!c->background)
            return nullopt;
        return c->background(s);
    };
    out.secondBackground = [pick](const Scheme& s) -> optional<Color> {
        const Color* c = pick(s);
        if (!c->secondBackground)
            return nullopt;
        return c->secondBackground(s);
    };
    out.contrastCurve = [pick](const Scheme& s) -> optional<ContrastCurve> {
        const Color* c = pick(s);
        if (!c->contrastCurve)
            return nullopt;
        return c->contrastCurve(s);
    };
    out.toneDeltaPair = [pick](const Scheme& s) -> optional<ToneDeltaPair> {
        const Color* c = pick(s);
        if (!c->toneDeltaPair)
            return nullopt;
        return c->toneDeltaPair(s);
    };
    return out;
}

// Python clone(): the same role under a new name
Color cloneAs(const Color& c, const char* name) {
    Color copy = c;
    copy.name = name;
    return copy;
}

// The role definitions below build std::function closures whose heap storage the analyzer
// cannot follow to its release, so it reports a leak at each function end. They are plain values.
// NOLINTBEGIN(clang-analyzer-cplusplus.NewDeleteLeaks)
// --- 2021 definitions (color_spec_2021.py) ----------------------------------------------------

Color origPrimaryPaletteKeyColor() {
    return make({
        .name = "primaryPaletteKeyColor",
        .palette = pal(&Scheme::primaryPalette),
        .tone =
            [](const Scheme& s) {
                return s.primaryPalette.keyColor().get_tone();
            },
    });
}

Color origSecondaryPaletteKeyColor() {
    return make({
        .name = "secondaryPaletteKeyColor",
        .palette = pal(&Scheme::secondaryPalette),
        .tone =
            [](const Scheme& s) {
                return s.secondaryPalette.keyColor().get_tone();
            },
    });
}

Color origTertiaryPaletteKeyColor() {
    return make({
        .name = "tertiaryPaletteKeyColor",
        .palette = pal(&Scheme::tertiaryPalette),
        .tone =
            [](const Scheme& s) {
                return s.tertiaryPalette.keyColor().get_tone();
            },
    });
}

Color origNeutralPaletteKeyColor() {
    return make({
        .name = "neutralPaletteKeyColor",
        .palette = pal(&Scheme::neutralPalette),
        .tone =
            [](const Scheme& s) {
                return s.neutralPalette.keyColor().get_tone();
            },
    });
}

Color origNeutralVariantPaletteKeyColor() {
    return make({
        .name = "neutralVariantPaletteKeyColor",
        .palette = pal(&Scheme::neutralVariantPalette),
        .tone =
            [](const Scheme& s) {
                return s.neutralVariantPalette.keyColor().get_tone();
            },
    });
}

Color origErrorPaletteKeyColor() {
    return make({
        .name = "errorPaletteKeyColor",
        .palette = pal(&Scheme::errorPalette),
        .tone =
            [](const Scheme& s) {
                return s.errorPalette.keyColor().get_tone();
            },
    });
}

Color origBackground() {
    return make({
        .name = "background",
        .palette = pal(&Scheme::neutralPalette),
        .tone =
            [](const Scheme& s) {
                return s.isDark ? 6.0 : 98.0;
            },
        .isBackground = true,
    });
}

Color origOnBackground() {
    return make({
        .name = "onBackground",
        .palette = pal(&Scheme::neutralPalette),
        .tone =
            [](const Scheme& s) {
                return s.isDark ? 90.0 : 10.0;
            },
        .background = roleFn(&background),
        .contrast = curve(3, 3, 4.5, 7),
    });
}

Color origSurface() {
    return make({
        .name = "surface",
        .palette = pal(&Scheme::neutralPalette),
        .tone =
            [](const Scheme& s) {
                return s.isDark ? 6.0 : 98.0;
            },
        .isBackground = true,
    });
}

Color origSurfaceDim() {
    return make({
        .name = "surfaceDim",
        .palette = pal(&Scheme::neutralPalette),
        .tone =
            [](const Scheme& s) {
                return s.isDark ? 6.0 : curveTone(87, 87, 80, 75, s);
            },
        .isBackground = true,
    });
}

Color origSurfaceBright() {
    return make({
        .name = "surfaceBright",
        .palette = pal(&Scheme::neutralPalette),
        .tone =
            [](const Scheme& s) {
                return s.isDark ? curveTone(24, 24, 29, 34, s) : 98.0;
            },
        .isBackground = true,
    });
}

Color origSurfaceContainerLowest() {
    return make({
        .name = "surfaceContainerLowest",
        .palette = pal(&Scheme::neutralPalette),
        .tone =
            [](const Scheme& s) {
                return s.isDark ? curveTone(4, 4, 2, 0, s) : 100.0;
            },
        .isBackground = true,
    });
}

Color origSurfaceContainerLow() {
    return make({
        .name = "surfaceContainerLow",
        .palette = pal(&Scheme::neutralPalette),
        .tone =
            [](const Scheme& s) {
                return s.isDark ? curveTone(10, 10, 11, 12, s) : curveTone(96, 96, 96, 95, s);
            },
        .isBackground = true,
    });
}

Color origSurfaceContainer() {
    return make({
        .name = "surfaceContainer",
        .palette = pal(&Scheme::neutralPalette),
        .tone =
            [](const Scheme& s) {
                return s.isDark ? curveTone(12, 12, 16, 20, s) : curveTone(94, 94, 92, 90, s);
            },
        .isBackground = true,
    });
}

Color origSurfaceContainerHigh() {
    return make({
        .name = "surfaceContainerHigh",
        .palette = pal(&Scheme::neutralPalette),
        .tone =
            [](const Scheme& s) {
                return s.isDark ? curveTone(17, 17, 21, 25, s) : curveTone(92, 92, 88, 85, s);
            },
        .isBackground = true,
    });
}

Color origSurfaceContainerHighest() {
    return make({
        .name = "surfaceContainerHighest",
        .palette = pal(&Scheme::neutralPalette),
        .tone =
            [](const Scheme& s) {
                return s.isDark ? curveTone(22, 22, 26, 30, s) : curveTone(90, 90, 84, 80, s);
            },
        .isBackground = true,
    });
}

Color origOnSurface() {
    return make({
        .name = "onSurface",
        .palette = pal(&Scheme::neutralPalette),
        .tone =
            [](const Scheme& s) {
                return s.isDark ? 90.0 : 10.0;
            },
        .background = highestSurfaceFn(),
        .contrast = curve(4.5, 7, 11, 21),
    });
}

Color origSurfaceVariant() {
    return make({
        .name = "surfaceVariant",
        .palette = pal(&Scheme::neutralVariantPalette),
        .tone =
            [](const Scheme& s) {
                return s.isDark ? 30.0 : 90.0;
            },
        .isBackground = true,
    });
}

Color origOnSurfaceVariant() {
    return make({
        .name = "onSurfaceVariant",
        .palette = pal(&Scheme::neutralVariantPalette),
        .tone =
            [](const Scheme& s) {
                return s.isDark ? 80.0 : 30.0;
            },
        .background = highestSurfaceFn(),
        .contrast = curve(3, 4.5, 7, 11),
    });
}

Color origInverseSurface() {
    return make({
        .name = "inverseSurface",
        .palette = pal(&Scheme::neutralPalette),
        .tone =
            [](const Scheme& s) {
                return s.isDark ? 90.0 : 20.0;
            },
        .isBackground = true,
    });
}

Color origInverseOnSurface() {
    return make({
        .name = "inverseOnSurface",
        .palette = pal(&Scheme::neutralPalette),
        .tone =
            [](const Scheme& s) {
                return s.isDark ? 20.0 : 95.0;
            },
        .background = roleFn(&inverseSurface),
        .contrast = curve(4.5, 7, 11, 21),
    });
}

Color origOutline() {
    return make({
        .name = "outline",
        .palette = pal(&Scheme::neutralVariantPalette),
        .tone =
            [](const Scheme& s) {
                return s.isDark ? 60.0 : 50.0;
            },
        .background = highestSurfaceFn(),
        .contrast = curve(1.5, 3, 4.5, 7),
    });
}

Color origOutlineVariant() {
    return make({
        .name = "outlineVariant",
        .palette = pal(&Scheme::neutralVariantPalette),
        .tone =
            [](const Scheme& s) {
                return s.isDark ? 30.0 : 80.0;
            },
        .background = highestSurfaceFn(),
        .contrast = curve(1, 1, 3, 4.5),
    });
}

Color origShadow() {
    return make({
        .name = "shadow",
        .palette = pal(&Scheme::neutralPalette),
        .tone =
            [](const Scheme&) {
                return 0.0;
            },
    });
}

Color origScrim() {
    return make({
        .name = "scrim",
        .palette = pal(&Scheme::neutralPalette),
        .tone =
            [](const Scheme&) {
                return 0.0;
            },
    });
}

Color origSurfaceTint() {
    return make({
        .name = "surfaceTint",
        .palette = pal(&Scheme::primaryPalette),
        .tone =
            [](const Scheme& s) {
                return s.isDark ? 80.0 : 40.0;
            },
        .isBackground = true,
    });
}

Color origPrimary() {
    return make({
        .name = "primary",
        .palette = pal(&Scheme::primaryPalette),
        .tone =
            [](const Scheme& s) {
                if (isMonochrome(s))
                    return s.isDark ? 100.0 : 0.0;
                return s.isDark ? 80.0 : 40.0;
            },
        .isBackground = true,
        .background = highestSurfaceFn(),
        .contrast = curve(3, 4.5, 7, 7),
        .pair = pairOf(&primaryContainer, &primary, 10, Polarity::Nearer, false),
    });
}

Color origOnPrimary() {
    return make({
        .name = "onPrimary",
        .palette = pal(&Scheme::primaryPalette),
        .tone =
            [](const Scheme& s) {
                if (isMonochrome(s))
                    return s.isDark ? 10.0 : 90.0;
                return s.isDark ? 20.0 : 100.0;
            },
        .background = roleFn(&primary),
        .contrast = curve(4.5, 7, 11, 21),
    });
}

Color origPrimaryContainer() {
    return make({
        .name = "primaryContainer",
        .palette = pal(&Scheme::primaryPalette),
        .tone =
            [](const Scheme& s) {
                if (isFidelity(s))
                    return s.sourceColorHct.get_tone();
                if (isMonochrome(s))
                    return s.isDark ? 85.0 : 25.0;
                return s.isDark ? 30.0 : 90.0;
            },
        .isBackground = true,
        .background = highestSurfaceFn(),
        .contrast = curve(1, 1, 3, 4.5),
        .pair = pairOf(&primaryContainer, &primary, 10, Polarity::Nearer, false),
    });
}

Color origOnPrimaryContainer() {
    return make({
        .name = "onPrimaryContainer",
        .palette = pal(&Scheme::primaryPalette),
        .tone =
            [](const Scheme& s) {
                if (isFidelity(s))
                    return foregroundTone(primaryContainer().tone(s), 4.5);
                if (isMonochrome(s))
                    return s.isDark ? 0.0 : 100.0;
                return s.isDark ? 90.0 : 30.0;
            },
        .background = roleFn(&primaryContainer),
        .contrast = curve(3, 4.5, 7, 11),
    });
}

Color origInversePrimary() {
    return make({
        .name = "inversePrimary",
        .palette = pal(&Scheme::primaryPalette),
        .tone =
            [](const Scheme& s) {
                return s.isDark ? 40.0 : 80.0;
            },
        .background = roleFn(&inverseSurface),
        .contrast = curve(3, 4.5, 7, 7),
    });
}

Color origSecondary() {
    return make({
        .name = "secondary",
        .palette = pal(&Scheme::secondaryPalette),
        .tone =
            [](const Scheme& s) {
                return s.isDark ? 80.0 : 40.0;
            },
        .isBackground = true,
        .background = highestSurfaceFn(),
        .contrast = curve(3, 4.5, 7, 7),
        .pair = pairOf(&secondaryContainer, &secondary, 10, Polarity::Nearer, false),
    });
}

Color origOnSecondary() {
    return make({
        .name = "onSecondary",
        .palette = pal(&Scheme::secondaryPalette),
        .tone =
            [](const Scheme& s) {
                if (isMonochrome(s))
                    return s.isDark ? 10.0 : 100.0;
                return s.isDark ? 20.0 : 100.0;
            },
        .background = roleFn(&secondary),
        .contrast = curve(4.5, 7, 11, 21),
    });
}

Color origSecondaryContainer() {
    return make({
        .name = "secondaryContainer",
        .palette = pal(&Scheme::secondaryPalette),
        .tone =
            [](const Scheme& s) {
                if (isMonochrome(s))
                    return s.isDark ? 30.0 : 85.0;
                if (isFidelity(s)) {
                    return findDesiredChromaByTone(
                        s.secondaryPalette.hue(), s.secondaryPalette.chroma(), s.isDark ? 30 : 90, !s.isDark);
                }
                return s.isDark ? 30.0 : 90.0;
            },
        .isBackground = true,
        .background = highestSurfaceFn(),
        .contrast = curve(1, 1, 3, 4.5),
        .pair = pairOf(&secondaryContainer, &secondary, 10, Polarity::Nearer, false),
    });
}

Color origOnSecondaryContainer() {
    return make({
        .name = "onSecondaryContainer",
        .palette = pal(&Scheme::secondaryPalette),
        .tone =
            [](const Scheme& s) {
                if (isMonochrome(s))
                    return s.isDark ? 90.0 : 10.0;
                if (isFidelity(s))
                    return foregroundTone(secondaryContainer().tone(s), 4.5);
                return s.isDark ? 90.0 : 30.0;
            },
        .background = roleFn(&secondaryContainer),
        .contrast = curve(3, 4.5, 7, 11),
    });
}

Color origTertiary() {
    return make({
        .name = "tertiary",
        .palette = pal(&Scheme::tertiaryPalette),
        .tone =
            [](const Scheme& s) {
                if (isMonochrome(s))
                    return s.isDark ? 90.0 : 25.0;
                return s.isDark ? 80.0 : 40.0;
            },
        .isBackground = true,
        .background = highestSurfaceFn(),
        .contrast = curve(3, 4.5, 7, 7),
        .pair = pairOf(&tertiaryContainer, &tertiary, 10, Polarity::Nearer, false),
    });
}

Color origOnTertiary() {
    return make({
        .name = "onTertiary",
        .palette = pal(&Scheme::tertiaryPalette),
        .tone =
            [](const Scheme& s) {
                if (isMonochrome(s))
                    return s.isDark ? 10.0 : 90.0;
                return s.isDark ? 20.0 : 100.0;
            },
        .background = roleFn(&tertiary),
        .contrast = curve(4.5, 7, 11, 21),
    });
}

Color origTertiaryContainer() {
    return make({
        .name = "tertiaryContainer",
        .palette = pal(&Scheme::tertiaryPalette),
        .tone =
            [](const Scheme& s) {
                if (isMonochrome(s))
                    return s.isDark ? 60.0 : 49.0;
                if (isFidelity(s)) {
                    return dislikeFixed(s.tertiaryPalette.hctFor(s.sourceColorHct.get_tone())).get_tone();
                }
                return s.isDark ? 30.0 : 90.0;
            },
        .isBackground = true,
        .background = highestSurfaceFn(),
        .contrast = curve(1, 1, 3, 4.5),
        .pair = pairOf(&tertiaryContainer, &tertiary, 10, Polarity::Nearer, false),
    });
}

Color origOnTertiaryContainer() {
    return make({
        .name = "onTertiaryContainer",
        .palette = pal(&Scheme::tertiaryPalette),
        .tone =
            [](const Scheme& s) {
                if (isMonochrome(s))
                    return s.isDark ? 0.0 : 100.0;
                if (isFidelity(s))
                    return foregroundTone(tertiaryContainer().tone(s), 4.5);
                return s.isDark ? 90.0 : 30.0;
            },
        .background = roleFn(&tertiaryContainer),
        .contrast = curve(3, 4.5, 7, 11),
    });
}

Color origError() {
    return make({
        .name = "error",
        .palette = pal(&Scheme::errorPalette),
        .tone =
            [](const Scheme& s) {
                return s.isDark ? 80.0 : 40.0;
            },
        .isBackground = true,
        .background = highestSurfaceFn(),
        .contrast = curve(3, 4.5, 7, 7),
        .pair = pairOf(&errorContainer, &error, 10, Polarity::Nearer, false),
    });
}

Color origOnError() {
    return make({
        .name = "onError",
        .palette = pal(&Scheme::errorPalette),
        .tone =
            [](const Scheme& s) {
                return s.isDark ? 20.0 : 100.0;
            },
        .background = roleFn(&error),
        .contrast = curve(4.5, 7, 11, 21),
    });
}

Color origErrorContainer() {
    return make({
        .name = "errorContainer",
        .palette = pal(&Scheme::errorPalette),
        .tone =
            [](const Scheme& s) {
                return s.isDark ? 30.0 : 90.0;
            },
        .isBackground = true,
        .background = highestSurfaceFn(),
        .contrast = curve(1, 1, 3, 4.5),
        .pair = pairOf(&errorContainer, &error, 10, Polarity::Nearer, false),
    });
}

Color origOnErrorContainer() {
    return make({
        .name = "onErrorContainer",
        .palette = pal(&Scheme::errorPalette),
        .tone =
            [](const Scheme& s) {
                if (isMonochrome(s))
                    return s.isDark ? 90.0 : 10.0;
                return s.isDark ? 90.0 : 30.0;
            },
        .background = roleFn(&errorContainer),
        .contrast = curve(3, 4.5, 7, 11),
    });
}

Color origPrimaryFixed() {
    return make({
        .name = "primaryFixed",
        .palette = pal(&Scheme::primaryPalette),
        .tone =
            [](const Scheme& s) {
                return isMonochrome(s) ? 40.0 : 90.0;
            },
        .isBackground = true,
        .background = highestSurfaceFn(),
        .contrast = curve(1, 1, 3, 4.5),
        .pair = pairOf(&primaryFixed, &primaryFixedDim, 10, Polarity::Lighter, true),
    });
}

Color origPrimaryFixedDim() {
    return make({
        .name = "primaryFixedDim",
        .palette = pal(&Scheme::primaryPalette),
        .tone =
            [](const Scheme& s) {
                return isMonochrome(s) ? 30.0 : 80.0;
            },
        .isBackground = true,
        .background = highestSurfaceFn(),
        .contrast = curve(1, 1, 3, 4.5),
        .pair = pairOf(&primaryFixed, &primaryFixedDim, 10, Polarity::Lighter, true),
    });
}

Color origOnPrimaryFixed() {
    return make({
        .name = "onPrimaryFixed",
        .palette = pal(&Scheme::primaryPalette),
        .tone =
            [](const Scheme& s) {
                return isMonochrome(s) ? 100.0 : 10.0;
            },
        .background = roleFn(&primaryFixedDim),
        .secondBackground = roleFn(&primaryFixed),
        .contrast = curve(4.5, 7, 11, 21),
    });
}

Color origOnPrimaryFixedVariant() {
    return make({
        .name = "onPrimaryFixedVariant",
        .palette = pal(&Scheme::primaryPalette),
        .tone =
            [](const Scheme& s) {
                return isMonochrome(s) ? 90.0 : 30.0;
            },
        .background = roleFn(&primaryFixedDim),
        .contrast = curve(3, 4.5, 7, 11),
    });
}

Color origSecondaryFixed() {
    return make({
        .name = "secondaryFixed",
        .palette = pal(&Scheme::secondaryPalette),
        .tone =
            [](const Scheme& s) {
                return isMonochrome(s) ? 80.0 : 90.0;
            },
        .isBackground = true,
        .background = highestSurfaceFn(),
        .contrast = curve(1, 1, 3, 4.5),
        .pair = pairOf(&secondaryFixed, &secondaryFixedDim, 10, Polarity::Lighter, true),
    });
}

Color origSecondaryFixedDim() {
    return make({
        .name = "secondaryFixedDim",
        .palette = pal(&Scheme::secondaryPalette),
        .tone =
            [](const Scheme& s) {
                return isMonochrome(s) ? 70.0 : 80.0;
            },
        .isBackground = true,
        .background = highestSurfaceFn(),
        .contrast = curve(1, 1, 3, 4.5),
        .pair = pairOf(&secondaryFixed, &secondaryFixedDim, 10, Polarity::Lighter, true),
    });
}

Color origOnSecondaryFixed() {
    return make({
        .name = "onSecondaryFixed",
        .palette = pal(&Scheme::secondaryPalette),
        .tone =
            [](const Scheme&) {
                return 10.0;
            },
        .background = roleFn(&secondaryFixedDim),
        .secondBackground = roleFn(&secondaryFixed),
        .contrast = curve(4.5, 7, 11, 21),
    });
}

Color origOnSecondaryFixedVariant() {
    return make({
        .name = "onSecondaryFixedVariant",
        .palette = pal(&Scheme::secondaryPalette),
        .tone =
            [](const Scheme& s) {
                return isMonochrome(s) ? 25.0 : 30.0;
            },
        .background = roleFn(&secondaryFixedDim),
        .contrast = curve(3, 4.5, 7, 11),
    });
}

Color origTertiaryFixed() {
    return make({
        .name = "tertiaryFixed",
        .palette = pal(&Scheme::tertiaryPalette),
        .tone =
            [](const Scheme& s) {
                return isMonochrome(s) ? 40.0 : 90.0;
            },
        .isBackground = true,
        .background = highestSurfaceFn(),
        .contrast = curve(1, 1, 3, 4.5),
        .pair = pairOf(&tertiaryFixed, &tertiaryFixedDim, 10, Polarity::Lighter, true),
    });
}

Color origTertiaryFixedDim() {
    return make({
        .name = "tertiaryFixedDim",
        .palette = pal(&Scheme::tertiaryPalette),
        .tone =
            [](const Scheme& s) {
                return isMonochrome(s) ? 30.0 : 80.0;
            },
        .isBackground = true,
        .background = highestSurfaceFn(),
        .contrast = curve(1, 1, 3, 4.5),
        .pair = pairOf(&tertiaryFixed, &tertiaryFixedDim, 10, Polarity::Lighter, true),
    });
}

Color origOnTertiaryFixed() {
    return make({
        .name = "onTertiaryFixed",
        .palette = pal(&Scheme::tertiaryPalette),
        .tone =
            [](const Scheme& s) {
                return isMonochrome(s) ? 100.0 : 10.0;
            },
        .background = roleFn(&tertiaryFixedDim),
        .secondBackground = roleFn(&tertiaryFixed),
        .contrast = curve(4.5, 7, 11, 21),
    });
}

Color origOnTertiaryFixedVariant() {
    return make({
        .name = "onTertiaryFixedVariant",
        .palette = pal(&Scheme::tertiaryPalette),
        .tone =
            [](const Scheme& s) {
                return isMonochrome(s) ? 90.0 : 30.0;
            },
        .background = roleFn(&tertiaryFixedDim),
        .contrast = curve(3, 4.5, 7, 11),
    });
}

// --- 2025 definitions (color_spec_2025.py), phone platform -------------------------------------

// The chroma multiplier of the on-surface roles (onSurface, onSurfaceVariant, outline, outlineVariant)
double onSurfaceChroma(const Scheme& s) {
    const bool yellow = isYellow(s.neutralPalette.hue());
    switch (s.variant) {
    case Variant::Neutral:
        return 2.2;
    case Variant::TonalSpot:
        return 1.7;
    case Variant::Expressive:
        if (s.isDark && yellow)
            return 3.0;
        return yellow ? 2.3 : 1.6;
    default:
        return 1.0;
    }
}

// Surface dim and bright: the chroma multiplier for a light (dim) or dark (bright) scheme
double surfaceTintChroma(const Scheme& s, bool applies) {
    if (!applies)
        return 1.0;
    const bool yellow = isYellow(s.neutralPalette.hue());
    switch (s.variant) {
    case Variant::Neutral:
        return 2.5;
    case Variant::TonalSpot:
        return 1.7;
    case Variant::Expressive:
        return yellow ? 2.7 : 1.75;
    case Variant::Vibrant:
        return 1.36;
    default:
        return 1.0;
    }
}

double primaryToneFor2025(const Scheme& s) {
    const TonalPalette& p = s.primaryPalette;
    switch (s.variant) {
    case Variant::Neutral:
        return s.isDark ? 80 : 40;
    case Variant::TonalSpot:
        return s.isDark ? 80 : tMaxC(p);
    case Variant::Expressive:
        if (isYellow(p.hue()))
            return tMaxC(p, 0, 25);
        if (isCyan(p.hue()))
            return tMaxC(p, 0, 88);
        return tMaxC(p, 0, 98);
    case Variant::Vibrant:
        return isCyan(p.hue()) ? tMaxC(p, 0, 88) : tMaxC(p, 0, 98);
    default:
        return 0;
    }
}

double primaryContainerToneFor2025(const Scheme& s) {
    const TonalPalette& p = s.primaryPalette;
    switch (s.variant) {
    case Variant::Neutral:
        return s.isDark ? 30 : 90;
    case Variant::TonalSpot:
        return s.isDark ? tMinC(p, 35, 93) : tMaxC(p, 0, 90);
    case Variant::Expressive:
        if (s.isDark)
            return tMaxC(p, 30, 93);
        return isCyan(p.hue()) ? tMaxC(p, 78, 88) : tMaxC(p, 78, 90);
    case Variant::Vibrant:
        if (s.isDark)
            return tMinC(p, 66, 93);
        return isCyan(p.hue()) ? tMaxC(p, 66, 88) : tMaxC(p, 66, 93);
    default:
        return 0;
    }
}

double secondaryToneFor2025(const Scheme& s) {
    const TonalPalette& p = s.secondaryPalette;
    switch (s.variant) {
    case Variant::Neutral:
        return s.isDark ? tMinC(p, 0, 98) : tMaxC(p);
    case Variant::Vibrant:
        return s.isDark ? tMaxC(p, 0, 90) : tMaxC(p, 0, 98);
    default:
        return s.isDark ? 80 : tMaxC(p);
    }
}

double secondaryContainerToneFor2025(const Scheme& s) {
    const TonalPalette& p = s.secondaryPalette;
    switch (s.variant) {
    case Variant::Vibrant:
        return s.isDark ? tMinC(p, 30, 40) : tMaxC(p, 84, 90);
    case Variant::Expressive:
        return s.isDark ? 15 : tMaxC(p, 90, 95);
    default:
        return s.isDark ? 25 : 90;
    }
}

double tertiaryToneFor2025(const Scheme& s) {
    const TonalPalette& p = s.tertiaryPalette;
    if (s.variant == Variant::Expressive || s.variant == Variant::Vibrant) {
        if (isCyan(p.hue()))
            return tMaxC(p, 0, 88);
        return s.isDark ? tMaxC(p, 0, 98) : tMaxC(p, 0, 100);
    }
    return s.isDark ? tMaxC(p, 0, 98) : tMaxC(p);
}

double tertiaryContainerToneFor2025(const Scheme& s) {
    const TonalPalette& p = s.tertiaryPalette;
    switch (s.variant) {
    case Variant::Neutral:
        return s.isDark ? tMaxC(p, 0, 93) : tMaxC(p, 0, 96);
    case Variant::TonalSpot:
        return s.isDark ? tMaxC(p, 0, 93) : tMaxC(p, 0, 100);
    case Variant::Expressive:
        if (isCyan(p.hue()))
            return tMaxC(p, 75, 88);
        return s.isDark ? tMaxC(p, 75, 93) : tMaxC(p, 75, 100);
    case Variant::Vibrant:
        return s.isDark ? tMaxC(p, 0, 93) : tMaxC(p, 72, 100);
    default:
        return 0;
    }
}

double errorToneFor2025(const Scheme& s) {
    return s.isDark ? tMinC(s.errorPalette, 0, 98) : tMaxC(s.errorPalette);
}

double errorContainerToneFor2025(const Scheme& s) {
    return s.isDark ? tMinC(s.errorPalette, 30, 93) : tMaxC(s.errorPalette, 0, 90);
}

// Python _surface_tone_2025 and the other surface tones: the phone values
double surfaceToneFor2025(const Scheme& s) {
    if (s.isDark)
        return 4;
    if (isYellow(s.neutralPalette.hue()))
        return 99;
    return s.variant == Variant::Vibrant ? 97 : 98;
}

// The 2025 role override, under the same name as the 2021 role
Color extSurface() {
    return make({
        .name = "surface",
        .palette = pal(&Scheme::neutralPalette),
        .tone =
            [](const Scheme& s) {
                return surfaceToneFor2025(s);
            },
        .isBackground = true,
    });
}

Color extSurfaceDim() {
    return make({
        .name = "surfaceDim",
        .palette = pal(&Scheme::neutralPalette),
        .tone =
            [](const Scheme& s) {
                if (s.isDark)
                    return 4.0;
                if (isYellow(s.neutralPalette.hue()))
                    return 90.0;
                return s.variant == Variant::Vibrant ? 85.0 : 87.0;
            },
        .isBackground = true,
        .chroma =
            [](const Scheme& s) {
                return surfaceTintChroma(s, !s.isDark);
            },
    });
}

Color extSurfaceBright() {
    return make({
        .name = "surfaceBright",
        .palette = pal(&Scheme::neutralPalette),
        .tone =
            [](const Scheme& s) {
                if (s.isDark)
                    return 18.0;
                if (isYellow(s.neutralPalette.hue()))
                    return 99.0;
                return s.variant == Variant::Vibrant ? 97.0 : 98.0;
            },
        .isBackground = true,
        .chroma =
            [](const Scheme& s) {
                return surfaceTintChroma(s, s.isDark);
            },
    });
}

Color extSurfaceContainerLowest() {
    return make({
        .name = "surfaceContainerLowest",
        .palette = pal(&Scheme::neutralPalette),
        .tone =
            [](const Scheme& s) {
                return s.isDark ? 0.0 : 100.0;
            },
        .isBackground = true,
    });
}

Color extSurfaceContainerLow() {
    return make({
        .name = "surfaceContainerLow",
        .palette = pal(&Scheme::neutralPalette),
        .tone =
            [](const Scheme& s) {
                if (s.isDark)
                    return 6.0;
                if (isYellow(s.neutralPalette.hue()))
                    return 98.0;
                return s.variant == Variant::Vibrant ? 95.0 : 96.0;
            },
        .isBackground = true,
        .chroma =
            [](const Scheme& s) {
                switch (s.variant) {
                case Variant::Neutral:
                    return 1.3;
                case Variant::TonalSpot:
                    return 1.25;
                case Variant::Expressive:
                    return isYellow(s.neutralPalette.hue()) ? 1.3 : 1.15;
                case Variant::Vibrant:
                    return 1.08;
                default:
                    return 1.0;
                }
            },
    });
}

Color extSurfaceContainer() {
    return make({
        .name = "surfaceContainer",
        .palette = pal(&Scheme::neutralPalette),
        .tone =
            [](const Scheme& s) {
                if (s.isDark)
                    return 9.0;
                if (isYellow(s.neutralPalette.hue()))
                    return 96.0;
                return s.variant == Variant::Vibrant ? 92.0 : 94.0;
            },
        .isBackground = true,
        .chroma =
            [](const Scheme& s) {
                switch (s.variant) {
                case Variant::Neutral:
                    return 1.6;
                case Variant::TonalSpot:
                    return 1.4;
                case Variant::Expressive:
                    return isYellow(s.neutralPalette.hue()) ? 1.6 : 1.3;
                case Variant::Vibrant:
                    return 1.15;
                default:
                    return 1.0;
                }
            },
    });
}

Color extSurfaceContainerHigh() {
    return make({
        .name = "surfaceContainerHigh",
        .palette = pal(&Scheme::neutralPalette),
        .tone =
            [](const Scheme& s) {
                if (s.isDark)
                    return 12.0;
                if (isYellow(s.neutralPalette.hue()))
                    return 94.0;
                return s.variant == Variant::Vibrant ? 90.0 : 92.0;
            },
        .isBackground = true,
        .chroma =
            [](const Scheme& s) {
                switch (s.variant) {
                case Variant::Neutral:
                    return 1.9;
                case Variant::TonalSpot:
                    return 1.5;
                case Variant::Expressive:
                    return isYellow(s.neutralPalette.hue()) ? 1.95 : 1.45;
                case Variant::Vibrant:
                    return 1.22;
                default:
                    return 1.0;
                }
            },
    });
}

Color extSurfaceContainerHighest() {
    return make({
        .name = "surfaceContainerHighest",
        .palette = pal(&Scheme::neutralPalette),
        .tone =
            [](const Scheme& s) {
                if (s.isDark)
                    return 15.0;
                if (isYellow(s.neutralPalette.hue()))
                    return 92.0;
                return s.variant == Variant::Vibrant ? 88.0 : 90.0;
            },
        .isBackground = true,
        .chroma =
            [](const Scheme& s) {
                switch (s.variant) {
                case Variant::Neutral:
                    return 2.2;
                case Variant::TonalSpot:
                    return 1.7;
                case Variant::Expressive:
                    return isYellow(s.neutralPalette.hue()) ? 2.3 : 1.6;
                case Variant::Vibrant:
                    return 1.29;
                default:
                    return 1.0;
                }
            },
    });
}

Color extOnSurface() {
    return make({
        .name = "onSurface",
        .palette = pal(&Scheme::neutralPalette),
        .tone =
            [](const Scheme& s) {
                if (s.variant == Variant::Vibrant)
                    return tMaxC(s.neutralPalette, 0, 100, 1.1);
                return highestSurface(s).toneOf(s);
            },
        .chroma =
            [](const Scheme& s) {
                return onSurfaceChroma(s);
            },
        .background = highestSurfaceFn(),
        .contrast =
            [](const Scheme& s) {
                return optional<ContrastCurve>(getCurve(s.isDark ? 11 : 9));
            },
    });
}

Color extOnSurfaceVariant() {
    return make({
        .name = "onSurfaceVariant",
        .palette = pal(&Scheme::neutralPalette),
        .chroma =
            [](const Scheme& s) {
                return onSurfaceChroma(s);
            },
        .background = highestSurfaceFn(),
        .contrast =
            [](const Scheme& s) {
                return optional<ContrastCurve>(getCurve(s.isDark ? 6 : 4.5));
            },
    });
}

Color extOutline() {
    return make({
        .name = "outline",
        .palette = pal(&Scheme::neutralPalette),
        .chroma =
            [](const Scheme& s) {
                return onSurfaceChroma(s);
            },
        .background = highestSurfaceFn(),
        .contrast = curveOf(3),
    });
}

Color extOutlineVariant() {
    return make({
        .name = "outlineVariant",
        .palette = pal(&Scheme::neutralPalette),
        .chroma =
            [](const Scheme& s) {
                return onSurfaceChroma(s);
            },
        .background = highestSurfaceFn(),
        .contrast = curveOf(1.5),
    });
}

Color extInverseSurface() {
    return make({
        .name = "inverseSurface",
        .palette = pal(&Scheme::neutralPalette),
        .tone =
            [](const Scheme& s) {
                return s.isDark ? 98.0 : 4.0;
            },
        .isBackground = true,
    });
}

Color extInverseOnSurface() {
    return make({
        .name = "inverseOnSurface",
        .palette = pal(&Scheme::neutralPalette),
        .background = roleFn(&inverseSurface),
        .contrast = curveOf(7),
    });
}

Color extPrimary() {
    return make({
        .name = "primary",
        .palette = pal(&Scheme::primaryPalette),
        .tone =
            [](const Scheme& s) {
                return primaryToneFor2025(s);
            },
        .isBackground = true,
        .background = highestSurfaceFn(),
        .contrast = curveOf(4.5),
        .pair =
            [](const Scheme&) {
                return optional<ToneDeltaPair>(ToneDeltaPair{
                    .roleA = primaryContainer(),
                    .roleB = primary(),
                    .delta = 5,
                    .polarity = Polarity::RelativeLighter,
                    .stayTogether = true,
                    .constraint = Constraint::Farther,
                });
            },
    });
}

Color extPrimaryDim() {
    return make({
        .name = "primaryDim",
        .palette = pal(&Scheme::primaryPalette),
        .tone =
            [](const Scheme& s) {
                if (s.variant == Variant::Neutral)
                    return 85.0;
                if (s.variant == Variant::TonalSpot)
                    return tMaxC(s.primaryPalette, 0, 90);
                return tMaxC(s.primaryPalette);
            },
        .isBackground = true,
        .background = roleFn(&surfaceContainerHigh),
        .contrast = curveOf(4.5),
        .pair = pairOf(&primaryDim, &primary, 5, Polarity::Darker, true, Constraint::Farther),
    });
}

Color extOnPrimary() {
    return make({
        .name = "onPrimary",
        .palette = pal(&Scheme::primaryPalette),
        .background = roleFn(&primary),
        .contrast = curveOf(6),
    });
}

Color extPrimaryContainer() {
    return make({
        .name = "primaryContainer",
        .palette = pal(&Scheme::primaryPalette),
        .tone =
            [](const Scheme& s) {
                return primaryContainerToneFor2025(s);
            },
        .isBackground = true,
        .background = highestSurfaceFn(),
        .contrast = curveWhenContrast(1.5),
    });
}

Color extOnPrimaryContainer() {
    return make({
        .name = "onPrimaryContainer",
        .palette = pal(&Scheme::primaryPalette),
        .background = roleFn(&primaryContainer),
        .contrast = curveOf(6),
    });
}

// The 2025 fixed roles take their tone from the container, in a light scheme at zero contrast
Scheme lightAtZeroContrast(const Scheme& s) {
    Scheme temp = s;
    temp.isDark = false;
    temp.contrastLevel = 0;
    return temp;
}

Color extPrimaryFixed() {
    return make({
        .name = "primaryFixed",
        .palette = pal(&Scheme::primaryPalette),
        .tone =
            [](const Scheme& s) {
                return primaryContainer().toneOf(lightAtZeroContrast(s));
            },
        .isBackground = true,
        .background = highestSurfaceFn(),
        .contrast = curveWhenContrast(1.5),
    });
}

Color extPrimaryFixedDim() {
    return make({
        .name = "primaryFixedDim",
        .palette = pal(&Scheme::primaryPalette),
        .tone =
            [](const Scheme& s) {
                return primaryFixed().toneOf(s);
            },
        .isBackground = true,
        .pair = pairOf(&primaryFixedDim, &primaryFixed, 5, Polarity::Darker, true, Constraint::Exact),
    });
}

Color extOnPrimaryFixed() {
    return make({
        .name = "onPrimaryFixed",
        .palette = pal(&Scheme::primaryPalette),
        .background = roleFn(&primaryFixedDim),
        .contrast = curveOf(7),
    });
}

Color extOnPrimaryFixedVariant() {
    return make({
        .name = "onPrimaryFixedVariant",
        .palette = pal(&Scheme::primaryPalette),
        .background = roleFn(&primaryFixedDim),
        .contrast = curveOf(4.5),
    });
}

Color extInversePrimary() {
    return make({
        .name = "inversePrimary",
        .palette = pal(&Scheme::primaryPalette),
        .tone =
            [](const Scheme& s) {
                return tMaxC(s.primaryPalette);
            },
        .background = roleFn(&inverseSurface),
        .contrast = curveOf(6),
    });
}

Color extSecondary() {
    return make({
        .name = "secondary",
        .palette = pal(&Scheme::secondaryPalette),
        .tone =
            [](const Scheme& s) {
                return secondaryToneFor2025(s);
            },
        .isBackground = true,
        .background = highestSurfaceFn(),
        .contrast = curveOf(4.5),
        .pair = pairOf(&secondaryContainer, &secondary, 5, Polarity::RelativeLighter, true, Constraint::Farther),
    });
}

Color extSecondaryDim() {
    return make({
        .name = "secondaryDim",
        .palette = pal(&Scheme::secondaryPalette),
        .tone =
            [](const Scheme& s) {
                return s.variant == Variant::Neutral ? 85.0 : tMaxC(s.secondaryPalette, 0, 90);
            },
        .isBackground = true,
        .background = roleFn(&surfaceContainerHigh),
        .contrast = curveOf(4.5),
        .pair = pairOf(&secondaryDim, &secondary, 5, Polarity::Darker, true, Constraint::Farther),
    });
}

Color extOnSecondary() {
    return make({
        .name = "onSecondary",
        .palette = pal(&Scheme::secondaryPalette),
        .background = roleFn(&secondary),
        .contrast = curveOf(6),
    });
}

Color extSecondaryContainer() {
    return make({
        .name = "secondaryContainer",
        .palette = pal(&Scheme::secondaryPalette),
        .tone =
            [](const Scheme& s) {
                return secondaryContainerToneFor2025(s);
            },
        .isBackground = true,
        .background = highestSurfaceFn(),
        .contrast = curveWhenContrast(1.5),
    });
}

Color extOnSecondaryContainer() {
    return make({
        .name = "onSecondaryContainer",
        .palette = pal(&Scheme::secondaryPalette),
        .background = roleFn(&secondaryContainer),
        .contrast = curveOf(6),
    });
}

Color extSecondaryFixed() {
    return make({
        .name = "secondaryFixed",
        .palette = pal(&Scheme::secondaryPalette),
        .tone =
            [](const Scheme& s) {
                return secondaryContainer().toneOf(lightAtZeroContrast(s));
            },
        .isBackground = true,
        .background = highestSurfaceFn(),
        .contrast = curveWhenContrast(1.5),
    });
}

Color extSecondaryFixedDim() {
    return make({
        .name = "secondaryFixedDim",
        .palette = pal(&Scheme::secondaryPalette),
        .tone =
            [](const Scheme& s) {
                return secondaryFixed().toneOf(s);
            },
        .isBackground = true,
        .pair = pairOf(&secondaryFixedDim, &secondaryFixed, 5, Polarity::Darker, true, Constraint::Exact),
    });
}

Color extOnSecondaryFixed() {
    return make({
        .name = "onSecondaryFixed",
        .palette = pal(&Scheme::secondaryPalette),
        .background = roleFn(&secondaryFixedDim),
        .contrast = curveOf(7),
    });
}

Color extOnSecondaryFixedVariant() {
    return make({
        .name = "onSecondaryFixedVariant",
        .palette = pal(&Scheme::secondaryPalette),
        .background = roleFn(&secondaryFixedDim),
        .contrast = curveOf(4.5),
    });
}

Color extTertiary() {
    return make({
        .name = "tertiary",
        .palette = pal(&Scheme::tertiaryPalette),
        .tone =
            [](const Scheme& s) {
                return tertiaryToneFor2025(s);
            },
        .isBackground = true,
        .background = highestSurfaceFn(),
        .contrast = curveOf(4.5),
        .pair = pairOf(&tertiaryContainer, &tertiary, 5, Polarity::RelativeLighter, true, Constraint::Farther),
    });
}

Color extTertiaryDim() {
    return make({
        .name = "tertiaryDim",
        .palette = pal(&Scheme::tertiaryPalette),
        .tone =
            [](const Scheme& s) {
                return s.variant == Variant::TonalSpot ? tMaxC(s.tertiaryPalette, 0, 90) : tMaxC(s.tertiaryPalette);
            },
        .isBackground = true,
        .background = roleFn(&surfaceContainerHigh),
        .contrast = curveOf(4.5),
        .pair = pairOf(&tertiaryDim, &tertiary, 5, Polarity::Darker, true, Constraint::Farther),
    });
}

Color extOnTertiary() {
    return make({
        .name = "onTertiary",
        .palette = pal(&Scheme::tertiaryPalette),
        .background = roleFn(&tertiary),
        .contrast = curveOf(6),
    });
}

Color extTertiaryContainer() {
    return make({
        .name = "tertiaryContainer",
        .palette = pal(&Scheme::tertiaryPalette),
        .tone =
            [](const Scheme& s) {
                return tertiaryContainerToneFor2025(s);
            },
        .isBackground = true,
        .background = highestSurfaceFn(),
        .contrast = curveWhenContrast(1.5),
    });
}

Color extOnTertiaryContainer() {
    return make({
        .name = "onTertiaryContainer",
        .palette = pal(&Scheme::tertiaryPalette),
        .background = roleFn(&tertiaryContainer),
        .contrast = curveOf(6),
    });
}

Color extTertiaryFixed() {
    return make({
        .name = "tertiaryFixed",
        .palette = pal(&Scheme::tertiaryPalette),
        .tone =
            [](const Scheme& s) {
                return tertiaryContainer().toneOf(lightAtZeroContrast(s));
            },
        .isBackground = true,
        .background = highestSurfaceFn(),
        .contrast = curveWhenContrast(1.5),
    });
}

Color extTertiaryFixedDim() {
    return make({
        .name = "tertiaryFixedDim",
        .palette = pal(&Scheme::tertiaryPalette),
        .tone =
            [](const Scheme& s) {
                return tertiaryFixed().toneOf(s);
            },
        .isBackground = true,
        .pair = pairOf(&tertiaryFixedDim, &tertiaryFixed, 5, Polarity::Darker, true, Constraint::Exact),
    });
}

Color extOnTertiaryFixed() {
    return make({
        .name = "onTertiaryFixed",
        .palette = pal(&Scheme::tertiaryPalette),
        .background = roleFn(&tertiaryFixedDim),
        .contrast = curveOf(7),
    });
}

Color extOnTertiaryFixedVariant() {
    return make({
        .name = "onTertiaryFixedVariant",
        .palette = pal(&Scheme::tertiaryPalette),
        .background = roleFn(&tertiaryFixedDim),
        .contrast = curveOf(4.5),
    });
}

Color extError() {
    return make({
        .name = "error",
        .palette = pal(&Scheme::errorPalette),
        .tone =
            [](const Scheme& s) {
                return errorToneFor2025(s);
            },
        .isBackground = true,
        .background = highestSurfaceFn(),
        .contrast = curveOf(4.5),
        .pair = pairOf(&errorContainer, &error, 5, Polarity::RelativeLighter, true, Constraint::Farther),
    });
}

Color extErrorDim() {
    return make({
        .name = "errorDim",
        .palette = pal(&Scheme::errorPalette),
        .tone =
            [](const Scheme& s) {
                return tMinC(s.errorPalette);
            },
        .isBackground = true,
        .background = roleFn(&surfaceContainerHigh),
        .contrast = curveOf(4.5),
        .pair = pairOf(&errorDim, &error, 5, Polarity::Darker, true, Constraint::Farther),
    });
}

Color extOnError() {
    return make({
        .name = "onError",
        .palette = pal(&Scheme::errorPalette),
        .background = roleFn(&error),
        .contrast = curveOf(6),
    });
}

Color extErrorContainer() {
    return make({
        .name = "errorContainer",
        .palette = pal(&Scheme::errorPalette),
        .tone =
            [](const Scheme& s) {
                return errorContainerToneFor2025(s);
            },
        .isBackground = true,
        .background = highestSurfaceFn(),
        .contrast = curveWhenContrast(1.5),
    });
}

Color extOnErrorContainer() {
    return make({
        .name = "onErrorContainer",
        .palette = pal(&Scheme::errorPalette),
        .background = roleFn(&errorContainer),
        .contrast = curveOf(4.5),
    });
}

// NOLINTEND(clang-analyzer-cplusplus.NewDeleteLeaks)

} // namespace

// --- Public roles ----------------------------------------------------------------------------

Color highestSurface(const Scheme& scheme) {
    return scheme.isDark ? surfaceBright() : surfaceDim();
}

// The roles the 2025 spec overrides merge the 2021 definition with the 2025 one
Color background() {
    return extend(origBackground(), cloneAs(surface(), "background"));
}

Color onBackground() {
    Color ext = cloneAs(onSurface(), "onBackground");
    ext.tone = [](const Scheme& s) {
        return onSurface().toneOf(s);
    };
    return extend(origOnBackground(), ext);
}

Color surface() {
    return extend(origSurface(), extSurface());
}

Color surfaceDim() {
    return extend(origSurfaceDim(), extSurfaceDim());
}

Color surfaceBright() {
    return extend(origSurfaceBright(), extSurfaceBright());
}

Color surfaceContainerLowest() {
    return extend(origSurfaceContainerLowest(), extSurfaceContainerLowest());
}

Color surfaceContainerLow() {
    return extend(origSurfaceContainerLow(), extSurfaceContainerLow());
}

Color surfaceContainer() {
    return extend(origSurfaceContainer(), extSurfaceContainer());
}

Color surfaceContainerHigh() {
    return extend(origSurfaceContainerHigh(), extSurfaceContainerHigh());
}

Color surfaceContainerHighest() {
    return extend(origSurfaceContainerHighest(), extSurfaceContainerHighest());
}

Color onSurface() {
    return extend(origOnSurface(), extOnSurface());
}

Color surfaceVariant() {
    return extend(origSurfaceVariant(), cloneAs(surfaceContainerHighest(), "surfaceVariant"));
}

Color onSurfaceVariant() {
    return extend(origOnSurfaceVariant(), extOnSurfaceVariant());
}

Color inverseSurface() {
    return extend(origInverseSurface(), extInverseSurface());
}

Color inverseOnSurface() {
    return extend(origInverseOnSurface(), extInverseOnSurface());
}

Color outline() {
    return extend(origOutline(), extOutline());
}

Color outlineVariant() {
    return extend(origOutlineVariant(), extOutlineVariant());
}

Color shadow() {
    return origShadow();
}

Color scrim() {
    return origScrim();
}

Color surfaceTint() {
    return extend(origSurfaceTint(), cloneAs(primary(), "surfaceTint"));
}

Color primary() {
    return extend(origPrimary(), extPrimary());
}

Color primaryDim() {
    return extPrimaryDim();
}

Color onPrimary() {
    return extend(origOnPrimary(), extOnPrimary());
}

Color primaryContainer() {
    return extend(origPrimaryContainer(), extPrimaryContainer());
}

Color onPrimaryContainer() {
    return extend(origOnPrimaryContainer(), extOnPrimaryContainer());
}

Color inversePrimary() {
    return extend(origInversePrimary(), extInversePrimary());
}

Color primaryFixed() {
    return extend(origPrimaryFixed(), extPrimaryFixed());
}

Color primaryFixedDim() {
    return extend(origPrimaryFixedDim(), extPrimaryFixedDim());
}

Color onPrimaryFixed() {
    return extend(origOnPrimaryFixed(), extOnPrimaryFixed());
}

Color onPrimaryFixedVariant() {
    return extend(origOnPrimaryFixedVariant(), extOnPrimaryFixedVariant());
}

Color secondary() {
    return extend(origSecondary(), extSecondary());
}

Color secondaryDim() {
    return extSecondaryDim();
}

Color onSecondary() {
    return extend(origOnSecondary(), extOnSecondary());
}

Color secondaryContainer() {
    return extend(origSecondaryContainer(), extSecondaryContainer());
}

Color onSecondaryContainer() {
    return extend(origOnSecondaryContainer(), extOnSecondaryContainer());
}

Color secondaryFixed() {
    return extend(origSecondaryFixed(), extSecondaryFixed());
}

Color secondaryFixedDim() {
    return extend(origSecondaryFixedDim(), extSecondaryFixedDim());
}

Color onSecondaryFixed() {
    return extend(origOnSecondaryFixed(), extOnSecondaryFixed());
}

Color onSecondaryFixedVariant() {
    return extend(origOnSecondaryFixedVariant(), extOnSecondaryFixedVariant());
}

Color tertiary() {
    return extend(origTertiary(), extTertiary());
}

Color tertiaryDim() {
    return extTertiaryDim();
}

Color onTertiary() {
    return extend(origOnTertiary(), extOnTertiary());
}

Color tertiaryContainer() {
    return extend(origTertiaryContainer(), extTertiaryContainer());
}

Color onTertiaryContainer() {
    return extend(origOnTertiaryContainer(), extOnTertiaryContainer());
}

Color tertiaryFixed() {
    return extend(origTertiaryFixed(), extTertiaryFixed());
}

Color tertiaryFixedDim() {
    return extend(origTertiaryFixedDim(), extTertiaryFixedDim());
}

Color onTertiaryFixed() {
    return extend(origOnTertiaryFixed(), extOnTertiaryFixed());
}

Color onTertiaryFixedVariant() {
    return extend(origOnTertiaryFixedVariant(), extOnTertiaryFixedVariant());
}

Color error() {
    return extend(origError(), extError());
}

Color errorDim() {
    return extErrorDim();
}

Color onError() {
    return extend(origOnError(), extOnError());
}

Color errorContainer() {
    return extend(origErrorContainer(), extErrorContainer());
}

Color onErrorContainer() {
    return extend(origOnErrorContainer(), extOnErrorContainer());
}

Color primaryPaletteKeyColor() {
    return origPrimaryPaletteKeyColor();
}

Color secondaryPaletteKeyColor() {
    return origSecondaryPaletteKeyColor();
}

Color tertiaryPaletteKeyColor() {
    return origTertiaryPaletteKeyColor();
}

Color neutralPaletteKeyColor() {
    return origNeutralPaletteKeyColor();
}

Color neutralVariantPaletteKeyColor() {
    return origNeutralVariantPaletteKeyColor();
}

Color errorPaletteKeyColor() {
    return origErrorPaletteKeyColor();
}

const std::vector<Entry>& all() {
    static const std::vector<Entry> k_entries = {
        { .name = "background", .make = &background },
        { .name = "onBackground", .make = &onBackground },
        { .name = "surface", .make = &surface },
        { .name = "surfaceDim", .make = &surfaceDim },
        { .name = "surfaceBright", .make = &surfaceBright },
        { .name = "surfaceContainerLowest", .make = &surfaceContainerLowest },
        { .name = "surfaceContainerLow", .make = &surfaceContainerLow },
        { .name = "surfaceContainer", .make = &surfaceContainer },
        { .name = "surfaceContainerHigh", .make = &surfaceContainerHigh },
        { .name = "surfaceContainerHighest", .make = &surfaceContainerHighest },
        { .name = "onSurface", .make = &onSurface },
        { .name = "surfaceVariant", .make = &surfaceVariant },
        { .name = "onSurfaceVariant", .make = &onSurfaceVariant },
        { .name = "outline", .make = &outline },
        { .name = "outlineVariant", .make = &outlineVariant },
        { .name = "inverseSurface", .make = &inverseSurface },
        { .name = "inverseOnSurface", .make = &inverseOnSurface },
        { .name = "shadow", .make = &shadow },
        { .name = "scrim", .make = &scrim },
        { .name = "surfaceTint", .make = &surfaceTint },
        { .name = "primary", .make = &primary },
        { .name = "primaryDim", .make = &primaryDim },
        { .name = "onPrimary", .make = &onPrimary },
        { .name = "primaryContainer", .make = &primaryContainer },
        { .name = "onPrimaryContainer", .make = &onPrimaryContainer },
        { .name = "inversePrimary", .make = &inversePrimary },
        { .name = "primaryFixed", .make = &primaryFixed },
        { .name = "primaryFixedDim", .make = &primaryFixedDim },
        { .name = "onPrimaryFixed", .make = &onPrimaryFixed },
        { .name = "onPrimaryFixedVariant", .make = &onPrimaryFixedVariant },
        { .name = "secondary", .make = &secondary },
        { .name = "secondaryDim", .make = &secondaryDim },
        { .name = "onSecondary", .make = &onSecondary },
        { .name = "secondaryContainer", .make = &secondaryContainer },
        { .name = "onSecondaryContainer", .make = &onSecondaryContainer },
        { .name = "secondaryFixed", .make = &secondaryFixed },
        { .name = "secondaryFixedDim", .make = &secondaryFixedDim },
        { .name = "onSecondaryFixed", .make = &onSecondaryFixed },
        { .name = "onSecondaryFixedVariant", .make = &onSecondaryFixedVariant },
        { .name = "tertiary", .make = &tertiary },
        { .name = "tertiaryDim", .make = &tertiaryDim },
        { .name = "onTertiary", .make = &onTertiary },
        { .name = "tertiaryContainer", .make = &tertiaryContainer },
        { .name = "onTertiaryContainer", .make = &onTertiaryContainer },
        { .name = "tertiaryFixed", .make = &tertiaryFixed },
        { .name = "tertiaryFixedDim", .make = &tertiaryFixedDim },
        { .name = "onTertiaryFixed", .make = &onTertiaryFixed },
        { .name = "onTertiaryFixedVariant", .make = &onTertiaryFixedVariant },
        { .name = "error", .make = &error },
        { .name = "errorDim", .make = &errorDim },
        { .name = "onError", .make = &onError },
        { .name = "errorContainer", .make = &errorContainer },
        { .name = "onErrorContainer", .make = &onErrorContainer },
        { .name = "primaryPaletteKeyColor", .make = &primaryPaletteKeyColor },
        { .name = "secondaryPaletteKeyColor", .make = &secondaryPaletteKeyColor },
        { .name = "tertiaryPaletteKeyColor", .make = &tertiaryPaletteKeyColor },
        { .name = "neutralPaletteKeyColor", .make = &neutralPaletteKeyColor },
        { .name = "neutralVariantPaletteKeyColor", .make = &neutralVariantPaletteKeyColor },
        { .name = "errorPaletteKeyColor", .make = &errorPaletteKeyColor },
    };
    return k_entries;
}

} // namespace caelestia::material::roles
