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

#include "cpp/dislike/dislike.h"

#include <cmath>

#include "cpp/cam/hct.h"

namespace material_color_utilities {

bool IsDisliked(Hct hct) {
  double roundedHue = std::round(hct.get_hue());

  bool hue_passes = roundedHue >= 90.0 && roundedHue <= 111.0;
  bool chroma_passes = std::round(hct.get_chroma()) > 16.0;
  bool tone_passes = std::round(hct.get_tone()) < 65.0;

  return hue_passes && chroma_passes && tone_passes;
}

Hct FixIfDisliked(Hct hct) {
  if (IsDisliked(hct)) {
    return Hct(hct.get_hue(), hct.get_chroma(), 70.0);
  }

  return hct;
}
}  // namespace material_color_utilities
