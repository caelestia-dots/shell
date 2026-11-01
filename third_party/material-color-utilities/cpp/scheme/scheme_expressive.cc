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

#include "cpp/scheme/scheme_expressive.h"

#include <vector>

#include "cpp/cam/hct.h"
#include "cpp/dynamiccolor/dynamic_scheme.h"
#include "cpp/dynamiccolor/variant.h"
#include "cpp/palettes/tones.h"

namespace material_color_utilities {

const std::vector<double> kHues = {0, 21, 51, 121, 151, 191, 271, 321, 360};

const std::vector<double> kSecondaryRotations = {45, 95, 45, 20, 45,
                                                 90, 45, 45, 45};

const std::vector<double> kTertiaryRotations = {120, 120, 20,  45, 20,
                                                15,  20,  120, 120};

SchemeExpressive::SchemeExpressive(Hct set_source_color_hct, bool set_is_dark,
                                   double set_contrast_level)
    : DynamicScheme(
          /*set_source_color_hct:*/ set_source_color_hct,
          /*variant:*/ Variant::kExpressive,
          /*contrast_level:*/ set_contrast_level,
          /*is_dark:*/ set_is_dark,
          /*primary_palette:*/
          TonalPalette(set_source_color_hct.get_hue() + 240.0, 40.0),
          /*secondary_palette:*/
          TonalPalette(DynamicScheme::GetRotatedHue(set_source_color_hct, kHues,
                                                    kSecondaryRotations),
                       24.0),
          /*tertiary_palette:*/
          TonalPalette(DynamicScheme::GetRotatedHue(set_source_color_hct, kHues,
                                                    kTertiaryRotations),
                       32.0),
          /*neutral_palette:*/
          TonalPalette(set_source_color_hct.get_hue() + 15.0, 8.0),
          /*neutral_variant_palette:*/
          TonalPalette(set_source_color_hct.get_hue() + 15, 12.0)) {}

SchemeExpressive::SchemeExpressive(Hct set_source_color_hct, bool set_is_dark)
    : SchemeExpressive::SchemeExpressive(set_source_color_hct, set_is_dark,
                                         0.0) {}

}  // namespace material_color_utilities
