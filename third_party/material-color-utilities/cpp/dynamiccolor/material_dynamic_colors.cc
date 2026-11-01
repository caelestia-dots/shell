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

#include "cpp/dynamiccolor/material_dynamic_colors.h"

#include <cmath>

#include "cpp/cam/cam.h"
#include "cpp/cam/hct.h"
#include "cpp/dislike/dislike.h"
#include "cpp/dynamiccolor/contrast_curve.h"
#include "cpp/dynamiccolor/dynamic_color.h"
#include "cpp/dynamiccolor/dynamic_scheme.h"
#include "cpp/dynamiccolor/tone_delta_pair.h"
#include "cpp/dynamiccolor/variant.h"
#include "cpp/utils/utils.h"

namespace material_color_utilities {

using std::nullopt;

bool IsFidelity(const DynamicScheme& scheme) {
  return scheme.variant == Variant::kFidelity ||
         scheme.variant == Variant::kContent;
}

bool IsMonochrome(const DynamicScheme& scheme) {
  return scheme.variant == Variant::kMonochrome;
}

Vec3 XyzInViewingConditions(Cam cam, ViewingConditions viewing_conditions) {
  double alpha = (cam.chroma == 0.0 || cam.j == 0.0)
                     ? 0.0
                     : cam.chroma / sqrt(cam.j / 100.0);

  double t = pow(
      alpha / pow(1.64 - pow(0.29,
                             viewing_conditions.background_y_to_white_point_y),
                  0.73),
      1.0 / 0.9);
  double h_rad = cam.hue * M_PI / 180.0;

  double e_hue = 0.25 * (cos(h_rad + 2.0) + 3.8);
  double ac =
      viewing_conditions.aw *
      pow(cam.j / 100.0, 1.0 / viewing_conditions.c / viewing_conditions.z);
  double p1 = e_hue * (50000.0 / 13.0) * viewing_conditions.n_c *
              viewing_conditions.ncb;

  double p2 = (ac / viewing_conditions.nbb);

  double h_sin = sin(h_rad);
  double h_cos = cos(h_rad);

  double gamma = 23.0 * (p2 + 0.305) * t /
                 (23.0 * p1 + 11 * t * h_cos + 108.0 * t * h_sin);
  double a = gamma * h_cos;
  double b = gamma * h_sin;
  double r_a = (460.0 * p2 + 451.0 * a + 288.0 * b) / 1403.0;
  double g_a = (460.0 * p2 - 891.0 * a - 261.0 * b) / 1403.0;
  double b_a = (460.0 * p2 - 220.0 * a - 6300.0 * b) / 1403.0;

  double r_c_base = fmax(0, (27.13 * fabs(r_a)) / (400.0 - fabs(r_a)));
  double r_c =
      Signum(r_a) * (100.0 / viewing_conditions.fl) * pow(r_c_base, 1.0 / 0.42);
  double g_c_base = fmax(0, (27.13 * fabs(g_a)) / (400.0 - fabs(g_a)));
  double g_c =
      Signum(g_a) * (100.0 / viewing_conditions.fl) * pow(g_c_base, 1.0 / 0.42);
  double b_c_base = fmax(0, (27.13 * fabs(b_a)) / (400.0 - fabs(b_a)));
  double b_c =
      Signum(b_a) * (100.0 / viewing_conditions.fl) * pow(b_c_base, 1.0 / 0.42);
  double r_f = r_c / viewing_conditions.rgb_d[0];
  double g_f = g_c / viewing_conditions.rgb_d[1];
  double b_f = b_c / viewing_conditions.rgb_d[2];

  double x = 1.86206786 * r_f - 1.01125463 * g_f + 0.14918677 * b_f;
  double y = 0.38752654 * r_f + 0.62144744 * g_f - 0.00897398 * b_f;
  double z = -0.01584150 * r_f - 0.03412294 * g_f + 1.04996444 * b_f;

  return {x, y, z};
}

Hct InViewingConditions(Hct hct, ViewingConditions vc) {
  // 1. Use CAM16 to find XYZ coordinates of color in specified VC.
  Cam cam16 = CamFromInt(hct.ToInt());
  Vec3 viewed_in_vc = XyzInViewingConditions(cam16, vc);

  // 2. Create CAM16 of those XYZ coordinates in default VC.
  Cam recast_in_vc =
      CamFromXyzAndViewingConditions(viewed_in_vc.a, viewed_in_vc.b,
                                     viewed_in_vc.c, kDefaultViewingConditions);

  // 3. Create HCT from:
  // - CAM16 using default VC with XYZ coordinates in specified VC.
  // - L* converted from Y in XYZ coordinates in specified VC.
  Hct recast_hct =
      Hct(recast_in_vc.hue, recast_in_vc.chroma, LstarFromY(viewed_in_vc.b));
  return recast_hct;
}

double FindDesiredChromaByTone(double hue, double chroma, double tone,
                               bool by_decreasing_tone) {
  double answer = tone;

  Hct closest_to_chroma = Hct(hue, chroma, tone);
  if (closest_to_chroma.get_chroma() < chroma) {
    double chroma_peak = closest_to_chroma.get_chroma();
    while (closest_to_chroma.get_chroma() < chroma) {
      answer += by_decreasing_tone ? -1.0 : 1.0;
      Hct potential_solution = Hct(hue, chroma, answer);
      if (chroma_peak > potential_solution.get_chroma()) {
        break;
      }
      if (abs(potential_solution.get_chroma() - chroma) < 0.4) {
        break;
      }

      double potential_delta = abs(potential_solution.get_chroma() - chroma);
      double current_delta = abs(closest_to_chroma.get_chroma() - chroma);
      if (potential_delta < current_delta) {
        closest_to_chroma = potential_solution;
      }
      chroma_peak = fmax(chroma_peak, potential_solution.get_chroma());
    }
  }

  return answer;
}

constexpr double kContentAccentToneDelta = 15.0;
DynamicColor highestSurface(const DynamicScheme& s) {
  return s.is_dark ? MaterialDynamicColors::SurfaceBright()
                   : MaterialDynamicColors::SurfaceDim();
}

// Compatibility Keys Colors for Android
DynamicColor MaterialDynamicColors::PrimaryPaletteKeyColor() {
  return DynamicColor::FromPalette(
      "primary_palette_key_color",
      [](const DynamicScheme& s) -> TonalPalette { return s.primary_palette; },
      [](const DynamicScheme& s) -> double {
        return s.primary_palette.get_key_color().get_tone();
      });
}

DynamicColor MaterialDynamicColors::SecondaryPaletteKeyColor() {
  return DynamicColor::FromPalette(
      "secondary_palette_key_color",
      [](const DynamicScheme& s) -> TonalPalette {
        return s.secondary_palette;
      },
      [](const DynamicScheme& s) -> double {
        return s.secondary_palette.get_key_color().get_tone();
      });
}

DynamicColor MaterialDynamicColors::TertiaryPaletteKeyColor() {
  return DynamicColor::FromPalette(
      "tertiary_palette_key_color",
      [](const DynamicScheme& s) -> TonalPalette { return s.tertiary_palette; },
      [](const DynamicScheme& s) -> double {
        return s.tertiary_palette.get_key_color().get_tone();
      });
}

DynamicColor MaterialDynamicColors::NeutralPaletteKeyColor() {
  return DynamicColor::FromPalette(
      "neutral_palette_key_color",
      [](const DynamicScheme& s) -> TonalPalette { return s.neutral_palette; },
      [](const DynamicScheme& s) -> double {
        return s.neutral_palette.get_key_color().get_tone();
      });
}

DynamicColor MaterialDynamicColors::NeutralVariantPaletteKeyColor() {
  return DynamicColor::FromPalette(
      "neutral_variant_palette_key_color",
      [](const DynamicScheme& s) -> TonalPalette {
        return s.neutral_variant_palette;
      },
      [](const DynamicScheme& s) -> double {
        return s.neutral_variant_palette.get_key_color().get_tone();
      });
}

DynamicColor MaterialDynamicColors::Background() {
  return DynamicColor(
      /* name= */ "background",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.neutral_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double { return s.is_dark ? 6.0 : 98.0; },
      /* isBackground= */ true,
      /* background= */ nullopt,
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ nullopt,
      /* toneDeltaPair= */ nullopt);
}

DynamicColor MaterialDynamicColors::OnBackground() {
  return DynamicColor(
      /* name= */ "on_background",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.neutral_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double { return s.is_dark ? 90.0 : 10.0; },
      /* isBackground= */ false,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor { return Background(); },
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ ContrastCurve(3.0, 3.0, 4.5, 7.0),
      /* toneDeltaPair= */ nullopt);
}

DynamicColor MaterialDynamicColors::Surface() {
  return DynamicColor(
      /* name= */ "surface",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.neutral_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double { return s.is_dark ? 6.0 : 98.0; },
      /* isBackground= */ true,
      /* background= */ nullopt,
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ nullopt,
      /* toneDeltaPair= */ nullopt);
}

DynamicColor MaterialDynamicColors::SurfaceDim() {
  return DynamicColor(
      /* name= */ "surface_dim",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.neutral_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double {
        return s.is_dark ? 6.0
                         : ContrastCurve(87.0, 87.0, 80.0, 75.0)
                               .get(s.contrast_level);
      },
      /* isBackground= */ true,
      /* background= */ nullopt,
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ nullopt,
      /* toneDeltaPair= */ nullopt);
}

DynamicColor MaterialDynamicColors::SurfaceBright() {
  return DynamicColor(
      /* name= */ "surface_bright",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.neutral_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double {
        return s.is_dark
                   ? ContrastCurve(24.0, 24.0, 29.0, 34.0).get(s.contrast_level)
                   : 98.0;
      },
      /* isBackground= */ true,
      /* background= */ nullopt,
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ nullopt,
      /* toneDeltaPair= */ nullopt);
}

DynamicColor MaterialDynamicColors::SurfaceContainerLowest() {
  return DynamicColor(
      /* name= */ "surface_container_lowest",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.neutral_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double {
        return s.is_dark
                   ? ContrastCurve(4.0, 4.0, 2.0, 0.0).get(s.contrast_level)
                   : 100.0;
      },
      /* isBackground= */ true,
      /* background= */ nullopt,
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ nullopt,
      /* toneDeltaPair= */ nullopt);
}

DynamicColor MaterialDynamicColors::SurfaceContainerLow() {
  return DynamicColor(
      /* name= */ "surface_container_low",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.neutral_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double {
        return s.is_dark
                   ? ContrastCurve(10.0, 10.0, 11.0, 12.0).get(s.contrast_level)
                   : ContrastCurve(96.0, 96.0, 96.0, 95.0)
                         .get(s.contrast_level);
      },
      /* isBackground= */ true,
      /* background= */ nullopt,
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ nullopt,
      /* toneDeltaPair= */ nullopt);
}

DynamicColor MaterialDynamicColors::SurfaceContainer() {
  return DynamicColor(
      /* name= */ "surface_container",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.neutral_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double {
        return s.is_dark
                   ? ContrastCurve(12.0, 12.0, 16.0, 20.0).get(s.contrast_level)
                   : ContrastCurve(94.0, 94.0, 92.0, 90.0)
                         .get(s.contrast_level);
      },
      /* isBackground= */ true,
      /* background= */ nullopt,
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ nullopt,
      /* toneDeltaPair= */ nullopt);
}

DynamicColor MaterialDynamicColors::SurfaceContainerHigh() {
  return DynamicColor(
      /* name= */ "surface_container_high",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.neutral_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double {
        return s.is_dark
                   ? ContrastCurve(17.0, 17.0, 21.0, 25.0).get(s.contrast_level)
                   : ContrastCurve(92.0, 92.0, 88.0, 85.0)
                         .get(s.contrast_level);
      },
      /* isBackground= */ true,
      /* background= */ nullopt,
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ nullopt,
      /* toneDeltaPair= */ nullopt);
}

DynamicColor MaterialDynamicColors::SurfaceContainerHighest() {
  return DynamicColor(
      /* name= */ "surface_container_highest",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.neutral_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double {
        return s.is_dark
                   ? ContrastCurve(22.0, 22.0, 26.0, 30.0).get(s.contrast_level)
                   : ContrastCurve(90.0, 90.0, 84.0, 80.0)
                         .get(s.contrast_level);
      },
      /* isBackground= */ true,
      /* background= */ nullopt,
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ nullopt,
      /* toneDeltaPair= */ nullopt);
}

DynamicColor MaterialDynamicColors::OnSurface() {
  return DynamicColor(
      /* name= */ "on_surface",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.neutral_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double { return s.is_dark ? 90.0 : 10.0; },
      /* isBackground= */ false,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor { return highestSurface(s); },
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ ContrastCurve(4.5, 7.0, 11.0, 21.0),
      /* toneDeltaPair= */ nullopt);
}

DynamicColor MaterialDynamicColors::SurfaceVariant() {
  return DynamicColor(
      /* name= */ "surface_variant",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette {
        return s.neutral_variant_palette;
      },
      /* tone= */
      [](const DynamicScheme& s) -> double { return s.is_dark ? 30.0 : 90.0; },
      /* isBackground= */ true,
      /* background= */ nullopt,
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ nullopt,
      /* toneDeltaPair= */ nullopt);
}

DynamicColor MaterialDynamicColors::OnSurfaceVariant() {
  return DynamicColor(
      /* name= */ "on_surface_variant",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette {
        return s.neutral_variant_palette;
      },
      /* tone= */
      [](const DynamicScheme& s) -> double { return s.is_dark ? 80.0 : 30.0; },
      /* isBackground= */ false,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor { return highestSurface(s); },
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ ContrastCurve(3.0, 4.5, 7.0, 11.0),
      /* toneDeltaPair= */ nullopt);
}

DynamicColor MaterialDynamicColors::InverseSurface() {
  return DynamicColor(
      /* name= */ "inverse_surface",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.neutral_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double { return s.is_dark ? 90.0 : 20.0; },
      /* isBackground= */ false,
      /* background= */ nullopt,
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ nullopt,
      /* toneDeltaPair= */ nullopt);
}

DynamicColor MaterialDynamicColors::InverseOnSurface() {
  return DynamicColor(
      /* name= */ "inverse_on_surface",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.neutral_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double { return s.is_dark ? 20.0 : 95.0; },
      /* isBackground= */ false,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor { return InverseSurface(); },
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ ContrastCurve(4.5, 7.0, 11.0, 21.0),
      /* toneDeltaPair= */ nullopt);
}

DynamicColor MaterialDynamicColors::Outline() {
  return DynamicColor(
      /* name= */ "outline",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette {
        return s.neutral_variant_palette;
      },
      /* tone= */
      [](const DynamicScheme& s) -> double { return s.is_dark ? 60.0 : 50.0; },
      /* isBackground= */ false,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor { return highestSurface(s); },
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ ContrastCurve(1.5, 3.0, 4.5, 7.0),
      /* toneDeltaPair= */ nullopt);
}

DynamicColor MaterialDynamicColors::OutlineVariant() {
  return DynamicColor(
      /* name= */ "outline_variant",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette {
        return s.neutral_variant_palette;
      },
      /* tone= */
      [](const DynamicScheme& s) -> double { return s.is_dark ? 30.0 : 80.0; },
      /* isBackground= */ false,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor { return highestSurface(s); },
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ ContrastCurve(1.0, 1.0, 3.0, 4.5),
      /* toneDeltaPair= */ nullopt);
}

DynamicColor MaterialDynamicColors::Shadow() {
  return DynamicColor(
      /* name= */ "shadow",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.neutral_palette; },
      /* tone= */ [](const DynamicScheme& s) -> double { return 0.0; },
      /* isBackground= */ false,
      /* background= */ nullopt,
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ nullopt,
      /* toneDeltaPair= */ nullopt);
}

