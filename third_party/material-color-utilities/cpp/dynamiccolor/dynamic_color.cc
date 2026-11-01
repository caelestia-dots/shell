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

#include "cpp/dynamiccolor/dynamic_color.h"

#include <algorithm>
#include <cmath>
#include <functional>
#include <optional>
#include <string>
#include <vector>

#include "cpp/cam/hct.h"
#include "cpp/contrast/contrast.h"
#include "cpp/dynamiccolor/dynamic_scheme.h"
#include "cpp/dynamiccolor/tone_delta_pair.h"
#include "cpp/palettes/tones.h"

namespace material_color_utilities {

using std::function;
using std::nullopt;
using std::optional;

using DoubleFunction = function<double(const DynamicScheme&)>;

template <class T, class U>
optional<U> SafeCall(optional<function<optional<U>(const T&)>> f, const T& x) {
  if (f == nullopt) {
    return nullopt;
  } else {
    return f.value()(x);
  }
}

template <class T, class U>
optional<U> SafeCallCleanResult(optional<function<U(T)>> f, T x) {
  if (f == nullopt) {
    return nullopt;
  } else {
    return f.value()(x);
  }
}

double ForegroundTone(double bg_tone, double ratio) {
  double lighter_tone = LighterUnsafe(/*tone*/ bg_tone, /*ratio*/ ratio);
  double darker_tone = DarkerUnsafe(/*tone*/ bg_tone, /*ratio*/ ratio);
  double lighter_ratio = RatioOfTones(lighter_tone, bg_tone);
  double darker_ratio = RatioOfTones(darker_tone, bg_tone);
  double prefer_lighter = TonePrefersLightForeground(bg_tone);

  if (prefer_lighter) {
    double negligible_difference =
        (abs(lighter_ratio - darker_ratio) < 0.1 && lighter_ratio < ratio &&
         darker_ratio < ratio);
    return lighter_ratio >= ratio || lighter_ratio >= darker_ratio ||
                   negligible_difference
               ? lighter_tone
               : darker_tone;
  } else {
    return darker_ratio >= ratio || darker_ratio >= lighter_ratio
               ? darker_tone
               : lighter_tone;
  }
}

double EnableLightForeground(double tone) {
  if (TonePrefersLightForeground(tone) && !ToneAllowsLightForeground(tone)) {
    return 49.0;
  }
  return tone;
}

bool TonePrefersLightForeground(double tone) { return round(tone) < 60; }

bool ToneAllowsLightForeground(double tone) { return round(tone) <= 49; }

/**
 * Default constructor.
 */
DynamicColor::DynamicColor(
    std::string name, std::function<TonalPalette(const DynamicScheme&)> palette,
    std::function<double(const DynamicScheme&)> tone, bool is_background,

    std::optional<std::function<DynamicColor(const DynamicScheme&)>> background,
    std::optional<std::function<DynamicColor(const DynamicScheme&)>>
        second_background,
    std::optional<ContrastCurve> contrast_curve,
    std::optional<std::function<ToneDeltaPair(const DynamicScheme&)>>
        tone_delta_pair)
    : name_(name),
      palette_(palette),
      tone_(tone),
      is_background_(is_background),
      background_(background),
      second_background_(second_background),
      contrast_curve_(contrast_curve),
      tone_delta_pair_(tone_delta_pair) {}

DynamicColor DynamicColor::FromPalette(
    std::string name, std::function<TonalPalette(const DynamicScheme&)> palette,
    std::function<double(const DynamicScheme&)> tone) {
  return DynamicColor(name, palette, tone,
                      /*is_background=*/false,
                      /*background=*/nullopt,
                      /*second_background=*/nullopt,
                      /*contrast_curve=*/nullopt,
                      /*tone_delta_pair=*/nullopt);
}

Argb DynamicColor::GetArgb(const DynamicScheme& scheme) {
  return palette_(scheme).get(GetTone(scheme));
}

Hct DynamicColor::GetHct(const DynamicScheme& scheme) {
  return Hct(GetArgb(scheme));
}

double DynamicColor::GetTone(const DynamicScheme& scheme) {
  bool decreasingContrast = scheme.contrast_level < 0;

  // Case 1: dual foreground, pair of colors with delta constraint.
  if (tone_delta_pair_ != std::nullopt) {
    ToneDeltaPair tone_delta_pair = tone_delta_pair_.value()(scheme);
    DynamicColor role_a = tone_delta_pair.role_a_;
    DynamicColor role_b = tone_delta_pair.role_b_;
    double delta = tone_delta_pair.delta_;
    TonePolarity polarity = tone_delta_pair.polarity_;
    bool stay_together = tone_delta_pair.stay_together_;

    DynamicColor bg = background_.value()(scheme);
    double bg_tone = bg.GetTone(scheme);

    bool a_is_nearer =
        (polarity == TonePolarity::kNearer ||
         (polarity == TonePolarity::kLighter && !scheme.is_dark) ||
         (polarity == TonePolarity::kDarker && scheme.is_dark));
    DynamicColor nearer = a_is_nearer ? role_a : role_b;
    DynamicColor farther = a_is_nearer ? role_b : role_a;
    bool am_nearer = this->name_ == nearer.name_;
    double expansion_dir = scheme.is_dark ? 1 : -1;

    // 1st round: solve to min, each
    double n_contrast =
        nearer.contrast_curve_.value().get(scheme.contrast_level);
    double f_contrast =
        farther.contrast_curve_.value().get(scheme.contrast_level);

    // If a color is good enough, it is not adjusted.
    // Initial and adjusted tones for `nearer`
    double n_initial_tone = nearer.tone_(scheme);
    double n_tone = RatioOfTones(bg_tone, n_initial_tone) >= n_contrast
                        ? n_initial_tone
                        : ForegroundTone(bg_tone, n_contrast);
    // Initial and adjusted tones for `farther`
    double f_initial_tone = farther.tone_(scheme);
    double f_tone = RatioOfTones(bg_tone, f_initial_tone) >= f_contrast
                        ? f_initial_tone
                        : ForegroundTone(bg_tone, f_contrast);

    if (decreasingContrast) {
      // If decreasing contrast, adjust color to the "bare minimum"
      // that satisfies contrast.
      n_tone = ForegroundTone(bg_tone, n_contrast);
      f_tone = ForegroundTone(bg_tone, f_contrast);
    }

    if ((f_tone - n_tone) * expansion_dir >= delta) {
      // Good! Tones satisfy the constraint; no change needed.
    } else {
      // 2nd round: expand farther to match delta.
      f_tone = std::clamp(n_tone + delta * expansion_dir, 0.0, 100.0);
      if ((f_tone - n_tone) * expansion_dir >= delta) {
        // Good! Tones now satisfy the constraint; no change needed.
      } else {
        // 3rd round: contract nearer to match delta.
        n_tone = std::clamp(f_tone - delta * expansion_dir, 0.0, 100.0);
      }
    }

    // Avoids the 50-59 awkward zone.
    if (50 <= n_tone && n_tone < 60) {
      // If `nearer` is in the awkward zone, move it away, together with
      // `farther`.
      if (expansion_dir > 0) {
        n_tone = 60;
        f_tone = std::max(f_tone, n_tone + delta * expansion_dir);
      } else {
        n_tone = 49;
        f_tone = std::min(f_tone, n_tone + delta * expansion_dir);
      }
    } else if (50 <= f_tone && f_tone < 60) {
      if (stay_together) {
        // Fixes both, to avoid two colors on opposite sides of the "awkward
        // zone".
        if (expansion_dir > 0) {
          n_tone = 60;
          f_tone = std::max(f_tone, n_tone + delta * expansion_dir);
        } else {
          n_tone = 49;
          f_tone = std::min(f_tone, n_tone + delta * expansion_dir);
        }
      } else {
        // Not required to stay together; fixes just one.
        if (expansion_dir > 0) {
          f_tone = 60;
        } else {
          f_tone = 49;
        }
      }
    }

    // Returns `n_tone` if this color is `nearer`, otherwise `f_tone`.
    return am_nearer ? n_tone : f_tone;
  } else {
    // Case 2: No contrast pair; just solve for itself.
    double answer = tone_(scheme);

    if (background_ == std::nullopt) {
      return answer;  // No adjustment for colors with no background.
    }

    double bg_tone = background_.value()(scheme).GetTone(scheme);

    double desired_ratio = contrast_curve_.value().get(scheme.contrast_level);

    if (RatioOfTones(bg_tone, answer) >= desired_ratio) {
      // Don't "improve" what's good enough.
    } else {
      // Rough improvement.
      answer = ForegroundTone(bg_tone, desired_ratio);
    }

    if (decreasingContrast) {
      answer = ForegroundTone(bg_tone, desired_ratio);
    }

    if (is_background_ && 50 <= answer && answer < 60) {
      // Must adjust
      if (RatioOfTones(49, bg_tone) >= desired_ratio) {
        answer = 49;
      } else {
        answer = 60;
      }
    }

    if (second_background_ != std::nullopt) {
      // Case 3: Adjust for dual backgrounds.

      double bg_tone_1 = background_.value()(scheme).GetTone(scheme);
      double bg_tone_2 = second_background_.value()(scheme).GetTone(scheme);

      double upper = std::max(bg_tone_1, bg_tone_2);
      double lower = std::min(bg_tone_1, bg_tone_2);

      if (RatioOfTones(upper, answer) >= desired_ratio &&
          RatioOfTones(lower, answer) >= desired_ratio) {
        return answer;
      }

      // The darkest light tone that satisfies the desired ratio,
      // or -1 if such ratio cannot be reached.
      double lightOption = Lighter(upper, desired_ratio);

      // The lightest dark tone that satisfies the desired ratio,
      // or -1 if such ratio cannot be reached.
      double darkOption = Darker(lower, desired_ratio);

      // Tones suitable for the foreground.
      std::vector<double> availables;
      if (lightOption != -1) {
        availables.push_back(lightOption);
      }
      if (darkOption != -1) {
        availables.push_back(darkOption);
      }

      bool prefersLight = TonePrefersLightForeground(bg_tone_1) ||
                          TonePrefersLightForeground(bg_tone_2);
      if (prefersLight) {
        return (lightOption < 0) ? 100 : lightOption;
      }
      if (availables.size() == 1) {
        return availables[0];
      }
      return (darkOption < 0) ? 0 : darkOption;
    }

    return answer;
  }
}

}  // namespace material_color_utilities
