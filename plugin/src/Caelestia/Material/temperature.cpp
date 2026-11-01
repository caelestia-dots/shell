#include "temperature.hpp"

#include <algorithm>
#include <cmath>
#include <numbers>
#include <numeric>

#include "color_utils.hpp"

namespace caelestia::material {

namespace {

constexpr int k_hueCount = 361; // hues 0..360 inclusive, as in the Python list

// Python list indexing, for the indices the algorithm computes as ints (always in range here)
template <typename T> const T& at(const std::vector<T>& values, int index) {
    return values[static_cast<size_t>(index)];
}

int sizeOf(const std::vector<int>& values) {
    return static_cast<int>(values.size());
}

int sanitizeIntDegrees(int degrees) {
    return ((degrees % 360) + 360) % 360;
}

// Python TemperatureCache.raw_temperature
double rawTemperature(const Hct& color) {
    const auto lab = labFromArgb(color.ToInt());
    const double hue = sanitizeDegrees(std::atan2(lab[2], lab[1]) * 180.0 / std::numbers::pi);
    const double chroma = std::sqrt((lab[1] * lab[1]) + (lab[2] * lab[2]));
    return -0.5 + 0.02 * std::pow(chroma, 1.07) * std::cos(sanitizeDegrees(hue - 50.0) * std::numbers::pi / 180.0);
}

} // namespace

TemperatureCache::TemperatureCache(const Hct& input)
    : m_input(input) {
    m_hcts.reserve(static_cast<size_t>(k_hueCount) + 1);
    for (int hue = 0; hue < k_hueCount; ++hue) {
        m_hcts.emplace_back(static_cast<double>(hue), input.get_chroma(), input.get_tone());
    }
    m_hcts.push_back(input);

    m_temps.reserve(m_hcts.size());
    for (const Hct& hct : m_hcts)
        m_temps.push_back(rawTemperature(hct));

    m_byTemp.resize(m_hcts.size());
    for (size_t i = 0; i < m_byTemp.size(); ++i)
        m_byTemp[i] = static_cast<int>(i);
    std::ranges::stable_sort(m_byTemp, [this](int a, int b) {
        return at(m_temps, a) < at(m_temps, b);
    });
}

double TemperatureCache::relativeTemperature(int index) const {
    const double coldestTemp = at(m_temps, m_byTemp.front());
    const double rangeTemp = at(m_temps, m_byTemp.back()) - coldestTemp;
    const double differenceFromColdest = at(m_temps, index) - coldestTemp;
    if (exactlyEqual(rangeTemp, 0.0))
        return 0.5;
    return differenceFromColdest / rangeTemp;
}

bool TemperatureCache::isBetween(double angle, double a, double b) {
    if (a < b)
        return a <= angle && angle <= b;
    return a <= angle || angle <= b;
}

std::vector<Hct> TemperatureCache::analogous(int count, int divisions) {
    const int inputIndex = k_hueCount;
    const int startHue = static_cast<int>(std::nearbyint(m_input.get_hue()));
    const int startIndex = startHue;

    double lastTemp = relativeTemperature(startIndex);
    std::vector<int> allColours = { startIndex };

    double absoluteTotalTempDelta = 0.0;
    for (int i = 0; i < 360; ++i) {
        const int hue = sanitizeIntDegrees(startHue + i);
        const double temp = relativeTemperature(hue);
        absoluteTotalTempDelta += std::fabs(temp - lastTemp);
        lastTemp = temp;
    }

    int hueAddend = 1;
    const double tempStep = absoluteTotalTempDelta / divisions;
    double totalTempDelta = 0.0;
    lastTemp = relativeTemperature(startIndex);

    while (sizeOf(allColours) < divisions) {
        const int hue = sanitizeIntDegrees(startHue + hueAddend);
        const double temp = relativeTemperature(hue);
        totalTempDelta += std::fabs(temp - lastTemp);

        double desiredTotalTempDeltaForIndex = static_cast<double>(allColours.size()) * tempStep;
        bool indexSatisfied = totalTempDelta >= desiredTotalTempDeltaForIndex;
        int indexAddend = 1;
        while (indexSatisfied && sizeOf(allColours) < divisions) {
            allColours.push_back(hue);
            desiredTotalTempDeltaForIndex =
                static_cast<double>(allColours.size() + static_cast<size_t>(indexAddend)) * tempStep;
            indexSatisfied = totalTempDelta >= desiredTotalTempDeltaForIndex;
            ++indexAddend;
        }

        lastTemp = temp;
        ++hueAddend;
        if (hueAddend > 360) {
            while (sizeOf(allColours) < divisions)
                allColours.push_back(hue);
            break;
        }
    }

    // Python list wrap-around: negative indices count from the end, and large ones wrap
    const int size = sizeOf(allColours);
    std::vector<int> answers = { inputIndex };
    const int increaseHueCount = static_cast<int>(std::floor((count - 1) / 2.0));
    for (int i = 1; i <= increaseHueCount; ++i) {
        int index = 0 - i;
        while (index < 0)
            index = size + index;
        if (index >= size)
            index %= size;
        answers.insert(answers.begin(), at(allColours, index));
    }

    const int decreaseHueCount = count - increaseHueCount - 1;
    for (int i = 1; i <= decreaseHueCount; ++i) {
        int index = i;
        while (index < 0)
            index = size + index;
        if (index >= size)
            index %= size;
        answers.push_back(at(allColours, index));
    }

    std::vector<Hct> result;
    result.reserve(answers.size());
    for (const int index : answers)
        result.push_back(at(m_hcts, index));
    return result;
}

Hct TemperatureCache::complement() {
    const int coldestIndex = m_byTemp.front();
    const int warmestIndex = m_byTemp.back();
    const double coldestHue = at(m_hcts, coldestIndex).get_hue();
    const double coldestTemp = at(m_temps, coldestIndex);
    const double warmestHue = at(m_hcts, warmestIndex).get_hue();
    const double warmestTemp = at(m_temps, warmestIndex);
    const double rangeTemp = warmestTemp - coldestTemp;

    const bool startHueIsColdestToWarmest = isBetween(m_input.get_hue(), coldestHue, warmestHue);
    const double startHue = startHueIsColdestToWarmest ? warmestHue : coldestHue;
    const double endHue = startHueIsColdestToWarmest ? coldestHue : warmestHue;
    const double directionOfRotation = 1.0;
    double smallestError = 1000.0;
    int answer = static_cast<int>(std::nearbyint(m_input.get_hue()));
    const double complementRelativeTemp = 1.0 - relativeTemperature(k_hueCount);

    for (int hueAddend = 0; hueAddend <= 360; ++hueAddend) {
        const double hue = sanitizeDegrees(startHue + directionOfRotation * hueAddend);
        if (!isBetween(hue, startHue, endHue))
            continue;

        const int possible = static_cast<int>(std::nearbyint(hue));
        const double relativeTemp = (at(m_temps, possible) - coldestTemp) / rangeTemp;
        const double error = std::fabs(complementRelativeTemp - relativeTemp);
        if (error < smallestError) {
            smallestError = error;
            answer = possible;
        }
    }
    return at(m_hcts, answer);
}

} // namespace caelestia::material