DynamicColor MaterialDynamicColors::Scrim() {
  return DynamicColor(
      /* name= */ "scrim",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.neutral_palette; },
      /* tone= */ [](const DynamicScheme& s) -> double { return 0.0; },
      /* isBackground= */ false,
      /* background= */ nullopt,
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ nullopt,
      /* toneDeltaPair= */ nullopt);
}

DynamicColor MaterialDynamicColors::SurfaceTint() {
  return DynamicColor(
      /* name= */ "surface_tint",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.primary_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double { return s.is_dark ? 80.0 : 40.0; },
      /* isBackground= */ true,
      /* background= */ nullopt,
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ nullopt,
      /* toneDeltaPair= */ nullopt);
}

DynamicColor MaterialDynamicColors::Primary() {
  return DynamicColor(
      /* name= */ "primary",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.primary_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double {
        if (IsMonochrome(s)) {
          return s.is_dark ? 100.0 : 0.0;
        }
        return s.is_dark ? 80.0 : 40.0;
      },
      /* isBackground= */ true,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor { return highestSurface(s); },
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ ContrastCurve(3.0, 4.5, 7.0, 7.0),
      /* toneDeltaPair= */
      [](const DynamicScheme& s) -> ToneDeltaPair {
        return ToneDeltaPair(PrimaryContainer(), Primary(), 10.0,
                             TonePolarity::kNearer, false);
      });
}

