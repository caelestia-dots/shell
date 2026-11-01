#pragma once

// Analogous and complementary colours by colour temperature: a port of materialyoucolor 3.0.2's
// TemperatureCache, which the Content and Fidelity schemes use. Kept as a port rather than taken
// from material-color-utilities, whose version picks different colours for some inputs.

#include <vector>

#include "dynamic.hpp"

namespace caelestia::material {

class TemperatureCache {
public:
    explicit TemperatureCache(const Hct& input);

    // `count` colours around the input, spread over `divisions` steps of colour temperature
    std::vector<Hct> analogous(int count = 5, int divisions = 12);

    // A colour across the temperature wheel from the input
    Hct complement();

private:
    [[nodiscard]] double relativeTemperature(int index) const;
    static bool isBetween(double angle, double a, double b);

    Hct m_input;
    // Index 0..360 is the colour at that hue (with the input's chroma and tone); 361 is the input
    std::vector<Hct> m_hcts;
    std::vector<double> m_temps;
    // Indices into m_hcts, sorted by temperature (coldest first)
    std::vector<int> m_byTemp;
};

} // namespace caelestia::material
