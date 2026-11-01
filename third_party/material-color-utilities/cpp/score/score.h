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

#ifndef CPP_SCORE_SCORE_H_
#define CPP_SCORE_SCORE_H_

#include <cstdlib>
#include <map>
#include <vector>

#include "cpp/utils/utils.h"

namespace material_color_utilities {

/**
 * Default options for ranking colors based on usage counts.
 * `desired`: is the max count of the colors returned.
 * `fallback_color_argb`: Is the default color that should be used if no
 *                        other colors are suitable.
 * `filter`: controls if the resulting colors should be filtered to not include
 *         hues that are not used often enough, and colors that are effectively
 *         grayscale.
 */
struct ScoreOptions {
  size_t desired = 4;  // 4 colors matches the Android wallpaper picker.
  int fallback_color_argb = 0xff4285f4;  // Google Blue.
  bool filter = true;                    // Avoid unsuitable colors.
};

/**
 * Given a map with keys of colors and values of how often the color appears,
 * rank the colors based on suitability for being used for a UI theme.
 *
 * The list returned is of length <= [desired]. The recommended color is the
 * first item, the least suitable is the last. There will always be at least
 * one color returned. If all the input colors were not suitable for a theme,
 * a default fallback color will be provided, Google Blue, or supplied fallback
 * color. The default number of colors returned is 4, simply because that's the
 * # of colors display in Android 12's wallpaper picker.
 */
std::vector<Argb> RankedSuggestions(
    const std::map<Argb, uint32_t>& argb_to_population,
    const ScoreOptions& options = {});
}  // namespace material_color_utilities

#endif  // CPP_SCORE_SCORE_H_
