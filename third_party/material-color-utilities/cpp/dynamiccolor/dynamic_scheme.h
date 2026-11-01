/*
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef CPP_DYNAMICCOLOR_DYNAMIC_SCHEME_H_
#define CPP_DYNAMICCOLOR_DYNAMIC_SCHEME_H_

#include <optional>
#include <vector>

#include "cpp/cam/hct.h"
#include "cpp/dynamiccolor/variant.h"
#include "cpp/palettes/tones.h"
#include "cpp/utils/utils.h"

namespace material_color_utilities {

struct DynamicScheme {
  Hct source_color_hct;
  Variant variant;
  bool is_dark;
  double contrast_level;

  TonalPalette primary_palette;
  TonalPalette secondary_palette;
  TonalPalette tertiary_palette;
  TonalPalette neutral_palette;
  TonalPalette neutral_variant_palette;
  TonalPalette error_palette;

  DynamicScheme(Hct source_color_hct, Variant variant, double contrast_level,
                bool is_dark, TonalPalette primary_palette,
                TonalPalette secondary_palette, TonalPalette tertiary_palette,
                TonalPalette neutral_palette,
                TonalPalette neutral_variant_palette,
                std::optional<TonalPalette> error_palette = std::nullopt);

  static double GetRotatedHue(Hct source_color, std::vector<double> hues,
                              std::vector<double> rotations);

  Argb SourceColorArgb() const;

  Argb GetPrimaryPaletteKeyColor() const;
  Argb GetSecondaryPaletteKeyColor() const;
  Argb GetTertiaryPaletteKeyColor() const;
  Argb GetNeutralPaletteKeyColor() const;
  Argb GetNeutralVariantPaletteKeyColor() const;
  Argb GetBackground() const;
  Argb GetOnBackground() const;
  Argb GetSurface() const;
  Argb GetSurfaceDim() const;
  Argb GetSurfaceBright() const;
  Argb GetSurfaceContainerLowest() const;
  Argb GetSurfaceContainerLow() const;
  Argb GetSurfaceContainer() const;
  Argb GetSurfaceContainerHigh() const;
  Argb GetSurfaceContainerHighest() const;
  Argb GetOnSurface() const;
  Argb GetSurfaceVariant() const;
  Argb GetOnSurfaceVariant() const;
  Argb GetInverseSurface() const;
  Argb GetInverseOnSurface() const;
  Argb GetOutline() const;
  Argb GetOutlineVariant() const;
  Argb GetShadow() const;
  Argb GetScrim() const;
  Argb GetSurfaceTint() const;
  Argb GetPrimary() const;
  Argb GetOnPrimary() const;
  Argb GetPrimaryContainer() const;
  Argb GetOnPrimaryContainer() const;
  Argb GetInversePrimary() const;
  Argb GetSecondary() const;
  Argb GetOnSecondary() const;
  Argb GetSecondaryContainer() const;
  Argb GetOnSecondaryContainer() const;
  Argb GetTertiary() const;
  Argb GetOnTertiary() const;
  Argb GetTertiaryContainer() const;
  Argb GetOnTertiaryContainer() const;
  Argb GetError() const;
  Argb GetOnError() const;
  Argb GetErrorContainer() const;
  Argb GetOnErrorContainer() const;
  Argb GetPrimaryFixed() const;
  Argb GetPrimaryFixedDim() const;
  Argb GetOnPrimaryFixed() const;
  Argb GetOnPrimaryFixedVariant() const;
  Argb GetSecondaryFixed() const;
  Argb GetSecondaryFixedDim() const;
  Argb GetOnSecondaryFixed() const;
  Argb GetOnSecondaryFixedVariant() const;
  Argb GetTertiaryFixed() const;
  Argb GetTertiaryFixedDim() const;
  Argb GetOnTertiaryFixed() const;
  Argb GetOnTertiaryFixedVariant() const;
};

}  // namespace material_color_utilities

#endif  // CPP_DYNAMICCOLOR_DYNAMIC_SCHEME_H_
