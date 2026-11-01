#pragma once

// The colour helpers of materialyoucolor's utils.color_utils, with the same formulas and order of
// operations, so colours and tones match the Python library to the last bit.

#include <cmath>
#include <vector>

#include "cpp/cam/cam.h"
#include "cpp/cam/viewing_conditions.h"
#include "cpp/utils/utils.h"

namespace caelestia::material {

// Python's `a == b` for floats: the colour maths compares against exact values (zero, -1, 99), and
// this keeps those comparisons explicit without tripping -Wfloat-equal. NaN is never equal.
inline bool exactlyEqual(double a, double b) {
    return !std::isnan(a) && !std::isnan(b) && !(a < b) && !(b < a);
}

// Python Cam16.viewed: the ARGB of a CAM16 colour, through the full-precision XYZ to sRGB matrix.
// MCU's IntFromCam uses a rounded matrix, which moves some colours by one step.
material_color_utilities::Argb argbFromCam(
    const material_color_utilities::Cam& cam, const material_color_utilities::ViewingConditions& viewing);

// Python y_from_lstar and lstar_from_y: CIE L* to relative luminance (0..100) and back
double yFromLstar(double lstar);
double lstarFromY(double y);

// Python lab_f and lab_invf
double labF(double t);
double labInvF(double ft);

// Python linearized: sRGB component (0..255) to linear light (0..100)
double linearized(int component);

// Python lab_from_argb, returned as { L, a, b }
std::vector<double> labFromArgb(material_color_utilities::Argb argb);

} // namespace caelestia::material
