#pragma once

// The colour roles of Material You (the 59 names of materialyoucolor's MaterialDynamicColors),
// resolved per scheme. Each role is the 2025 definition over the 2021 one where the 2025 spec
// overrides it, as the Python library merges them, so a scheme's spec picks the right one.

#include <string_view>
#include <utility>
#include <vector>

#include "dynamic.hpp"

namespace caelestia::material::roles {

// The background the role `highestSurface` picks for a scheme (surfaceBright when dark)
Color highestSurface(const Scheme& scheme);

Color background();
Color onBackground();
Color surface();
Color surfaceDim();
Color surfaceBright();
Color surfaceContainerLowest();
Color surfaceContainerLow();
Color surfaceContainer();
Color surfaceContainerHigh();
Color surfaceContainerHighest();
Color onSurface();
Color surfaceVariant();
Color onSurfaceVariant();
Color inverseSurface();
Color inverseOnSurface();
Color outline();
Color outlineVariant();
Color shadow();
Color scrim();
Color surfaceTint();
Color primary();
Color primaryDim();
Color onPrimary();
Color primaryContainer();
Color onPrimaryContainer();
Color inversePrimary();
Color primaryFixed();
Color primaryFixedDim();
Color onPrimaryFixed();
Color onPrimaryFixedVariant();
Color secondary();
Color secondaryDim();
Color onSecondary();
Color secondaryContainer();
Color onSecondaryContainer();
Color secondaryFixed();
Color secondaryFixedDim();
Color onSecondaryFixed();
Color onSecondaryFixedVariant();
Color tertiary();
Color tertiaryDim();
Color onTertiary();
Color tertiaryContainer();
Color onTertiaryContainer();
Color tertiaryFixed();
Color tertiaryFixedDim();
Color onTertiaryFixed();
Color onTertiaryFixedVariant();
Color error();
Color errorDim();
Color onError();
Color errorContainer();
Color onErrorContainer();
Color primaryPaletteKeyColor();
Color secondaryPaletteKeyColor();
Color tertiaryPaletteKeyColor();
Color neutralPaletteKeyColor();
Color neutralVariantPaletteKeyColor();
Color errorPaletteKeyColor();

using Maker = Color (*)();

struct Entry {
    std::string_view name;
    Maker make;
};

// All 59 roles, in materialyoucolor's order
const std::vector<Entry>& all();

} // namespace caelestia::material::roles
