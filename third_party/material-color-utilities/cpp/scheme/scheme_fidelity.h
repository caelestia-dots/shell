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

#ifndef CPP_SCHEME_SCHEME_FIDELITY_H_
#define CPP_SCHEME_SCHEME_FIDELITY_H_

#include "cpp/cam/hct.h"
#include "cpp/dynamiccolor/dynamic_scheme.h"

namespace material_color_utilities {

struct SchemeFidelity : public DynamicScheme {
  SchemeFidelity(Hct set_source_color_hct, bool set_is_dark,
                 double set_contrast_level);
  SchemeFidelity(Hct set_source_color_hct, bool set_is_dark);
};

}  // namespace material_color_utilities

#endif  // CPP_SCHEME_SCHEME_FIDELITY_H_
