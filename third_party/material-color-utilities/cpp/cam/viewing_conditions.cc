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

#include "cpp/cam/viewing_conditions.h"

#include <math.h>
#include <stdio.h>

#include "cpp/utils/utils.h"

namespace material_color_utilities {

static double lerp(double start, double stop, double amount) {
  return (1.0 - amount) * start + amount * stop;
}

ViewingConditions CreateViewingConditions(const double white_point[3],
                                          const double adapting_luminance,
                                          const double background_lstar,
                                          const double surround,
                                          const bool discounting_illuminant) {
  double background_lstar_corrected =
      (background_lstar < 30.0) ? 30.0 : background_lstar;
  double rgb_w[3] = {
      0.401288 * white_point[0] + 0.650173 * white_point[1] -
          0.051461 * white_point[2],
      -0.250268 * white_point[0] + 1.204414 * white_point[1] +
          0.045854 * white_point[2],
      -0.002079 * white_point[0] + 0.048952 * white_point[1] +
          0.953127 * white_point[2],
  };
  double f = 0.8 + (surround / 10.0);
  double c = f >= 0.9 ? lerp(0.59, 0.69, (f - 0.9) * 10.0)
                      : lerp(0.525, 0.59, (f - 0.8) * 10.0);
  double d = discounting_illuminant
                 ? 1.0
                 : f * (1.0 - ((1.0 / 3.6) *
                               exp((-adapting_luminance - 42.0) / 92.0)));
  d = d > 1.0 ? 1.0 : d < 0.0 ? 0.0 : d;
  double nc = f;
  double rgb_d[3] = {(d * (100.0 / rgb_w[0]) + 1.0 - d),
                     (d * (100.0 / rgb_w[1]) + 1.0 - d),
                     (d * (100.0 / rgb_w[2]) + 1.0 - d)};

  double k = 1.0 / (5.0 * adapting_luminance + 1.0);
  double k4 = k * k * k * k;
  double k4f = 1.0 - k4;
  double fl = (k4 * adapting_luminance) +
              (0.1 * k4f * k4f * pow(5.0 * adapting_luminance, 1.0 / 3.0));
  double fl_root = pow(fl, 0.25);
  double n = YFromLstar(background_lstar_corrected) / white_point[1];
  double z = 1.48 + sqrt(n);
  double nbb = 0.725 / pow(n, 0.2);
  double ncb = nbb;
  double rgb_a_factors[3] = {pow(fl * rgb_d[0] * rgb_w[0] / 100.0, 0.42),
                             pow(fl * rgb_d[1] * rgb_w[1] / 100.0, 0.42),
                             pow(fl * rgb_d[2] * rgb_w[2] / 100.0, 0.42)};
  double rgb_a[3] = {
      400.0 * rgb_a_factors[0] / (rgb_a_factors[0] + 27.13),
      400.0 * rgb_a_factors[1] / (rgb_a_factors[1] + 27.13),
      400.0 * rgb_a_factors[2] / (rgb_a_factors[2] + 27.13),
  };
  double aw = (40.0 * rgb_a[0] + 20.0 * rgb_a[1] + rgb_a[2]) / 20.0 * nbb;
  ViewingConditions viewingConditions = {
      adapting_luminance,
      background_lstar_corrected,
      surround,
      discounting_illuminant,
      n,
      aw,
      nbb,
      ncb,
      c,
      nc,
      fl,
      fl_root,
      z,
      {white_point[0], white_point[1], white_point[2]},
      {rgb_d[0], rgb_d[1], rgb_d[2]},
  };
  return viewingConditions;
}

ViewingConditions DefaultWithBackgroundLstar(const double background_lstar) {
  return CreateViewingConditions(kWhitePointD65,
                                 (200.0 / kPi * YFromLstar(50.0) / 100.0),
                                 background_lstar, 2.0, 0);
}

void PrintDefaultFrame() {
  ViewingConditions frame = CreateViewingConditions(
      kWhitePointD65, (200.0 / kPi * YFromLstar(50.0) / 100.0), 50.0, 2.0, 0);
  printf(
      "(Frame){%0.9lf,\n %0.9lf,\n %0.9lf,\n %s\n, %0.9lf,\n "
      "%0.9lf,\n%0.9lf,\n%0.9lf,\n%0.9lf,\n%0.9lf,\n"
      "%0.9lf,\n%0.9lf,\n%0.9lf,\n%0.9lf,\n"
      "%0.9lf,\n%0.9lf\n};",
      frame.adapting_luminance, frame.background_lstar, frame.surround,
      frame.discounting_illuminant ? "true" : "false",
      frame.background_y_to_white_point_y, frame.aw, frame.nbb, frame.ncb,
      frame.c, frame.n_c, frame.fl, frame.fl_root, frame.z, frame.rgb_d[0],
      frame.rgb_d[1], frame.rgb_d[2]);
}

}  // namespace material_color_utilities
