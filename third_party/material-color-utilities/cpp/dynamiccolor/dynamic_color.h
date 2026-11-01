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

#ifndef CPP_DYNAMICCOLOR_DYNAMIC_COLOR_H_
#define CPP_DYNAMICCOLOR_DYNAMIC_COLOR_H_

#include <functional>
#include <optional>
#include <string>

#include "cpp/cam/hct.h"
#include "cpp/dynamiccolor/contrast_curve.h"
#include "cpp/dynamiccolor/dynamic_scheme.h"
#include "cpp/utils/utils.h"

namespace material_color_utilities {

struct ToneDeltaPair;

/**
 * Given a background tone, find a foreground tone, while ensuring they reach
 * a contrast ratio that is as close to [ratio] as possible.
 *
 * [bgTone] Tone in HCT. Range is 0 to 100, undefined behavior when it falls
 * outside that range.
 * [ratio] The contrast ratio desired between [bgTone] and the return value.
 */
double ForegroundTone(double bg_tone, double ratio);

/**
 * Adjust a tone such that white has 4.5 contrast, if the tone is
 * reasonably close to supporting it.
 */
double EnableLightForeground(double tone);

/**
 * Returns whether [tone] prefers a light foreground.
 *
 * People prefer white foregrounds on ~T60-70. Observed over time, and also
 * by Andrew Somers during research for APCA.
 *
 * T60 used as to create the smallest discontinuity possible when skipping
 * down to T49 in order to ensure light foregrounds.
 *
 * Since `tertiaryContainer` in dark monochrome scheme requires a tone of
 * 60, it should not be adjusted. Therefore, 60 is excluded here.
 */
bool TonePrefersLightForeground(double tone);

/**
 * Returns whether [tone] can reach a contrast ratio of 4.5 with a lighter
 * color.
 */
bool ToneAllowsLightForeground(double tone);

/**
 * @param name_ The name of the dynamic color.
 * @param palette_ Function that provides a TonalPalette given
 * DynamicScheme. A TonalPalette is defined by a hue and chroma, so this
 * replaces the need to specify hue/chroma. By providing a tonal palette, when
 * contrast adjustments are made, intended chroma can be preserved.
 * @param tone_ Function that provides a tone given DynamicScheme.
 * @param is_background_ Whether this dynamic color is a background, with
 * some other color as the foreground.
 * @param background_ The background of the dynamic color (as a function of a
 *     `DynamicScheme`), if it exists.
 * @param second_background_ A second background of the dynamic color (as a
 *     function of a `DynamicScheme`), if it
 * exists.
 * @param contrast_curve_ A `ContrastCurve` object specifying how its contrast
 * against its background should behave in various contrast levels options.
 * @param tone_delta_pair_ A `ToneDeltaPair` object specifying a tone delta
 * constraint between two colors. One of them must be the color being
 * constructed.
 */
struct DynamicColor {
  std::string name_;
  std::function<TonalPalette(const DynamicScheme&)> palette_;
  std::function<double(const DynamicScheme&)> tone_;
  bool is_background_;

  std::optional<std::function<DynamicColor(const DynamicScheme&)>> background_;
  std::optional<std::function<DynamicColor(const DynamicScheme&)>>
      second_background_;
  std::optional<ContrastCurve> contrast_curve_;
  std::optional<std::function<ToneDeltaPair(const DynamicScheme&)>>
      tone_delta_pair_;

  /** A convenience constructor, only requiring name, palette, and tone. */
  static DynamicColor FromPalette(
      std::string name,
      std::function<TonalPalette(const DynamicScheme&)> palette,
      std::function<double(const DynamicScheme&)> tone);

  Argb GetArgb(const DynamicScheme& scheme);

  Hct GetHct(const DynamicScheme& scheme);

  double GetTone(const DynamicScheme& scheme);

  /** The default constructor. */
  DynamicColor(std::string name,
               std::function<TonalPalette(const DynamicScheme&)> palette,
               std::function<double(const DynamicScheme&)> tone,
               bool is_background,

               std::optional<std::function<DynamicColor(const DynamicScheme&)>>
                   background,
               std::optional<std::function<DynamicColor(const DynamicScheme&)>>
                   second_background,
               std::optional<ContrastCurve> contrast_curve,
               std::optional<std::function<ToneDeltaPair(const DynamicScheme&)>>
                   tone_delta_pair);
};

}  // namespace material_color_utilities

#endif  // CPP_DYNAMICCOLOR_DYNAMIC_COLOR_H_
