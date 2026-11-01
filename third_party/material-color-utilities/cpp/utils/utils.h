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

#ifndef CPP_UTILS_UTILS_H_
#define CPP_UTILS_UTILS_H_

#include <cstdint>
#include <string>

namespace material_color_utilities {

using Argb = uint32_t;

/**
 * A vector with three floating-point numbers as components.
 */
struct Vec3 {
  double a = 0.0;
  double b = 0.0;
  double c = 0.0;
};

/**
 * Value of pi.
 */
inline constexpr double kPi = 3.141592653589793;

/**
 * Returns the standard white point; white on a sunny day.
 */
inline constexpr double kWhitePointD65[] = {95.047, 100.0, 108.883};

/**
 * Returns the red component of a color in ARGB format.
 */
int RedFromInt(const Argb argb);

/**
 * Returns the green component of a color in ARGB format.
 */
int GreenFromInt(const Argb argb);

/**
 * Returns the blue component of a color in ARGB format.
 */
int BlueFromInt(const Argb argb);

/**
 * Returns the alpha component of a color in ARGB format.
 */
int AlphaFromInt(const Argb argb);

/**
 * Converts a color from RGB components to ARGB format.
 */
Argb ArgbFromRgb(const int red, const int green, const int blue);

/**
 * Converts a color from linear RGB components to ARGB format.
 */
Argb ArgbFromLinrgb(Vec3 linrgb);

/**
 * Returns whether a color in ARGB format is opaque.
 */
bool IsOpaque(const Argb argb);

/**
 * Sanitizes a degree measure as an integer.
 *
 * @return a degree measure between 0 (inclusive) and 360 (exclusive).
 */
int SanitizeDegreesInt(const int degrees);

/**
 * Sanitizes a degree measure as an floating-point number.
 *
 * @return a degree measure between 0.0 (inclusive) and 360.0 (exclusive).
 */
double SanitizeDegreesDouble(const double degrees);

/**
 * Distance of two points on a circle, represented using degrees.
 */
double DiffDegrees(const double a, const double b);

/**
 * Sign of direction change needed to travel from one angle to
 * another.
 *
 * For angles that are 180 degrees apart from each other, both
 * directions have the same travel distance, so either direction is
 * shortest. The value 1.0 is returned in this case.
 *
 * @param from The angle travel starts from, in degrees.
 *
 * @param to The angle travel ends at, in degrees.
 *
 * @return -1 if decreasing from leads to the shortest travel
 * distance, 1 if increasing from leads to the shortest travel
 * distance.
 */
double RotationDirection(const double from, const double to);

/**
 * Computes the L* value of a color in ARGB representation.
 *
 * @param argb ARGB representation of a color
 *
 * @return L*, from L*a*b*, coordinate of the color
 */
double LstarFromArgb(const Argb argb);

/**
 * Returns the hexadecimal representation of a color.
 */
std::string HexFromArgb(Argb argb);

/**
 * Linearizes an RGB component.
 *
 * @param rgb_component 0 <= rgb_component <= 255, represents R/G/B
 * channel
 *
 * @return 0.0 <= output <= 100.0, color channel converted to
 * linear RGB space
 */
double Linearized(const int rgb_component);

/**
 * Delinearizes an RGB component.
 *
 * @param rgb_component 0.0 <= rgb_component <= 100.0, represents linear
 * R/G/B channel
 *
 * @return 0 <= output <= 255, color channel converted to regular
 * RGB space
 */
int Delinearized(const double rgb_component);

/**
 * Converts an L* value to a Y value.
 *
 * L* in L*a*b* and Y in XYZ measure the same quantity, luminance.
 *
 * L* measures perceptual luminance, a linear scale. Y in XYZ
 * measures relative luminance, a logarithmic scale.
 *
 * @param lstar L* in L*a*b*. 0.0 <= L* <= 100.0
 *
 * @return Y in XYZ. 0.0 <= Y <= 100.0
 */
double YFromLstar(const double lstar);

/**
 * Converts a Y value to an L* value.
 *
 * L* in L*a*b* and Y in XYZ measure the same quantity, luminance.
 *
 * L* measures perceptual luminance, a linear scale. Y in XYZ
 * measures relative luminance, a logarithmic scale.
 *
 * @param y Y in XYZ. 0.0 <= Y <= 100.0
 *
 * @return L* in L*a*b*. 0.0 <= L* <= 100.0
 */
double LstarFromY(const double y);

/**
 * Converts an L* value to an ARGB representation.
 *
 * @param lstar L* in L*a*b*. 0.0 <= L* <= 100.0
 *
 * @return ARGB representation of grayscale color with lightness matching L*
 */
Argb IntFromLstar(const double lstar);

/**
 * The signum function.
 *
 * @return 1 if num > 0, -1 if num < 0, and 0 if num = 0
 */
int Signum(double num);

/**
 * The linear interpolation function.
 *
 * @return start if amount = 0 and stop if amount = 1
 */
double Lerp(double start, double stop, double amount);

/**
 * Multiplies a 1x3 row vector with a 3x3 matrix, returning the product.
 */
Vec3 MatrixMultiply(Vec3 input, const double matrix[3][3]);

}  // namespace material_color_utilities
#endif  // CPP_UTILS_UTILS_H_
