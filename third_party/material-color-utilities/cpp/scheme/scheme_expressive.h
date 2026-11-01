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

#ifndef CPP_SCHEME_SCHEME_EXPRESSIVE_H_
#define CPP_SCHEME_SCHEME_EXPRESSIVE_H_

#include "cpp/cam/hct.h"
#include "cpp/dynamiccolor/dynamic_scheme.h"

namespace material_color_utilities {

struct SchemeExpressive : public DynamicScheme {
  SchemeExpressive(Hct source_color_hct, bool is_dark, double contrast_level);
  SchemeExpressive(Hct source_color_hct, bool is_dark);
};

}  // namespace material_color_utilities

#endif  // CPP_SCHEME_SCHEME_EXPRESSIVE_H_