DynamicColor MaterialDynamicColors::OnPrimary() {
  return DynamicColor(
      /* name= */ "on_primary",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.primary_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double {
        if (IsMonochrome(s)) {
          return s.is_dark ? 10.0 : 90.0;
        }
        return s.is_dark ? 20.0 : 100.0;
      },
      /* isBackground= */ false,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor { return Primary(); },
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ ContrastCurve(4.5, 7.0, 11.0, 21.0),
      /* toneDeltaPair= */ nullopt);
}

DynamicColor MaterialDynamicColors::PrimaryContainer() {
  return DynamicColor(
      /* name= */ "primary_container",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.primary_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double {
        if (IsFidelity(s)) {
          return s.source_color_hct.get_tone();
        }
        if (IsMonochrome(s)) {
          return s.is_dark ? 85.0 : 25.0;
        }
        return s.is_dark ? 30.0 : 90.0;
      },
      /* isBackground= */ true,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor { return highestSurface(s); },
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ ContrastCurve(1.0, 1.0, 3.0, 4.5),
      /* toneDeltaPair= */
      [](const DynamicScheme& s) -> ToneDeltaPair {
        return ToneDeltaPair(PrimaryContainer(), Primary(), 10.0,
                             TonePolarity::kNearer, false);
      });
}

