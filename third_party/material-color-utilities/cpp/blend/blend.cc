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

#include "cpp/blend/blend.h"

#include <algorithm>
#include <cstdint>

#include "cpp/cam/cam.h"
#include "cpp/cam/hct.h"
#include "cpp/cam/viewing_conditions.h"
#include "cpp/utils/utils.h"

namespace material_color_utilities {

Argb BlendHarmonize(const Argb design_color, const Argb key_color) {
  Hct from_hct(design_color);
  Hct to_hct(key_color);
  double difference_degrees = DiffDegrees(from_hct.get_hue(), to_hct.get_hue());
  double rotation_degrees = std::min(difference_degrees * 0.5, 15.0);
  double output_hue = SanitizeDegreesDouble(
      from_hct.get_hue() +
      rotation_degrees *
          RotationDirection(from_hct.get_hue(), to_hct.get_hue()));
  from_hct.set_hue(output_hue);
  return from_hct.ToInt();
}

Argb BlendHctHue(const Argb from, const Argb to, const double amount) {
  int ucs = BlendCam16Ucs(from, to, amount);
  Hct ucs_hct(ucs);
  Hct from_hct(from);
  from_hct.set_hue(ucs_hct.get_hue());
  return from_hct.ToInt();
}

Argb BlendCam16Ucs(const Argb from, const Argb to, const double amount) {
  Cam from_cam = CamFromInt(from);
  Cam to_cam = CamFromInt(to);

  const double a_j = from_cam.jstar;
  const double a_a = from_cam.astar;
  const double a_b = from_cam.bstar;

  const double b_j = to_cam.jstar;
  const double b_a = to_cam.astar;
  const double b_b = to_cam.bstar;

  const double jstar = a_j + (b_j - a_j) * amount;
  const double astar = a_a + (b_a - a_a) * amount;
  const double bstar = a_b + (b_b - a_b) * amount;

  const Cam blended = CamFromUcsAndViewingConditions(jstar, astar, bstar,
                                                     kDefaultViewingConditions);
  return IntFromCam(blended);
}

}  // namespace material_color_utilities
