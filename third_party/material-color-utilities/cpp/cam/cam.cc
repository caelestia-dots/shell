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

#include "cpp/cam/cam.h"

#include <assert.h>
#include <math.h>

#include "cpp/cam/hct_solver.h"
#include "cpp/cam/viewing_conditions.h"
#include "cpp/utils/utils.h"

namespace material_color_utilities {

Cam CamFromJchAndViewingConditions(double j, double c, double h,
                                   ViewingConditions viewing_conditions);

Cam CamFromUcsAndViewingConditions(
    double jstar, double astar, double bstar,
    const ViewingConditions &viewing_conditions) {
  const double a = astar;
  const double b = bstar;
  const double m = sqrt(a * a + b * b);
  const double m_2 = (exp(m * 0.0228) - 1.0) / 0.0228;
  const double c = m_2 / viewing_conditions.fl_root;
  double h = atan2(b, a) * (180.0 / kPi);
  if (h < 0.0) {
    h += 360.0;
  }
  const double j = jstar / (1 - (jstar - 100) * 0.007);
  return CamFromJchAndViewingConditions(j, c, h, viewing_conditions);
}

Cam CamFromIntAndViewingConditions(
    Argb argb, const ViewingConditions &viewing_conditions) {
  // XYZ from ARGB, inlined.
  int red = (argb & 0x00ff0000) >> 16;
  int green = (argb & 0x0000ff00) >> 8;
  int blue = (argb & 0x000000ff);
  double red_l = Linearized(red);
  double green_l = Linearized(green);
  double blue_l = Linearized(blue);
  double x = 0.41233895 * red_l + 0.35762064 * green_l + 0.18051042 * blue_l;
  double y = 0.2126 * red_l + 0.7152 * green_l + 0.0722 * blue_l;
  double z = 0.01932141 * red_l + 0.11916382 * green_l + 0.95034478 * blue_l;

  // Convert XYZ to 'cone'/'rgb' responses
  double r_c = 0.401288 * x + 0.650173 * y - 0.051461 * z;
  double g_c = -0.250268 * x + 1.204414 * y + 0.045854 * z;
  double b_c = -0.002079 * x + 0.048952 * y + 0.953127 * z;

  // Discount illuminant.
  double r_d = viewing_conditions.rgb_d[0] * r_c;
  double g_d = viewing_conditions.rgb_d[1] * g_c;
  double b_d = viewing_conditions.rgb_d[2] * b_c;

  // Chromatic adaptation.
  double r_af = pow(viewing_conditions.fl * fabs(r_d) / 100.0, 0.42);
  double g_af = pow(viewing_conditions.fl * fabs(g_d) / 100.0, 0.42);
  double b_af = pow(viewing_conditions.fl * fabs(b_d) / 100.0, 0.42);
  double r_a = Signum(r_d) * 400.0 * r_af / (r_af + 27.13);
  double g_a = Signum(g_d) * 400.0 * g_af / (g_af + 27.13);
  double b_a = Signum(b_d) * 400.0 * b_af / (b_af + 27.13);

  // Redness-greenness
  double a = (11.0 * r_a + -12.0 * g_a + b_a) / 11.0;
  double b = (r_a + g_a - 2.0 * b_a) / 9.0;
  double u = (20.0 * r_a + 20.0 * g_a + 21.0 * b_a) / 20.0;
  double p2 = (40.0 * r_a + 20.0 * g_a + b_a) / 20.0;

  double radians = atan2(b, a);
  double degrees = radians * 180.0 / kPi;
  double hue = SanitizeDegreesDouble(degrees);
  double hue_radians = hue * kPi / 180.0;
  double ac = p2 * viewing_conditions.nbb;

  double j = 100.0 * pow(ac / viewing_conditions.aw,
                         viewing_conditions.c * viewing_conditions.z);
  double q = (4.0 / viewing_conditions.c) * sqrt(j / 100.0) *
             (viewing_conditions.aw + 4.0) * viewing_conditions.fl_root;
  double hue_prime = hue < 20.14 ? hue + 360 : hue;
  double e_hue = 0.25 * (cos(hue_prime * kPi / 180.0 + 2.0) + 3.8);
  double p1 =
      50000.0 / 13.0 * e_hue * viewing_conditions.n_c * viewing_conditions.ncb;
  double t = p1 * sqrt(a * a + b * b) / (u + 0.305);
  double alpha =
      pow(t, 0.9) *
      pow(1.64 - pow(0.29, viewing_conditions.background_y_to_white_point_y),
          0.73);
  double c = alpha * sqrt(j / 100.0);
  double m = c * viewing_conditions.fl_root;
  double s = 50.0 * sqrt((alpha * viewing_conditions.c) /
                         (viewing_conditions.aw + 4.0));
  double jstar = (1.0 + 100.0 * 0.007) * j / (1.0 + 0.007 * j);
  double mstar = 1.0 / 0.0228 * log(1.0 + 0.0228 * m);
  double astar = mstar * cos(hue_radians);
  double bstar = mstar * sin(hue_radians);
  return {hue, c, j, q, m, s, jstar, astar, bstar};
}

Cam CamFromInt(Argb argb) {
  return CamFromIntAndViewingConditions(argb, kDefaultViewingConditions);
}

Argb IntFromCamAndViewingConditions(Cam cam,
                                    ViewingConditions viewing_conditions) {
  double alpha = (cam.chroma == 0.0 || cam.j == 0.0)
                     ? 0.0
                     : cam.chroma / sqrt(cam.j / 100.0);
  double t = pow(
      alpha / pow(1.64 - pow(0.29,
                             viewing_conditions.background_y_to_white_point_y),
                  0.73),
      1.0 / 0.9);
  double h_rad = cam.hue * kPi / 180.0;
  double e_hue = 0.25 * (cos(h_rad + 2.0) + 3.8);
  double ac =
      viewing_conditions.aw *
      pow(cam.j / 100.0, 1.0 / viewing_conditions.c / viewing_conditions.z);
  double p1 = e_hue * (50000.0 / 13.0) * viewing_conditions.n_c *
              viewing_conditions.ncb;
  double p2 = ac / viewing_conditions.nbb;
  double h_sin = sin(h_rad);
  double h_cos = cos(h_rad);
  double gamma = 23.0 * (p2 + 0.305) * t /
                 (23.0 * p1 + 11.0 * t * h_cos + 108.0 * t * h_sin);
  double a = gamma * h_cos;
  double b = gamma * h_sin;
  double r_a = (460.0 * p2 + 451.0 * a + 288.0 * b) / 1403.0;
  double g_a = (460.0 * p2 - 891.0 * a - 261.0 * b) / 1403.0;
  double b_a = (460.0 * p2 - 220.0 * a - 6300.0 * b) / 1403.0;

  double r_c_base = fmax(0, (27.13 * fabs(r_a)) / (400.0 - fabs(r_a)));
  double r_c =
      Signum(r_a) * (100.0 / viewing_conditions.fl) * pow(r_c_base, 1.0 / 0.42);
  double g_c_base = fmax(0, (27.13 * fabs(g_a)) / (400.0 - fabs(g_a)));
  double g_c =
      Signum(g_a) * (100.0 / viewing_conditions.fl) * pow(g_c_base, 1.0 / 0.42);
  double b_c_base = fmax(0, (27.13 * fabs(b_a)) / (400.0 - fabs(b_a)));
  double b_c =
      Signum(b_a) * (100.0 / viewing_conditions.fl) * pow(b_c_base, 1.0 / 0.42);
  double r_x = r_c / viewing_conditions.rgb_d[0];
  double g_x = g_c / viewing_conditions.rgb_d[1];
  double b_x = b_c / viewing_conditions.rgb_d[2];
  double x = 1.86206786 * r_x - 1.01125463 * g_x + 0.14918677 * b_x;
  double y = 0.38752654 * r_x + 0.62144744 * g_x - 0.00897398 * b_x;
  double z = -0.01584150 * r_x - 0.03412294 * g_x + 1.04996444 * b_x;

  // intFromXyz
  double r_l = 3.2406 * x - 1.5372 * y - 0.4986 * z;
  double g_l = -0.9689 * x + 1.8758 * y + 0.0415 * z;
  double b_l = 0.0557 * x - 0.2040 * y + 1.0570 * z;

  int red = Delinearized(r_l);
  int green = Delinearized(g_l);
  int blue = Delinearized(b_l);

  return ArgbFromRgb(red, green, blue);
}

Argb IntFromCam(Cam cam) {
  return IntFromCamAndViewingConditions(cam, kDefaultViewingConditions);
}

Cam CamFromJchAndViewingConditions(double j, double c, double h,
                                   ViewingConditions viewing_conditions) {
  double q = (4.0 / viewing_conditions.c) * sqrt(j / 100.0) *
             (viewing_conditions.aw + 4.0) * (viewing_conditions.fl_root);
  double m = c * viewing_conditions.fl_root;
  double alpha = c / sqrt(j / 100.0);
  double s = 50.0 * sqrt((alpha * viewing_conditions.c) /
                         (viewing_conditions.aw + 4.0));
  double hue_radians = h * kPi / 180.0;
  double jstar = (1.0 + 100.0 * 0.007) * j / (1.0 + 0.007 * j);
  double mstar = 1.0 / 0.0228 * log(1.0 + 0.0228 * m);
  double astar = mstar * cos(hue_radians);
  double bstar = mstar * sin(hue_radians);
  return {h, c, j, q, m, s, jstar, astar, bstar};
}

double CamDistance(Cam a, Cam b) {
  double d_j = a.jstar - b.jstar;
  double d_a = a.astar - b.astar;
  double d_b = a.bstar - b.bstar;
  double d_e_prime = sqrt(d_j * d_j + d_a * d_a + d_b * d_b);
  double d_e = 1.41 * pow(d_e_prime, 0.63);
  return d_e;
}

Argb IntFromHcl(double hue, double chroma, double lstar) {
  return SolveToInt(hue, chroma, lstar);
}

Cam CamFromXyzAndViewingConditions(
    double x, double y, double z, const ViewingConditions &viewing_conditions) {
  // Convert XYZ to 'cone'/'rgb' responses
  double r_c = 0.401288 * x + 0.650173 * y - 0.051461 * z;
  double g_c = -0.250268 * x + 1.204414 * y + 0.045854 * z;
  double b_c = -0.002079 * x + 0.048952 * y + 0.953127 * z;

  // Discount illuminant.
  double r_d = viewing_conditions.rgb_d[0] * r_c;
  double g_d = viewing_conditions.rgb_d[1] * g_c;
  double b_d = viewing_conditions.rgb_d[2] * b_c;

  // Chromatic adaptation.
  double r_af = pow(viewing_conditions.fl * fabs(r_d) / 100.0, 0.42);
  double g_af = pow(viewing_conditions.fl * fabs(g_d) / 100.0, 0.42);
  double b_af = pow(viewing_conditions.fl * fabs(b_d) / 100.0, 0.42);
  double r_a = Signum(r_d) * 400.0 * r_af / (r_af + 27.13);
  double g_a = Signum(g_d) * 400.0 * g_af / (g_af + 27.13);
  double b_a = Signum(b_d) * 400.0 * b_af / (b_af + 27.13);

  // Redness-greenness
  double a = (11.0 * r_a + -12.0 * g_a + b_a) / 11.0;
  double b = (r_a + g_a - 2.0 * b_a) / 9.0;
  double u = (20.0 * r_a + 20.0 * g_a + 21.0 * b_a) / 20.0;
  double p2 = (40.0 * r_a + 20.0 * g_a + b_a) / 20.0;

  double radians = atan2(b, a);
  double degrees = radians * 180.0 / kPi;
  double hue = SanitizeDegreesDouble(degrees);
  double hue_radians = hue * kPi / 180.0;
  double ac = p2 * viewing_conditions.nbb;

  double j = 100.0 * pow(ac / viewing_conditions.aw,
                         viewing_conditions.c * viewing_conditions.z);
  double q = (4.0 / viewing_conditions.c) * sqrt(j / 100.0) *
             (viewing_conditions.aw + 4.0) * viewing_conditions.fl_root;
  double hue_prime = hue < 20.14 ? hue + 360 : hue;
  double e_hue = 0.25 * (cos(hue_prime * kPi / 180.0 + 2.0) + 3.8);
  double p1 =
      50000.0 / 13.0 * e_hue * viewing_conditions.n_c * viewing_conditions.ncb;
  double t = p1 * sqrt(a * a + b * b) / (u + 0.305);
  double alpha =
      pow(t, 0.9) *
      pow(1.64 - pow(0.29, viewing_conditions.background_y_to_white_point_y),
          0.73);
  double c = alpha * sqrt(j / 100.0);
  double m = c * viewing_conditions.fl_root;
  double s = 50.0 * sqrt((alpha * viewing_conditions.c) /
                         (viewing_conditions.aw + 4.0));
  double jstar = (1.0 + 100.0 * 0.007) * j / (1.0 + 0.007 * j);
  double mstar = 1.0 / 0.0228 * log(1.0 + 0.0228 * m);
  double astar = mstar * cos(hue_radians);
  double bstar = mstar * sin(hue_radians);
  return {hue, c, j, q, m, s, jstar, astar, bstar};
}

}  // namespace material_color_utilities
