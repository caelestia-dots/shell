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

#include "cpp/utils/utils.h"

#include <math.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <string>

#include <format>

namespace material_color_utilities {

int RedFromInt(const Argb argb) { return (argb & 0x00ff0000) >> 16; }

int GreenFromInt(const Argb argb) { return (argb & 0x0000ff00) >> 8; }

int BlueFromInt(const Argb argb) { return (argb & 0x000000ff); }

Argb ArgbFromRgb(const int red, const int green, const int blue) {
  return 0xFF000000 | ((red & 0xff) << 16) | ((green & 0xff) << 8) |
         (blue & 0xff);
}

// Converts a color from linear RGB components to ARGB format.
Argb ArgbFromLinrgb(Vec3 linrgb) {
  int r = Delinearized(linrgb.a);
  int g = Delinearized(linrgb.b);
  int b = Delinearized(linrgb.c);

  return 0xFF000000 | ((r & 0x0ff) << 16) | ((g & 0x0ff) << 8) | (b & 0x0ff);
}

int Delinearized(const double rgb_component) {
  double normalized = rgb_component / 100;
  double delinearized;
  if (normalized <= 0.0031308) {
    delinearized = normalized * 12.92;
  } else {
    delinearized = 1.055 * std::pow(normalized, 1.0 / 2.4) - 0.055;
  }
  return std::clamp((int)round(delinearized * 255.0), 0, 255);
}

double Linearized(const int rgb_component) {
  double normalized = rgb_component / 255.0;
  if (normalized <= 0.040449936) {
    return normalized / 12.92 * 100.0;
  } else {
    return std::pow((normalized + 0.055) / 1.055, 2.4) * 100.0;
  }
}

int AlphaFromInt(Argb argb) { return (argb & 0xff000000) >> 24; }

bool IsOpaque(Argb argb) { return AlphaFromInt(argb) == 255; }

double LstarFromArgb(Argb argb) {
  // xyz from argb
  int red = (argb & 0x00ff0000) >> 16;
  int green = (argb & 0x0000ff00) >> 8;
  int blue = (argb & 0x000000ff);
  double red_l = Linearized(red);
  double green_l = Linearized(green);
  double blue_l = Linearized(blue);
  double y = 0.2126 * red_l + 0.7152 * green_l + 0.0722 * blue_l;
  return LstarFromY(y);
}

double YFromLstar(double lstar) {
  static const double ke = 8.0;
  if (lstar > ke) {
    double cube_root = (lstar + 16.0) / 116.0;
    double cube = cube_root * cube_root * cube_root;
    return cube * 100.0;
  } else {
    return lstar / (24389.0 / 27.0) * 100.0;
  }
}

double LstarFromY(double y) {
  static const double e = 216.0 / 24389.0;
  double yNormalized = y / 100.0;
  if (yNormalized <= e) {
    return (24389.0 / 27.0) * yNormalized;
  } else {
    return 116.0 * std::pow(yNormalized, 1.0 / 3.0) - 16.0;
  }
}

int SanitizeDegreesInt(const int degrees) {
  if (degrees < 0) {
    return (degrees % 360) + 360;
  } else if (degrees >= 360.0) {
    return degrees % 360;
  } else {
    return degrees;
  }
}

// Sanitizes a degree measure as a floating-point number.
//
// Returns a degree measure between 0.0 (inclusive) and 360.0 (exclusive).
double SanitizeDegreesDouble(const double degrees) {
  if (degrees < 0.0) {
    return fmod(degrees, 360.0) + 360;
  } else if (degrees >= 360.0) {
    return fmod(degrees, 360.0);
  } else {
    return degrees;
  }
}

double DiffDegrees(const double a, const double b) {
  return 180.0 - abs(abs(a - b) - 180.0);
}

double RotationDirection(const double from, const double to) {
  double increasing_difference = SanitizeDegreesDouble(to - from);
  return increasing_difference <= 180.0 ? 1.0 : -1.0;
}

// Converts a color in ARGB format to a hexadecimal string in lowercase.
//
// For instance: hex_from_argb(0xff012345) == "ff012345"
std::string HexFromArgb(Argb argb) { return std::format("{:x}", argb); }

Argb IntFromLstar(const double lstar) {
  double y = YFromLstar(lstar);
  int component = Delinearized(y);
  return ArgbFromRgb(component, component, component);
}

// The signum function.
//
// Returns 1 if num > 0, -1 if num < 0, and 0 if num = 0
int Signum(double num) {
  if (num < 0) {
    return -1;
  } else if (num == 0) {
    return 0;
  } else {
    return 1;
  }
}

double Lerp(double start, double stop, double amount) {
  return (1.0 - amount) * start + amount * stop;
}

Vec3 MatrixMultiply(Vec3 input, const double matrix[3][3]) {
  double a =
      input.a * matrix[0][0] + input.b * matrix[0][1] + input.c * matrix[0][2];
  double b =
      input.a * matrix[1][0] + input.b * matrix[1][1] + input.c * matrix[1][2];
  double c =
      input.a * matrix[2][0] + input.b * matrix[2][1] + input.c * matrix[2][2];
  return (Vec3){a, b, c};
}
}  // namespace material_color_utilities