DynamicColor MaterialDynamicColors::OnPrimaryContainer() {
  return DynamicColor(
      /* name= */
      "on_primary_container",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.primary_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double {
        if (IsFidelity(s)) {
          return ForegroundTone(PrimaryContainer().tone_(s), 4.5);
        }
        if (IsMonochrome(s)) {
          return s.is_dark ? 0.0 : 100.0;
        }
        return s.is_dark ? 90.0 : 30.0;
      },
      /* isBackground= */ false,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor { return PrimaryContainer(); },
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ ContrastCurve(3.0, 4.5, 7.0, 11.0),
      /* toneDeltaPair= */ nullopt);
}

DynamicColor MaterialDynamicColors::InversePrimary() {
  return DynamicColor(
      /* name= */ "inverse_primary",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.primary_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double { return s.is_dark ? 40.0 : 80.0; },
      /* isBackground= */ false,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor { return InverseSurface(); },
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ ContrastCurve(3.0, 4.5, 7.0, 7.0),
      /* toneDeltaPair= */ nullopt);
}

DynamicColor MaterialDynamicColors::Secondary() {
  return DynamicColor(
      /* name= */ "secondary",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette {
        return s.secondary_palette;
      },
      /* tone= */
      [](const DynamicScheme& s) -> double { return s.is_dark ? 80.0 : 40.0; },
      /* isBackground= */ true,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor { return highestSurface(s); },
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ ContrastCurve(3.0, 4.5, 7.0, 7.0),
      /* toneDeltaPair= */
      [](const DynamicScheme& s) -> ToneDeltaPair {
        return ToneDeltaPair(SecondaryContainer(), Secondary(), 10.0,
                             TonePolarity::kNearer, false);
      });
}

