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

#include "cpp/temperature/temperature_cache.h"

#include <algorithm>
#include <map>
#include <vector>

#include "cpp/cam/hct.h"
#include "cpp/quantize/lab.h"
#include "cpp/utils/utils.h"

namespace material_color_utilities {

TemperatureCache::TemperatureCache(Hct input) : input_(input) {}

Hct TemperatureCache::GetComplement() {
  if (precomputed_complement_.has_value()) {
    return precomputed_complement_.value();
  }

  double coldest_hue = GetColdest().get_hue();
  double coldest_temp = GetTempsByHct().at(GetColdest());

  double warmest_hue = GetWarmest().get_hue();
  double warmest_temp = GetTempsByHct().at(GetWarmest());
  double range = warmest_temp - coldest_temp;
  bool start_hue_is_coldest_to_warmest =
      IsBetween(input_.get_hue(), coldest_hue, warmest_hue);
  double start_hue =
      start_hue_is_coldest_to_warmest ? warmest_hue : coldest_hue;
  double end_hue = start_hue_is_coldest_to_warmest ? coldest_hue : warmest_hue;
  double direction_of_rotation = 1.0;
  double smallest_error = 1000.0;
  Hct answer = GetHctsByHue().at((int)round(input_.get_hue()));

  double complement_relative_temp = (1.0 - GetRelativeTemperature(input_));
  // Find the color in the other section, closest to the inverse percentile
  // of the input color. This is the complement.
  for (double hue_addend = 0.0; hue_addend <= 360.0; hue_addend += 1.0) {
    double hue =
        SanitizeDegreesDouble(start_hue + direction_of_rotation * hue_addend);
    if (!IsBetween(hue, start_hue, end_hue)) {
      continue;
    }
    Hct possible_answer = GetHctsByHue().at((int)round(hue));
    double relative_temp =
        (GetTempsByHct().at(possible_answer) - coldest_temp) / range;
    double error = abs(complement_relative_temp - relative_temp);
    if (error < smallest_error) {
      smallest_error = error;
      answer = possible_answer;
    }
  }
  precomputed_complement_ = answer;
  return precomputed_complement_.value();
}

std::vector<Hct> TemperatureCache::GetAnalogousColors() {
  return GetAnalogousColors(5, 12);
}

std::vector<Hct> TemperatureCache::GetAnalogousColors(int count,
                                                      int divisions) {
  // The starting hue is the hue of the input color.
  int start_hue = (int)round(input_.get_hue());
  Hct start_hct = GetHctsByHue().at(start_hue);
  double last_temp = GetRelativeTemperature(start_hct);

  std::vector<Hct> all_colors;
  all_colors.push_back(start_hct);

  double absolute_total_temp_delta = 0.0;
  for (int i = 0; i < 360; i++) {
    int hue = SanitizeDegreesInt(start_hue + i);
    Hct hct = GetHctsByHue().at(hue);
    double temp = GetRelativeTemperature(hct);
    double temp_delta = abs(temp - last_temp);
    last_temp = temp;
    absolute_total_temp_delta += temp_delta;
  }

  int hue_addend = 1;
  double temp_step = absolute_total_temp_delta / (double)divisions;
  double total_temp_delta = 0.0;
  last_temp = GetRelativeTemperature(start_hct);
  while (all_colors.size() < static_cast<size_t>(divisions)) {
    int hue = SanitizeDegreesInt(start_hue + hue_addend);
    Hct hct = GetHctsByHue().at(hue);
    double temp = GetRelativeTemperature(hct);
    double temp_delta = abs(temp - last_temp);
    total_temp_delta += temp_delta;

    double desired_total_temp_delta_for_index = (all_colors.size() * temp_step);
    bool index_satisfied =
        total_temp_delta >= desired_total_temp_delta_for_index;
    int index_addend = 1;
    // Keep adding this hue to the answers until its temperature is
    // insufficient. This ensures consistent behavior when there aren't
    // `divisions` discrete steps between 0 and 360 in hue with `temp_step`
    // delta in temperature between them.
    //
    // For example, white and black have no analogues: there are no other
    // colors at T100/T0. Therefore, they should just be added to the array
    // as answers.
    while (index_satisfied &&
           all_colors.size() < static_cast<size_t>(divisions)) {
      all_colors.push_back(hct);
      desired_total_temp_delta_for_index =
          ((all_colors.size() + index_addend) * temp_step);
      index_satisfied = total_temp_delta >= desired_total_temp_delta_for_index;
      index_addend++;
    }
    last_temp = temp;
    hue_addend++;

    if (hue_addend > 360) {
      while (all_colors.size() < static_cast<size_t>(divisions)) {
        all_colors.push_back(hct);
      }
      break;
    }
  }

  std::vector<Hct> answers;
  answers.push_back(input_);

  int ccw_count = (int)floor(((double)count - 1.0) / 2.0);
  for (int i = 1; i < (ccw_count + 1); i++) {
    int index = 0 - i;
    while (index < 0) {
      index = all_colors.size() + index;
    }
    if (static_cast<size_t>(index) >= all_colors.size()) {
      index = index % all_colors.size();
    }
    answers.insert(answers.begin(), all_colors.at(index));
  }

  int cw_count = count - ccw_count - 1;
  for (int i = 1; i < (cw_count + 1); i++) {
    size_t index = i;
    while (index < 0) {
      index = all_colors.size() + index;
    }
    if (index >= all_colors.size()) {
      index = index % all_colors.size();
    }
    answers.push_back(all_colors.at(index));
  }

  return answers;
}

double TemperatureCache::GetRelativeTemperature(Hct hct) {
  double range =
      GetTempsByHct().at(GetWarmest()) - GetTempsByHct().at(GetColdest());
  double difference_from_coldest =
      GetTempsByHct().at(hct) - GetTempsByHct().at(GetColdest());
  // Handle when there's no difference in temperature between warmest and
  // coldest: for example, at T100, only one color is available, white.
  if (range == 0.) {
    return 0.5;
  }
  return difference_from_coldest / range;
}

double TemperatureCache::RawTemperature(Hct color) {
  Lab lab = LabFromInt(color.ToInt());
  double hue = SanitizeDegreesDouble(atan2(lab.b, lab.a) * 180.0 / kPi);
  double chroma = hypot(lab.a, lab.b);
  return -0.5 + 0.02 * pow(chroma, 1.07) *
                    cos(SanitizeDegreesDouble(hue - 50.) * kPi / 180);
}

Hct TemperatureCache::GetColdest() { return GetHctsByTemp().at(0); }

std::vector<Hct> TemperatureCache::GetHctsByHue() {
  if (precomputed_hcts_by_hue_.has_value()) {
    return precomputed_hcts_by_hue_.value();
  }
  std::vector<Hct> hcts;
  for (double hue = 0.; hue <= 360.; hue += 1.) {
    Hct color_at_hue(hue, input_.get_chroma(), input_.get_tone());
    hcts.push_back(color_at_hue);
  }
  precomputed_hcts_by_hue_ = hcts;
  return precomputed_hcts_by_hue_.value();
}

std::vector<Hct> TemperatureCache::GetHctsByTemp() {
  if (precomputed_hcts_by_temp_.has_value()) {
    return precomputed_hcts_by_temp_.value();
  }

  std::vector<Hct> hcts(GetHctsByHue());
  hcts.push_back(input_);
  std::map<Hct, double> temps_by_hct(GetTempsByHct());
  sort(hcts.begin(), hcts.end(),
       [temps_by_hct](const Hct a, const Hct b) -> bool {
         return temps_by_hct.at(a) < temps_by_hct.at(b);
       });
  precomputed_hcts_by_temp_ = hcts;
  return precomputed_hcts_by_temp_.value();
}

std::map<Hct, double> TemperatureCache::GetTempsByHct() {
  if (precomputed_temps_by_hct_.has_value()) {
    return precomputed_temps_by_hct_.value();
  }

  std::vector<Hct> all_hcts(GetHctsByHue());
  all_hcts.push_back(input_);

  std::map<Hct, double> temperatures_by_hct;
  for (Hct hct : all_hcts) {
    temperatures_by_hct[hct] = RawTemperature(hct);
  }

  precomputed_temps_by_hct_ = temperatures_by_hct;
  return precomputed_temps_by_hct_.value();
}

Hct TemperatureCache::GetWarmest() {
  return GetHctsByTemp().at(GetHctsByTemp().size() - 1);
}

bool TemperatureCache::IsBetween(double angle, double a, double b) {
  if (a < b) {
    return a <= angle && angle <= b;
  }
  return a <= angle || angle <= b;
}

}  // namespace material_color_utilities
