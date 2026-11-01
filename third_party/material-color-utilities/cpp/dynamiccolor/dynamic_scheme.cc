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

#include "cpp/dynamiccolor/dynamic_scheme.h"

#include <optional>
#include <vector>

#include "cpp/cam/hct.h"
#include "cpp/dynamiccolor/material_dynamic_colors.h"
#include "cpp/dynamiccolor/variant.h"
#include "cpp/palettes/tones.h"
#include "cpp/utils/utils.h"

namespace material_color_utilities {

DynamicScheme::DynamicScheme(Hct source_color_hct, Variant variant,
                             double contrast_level, bool is_dark,
                             TonalPalette primary_palette,
                             TonalPalette secondary_palette,
                             TonalPalette tertiary_palette,
                             TonalPalette neutral_palette,
                             TonalPalette neutral_variant_palette,
                             std::optional<TonalPalette> error_palette)
    : source_color_hct(source_color_hct),
      variant(variant),
      is_dark(is_dark),
      contrast_level(contrast_level),
      primary_palette(primary_palette),
      secondary_palette(secondary_palette),
      tertiary_palette(tertiary_palette),
      neutral_palette(neutral_palette),
      neutral_variant_palette(neutral_variant_palette),
      error_palette(error_palette.value_or(TonalPalette(25.0, 84.0))) {}

double DynamicScheme::GetRotatedHue(Hct source_color, std::vector<double> hues,
                                    std::vector<double> rotations) {
  double source_hue = source_color.get_hue();

  if (rotations.size() == 1) {
    return SanitizeDegreesDouble(source_color.get_hue() + rotations[0]);
  }
  int size = hues.size();
  for (int i = 0; i <= (size - 2); ++i) {
    double this_hue = hues[i];
    double next_hue = hues[i + 1];
    if (this_hue < source_hue && source_hue < next_hue) {
      return SanitizeDegreesDouble(source_hue + rotations[i]);
    }
  }

  return source_hue;
}

Argb DynamicScheme::SourceColorArgb() const { return source_color_hct.ToInt(); }

Argb DynamicScheme::GetPrimaryPaletteKeyColor() const {
  return MaterialDynamicColors::PrimaryPaletteKeyColor().GetArgb(*this);
}

Argb DynamicScheme::GetSecondaryPaletteKeyColor() const {
  return MaterialDynamicColors::SecondaryPaletteKeyColor().GetArgb(*this);
}

Argb DynamicScheme::GetTertiaryPaletteKeyColor() const {
  return MaterialDynamicColors::TertiaryPaletteKeyColor().GetArgb(*this);
}

Argb DynamicScheme::GetNeutralPaletteKeyColor() const {
  return MaterialDynamicColors::NeutralPaletteKeyColor().GetArgb(*this);
}

Argb DynamicScheme::GetNeutralVariantPaletteKeyColor() const {
  return MaterialDynamicColors::NeutralVariantPaletteKeyColor().GetArgb(*this);
}

Argb DynamicScheme::GetBackground() const {
  return MaterialDynamicColors::Background().GetArgb(*this);
}

Argb DynamicScheme::GetOnBackground() const {
  return MaterialDynamicColors::OnBackground().GetArgb(*this);
}

Argb DynamicScheme::GetSurface() const {
  return MaterialDynamicColors::Surface().GetArgb(*this);
}

Argb DynamicScheme::GetSurfaceDim() const {
  return MaterialDynamicColors::SurfaceDim().GetArgb(*this);
}

Argb DynamicScheme::GetSurfaceBright() const {
  return MaterialDynamicColors::SurfaceBright().GetArgb(*this);
}

Argb DynamicScheme::GetSurfaceContainerLowest() const {
  return MaterialDynamicColors::SurfaceContainerLowest().GetArgb(*this);
}

Argb DynamicScheme::GetSurfaceContainerLow() const {
  return MaterialDynamicColors::SurfaceContainerLow().GetArgb(*this);
}

Argb DynamicScheme::GetSurfaceContainer() const {
  return MaterialDynamicColors::SurfaceContainer().GetArgb(*this);
}

Argb DynamicScheme::GetSurfaceContainerHigh() const {
  return MaterialDynamicColors::SurfaceContainerHigh().GetArgb(*this);
}

Argb DynamicScheme::GetSurfaceContainerHighest() const {
  return MaterialDynamicColors::SurfaceContainerHighest().GetArgb(*this);
}

Argb DynamicScheme::GetOnSurface() const {
  return MaterialDynamicColors::OnSurface().GetArgb(*this);
}

Argb DynamicScheme::GetSurfaceVariant() const {
  return MaterialDynamicColors::SurfaceVariant().GetArgb(*this);
}

Argb DynamicScheme::GetOnSurfaceVariant() const {
  return MaterialDynamicColors::OnSurfaceVariant().GetArgb(*this);
}

Argb DynamicScheme::GetInverseSurface() const {
  return MaterialDynamicColors::InverseSurface().GetArgb(*this);
}

Argb DynamicScheme::GetInverseOnSurface() const {
  return MaterialDynamicColors::InverseOnSurface().GetArgb(*this);
}

Argb DynamicScheme::GetOutline() const {
  return MaterialDynamicColors::Outline().GetArgb(*this);
}

Argb DynamicScheme::GetOutlineVariant() const {
  return MaterialDynamicColors::OutlineVariant().GetArgb(*this);
}

Argb DynamicScheme::GetShadow() const {
  return MaterialDynamicColors::Shadow().GetArgb(*this);
}

Argb DynamicScheme::GetScrim() const {
  return MaterialDynamicColors::Scrim().GetArgb(*this);
}

Argb DynamicScheme::GetSurfaceTint() const {
  return MaterialDynamicColors::SurfaceTint().GetArgb(*this);
}

Argb DynamicScheme::GetPrimary() const {
  return MaterialDynamicColors::Primary().GetArgb(*this);
}

Argb DynamicScheme::GetOnPrimary() const {
  return MaterialDynamicColors::OnPrimary().GetArgb(*this);
}

Argb DynamicScheme::GetPrimaryContainer() const {
  return MaterialDynamicColors::PrimaryContainer().GetArgb(*this);
}

Argb DynamicScheme::GetOnPrimaryContainer() const {
  return MaterialDynamicColors::OnPrimaryContainer().GetArgb(*this);
}

Argb DynamicScheme::GetInversePrimary() const {
  return MaterialDynamicColors::InversePrimary().GetArgb(*this);
}

Argb DynamicScheme::GetSecondary() const {
  return MaterialDynamicColors::Secondary().GetArgb(*this);
}

Argb DynamicScheme::GetOnSecondary() const {
  return MaterialDynamicColors::OnSecondary().GetArgb(*this);
}

Argb DynamicScheme::GetSecondaryContainer() const {
  return MaterialDynamicColors::SecondaryContainer().GetArgb(*this);
}

Argb DynamicScheme::GetOnSecondaryContainer() const {
  return MaterialDynamicColors::OnSecondaryContainer().GetArgb(*this);
}

Argb DynamicScheme::GetTertiary() const {
  return MaterialDynamicColors::Tertiary().GetArgb(*this);
}

Argb DynamicScheme::GetOnTertiary() const {
  return MaterialDynamicColors::OnTertiary().GetArgb(*this);
}

Argb DynamicScheme::GetTertiaryContainer() const {
  return MaterialDynamicColors::TertiaryContainer().GetArgb(*this);
}

Argb DynamicScheme::GetOnTertiaryContainer() const {
  return MaterialDynamicColors::OnTertiaryContainer().GetArgb(*this);
}

Argb DynamicScheme::GetError() const {
  return MaterialDynamicColors::Error().GetArgb(*this);
}

Argb DynamicScheme::GetOnError() const {
  return MaterialDynamicColors::OnError().GetArgb(*this);
}

Argb DynamicScheme::GetErrorContainer() const {
  return MaterialDynamicColors::ErrorContainer().GetArgb(*this);
}

Argb DynamicScheme::GetOnErrorContainer() const {
  return MaterialDynamicColors::OnErrorContainer().GetArgb(*this);
}

Argb DynamicScheme::GetPrimaryFixed() const {
  return MaterialDynamicColors::PrimaryFixed().GetArgb(*this);
}

Argb DynamicScheme::GetPrimaryFixedDim() const {
  return MaterialDynamicColors::PrimaryFixedDim().GetArgb(*this);
}

Argb DynamicScheme::GetOnPrimaryFixed() const {
  return MaterialDynamicColors::OnPrimaryFixed().GetArgb(*this);
}

Argb DynamicScheme::GetOnPrimaryFixedVariant() const {
  return MaterialDynamicColors::OnPrimaryFixedVariant().GetArgb(*this);
}

Argb DynamicScheme::GetSecondaryFixed() const {
  return MaterialDynamicColors::SecondaryFixed().GetArgb(*this);
}

Argb DynamicScheme::GetSecondaryFixedDim() const {
  return MaterialDynamicColors::SecondaryFixedDim().GetArgb(*this);
}

Argb DynamicScheme::GetOnSecondaryFixed() const {
  return MaterialDynamicColors::OnSecondaryFixed().GetArgb(*this);
}

Argb DynamicScheme::GetOnSecondaryFixedVariant() const {
  return MaterialDynamicColors::OnSecondaryFixedVariant().GetArgb(*this);
}

Argb DynamicScheme::GetTertiaryFixed() const {
  return MaterialDynamicColors::TertiaryFixed().GetArgb(*this);
}

Argb DynamicScheme::GetTertiaryFixedDim() const {
  return MaterialDynamicColors::TertiaryFixedDim().GetArgb(*this);
}

Argb DynamicScheme::GetOnTertiaryFixed() const {
  return MaterialDynamicColors::OnTertiaryFixed().GetArgb(*this);
}

Argb DynamicScheme::GetOnTertiaryFixedVariant() const {
  return MaterialDynamicColors::OnTertiaryFixedVariant().GetArgb(*this);
}

}  // namespace material_color_utilities
