#pragma once

// Port of the caelestia CLI's colour generation (caelestia/utils/material): the Material scheme of
// an image's primary colour, plus the terminal, named and extended colours that go with it.

#include <cstdint>
#include <map>
#include <string>
#include <utility>
#include <vector>

#include "dynamic.hpp"

namespace caelestia::material {

struct GeneratorOptions {
    std::string variant =
        "tonalspot"; // content, expressive, fidelity, fruitsalad, monochrome, neutral, rainbow, tonalspot, vibrant
    std::string flavour = "default"; // "hard" darkens or lightens the surfaces further
    bool light = false;
};

// Colour name -> six lowercase hex digits, as the CLI writes them
using Colours = std::map<std::string, std::string>;

// The scheme's colours for a primary colour (the CLI's gen_scheme)
Colours generateScheme(const GeneratorOptions& options, const Hct& primary);

// The primary colour of an image's pixels (the CLI's Score, over an ImageQuantizeCelebi result).
// `pixels` are ARGB; the alpha channel is ignored.
Hct scoreImagePixels(const std::vector<Argb>& pixels);

// Score of an already quantised population, { argb, count }
Hct scoreColours(const std::vector<std::pair<Argb, uint32_t>>& colorsToPopulation, bool filterEnabled = false);

} // namespace caelestia::material
