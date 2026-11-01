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

#include "cpp/palettes/tones.h"

#include <cmath>

#include "cpp/cam/cam.h"
#include "cpp/cam/hct.h"

namespace material_color_utilities {

TonalPalette::TonalPalette(Argb argb) : key_color_(0.0, 0.0, 0.0) {
  Cam cam = CamFromInt(argb);
  hue_ = cam.hue;
  chroma_ = cam.chroma;
  key_color_ = KeyColor(cam.hue, cam.chroma).create();
}

TonalPalette::TonalPalette(Hct hct)
    : key_color_(hct.get_hue(), hct.get_chroma(), hct.get_tone()) {
  hue_ = hct.get_hue();
  chroma_ = hct.get_chroma();
}

TonalPalette::TonalPalette(double hue, double chroma)
    : key_color_(hue, chroma, 0.0) {
  hue_ = hue;
  chroma_ = chroma;
  key_color_ = KeyColor(hue, chroma).create();
}

TonalPalette::TonalPalette(double hue, double chroma, Hct key_color)
    : key_color_(key_color.get_hue(), key_color.get_chroma(),
                 key_color.get_tone()) {
  hue_ = hue;
  chroma_ = chroma;
}

Argb TonalPalette::get(double tone) const {
  return IntFromHcl(hue_, chroma_, tone);
}

KeyColor::KeyColor(double hue, double requested_chroma)
    : hue_(hue), requested_chroma_(requested_chroma) {}

Hct KeyColor::create() {
  // Pivot around T50 because T50 has the most chroma available, on
  // average. Thus it is most likely to have a direct answer.
  const int pivot_tone = 50;
  const int tone_step_size = 1;
  // Epsilon to accept values slightly higher than the requested chroma.
  const double epsilon = 0.01;

  // Binary search to find the tone that can provide a chroma that is closest
  // to the requested chroma.
  int lower_tone = 0;
  int upper_tone = 100;
  while (lower_tone < upper_tone) {
    const int mid_tone = (lower_tone + upper_tone) / 2;
    bool is_ascending =
        max_chroma(mid_tone) < max_chroma(mid_tone + tone_step_size);
    bool sufficient_chroma =
        max_chroma(mid_tone) >= requested_chroma_ - epsilon;

    if (sufficient_chroma) {
      // Either range [lower_tone, mid_tone] or [mid_tone, upper_tone] has
      // the answer, so search in the range that is closer the pivot tone.
      if (abs(lower_tone - pivot_tone) < abs(upper_tone - pivot_tone)) {
        upper_tone = mid_tone;
      } else {
        if (lower_tone == mid_tone) {
          return Hct(hue_, requested_chroma_, lower_tone);
        }
        lower_tone = mid_tone;
      }
    } else {
      // As there's no sufficient chroma in the mid_tone, follow the direction
      // to the chroma peak.
      if (is_ascending) {
        lower_tone = mid_tone + tone_step_size;
      } else {
        // Keep mid_tone for potential chroma peak.
        upper_tone = mid_tone;
      }
    }
  }

  return Hct(hue_, requested_chroma_, lower_tone);
}

double KeyColor::max_chroma(double tone) {
  auto it = chroma_cache_.find(tone);
  if (it != chroma_cache_.end()) {
    return it->second;
  }

  double chroma = Hct(hue_, max_chroma_value_, tone).get_chroma();
  chroma_cache_[tone] = chroma;
  return chroma;
};

}  // namespace material_color_utilities
