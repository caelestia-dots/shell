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

#include "cpp/contrast/contrast.h"

#include <algorithm>
#include <cmath>

#include "cpp/utils/utils.h"

namespace material_color_utilities {
// Given a color and a contrast ratio to reach, the luminance of a color that
// reaches that ratio with the color can be calculated. However, that luminance
// may not contrast as desired, i.e. the contrast ratio of the input color
// and the returned luminance may not reach the contrast ratio  asked for.
//
// When the desired contrast ratio and the result contrast ratio differ by
// more than this amount,  an error value should be returned, or the method
// should be documented as 'unsafe', meaning, it will return a valid luminance
// but that luminance may not meet the requested contrast ratio.
//
// 0.04 selected because it ensures the resulting ratio rounds to the
// same tenth.
constexpr double CONTRAST_RATIO_EPSILON = 0.04;

// Color spaces that measure luminance, such as Y in XYZ, L* in L*a*b*,
// or T in HCT, are known as  perceptual accurate color spaces.
//
// To be displayed, they must gamut map to a "display space", one that has
// a defined limit on the number of colors. Display spaces include sRGB,
// more commonly understood as RGB/HSL/HSV/HSB.
//
// Gamut mapping is undefined and not defined by the color space. Any
// gamut mapping algorithm must choose how to sacrifice accuracy in hue,
// saturation, and/or lightness.
//
// A principled solution is to maintain lightness, thus maintaining
// contrast/a11y, maintain hue, thus maintaining aesthetic intent, and reduce
// chroma until the color is in gamut.
//
// HCT chooses this solution, but, that doesn't mean it will _exactly_ matched
// desired lightness, if only because RGB is quantized: RGB is expressed as
// a set of integers: there may be an RGB color with, for example,
// 47.892 lightness, but not 47.891.
//
// To allow for this inherent incompatibility between perceptually accurate
// color spaces and display color spaces, methods that take a contrast ratio
// and luminance, and return a luminance that reaches that contrast ratio for
// the input luminance, purposefully darken/lighten their result such that
// the desired contrast ratio will be reached even if inaccuracy is introduced.
//
// 0.4 is generous, ex. HCT requires much less delta. It was chosen because
// it provides a rough guarantee that as long as a percetual color space
// gamut maps lightness such that the resulting lightness rounds to the same
// as the requested, the desired contrast ratio will be reached.
constexpr double LUMINANCE_GAMUT_MAP_TOLERANCE = 0.4;

double RatioOfYs(double y1, double y2) {
  double lighter = y1 > y2 ? y1 : y2;
  double darker = (lighter == y2) ? y1 : y2;
  return (lighter + 5.0) / (darker + 5.0);
}

double RatioOfTones(double tone_a, double tone_b) {
  tone_a = std::clamp(tone_a, 0.0, 100.0);
  tone_b = std::clamp(tone_b, 0.0, 100.0);
  return RatioOfYs(YFromLstar(tone_a), YFromLstar(tone_b));
}

double Lighter(double tone, double ratio) {
  if (tone < 0.0 || tone > 100.0) {
    return -1.0;
  }

  double dark_y = YFromLstar(tone);
  double light_y = ratio * (dark_y + 5.0) - 5.0;
  double real_contrast = RatioOfYs(light_y, dark_y);
  double delta = abs(real_contrast - ratio);
  if (real_contrast < ratio && delta > CONTRAST_RATIO_EPSILON) {
    return -1;
  }

  // ensure gamut mapping, which requires a 'range' on tone, will still result
  // the correct ratio by darkening slightly.
  double value = LstarFromY(light_y) + LUMINANCE_GAMUT_MAP_TOLERANCE;
  if (value < 0 || value > 100) {
    return -1;
  }
  return value;
}

double Darker(double tone, double ratio) {
  if (tone < 0.0 || tone > 100.0) {
    return -1.0;
  }

  double light_y = YFromLstar(tone);
  double dark_y = ((light_y + 5.0) / ratio) - 5.0;
  double real_contrast = RatioOfYs(light_y, dark_y);

  double delta = abs(real_contrast - ratio);
  if (real_contrast < ratio && delta > CONTRAST_RATIO_EPSILON) {
    return -1;
  }

  // ensure gamut mapping, which requires a 'range' on tone, will still result
  // the correct ratio by darkening slightly.
  double value = LstarFromY(dark_y) - LUMINANCE_GAMUT_MAP_TOLERANCE;
  if (value < 0 || value > 100) {
    return -1;
  }
  return value;
}

double LighterUnsafe(double tone, double ratio) {
  double lighter_safe = Lighter(tone, ratio);
  return (lighter_safe < 0.0) ? 100.0 : lighter_safe;
}

double DarkerUnsafe(double tone, double ratio) {
  double darker_safe = Darker(tone, ratio);
  return (darker_safe < 0.0) ? 0.0 : darker_safe;
}

}  // namespace material_color_utilities