DynamicColor MaterialDynamicColors::OnSecondary() {
  return DynamicColor(
      /* name= */ "on_secondary",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette {
        return s.secondary_palette;
      },
      /* tone= */
      [](const DynamicScheme& s) -> double {
        if (IsMonochrome(s)) {
          return s.is_dark ? 10.0 : 100.0;
        } else {
          return s.is_dark ? 20.0 : 100.0;
        }
      },
      /* isBackground= */ false,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor { return Secondary(); },
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ ContrastCurve(4.5, 7.0, 11.0, 21.0),
      /* toneDeltaPair= */ nullopt);
}

DynamicColor MaterialDynamicColors::SecondaryContainer() {
  return DynamicColor(
      /* name= */ "secondary_container",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette {
        return s.secondary_palette;
      },
      /* tone= */
      [](const DynamicScheme& s) -> double {
        double initialTone = s.is_dark ? 30.0 : 90.0;
        if (IsMonochrome(s)) {
          return s.is_dark ? 30.0 : 85.0;
        }
        if (!IsFidelity(s)) {
          return initialTone;
        }
        return FindDesiredChromaByTone(s.secondary_palette.get_hue(),
                                       s.secondary_palette.get_chroma(),
                                       initialTone, s.is_dark ? false : true);
      },
      /* isBackground= */ true,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor { return highestSurface(s); },
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ ContrastCurve(1.0, 1.0, 3.0, 4.5),
      /* toneDeltaPair= */
      [](const DynamicScheme& s) -> ToneDeltaPair {
        return ToneDeltaPair(SecondaryContainer(), Secondary(), 10.0,
                             TonePolarity::kNearer, false);
      });
}

