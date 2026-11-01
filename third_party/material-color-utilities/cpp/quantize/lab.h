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

#ifndef CPP_QUANTIZE_LAB_H_
#define CPP_QUANTIZE_LAB_H_

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <map>
#include <set>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#include "cpp/utils/utils.h"

namespace material_color_utilities {

struct Lab {
  double l = 0.0;
  double a = 0.0;
  double b = 0.0;

  double DeltaE(const Lab& lab) {
    double d_l = l - lab.l;
    double d_a = a - lab.a;
    double d_b = b - lab.b;
    return (d_l * d_l) + (d_a * d_a) + (d_b * d_b);
  }

  std::string ToString() {
    return "Lab: L* " + std::to_string(l) + " a* " + std::to_string(a) +
           " b* " + std::to_string(b);
  }
};

Argb IntFromLab(const Lab lab);
Lab LabFromInt(const Argb argb);

}  // namespace material_color_utilities
#endif  // CPP_QUANTIZE_LAB_H_
