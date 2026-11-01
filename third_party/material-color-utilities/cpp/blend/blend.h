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

#ifndef CPP_BLEND_BLEND_H_
#define CPP_BLEND_BLEND_H_

#include <cstdint>

#include "cpp/utils/utils.h"

namespace material_color_utilities {

Argb BlendHarmonize(const Argb design_color, const Argb key_color);
Argb BlendHctHue(const Argb from, const Argb to, const double amount);
Argb BlendCam16Ucs(const Argb from, const Argb to, const double amount);

}  // namespace material_color_utilities
#endif  // CPP_BLEND_BLEND_H_
