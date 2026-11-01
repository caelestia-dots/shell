/*
 * Copyright 2022 Google LLC
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

#include "cpp/score/score.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <map>
#include <utility>
#include <vector>

#include "cpp/cam/hct.h"
#include "cpp/utils/utils.h"

namespace material_color_utilities {

constexpr double kTargetChroma = 48.0;  // A1 Chroma
constexpr double kWeightProportion = 0.7;
constexpr double kWeightChromaAbove = 0.3;
constexpr double kWeightChromaBelow = 0.1;
constexpr double kCutoffChroma = 5.0;
constexpr double kCutoffExcitedProportion = 0.01;

bool CompareScoredHCT(const std::pair<Hct, double>& a,
                      const std::pair<Hct, double>& b) {
  return a.second > b.second;
}

std::vector<Argb> RankedSuggestions(
    const std::map<Argb, uint32_t>& argb_to_population,
    const ScoreOptions& options) {
  // Get the HCT color for each Argb value, while finding the per hue count and
  // total count.
  std::vector<Hct> colors_hct;
  std::vector<uint32_t> hue_population(360, 0);
  double population_sum = 0;
  for (const auto& [argb, population] : argb_to_population) {
    Hct hct(argb);
    colors_hct.push_back(hct);
    int hue = floor(hct.get_hue());
    hue_population[hue] += population;
    population_sum += population;
  }

  // Hues with more usage in neighboring 30 degree slice get a larger number.
  std::vector<double> hue_excited_proportions(360, 0.0);
  for (int hue = 0; hue < 360; hue++) {
    double proportion = hue_population[hue] / population_sum;
    for (int i = hue - 14; i < hue + 16; i++) {
      int neighbor_hue = SanitizeDegreesInt(i);
      hue_excited_proportions[neighbor_hue] += proportion;
    }
  }

  // Scores each HCT color based on usage and chroma, while optionally
  // filtering out values that do not have enough chroma or usage.
  std::vector<std::pair<Hct, double>> scored_hcts;
  for (Hct hct : colors_hct) {
    int hue = SanitizeDegreesInt(round(hct.get_hue()));
    double proportion = hue_excited_proportions[hue];
    if (options.filter && (hct.get_chroma() < kCutoffChroma ||
                           proportion <= kCutoffExcitedProportion)) {
      continue;
    }

    double proportion_score = proportion * 100.0 * kWeightProportion;
    double chroma_weight = hct.get_chroma() < kTargetChroma
                               ? kWeightChromaBelow
                               : kWeightChromaAbove;
    double chroma_score = (hct.get_chroma() - kTargetChroma) * chroma_weight;
    double score = proportion_score + chroma_score;
    scored_hcts.push_back({hct, score});
  }
  // Sorted so that colors with higher scores come first.
  sort(scored_hcts.begin(), scored_hcts.end(), CompareScoredHCT);

  // Iterates through potential hue differences in degrees in order to select
  // the colors with the largest distribution of hues possible. Starting at
  // 90 degrees(maximum difference for 4 colors) then decreasing down to a
  // 15 degree minimum.
  std::vector<Hct> chosen_colors;
  for (int difference_degrees = 90; difference_degrees >= 15;
       difference_degrees--) {
    chosen_colors.clear();
    for (auto entry : scored_hcts) {
      Hct hct = entry.first;
      auto duplicate_hue = std::find_if(
          chosen_colors.begin(), chosen_colors.end(),
          [&hct, difference_degrees](Hct chosen_hct) {
            return DiffDegrees(hct.get_hue(), chosen_hct.get_hue()) <
                   difference_degrees;
          });
      if (duplicate_hue == chosen_colors.end()) {
        chosen_colors.push_back(hct);
        if (chosen_colors.size() >= options.desired) break;
      }
    }
    if (chosen_colors.size() >= options.desired) break;
  }
  std::vector<Argb> colors;
  if (chosen_colors.empty()) {
    colors.push_back(options.fallback_color_argb);
  }
  for (auto chosen_hct : chosen_colors) {
    colors.push_back(chosen_hct.ToInt());
  }
  return colors;
}

}  // namespace material_color_utilities
