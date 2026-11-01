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

#include "cpp/quantize/celebi.h"

#include <cstddef>
#include <cstdio>
#include <cstdlib>
#include <vector>

#include "cpp/quantize/wsmeans.h"
#include "cpp/quantize/wu.h"
#include "cpp/utils/utils.h"

namespace material_color_utilities {

QuantizerResult QuantizeCelebi(const std::vector<Argb>& pixels,
                               uint16_t max_colors) {
  if (max_colors == 0 || pixels.empty()) {
    return QuantizerResult();
  }

  if (max_colors > 256) {
    max_colors = 256;
  }

  int pixel_count = pixels.size();

  std::vector<Argb> opaque_pixels;
  opaque_pixels.reserve(pixel_count);
  for (int i = 0; i < pixel_count; i++) {
    int pixel = pixels[i];
    if (!IsOpaque(pixel)) {
      continue;
    }
    opaque_pixels.push_back(pixel);
  }

  std::vector<Argb> wu_result = QuantizeWu(opaque_pixels, max_colors);

  QuantizerResult result =
      QuantizeWsmeans(opaque_pixels, wu_result, max_colors);

  return result;
}

}  // namespace material_color_utilities