DynamicColor MaterialDynamicColors::OnSecondaryContainer() {
  return DynamicColor(
      /* name= */
      "on_secondary_container",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette {
        return s.secondary_palette;
      },
      /* tone= */
      [](const DynamicScheme& s) -> double {
        if (IsMonochrome(s)) {
          return s.is_dark ? 90.0 : 10.0;
        }
        if (!IsFidelity(s)) {
          return s.is_dark ? 90.0 : 30.0;
        }
        return ForegroundTone(SecondaryContainer().tone_(s), 4.5);
      },
      /* isBackground= */ false,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor {
        return SecondaryContainer();
      },
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ ContrastCurve(3.0, 4.5, 7.0, 11.0),
      /* toneDeltaPair= */ nullopt);
}

DynamicColor MaterialDynamicColors::Tertiary() {
  return DynamicColor(
      /* name= */ "tertiary",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.tertiary_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double {
        if (IsMonochrome(s)) {
          return s.is_dark ? 90.0 : 25.0;
        }
        return s.is_dark ? 80.0 : 40.0;
      },
      /* isBackground= */ true,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor { return highestSurface(s); },
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ ContrastCurve(3.0, 4.5, 7.0, 7.0),
      /* toneDeltaPair= */
      [](const DynamicScheme& s) -> ToneDeltaPair {
        return ToneDeltaPair(TertiaryContainer(), Tertiary(), 10.0,
                             TonePolarity::kNearer, false);
      });
}

DynamicColor MaterialDynamicColors::OnTertiary() {
  return DynamicColor(
      /* name= */ "on_tertiary",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.tertiary_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double {
        if (IsMonochrome(s)) {
          return s.is_dark ? 10.0 : 90.0;
        }
        return s.is_dark ? 20.0 : 100.0;
      },
      /* isBackground= */ false,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor { return Tertiary(); },
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ ContrastCurve(4.5, 7.0, 11.0, 21.0),
      /* toneDeltaPair= */ nullopt);
}

DynamicColor MaterialDynamicColors::TertiaryContainer() {
  return DynamicColor(
      /* name= */ "tertiary_container",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.tertiary_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double {
        if (IsMonochrome(s)) {
          return s.is_dark ? 60.0 : 49.0;
        }
        if (!IsFidelity(s)) {
          return s.is_dark ? 30.0 : 90.0;
        }
        Hct proposedHct =
            Hct(s.tertiary_palette.get(s.source_color_hct.get_tone()));
        return FixIfDisliked(proposedHct).get_tone();
      },
      /* isBackground= */ true,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor { return highestSurface(s); },
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ ContrastCurve(1.0, 1.0, 3.0, 4.5),
      /* toneDeltaPair= */
      [](const DynamicScheme& s) -> ToneDeltaPair {
        return ToneDeltaPair(TertiaryContainer(), Tertiary(), 10.0,
                             TonePolarity::kNearer, false);
      });
}

DynamicColor MaterialDynamicColors::OnTertiaryContainer() {
  return DynamicColor(
      /* name= */
      "on_tertiary_container",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.tertiary_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double {
        if (IsMonochrome(s)) {
          return s.is_dark ? 0.0 : 100.0;
        }
        if (!IsFidelity(s)) {
          return s.is_dark ? 90.0 : 30.0;
        }
        return ForegroundTone(TertiaryContainer().tone_(s), 4.5);
      },
      /* isBackground= */ false,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor {
        return TertiaryContainer();
      },
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ ContrastCurve(3.0, 4.5, 7.0, 11.0),
      /* toneDeltaPair= */ nullopt);
}

DynamicColor MaterialDynamicColors::Error() {
  return DynamicColor(
      /* name= */ "error",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.error_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double { return s.is_dark ? 80.0 : 40.0; },
      /* isBackground= */ true,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor { return highestSurface(s); },
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ ContrastCurve(3.0, 4.5, 7.0, 7.0),
      /* toneDeltaPair= */
      [](const DynamicScheme& s) -> ToneDeltaPair {
        return ToneDeltaPair(ErrorContainer(), Error(), 10.0,
                             TonePolarity::kNearer, false);
      });
}

DynamicColor MaterialDynamicColors::OnError() {
  return DynamicColor(
      /* name= */ "on_error",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.error_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double { return s.is_dark ? 20.0 : 100.0; },
      /* isBackground= */ false,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor { return Error(); },
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ ContrastCurve(4.5, 7.0, 11.0, 21.0),
      /* toneDeltaPair= */ nullopt);
}

