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

#include "cpp/scheme/scheme_content.h"

#include <cmath>

#include "cpp/cam/hct.h"
#include "cpp/dislike/dislike.h"
#include "cpp/dynamiccolor/dynamic_scheme.h"
#include "cpp/dynamiccolor/variant.h"
#include "cpp/palettes/tones.h"
#include "cpp/temperature/temperature_cache.h"

namespace material_color_utilities {

SchemeContent::SchemeContent(Hct set_source_color_hct, bool set_is_dark,
                             double set_contrast_level)
    : DynamicScheme(
          /*set_source_color_hct:*/ set_source_color_hct,
          /*variant:*/ Variant::kContent,
          /*contrast_level:*/ set_contrast_level,
          /*is_dark:*/ set_is_dark,
          /*primary_palette:*/
          TonalPalette(set_source_color_hct.get_hue(),
                       set_source_color_hct.get_chroma()),
          /*secondary_palette:*/
          TonalPalette(set_source_color_hct.get_hue(),
                       fmax(set_source_color_hct.get_chroma() - 32.0,
                            set_source_color_hct.get_chroma() * 0.5)),
          /*tertiary_palette:*/
          TonalPalette(FixIfDisliked(TemperatureCache(set_source_color_hct)
                                         .GetAnalogousColors(3, 6)
                                         .at(2))),
          /*neutral_palette:*/
          TonalPalette(set_source_color_hct.get_hue(),
                       set_source_color_hct.get_chroma() / 8.0),
          /*neutral_variant_palette:*/
          TonalPalette(set_source_color_hct.get_hue(),
                       set_source_color_hct.get_chroma() / 8.0 + 4.0)) {}

SchemeContent::SchemeContent(Hct set_source_color_hct, bool set_is_dark)
    : SchemeContent::SchemeContent(set_source_color_hct, set_is_dark, 0.0) {}

}  // namespace material_color_utilities
