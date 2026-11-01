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

#ifndef CPP_TEMPERATURE_TEMPERATURE_CACHE_H_
#define CPP_TEMPERATURE_TEMPERATURE_CACHE_H_

#include <map>
#include <optional>
#include <vector>

#include "cpp/cam/hct.h"

namespace material_color_utilities {

/**
 * Design utilities using color temperature theory.
 *
 * <p>Analogous colors, complementary color, and cache to efficiently, lazily,
 * generate data for calculations when needed.
 */
class TemperatureCache {
 public:
  /**
   * Create a cache that allows calculation of ex. complementary and analogous
   * colors.
   *
   * @param input Color to find complement/analogous colors of. Any colors will
   * have the same tone, and chroma as the input color, modulo any restrictions
   * due to the other hues having lower limits on chroma.
   */
  explicit TemperatureCache(Hct input);

  /**
   * A color that complements the input color aesthetically.
   *
   * <p>In art, this is usually described as being across the color wheel.
   * History of this shows intent as a color that is just as cool-warm as the
   * input color is warm-cool.
   */
  Hct GetComplement();

  /**
   * 5 colors that pair well with the input color.
   *
   * <p>The colors are equidistant in temperature and adjacent in hue.
   */
  std::vector<Hct> GetAnalogousColors();

  /**
   * A set of colors with differing hues, equidistant in temperature.
   *
   * <p>In art, this is usually described as a set of 5 colors on a color wheel
   * divided into 12 sections. This method allows provision of either of those
   * values.
   *
   * <p>Behavior is undefined when count or divisions is 0. When divisions <
   * count, colors repeat.
   *
   * @param count The number of colors to return, includes the input color.
   * @param divisions The number of divisions on the color wheel.
   */
  std::vector<Hct> GetAnalogousColors(int count, int divisions);

  /**
   * Temperature relative to all colors with the same chroma and tone.
   *
   * @param hct HCT to find the relative temperature of.
   * @return Value on a scale from 0 to 1.
   */
  double GetRelativeTemperature(Hct hct);

  /**
   * Value representing cool-warm factor of a color. Values below 0 are
   * considered cool, above, warm.
   *
   * <p>Color science has researched emotion and harmony, which art uses to
   * select colors. Warm-cool is the foundation of analogous and complementary
   * colors. See: - Li-Chen Ou's Chapter 19 in Handbook of Color Psychology
   * (2015). - Josef Albers' Interaction of Color chapters 19 and 21.
   *
   * <p>Implementation of Ou, Woodcock and Wright's algorithm, which uses
   * Lab/LCH color space. Return value has these properties:<br>
   * - Values below 0 are cool, above 0 are warm.<br>
   * - Lower bound: -9.66. Chroma is infinite. Assuming max of Lab chroma
   * 130.<br>
   * - Upper bound: 8.61. Chroma is infinite. Assuming max of Lab chroma 130.
   */
  static double RawTemperature(Hct color);

 private:
  Hct input_;

  std::optional<Hct> precomputed_complement_;
  std::optional<std::vector<Hct>> precomputed_hcts_by_temp_;
  std::optional<std::vector<Hct>> precomputed_hcts_by_hue_;
  std::optional<std::map<Hct, double>> precomputed_temps_by_hct_;

  /** Coldest color with same chroma and tone as input. */
  Hct GetColdest();

  /** Warmest color with same chroma and tone as input. */
  Hct GetWarmest();

  /** Determines if an angle is between two other angles, rotating clockwise. */
  static bool IsBetween(double angle, double a, double b);

  /**
   * HCTs for all colors with the same chroma/tone as the input.
   *
   * <p>Sorted by hue, ex. index 0 is hue 0.
   */
  std::vector<Hct> GetHctsByHue();

  /**
   * HCTs for all colors with the same chroma/tone as the input.
   *
   * <p>Sorted from coldest first to warmest last.
   */
  std::vector<Hct> GetHctsByTemp();

  /** Keys of HCTs in GetHctsByTemp, values of raw temperature. */
  std::map<Hct, double> GetTempsByHct();
};

}  // namespace material_color_utilities

#endif  // CPP_TEMPERATURE_TEMPERATURE_CACHE_H_