DynamicColor MaterialDynamicColors::ErrorContainer() {
  return DynamicColor(
      /* name= */ "error_container",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.error_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double { return s.is_dark ? 30.0 : 90.0; },
      /* isBackground= */ true,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor { return highestSurface(s); },
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ ContrastCurve(1.0, 1.0, 3.0, 4.5),
      /* toneDeltaPair= */
      [](const DynamicScheme& s) -> ToneDeltaPair {
        return ToneDeltaPair(ErrorContainer(), Error(), 10.0,
                             TonePolarity::kNearer, false);
      });
}

DynamicColor MaterialDynamicColors::OnErrorContainer() {
  return DynamicColor(
      /* name= */
      "on_error_container",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.error_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double {
        if (IsMonochrome(s)) {
          return s.is_dark ? 90.0 : 10.0;
        }
        return s.is_dark ? 90.0 : 30.0;
      },
      /* isBackground= */ false,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor { return ErrorContainer(); },
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ ContrastCurve(3.0, 4.5, 7.0, 11.0),
      /* toneDeltaPair= */ nullopt);
}

DynamicColor MaterialDynamicColors::PrimaryFixed() {
  return DynamicColor(
      /* name= */ "primary_fixed",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.primary_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double {
        return IsMonochrome(s) ? 40.0 : 90.0;
      },
      /* isBackground= */ true,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor { return highestSurface(s); },
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ ContrastCurve(1.0, 1.0, 3.0, 4.5),
      /* toneDeltaPair= */
      [](const DynamicScheme& s) -> ToneDeltaPair {
        return ToneDeltaPair(PrimaryFixed(), PrimaryFixedDim(), 10.0,
                             TonePolarity::kLighter, true);
      });
}

DynamicColor MaterialDynamicColors::PrimaryFixedDim() {
  return DynamicColor(
      /* name= */ "primary_fixed_dim",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.primary_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double {
        return IsMonochrome(s) ? 30.0 : 80.0;
      },
      /* isBackground= */ true,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor { return highestSurface(s); },
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ ContrastCurve(1.0, 1.0, 3.0, 4.5),
      /* toneDeltaPair= */
      [](const DynamicScheme& s) -> ToneDeltaPair {
        return ToneDeltaPair(PrimaryFixed(), PrimaryFixedDim(), 10.0,
                             TonePolarity::kLighter, true);
      });
}

DynamicColor MaterialDynamicColors::OnPrimaryFixed() {
  return DynamicColor(
      /* name= */ "on_primary_fixed",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.primary_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double {
        return IsMonochrome(s) ? 100.0 : 10.0;
      },
      /* isBackground= */ false,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor { return PrimaryFixedDim(); },
      /* secondBackground= */
      [](const DynamicScheme& s) -> DynamicColor { return PrimaryFixed(); },
      /* contrastCurve= */ ContrastCurve(4.5, 7.0, 11.0, 21.0),
      /* toneDeltaPair= */ nullopt);
}

DynamicColor MaterialDynamicColors::OnPrimaryFixedVariant() {
  return DynamicColor(
      /* name= */ "on_primary_fixed_variant",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.primary_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double {
        return IsMonochrome(s) ? 90.0 : 30.0;
      },
      /* isBackground= */ false,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor { return PrimaryFixedDim(); },
      /* secondBackground= */
      [](const DynamicScheme& s) -> DynamicColor { return PrimaryFixed(); },
      /* contrastCurve= */ ContrastCurve(3.0, 4.5, 7.0, 11.0),
      /* toneDeltaPair= */ nullopt);
}

DynamicColor MaterialDynamicColors::SecondaryFixed() {
  return DynamicColor(
      /* name= */ "secondary_fixed",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette {
        return s.secondary_palette;
      },
      /* tone= */
      [](const DynamicScheme& s) -> double {
        return IsMonochrome(s) ? 80.0 : 90.0;
      },
      /* isBackground= */ true,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor { return highestSurface(s); },
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ ContrastCurve(1.0, 1.0, 3.0, 4.5),
      /* toneDeltaPair= */
      [](const DynamicScheme& s) -> ToneDeltaPair {
        return ToneDeltaPair(SecondaryFixed(), SecondaryFixedDim(), 10.0,
                             TonePolarity::kLighter, true);
      });
}

DynamicColor MaterialDynamicColors::SecondaryFixedDim() {
  return DynamicColor(
      /* name= */ "secondary_fixed_dim",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette {
        return s.secondary_palette;
      },
      /* tone= */
      [](const DynamicScheme& s) -> double {
        return IsMonochrome(s) ? 70.0 : 80.0;
      },
      /* isBackground= */ true,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor { return highestSurface(s); },
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ ContrastCurve(1.0, 1.0, 3.0, 4.5),
      /* toneDeltaPair= */
      [](const DynamicScheme& s) -> ToneDeltaPair {
        return ToneDeltaPair(SecondaryFixed(), SecondaryFixedDim(), 10.0,
                             TonePolarity::kLighter, true);
      });
}

