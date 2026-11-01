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

#ifndef CPP_DISLIKE_DISLIKE_H_
#define CPP_DISLIKE_DISLIKE_H_

#include "cpp/cam/hct.h"

namespace material_color_utilities {

/**
 * Checks and/or fixes universally disliked colors.
 *
 * Color science studies of color preference indicate universal distaste for
 * dark yellow-greens, and also show this is correlated to distate for
 * biological waste and rotting food.
 *
 * See Palmer and Schloss, 2010 or Schloss and Palmer's Chapter 21 in Handbook
 * of Color Psychology (2015).
 */

/**
 * @return whether the color is disliked.
 *
 * Disliked is defined as a dark yellow-green that is not neutral.
 * @param hct The color to be tested.
 */
bool IsDisliked(Hct hct);

/**
 * If a color is disliked, lightens it to make it likable.
 *
 * The original color is not modified.
 *
 * @param hct The color to be tested (and fixed, if needed).
 * @return The original color if it is not disliked; otherwise, the fixed
 *     color.
 */
Hct FixIfDisliked(Hct hct);
}  // namespace material_color_utilities

#endif  // CPP_DISLIKE_DISLIKE_H_
