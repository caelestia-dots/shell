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

#ifndef CPP_CAM_HCT_H_
#define CPP_CAM_HCT_H_

#include "cpp/utils/utils.h"

namespace material_color_utilities {

/**
 * HCT: hue, chroma, and tone.
 *
 * A color system built using CAM16 hue and chroma, and L* (lightness) from
 * the L*a*b* color space, providing a perceptually accurate
 * color measurement system that can also accurately render what colors
 * will appear as in different lighting environments.
 *
 * Using L* creates a link between the color system, contrast, and thus
 * accessibility. Contrast ratio depends on relative luminance, or Y in the XYZ
 * color space. L*, or perceptual luminance can be calculated from Y.
 *
 * Unlike Y, L* is linear to human perception, allowing trivial creation of
 * accurate color tones.
 *
 * Unlike contrast ratio, measuring contrast in L* is linear, and simple to
 * calculate. A difference of 40 in HCT tone guarantees a contrast ratio >= 3.0,
 * and a difference of 50 guarantees a contrast ratio >= 4.5.
 */
class Hct {
 public:
  /**
   * Creates an HCT color from hue, chroma, and tone.
   *
   * @param hue 0 <= hue < 360; invalid values are corrected.
   * @param chroma >= 0; the maximum value of chroma depends on the hue
   * and tone. May be lower than the requested chroma.
   * @param tone 0 <= tone <= 100; invalid values are corrected.
   * @return HCT representation of a color in default viewing conditions.
   */
  Hct(double hue, double chroma, double tone);

  /**
   * Creates an HCT color from a color.
   *
   * @param argb ARGB representation of a color.
   * @return HCT representation of a color in default viewing conditions
   */
  explicit Hct(Argb argb);

  /**
   * Returns the hue of the color.
   *
   * @return hue of the color, in degrees.
   */
  double get_hue() const;

  /**
   * Returns the chroma of the color.
   *
   * @return chroma of the color.
   */
  double get_chroma() const;

  /**
   * Returns the tone of the color.
   *
   * @return tone of the color, satisfying 0 <= tone <= 100.
   */
  double get_tone() const;

  /**
   * Returns the color in ARGB format.
   *
   * @return an integer, representing the color in ARGB format.
   */
  Argb ToInt() const;

  /**
   * Sets the hue of this color. Chroma may decrease because chroma has a
   * different maximum for any given hue and tone.
   *
   * @param new_hue 0 <= new_hue < 360; invalid values are corrected.
   */
  void set_hue(double new_hue);

  /**
   * Sets the chroma of this color. Chroma may decrease because chroma has a
   * different maximum for any given hue and tone.
   *
   * @param new_chroma 0 <= new_chroma < ?
   */
  void set_chroma(double new_chroma);

  /**
   * Sets the tone of this color. Chroma may decrease because chroma has a
   * different maximum for any given hue and tone.
   *
   * @param new_tone 0 <= new_tone <= 100; invalid valids are corrected.
   */
  void set_tone(double new_tone);

  /**
   * For using HCT as a key in a ordered map.
   */
  bool operator<(const Hct& a) const { return hue_ < a.hue_; }

 private:
  /**
   * Sets the Hct object to represent an sRGB color.
   *
   * @param argb the new color as an integer in ARGB format.
   */
  void SetInternalState(Argb argb);

  double hue_ = 0.0;
  double chroma_ = 0.0;
  double tone_ = 0.0;
  Argb argb_ = 0;
};

}  // namespace material_color_utilities

#endif  // CPP_CAM_HCT_H_
