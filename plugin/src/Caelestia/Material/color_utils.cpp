#include "color_utils.hpp"

#include <algorithm>
#include <cmath>
#include <numbers>

namespace caelestia::material {

using material_color_utilities::Argb;

double yFromLstar(double lstar) {
    return 100.0 * labInvF((lstar + 16.0) / 116.0);
}

double lstarFromY(double y) {
    return labF(y / 100.0) * 116.0 - 16.0;
}

double labF(double t) {
    const double e = 216.0 / 24389.0;
    const double kappa = 24389.0 / 27.0;
    if (t > e)
        return std::pow(t, 1.0 / 3.0);
    return (kappa * t + 16) / 116;
}

double labInvF(double ft) {
    const double e = 216.0 / 24389.0;
    const double kappa = 24389.0 / 27.0;
    const double ft3 = ft * ft * ft;
    if (ft3 > e)
        return ft3;
    return (116 * ft - 16) / kappa;
}

double linearized(int component) {
    const double normalized = component / 255.0;
    if (normalized <= 0.040449936)
        return normalized / 12.92 * 100.0;
    return std::pow((normalized + 0.055) / 1.055, 2.4) * 100.0;
}

std::vector<double> labFromArgb(Argb argb) {
    const double linearR = linearized(static_cast<int>((argb >> 16u) & 0xFFu));
    const double linearG = linearized(static_cast<int>((argb >> 8u) & 0xFFu));
    const double linearB = linearized(static_cast<int>(argb & 0xFFu));

    const double x = 0.41233895 * linearR + 0.35762064 * linearG + 0.18051042 * linearB;
    const double y = 0.2126 * linearR + 0.7152 * linearG + 0.0722 * linearB;
    const double z = 0.01932141 * linearR + 0.11916382 * linearG + 0.95034478 * linearB;

    const double fx = labF(x / 95.047);
    const double fy = labF(y / 100.0);
    const double fz = labF(z / 108.883);

    return { 116.0 * fy - 16.0, 500.0 * (fx - fy), 200.0 * (fy - fz) };
}

namespace {

// Python signum
double signum(double num) {
    if (num < 0)
        return -1;
    if (exactlyEqual(num, 0.0))
        return 0;
    return 1;
}

// Python delinearized: linear light (0..100) to an 8-bit component, rounding halves to even
int delinearized(double rgbComponent) {
    const double normalized = rgbComponent / 100.0;
    double value = 0.0;
    if (normalized <= 0.0031308) {
        value = normalized * 12.92;
    } else {
        value = 1.055 * std::pow(normalized, 1.0 / 2.4) - 0.055;
    }
    const int component = static_cast<int>(std::nearbyint(value * 255.0));
    return std::clamp(component, 0, 255);
}

} // namespace

Argb argbFromCam(const material_color_utilities::Cam& cam, const material_color_utilities::ViewingConditions& viewing) {
    const double alpha =
        (exactlyEqual(cam.chroma, 0.0) || exactlyEqual(cam.j, 0.0)) ? 0.0 : cam.chroma / std::sqrt(cam.j / 100.0);
    const double t =
        std::pow(alpha / std::pow(1.64 - std::pow(0.29, viewing.background_y_to_white_point_y), 0.73), 1.0 / 0.9);
    const double hRad = cam.hue * std::numbers::pi / 180.0;
    const double eHue = 0.25 * (std::cos(hRad + 2.0) + 3.8);
    const double ac = viewing.aw * std::pow(cam.j / 100.0, 1.0 / viewing.c / viewing.z);
    const double p1 = eHue * (50000.0 / 13.0) * viewing.n_c * viewing.ncb;
    const double p2 = ac / viewing.nbb;
    const double hSin = std::sin(hRad);
    const double hCos = std::cos(hRad);
    const double gamma = 23.0 * (p2 + 0.305) * t / (23.0 * p1 + 11 * t * hCos + 108.0 * t * hSin);
    const double a = gamma * hCos;
    const double b = gamma * hSin;
    const double rA = (460.0 * p2 + 451.0 * a + 288.0 * b) / 1403.0;
    const double gA = (460.0 * p2 - 891.0 * a - 261.0 * b) / 1403.0;
    const double bA = (460.0 * p2 - 220.0 * a - 6300.0 * b) / 1403.0;

    const auto adapted = [&viewing](double component) {
        const double base = std::max(0.0, (27.13 * std::fabs(component)) / (400.0 - std::fabs(component)));
        return signum(component) * (100.0 / viewing.fl) * std::pow(base, 1.0 / 0.42);
    };
    const double rF = adapted(rA) / viewing.rgb_d[0];
    const double gF = adapted(gA) / viewing.rgb_d[1];
    const double bF = adapted(bA) / viewing.rgb_d[2];

    const double x = 1.86206786 * rF - 1.01125463 * gF + 0.14918677 * bF;
    const double y = 0.38752654 * rF + 0.62144744 * gF - 0.00897398 * bF;
    const double z = -0.01584150 * rF - 0.03412294 * gF + 1.04996444 * bF;

    const double linearR = 3.2413774792388685 * x - 1.5376652402851851 * y - 0.49885366846268053 * z;
    const double linearG = -0.9691452513005321 * x + 1.8758853451067872 * y + 0.04156585616912061 * z;
    const double linearB = 0.05562093689691305 * x - 0.20395524564742123 * y + 1.0571799111220335 * z;

    return 0xFF000000u | (static_cast<Argb>(delinearized(linearR)) << 16u) |
           (static_cast<Argb>(delinearized(linearG)) << 8u) | static_cast<Argb>(delinearized(linearB));
}

} // namespace caelestia::material