DynamicColor MaterialDynamicColors::OnSecondaryFixed() {
  return DynamicColor(
      /* name= */ "on_secondary_fixed",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette {
        return s.secondary_palette;
      },
      /* tone= */ [](const DynamicScheme& s) -> double { return 10.0; },
      /* isBackground= */ false,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor {
        return SecondaryFixedDim();
      },
      /* secondBackground= */
      [](const DynamicScheme& s) -> DynamicColor { return SecondaryFixed(); },
      /* contrastCurve= */ ContrastCurve(4.5, 7.0, 11.0, 21.0),
      /* toneDeltaPair= */ nullopt);
}

DynamicColor MaterialDynamicColors::OnSecondaryFixedVariant() {
  return DynamicColor(
      /* name= */ "on_secondary_fixed_variant",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette {
        return s.secondary_palette;
      },
      /* tone= */
      [](const DynamicScheme& s) -> double {
        return IsMonochrome(s) ? 25.0 : 30.0;
      },
      /* isBackground= */ false,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor {
        return SecondaryFixedDim();
      },
      /* secondBackground= */
      [](const DynamicScheme& s) -> DynamicColor { return SecondaryFixed(); },
      /* contrastCurve= */ ContrastCurve(3.0, 4.5, 7.0, 11.0),
      /* toneDeltaPair= */ nullopt);
}

DynamicColor MaterialDynamicColors::TertiaryFixed() {
  return DynamicColor(
      /* name= */ "tertiary_fixed",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.tertiary_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double {
        return IsMonochrome(s) ? 40.0 : 90.0;
      },
      /* isBackground= */ true,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor { return highestSurface(s); },
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ ContrastCurve(1.0, 1.0, 3.0, 4.5),
      /* toneDeltaPair= */
      [](const DynamicScheme& s) -> ToneDeltaPair {
        return ToneDeltaPair(TertiaryFixed(), TertiaryFixedDim(), 10.0,
                             TonePolarity::kLighter, true);
      });
}

DynamicColor MaterialDynamicColors::TertiaryFixedDim() {
  return DynamicColor(
      /* name= */ "tertiary_fixed_dim",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.tertiary_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double {
        return IsMonochrome(s) ? 30.0 : 80.0;
      },
      /* isBackground= */ true,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor { return highestSurface(s); },
      /* secondBackground= */ nullopt,
      /* contrastCurve= */ ContrastCurve(1.0, 1.0, 3.0, 4.5),
      /* toneDeltaPair= */
      [](const DynamicScheme& s) -> ToneDeltaPair {
        return ToneDeltaPair(TertiaryFixed(), TertiaryFixedDim(), 10.0,
                             TonePolarity::kLighter, true);
      });
}

DynamicColor MaterialDynamicColors::OnTertiaryFixed() {
  return DynamicColor(
      /* name= */ "on_tertiary_fixed",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.tertiary_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double {
        return IsMonochrome(s) ? 100.0 : 10.0;
      },
      /* isBackground= */ false,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor { return TertiaryFixedDim(); },
      /* secondBackground= */
      [](const DynamicScheme& s) -> DynamicColor { return TertiaryFixed(); },
      /* contrastCurve= */ ContrastCurve(4.5, 7.0, 11.0, 21.0),
      /* toneDeltaPair= */ nullopt);
}

DynamicColor MaterialDynamicColors::OnTertiaryFixedVariant() {
  return DynamicColor(
      /* name= */ "on_tertiary_fixed_variant",
      /* palette= */
      [](const DynamicScheme& s) -> TonalPalette { return s.tertiary_palette; },
      /* tone= */
      [](const DynamicScheme& s) -> double {
        return IsMonochrome(s) ? 90.0 : 30.0;
      },
      /* isBackground= */ false,
      /* background= */
      [](const DynamicScheme& s) -> DynamicColor { return TertiaryFixedDim(); },
      /* secondBackground= */
      [](const DynamicScheme& s) -> DynamicColor { return TertiaryFixed(); },
      /* contrastCurve= */ ContrastCurve(3.0, 4.5, 7.0, 11.0),
      /* toneDeltaPair= */ nullopt);
}

}  // namespace material_color_utilities
