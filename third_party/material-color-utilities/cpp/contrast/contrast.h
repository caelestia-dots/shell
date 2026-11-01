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

#ifndef CPP_CONTRAST_CONTRAST_H_
#define CPP_CONTRAST_CONTRAST_H_

/**
 * Utility methods for calculating contrast given two colors, or calculating a
 * color given one color and a contrast ratio.
 *
 * Contrast ratio is calculated using XYZ's Y. When linearized to match human
 * perception, Y becomes HCT's tone and L*a*b*'s' L*. Informally, this is the
 * lightness of a color.
 *
 * Methods refer to tone, T in the the HCT color space.
 * Tone is equivalent to L* in the L*a*b* color space, or L in the LCH color
 * space.
 */
namespace material_color_utilities {
/**
 * @return a contrast ratio, which ranges from 1 to 21.
 * @param tone_a Tone between 0 and 100. Values outside will be clamped.
 * @param tone_b Tone between 0 and 100. Values outside will be clamped.
 */
double RatioOfTones(double tone_a, double tone_b);

/**
 * @return a tone >= [tone] that ensures [ratio].
 * Return value is between 0 and 100.
 * Returns -1 if [ratio] cannot be achieved with [tone].
 *
 * @param tone Tone return value must contrast with.
 * Range is 0 to 100. Invalid values will result in -1 being returned.
 * @param ratio Contrast ratio of return value and [tone].
 * Range is 1 to 21, invalid values have undefined behavior.
 */
double Lighter(double tone, double ratio);

/**
 * @return a tone <= [tone] that ensures [ratio].
 * Return value is between 0 and 100.
 * Returns -1 if [ratio] cannot be achieved with [tone].
 *
 * @param tone Tone return value must contrast with.
 * Range is 0 to 100. Invalid values will result in -1 being returned.
 * @param ratio Contrast ratio of return value and [tone].
 * Range is 1 to 21, invalid values have undefined behavior.
 */
double Darker(double tone, double ratio);

/**
 * @return a tone >= [tone] that ensures [ratio].
 * Return value is between 0 and 100.
 * Returns 100 if [ratio] cannot be achieved with [tone].
 *
 * This method is unsafe because the returned value is guaranteed to be in
 * bounds for tone, i.e. between 0 and 100. However, that value may not reach
 * the [ratio] with [tone]. For example, there is no color lighter than T100.
 *
 * @param tone Tone return value must contrast with.
 * Range is 0 to 100. Invalid values will result in 100 being returned.
 * @param ratio Desired contrast ratio of return value and tone parameter.
 * Range is 1 to 21, invalid values have undefined behavior.
 */
double LighterUnsafe(double tone, double ratio);

/**
 * @return a tone <= [tone] that ensures [ratio].
 * Return value is between 0 and 100.
 * Returns 0 if [ratio] cannot be achieved with [tone].
 *
 * This method is unsafe because the returned value is guaranteed to be in
 * bounds for tone, i.e. between 0 and 100. However, that value may not reach
 * the [ratio] with [tone]. For example, there is no color darker than T0.
 *
 * @param tone Tone return value must contrast with.
 * Range is 0 to 100. Invalid values will result in 0 being returned.
 * @param ratio Desired contrast ratio of return value and tone parameter.
 * Range is 1 to 21, invalid values have undefined behavior.
 */
double DarkerUnsafe(double tone, double ratio);
}  // namespace material_color_utilities

#endif  // CPP_CONTRAST_CONTRAST_H_
