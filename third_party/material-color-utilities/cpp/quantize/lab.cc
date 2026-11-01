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

#include "cpp/quantize/lab.h"

#include <math.h>

#include "cpp/utils/utils.h"

namespace material_color_utilities {

Argb IntFromLab(const Lab lab) {
  double e = 216.0 / 24389.0;
  double kappa = 24389.0 / 27.0;
  double ke = 8.0;

  double fy = (lab.l + 16.0) / 116.0;
  double fx = (lab.a / 500.0) + fy;
  double fz = fy - (lab.b / 200.0);
  double fx3 = fx * fx * fx;
  double x_normalized = (fx3 > e) ? fx3 : (116.0 * fx - 16.0) / kappa;
  double y_normalized = (lab.l > ke) ? fy * fy * fy : (lab.l / kappa);
  double fz3 = fz * fz * fz;
  double z_normalized = (fz3 > e) ? fz3 : (116.0 * fz - 16.0) / kappa;
  double x = x_normalized * kWhitePointD65[0];
  double y = y_normalized * kWhitePointD65[1];
  double z = z_normalized * kWhitePointD65[2];

  // intFromXyz
  double rL = 3.2406 * x - 1.5372 * y - 0.4986 * z;
  double gL = -0.9689 * x + 1.8758 * y + 0.0415 * z;
  double bL = 0.0557 * x - 0.2040 * y + 1.0570 * z;

  int red = Delinearized(rL);
  int green = Delinearized(gL);
  int blue = Delinearized(bL);

  return ArgbFromRgb(red, green, blue);
}

Lab LabFromInt(const Argb argb) {
  int red = (argb & 0x00ff0000) >> 16;
  int green = (argb & 0x0000ff00) >> 8;
  int blue = (argb & 0x000000ff);
  double red_l = Linearized(red);
  double green_l = Linearized(green);
  double blue_l = Linearized(blue);
  double x = 0.41233895 * red_l + 0.35762064 * green_l + 0.18051042 * blue_l;
  double y = 0.2126 * red_l + 0.7152 * green_l + 0.0722 * blue_l;
  double z = 0.01932141 * red_l + 0.11916382 * green_l + 0.95034478 * blue_l;
  double y_normalized = y / kWhitePointD65[1];
  double e = 216.0 / 24389.0;
  double kappa = 24389.0 / 27.0;
  double fy;
  if (y_normalized > e) {
    fy = pow(y_normalized, 1.0 / 3.0);
  } else {
    fy = (kappa * y_normalized + 16) / 116;
  }

  double x_normalized = x / kWhitePointD65[0];
  double fx;
  if (x_normalized > e) {
    fx = pow(x_normalized, 1.0 / 3.0);
  } else {
    fx = (kappa * x_normalized + 16) / 116;
  }

  double z_normalized = z / kWhitePointD65[2];
  double fz;
  if (z_normalized > e) {
    fz = pow(z_normalized, 1.0 / 3.0);
  } else {
    fz = (kappa * z_normalized + 16) / 116;
  }

  double l = 116.0 * fy - 16;
  double a = 500.0 * (fx - fy);
  double b = 200.0 * (fy - fz);
  return {l, a, b};
}

}  // namespace material_color_utilities
