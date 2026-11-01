#include "generator.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdlib>
#include <format>
#include <map>
#include <memory>
#include <optional>

#include "cpp/cam/cam.h"
#include "cpp/quantize/celebi.h"
#include "color_utils.hpp"
#include "roles.hpp"

namespace caelestia::material {

namespace {

using material_color_utilities::CamFromIntAndViewingConditions;
using material_color_utilities::CamFromUcsAndViewingConditions;

// The CLI's hex_to_hct: a six digit colour with full alpha
Hct hexToHct(const char* hex) {
    return Hct(0xFF000000u | static_cast<Argb>(std::strtoul(hex, nullptr, 16)));
}

const std::array<Hct, 16>& lightGruvbox() {
    static const std::array<Hct, 16> k_colours = {
        hexToHct("FDF9F3"),
        hexToHct("FF6188"),
        hexToHct("A9DC76"),
        hexToHct("FC9867"),
        hexToHct("FFD866"),
        hexToHct("F47FD4"),
        hexToHct("78DCE8"),
        hexToHct("333034"),
        hexToHct("121212"),
        hexToHct("FF6188"),
        hexToHct("A9DC76"),
        hexToHct("FC9867"),
        hexToHct("FFD866"),
        hexToHct("F47FD4"),
        hexToHct("78DCE8"),
        hexToHct("333034"),
    };
    return k_colours;
}

const std::array<Hct, 16>& darkGruvbox() {
    static const std::array<Hct, 16> k_colours = {
        hexToHct("282828"),
        hexToHct("CC241D"),
        hexToHct("98971A"),
        hexToHct("D79921"),
        hexToHct("458588"),
        hexToHct("B16286"),
        hexToHct("689D6A"),
        hexToHct("A89984"),
        hexToHct("928374"),
        hexToHct("FB4934"),
        hexToHct("B8BB26"),
        hexToHct("FABD2F"),
        hexToHct("83A598"),
        hexToHct("D3869B"),
        hexToHct("8EC07C"),
        hexToHct("EBDBB2"),
    };
    return k_colours;
}

const std::array<Hct, 14>& lightCatppuccin() {
    static const std::array<Hct, 14> k_colours = {
        hexToHct("dc8a78"),
        hexToHct("dd7878"),
        hexToHct("ea76cb"),
        hexToHct("8839ef"),
        hexToHct("d20f39"),
        hexToHct("e64553"),
        hexToHct("fe640b"),
        hexToHct("df8e1d"),
        hexToHct("40a02b"),
        hexToHct("179299"),
        hexToHct("04a5e5"),
        hexToHct("209fb5"),
        hexToHct("1e66f5"),
        hexToHct("7287fd"),
    };
    return k_colours;
}

const std::array<Hct, 14>& darkCatppuccin() {
    static const std::array<Hct, 14> k_colours = {
        hexToHct("f5e0dc"),
        hexToHct("f2cdcd"),
        hexToHct("f5c2e7"),
        hexToHct("cba6f7"),
        hexToHct("f38ba8"),
        hexToHct("eba0ac"),
        hexToHct("fab387"),
        hexToHct("f9e2af"),
        hexToHct("a6e3a1"),
        hexToHct("94e2d5"),
        hexToHct("89dceb"),
        hexToHct("74c7ec"),
        hexToHct("89b4fa"),
        hexToHct("b4befe"),
    };
    return k_colours;
}

struct KColour {
    const char* name;
    Hct hct;
};

const std::array<KColour, 5>& kColours() {
    static const std::array<KColour, 5> k_colours = {
        {
            { .name = "klink", .hct = hexToHct("2980b9") },
            { .name = "kvisited", .hct = hexToHct("9b59b6") },
            { .name = "knegative", .hct = hexToHct("da4453") },
            { .name = "kneutral", .hct = hexToHct("f67400") },
            { .name = "kpositive", .hct = hexToHct("27ae60") },
        },
    };
    return k_colours;
}

const std::array<const char*, 14>& colourNames() {
    static const std::array<const char*, 14> k_names = {
        "rosewater",
        "flamingo",
        "pink",
        "mauve",
        "red",
        "maroon",
        "peach",
        "yellow",
        "green",
        "teal",
        "sky",
        "sapphire",
        "blue",
        "lavender",
    };
    return k_names;
}

Variant variantOf(const std::string& name) {
    if (name == "content")
        return Variant::Content;
    if (name == "expressive")
        return Variant::Expressive;
    if (name == "fidelity")
        return Variant::Fidelity;
    if (name == "fruitsalad")
        return Variant::FruitSalad;
    if (name == "monochrome")
        return Variant::Monochrome;
    if (name == "neutral")
        return Variant::Neutral;
    if (name == "rainbow")
        return Variant::Rainbow;
    if (name == "tonalspot")
        return Variant::TonalSpot;
    return Variant::Vibrant;
}

// Python difference_degrees and rotation_direction (materialyoucolor utils)
double differenceDegrees(double a, double b) {
    return 180.0 - std::fabs(std::fabs(a - b) - 180.0);
}

double rotationDirection(double from, double to) {
    const double increasing = sanitizeDegrees(to - from);
    return increasing <= 180.0 ? 1.0 : -1.0;
}

// The CLI's harmonize: shifts a colour's hue towards another's, and scales its tone
Hct harmonize(const Hct& from, const Hct& to, double toneBoost) {
    const double rotation = std::min(differenceDegrees(from.get_hue(), to.get_hue()) * 0.8, 100.0);
    const double outputHue =
        sanitizeDegrees(from.get_hue() + rotation * rotationDirection(from.get_hue(), to.get_hue()));
    return { outputHue, from.get_chroma(), from.get_tone() * (1 + toneBoost) };
}

Hct lighten(const Hct& colour, double amount) {
    const double diff = (100 - colour.get_tone()) * amount;
    return { colour.get_hue(), colour.get_chroma() + diff / 5, colour.get_tone() + diff };
}

Hct darken(const Hct& colour, double amount) {
    const double diff = colour.get_tone() * amount;
    return { colour.get_hue(), colour.get_chroma() - diff / 5, colour.get_tone() - diff };
}

Hct grayscale(const Hct& colour, bool light) {
    const Hct shifted = light ? darken(colour, 0.35) : lighten(colour, 0.65);
    return { shifted.get_hue(), 0, shifted.get_tone() };
}

// Blend.cam16_ucs: blends two colours in CAM16-UCS space
Argb cam16Ucs(Argb from, Argb to, double amount) {
    const auto& viewing = material_color_utilities::kDefaultViewingConditions;
    const auto fromCam = CamFromIntAndViewingConditions(from, viewing);
    const auto toCam = CamFromIntAndViewingConditions(to, viewing);
    const double jstar = fromCam.jstar + (toCam.jstar - fromCam.jstar) * amount;
    const double astar = fromCam.astar + (toCam.astar - fromCam.astar) * amount;
    const double bstar = fromCam.bstar + (toCam.bstar - fromCam.bstar) * amount;
    return argbFromCam(CamFromUcsAndViewingConditions(jstar, astar, bstar, viewing), viewing);
}

Hct mix(const Hct& a, const Hct& b, double weight) {
    return Hct(cam16Ucs(a.ToInt(), b.ToInt(), weight));
}

// The CLI writes colours as the six hex digits after the alpha byte
std::string hexOf(Argb argb) {
    return std::format("{:06x}", argb & 0xFFFFFFu);
}

int sanitizeIntDegrees(int degrees) {
    return ((degrees % 360) + 360) % 360;
}

} // namespace

// Kept in the order of the CLI's gen_scheme, which it's checked against step by step
// NOLINTNEXTLINE(readability-function-cognitive-complexity)
Colours generateScheme(const GeneratorOptions& options, const Hct& primary) {
    const bool isLight = options.light;
    const bool isMonochrome = options.variant == "monochrome";
    const bool isNeutral = options.variant == "neutral";
    const bool isHard = options.flavour == "hard";

    // A colour slot. Aliases (the CLI's shared colour entries) point at the same slot, so the
    // in-place chroma change for neutral schemes reaches each name that shares it.
    using Slot = std::shared_ptr<Hct>;
    std::map<std::string, Slot> colours;
    auto const put = [&colours](const std::string& key, const Hct& value) {
        colours[key] = std::make_shared<Hct>(value);
    };
    auto const at = [&colours](const std::string& key) -> Hct {
        return *colours.at(key);
    };
    auto const alias = [&colours](const std::string& key, const std::string& from) {
        colours[key] = colours.at(from);
    };

    // Material colours
    const Scheme scheme(primary, variantOf(options.variant), 0.0, !isLight, SpecVersion::V2025);
    for (const auto& entry : roles::all()) {
        put(std::string(entry.name), entry.make().hct(scheme));
    }

    // Backwards compatibility with the old colour names
    alias("primary_paletteKeyColor", "primaryPaletteKeyColor");
    alias("secondary_paletteKeyColor", "secondaryPaletteKeyColor");
    alias("tertiary_paletteKeyColor", "tertiaryPaletteKeyColor");
    alias("neutral_paletteKeyColor", "neutralPaletteKeyColor");
    alias("neutral_variant_paletteKeyColor", "neutralVariantPaletteKeyColor");

    // Harmonize terminal colours
    const auto& gruvbox = isLight ? lightGruvbox() : darkGruvbox();
    for (int i = 0; i < 16; ++i) {
        const Hct& hct = gruvbox[static_cast<size_t>(i)];
        const std::string key = "term" + std::to_string(i);
        if (isMonochrome) {
            put(key, grayscale(hct, isLight));
        } else {
            const double boost = (i < 8 ? 0.35 : 0.2) * (isLight ? -1 : 1);
            put(key, harmonize(hct, at("primary_paletteKeyColor"), boost));
        }
    }

    // Harmonize named colours
    const auto& catppuccin = isLight ? lightCatppuccin() : darkCatppuccin();
    for (size_t i = 0; i < catppuccin.size(); ++i) {
        const std::string key = colourNames()[i];
        if (isMonochrome) {
            put(key, grayscale(catppuccin[i], isLight));
        } else {
            put(key, harmonize(catppuccin[i], at("primary_paletteKeyColor"), isLight ? -0.2 : 0.05));
        }
    }

    // Kolours
    for (const auto& kColour : kColours()) {
        const std::string name = kColour.name;
        put(name, harmonize(kColour.hct, at("primary"), 0.1));
        put(name + "Selection", harmonize(kColour.hct, at("onPrimaryFixedVariant"), 0.1));
        if (isMonochrome) {
            put(name, grayscale(at(name), isLight));
            put(name + "Selection", grayscale(at(name + "Selection"), isLight));
        }
    }

    if (isNeutral) {
        for (auto const& entry : colours) {
            const Hct current = *entry.second;
            *entry.second = Hct(current.get_hue(), current.get_chroma() - 15, current.get_tone());
        }
    }

    // Darken surfaces for hard flavour
    if (isHard) {
        std::vector<std::string> names = { "background" };
        for (const auto& entry : colours) {
            if (entry.first.starts_with("surface"))
                names.push_back(entry.first);
        }
        for (const auto& name : names) {
            put(name, isLight ? lighten(at(name), 0.4) : darken(at(name), 0.8));
        }
        put("term0", isLight ? lighten(at("term0"), 0.4) : darken(at("term0"), 0.9));
    }

    // Deprecated names
    alias("text", "onBackground");
    alias("subtext1", "onSurfaceVariant");
    alias("subtext0", "outline");
    put("overlay2", mix(at("surface"), at("outline"), 0.86));
    put("overlay1", mix(at("surface"), at("outline"), 0.71));
    put("overlay0", mix(at("surface"), at("outline"), 0.57));
    put("surface2", mix(at("surface"), at("outline"), 0.43));
    put("surface1", mix(at("surface"), at("outline"), 0.29));
    put("surface0", mix(at("surface"), at("outline"), 0.14));
    alias("base", "surface");
    put("mantle", darken(at("surface"), 0.03));
    put("crust", darken(at("surface"), 0.05));

    // More darkening for hard flavour
    if (isHard) {
        for (const char* name : { "base", "mantle", "crust" }) {
            put(name, isLight ? lighten(at(name), 0.4) : darken(at(name), 0.9));
        }
        for (int i = 0; i < 3; ++i) {
            const std::string overlay = "overlay" + std::to_string(i);
            const std::string surface = "surface" + std::to_string(i);
            put(overlay, isLight ? lighten(at(overlay), 0.4) : darken(at(overlay), 0.8));
            put(surface, isLight ? lighten(at(surface), 0.4) : darken(at(surface), 0.8));
        }
    }

    Colours out;
    for (const auto& entry : colours) {
        out[entry.first] = hexOf(entry.second->ToInt());
    }

    // Extended material
    if (isLight) {
        out["success"] = "4F6354";
        out["onSuccess"] = "FFFFFF";
        out["successContainer"] = "D1E8D5";
        out["onSuccessContainer"] = "0C1F13";
    } else {
        out["success"] = "B5CCBA";
        out["onSuccess"] = "213528";
        out["successContainer"] = "374B3E";
        out["onSuccessContainer"] = "D1E9D6";
    }
    return out;
}

Hct scoreColours(const std::vector<std::pair<Argb, uint32_t>>& colorsToPopulation, bool filterEnabled) {
    std::vector<Hct> colorsHct;
    colorsHct.reserve(colorsToPopulation.size());
    std::array<uint64_t, 360> huePopulation{};
    uint64_t populationSum = 0;

    for (const auto& [argb, population] : colorsToPopulation) {
        const Hct hct(argb);
        colorsHct.push_back(hct);
        huePopulation[static_cast<size_t>(hct.get_hue())] += population;
        populationSum += population;
    }

    std::array<double, 360> huePopulationExcited{};
    for (int hue = 0; hue < 360; ++hue) {
        const double proportion =
            static_cast<double>(huePopulation[static_cast<size_t>(hue)]) / static_cast<double>(populationSum);
        for (int i = hue - 14; i < hue + 16; ++i) {
            huePopulationExcited[static_cast<size_t>(sanitizeIntDegrees(i))] += proportion;
        }
    }

    struct Scored {
        Hct hct;
        double score;
    };

    std::vector<Scored> scored;
    for (const Hct& hct : colorsHct) {
        const int hue = sanitizeIntDegrees(static_cast<int>(roundHalfEven(hct.get_hue())));
        const double proportion = huePopulationExcited[static_cast<size_t>(hue)];
        if (filterEnabled && (hct.get_chroma() < 5.0 || proportion <= 0.01))
            continue;

        const double proportionScore = proportion * 100.0 * 0.7;
        const double chromaWeight = hct.get_chroma() < 48.0 ? 0.1 : 0.3;
        const double chromaScore = (hct.get_chroma() - 48.0) * chromaWeight;
        scored.push_back({ .hct = hct, .score = proportionScore + chromaScore });
    }
    std::ranges::stable_sort(scored, [](const Scored& a, const Scored& b) {
        return a.score > b.score;
    });

    std::optional<Hct> primary;
    for (int cutoff = 20; cutoff >= 0 && !primary; --cutoff) {
        for (const Scored& item : scored) {
            if (item.hct.get_chroma() > cutoff && item.hct.get_tone() > cutoff * 3) {
                primary = item.hct;
                break;
            }
        }
    }

    if (primary)
        return dislikeFixed(*primary);
    // Python retries without the filter here. Without a filter and no chromatic colour, the CLI's
    // recursion never ends, so this returns a neutral grey instead.
    if (filterEnabled)
        return scoreColours(colorsToPopulation, false);
    return { 0.0, 0.0, 50.0 };
}

Hct scoreImagePixels(const std::vector<Argb>& pixels) {
    std::vector<Argb> opaque;
    opaque.reserve(pixels.size());
    for (const Argb pixel : pixels)
        opaque.push_back(0xFF000000u | (pixel & 0xFFFFFFu));

    const auto result = material_color_utilities::QuantizeCelebi(opaque, 128);
    std::vector<std::pair<Argb, uint32_t>> const population(result.color_to_count.begin(), result.color_to_count.end());
    return scoreColours(population, false);
}

} // namespace caelestia::material
