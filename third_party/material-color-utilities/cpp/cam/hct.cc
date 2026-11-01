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

#include "cpp/cam/hct.h"

#include "cpp/cam/hct_solver.h"
#include "cpp/utils/utils.h"

namespace material_color_utilities {
Hct::Hct(double hue, double chroma, double tone) {
  SetInternalState(SolveToInt(hue, chroma, tone));
}

Hct::Hct(Argb argb) { SetInternalState(argb); }

double Hct::get_hue() const { return hue_; }

double Hct::get_chroma() const { return chroma_; }

double Hct::get_tone() const { return tone_; }

Argb Hct::ToInt() const { return argb_; }

void Hct::set_hue(double new_hue) {
  SetInternalState(SolveToInt(new_hue, chroma_, tone_));
}

void Hct::set_chroma(double new_chroma) {
  SetInternalState(SolveToInt(hue_, new_chroma, tone_));
}

void Hct::set_tone(double new_tone) {
  SetInternalState(SolveToInt(hue_, chroma_, new_tone));
}

void Hct::SetInternalState(Argb argb) {
  argb_ = argb;
  Cam cam = CamFromInt(argb);
  hue_ = cam.hue;
  chroma_ = cam.chroma;
  tone_ = LstarFromArgb(argb);
}

}  // namespace material_color_utilities
