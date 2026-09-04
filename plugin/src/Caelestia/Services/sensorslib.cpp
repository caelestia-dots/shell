#include "sensorslib.hpp"

#include <qloggingcategory.h>

#include <sensors/sensors.h>

#include <atomic>
#include <cctype>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <mutex>
#include <utility>

namespace {

Q_LOGGING_CATEGORY(lcSensorsLib, "caelestia.services.sensorslib", QtInfoMsg)

} // namespace

namespace caelestia::services::sensorslib {

namespace {

std::atomic<bool> g_initOk{ false };
std::once_flag g_initFlag;

void doInit() {
    if (sensors_init(nullptr) != 0) {
        qCWarning(lcSensorsLib, "sensors_init failed");
        g_initOk.store(false, std::memory_order_release);
        return;
    }
    g_initOk.store(true, std::memory_order_release);
    std::atexit([] {
        if (g_initOk.load(std::memory_order_acquire)) {
            sensors_cleanup();
        }
    });
}

[[nodiscard]] std::optional<double> readTempInput(const sensors_chip_name* chip, const sensors_feature* feat) {
    const auto* sf = sensors_get_subfeature(chip, feat, SENSORS_SUBFEATURE_TEMP_INPUT);
    if (!sf)
        return std::nullopt;
    double value = 0.0;
    if (sensors_get_value(chip, sf->number, &value) != 0)
        return std::nullopt;
    return value;
}

[[nodiscard]] QByteArray featureLabel(const sensors_chip_name* chip, const sensors_feature* feat) {
    char* raw = sensors_get_label(chip, feat);
    if (!raw)
        return {};
    QByteArray out(raw);
    std::free(raw);
    return out;
}

bool labelEquals(const QByteArray& label, const char* literal) {
    return label == QByteArrayView(literal);
}

bool labelStartsWith(const QByteArray& label, const char* prefix) {
    const auto n = std::strlen(prefix);
    return std::cmp_greater_equal(label.size(), n) && std::memcmp(label.constData(), prefix, n) == 0;
}

// Walks every labelled temperature feature, optionally restricted to one bus type
template <typename F> void forEachTempFeature(short busType, F&& fn) {
    int chipNr = 0;
    while (const auto* chip = sensors_get_detected_chips(nullptr, &chipNr)) {
        if (busType != SENSORS_BUS_TYPE_ANY && chip->bus.type != busType)
            continue;

        int featNr = 0;
        while (const auto* feat = sensors_get_features(chip, &featNr)) {
            if (feat->type != SENSORS_FEATURE_TEMP)
                continue;

            const auto label = featureLabel(chip, feat);
            if (label.isEmpty())
                continue;

            fn(chip, feat, label);
        }
    }
}

enum class GpuTempKind : std::uint8_t {
    None,
    Primary,
    Fallback
};

// Indexed tempN labels and the vendor die labels are the reading we want,
// junction/mem only stand in when no primary sensor exists
GpuTempKind classifyGpuTempLabel(const QByteArray& label) {
    if (label.isEmpty())
        return GpuTempKind::None;

    const auto tempIndexed =
        labelStartsWith(label, "temp") && label.size() > 4 && std::isdigit(static_cast<unsigned char>(label[4]));
    if (tempIndexed || labelEquals(label, "GPU core") || labelEquals(label, "edge"))
        return GpuTempKind::Primary;
    if (labelEquals(label, "junction") || labelEquals(label, "mem"))
        return GpuTempKind::Fallback;

    return GpuTempKind::None;
}

struct TempAccum {
    double sum = 0.0;
    int count = 0;

    void add(double value);
    [[nodiscard]] std::optional<double> average() const;
};

void TempAccum::add(double value) {
    sum += value;
    ++count;
}

std::optional<double> TempAccum::average() const {
    if (count == 0)
        return std::nullopt;
    return sum / count;
}

} // namespace

void ensureInit() {
    std::call_once(g_initFlag, doInit);
}

std::optional<double> cpuPackageTemp() {
    ensureInit();
    if (!g_initOk.load(std::memory_order_acquire))
        return std::nullopt;

    std::optional<double> primary;  // Package id N / Tdie
    std::optional<double> fallback; // Tctl

    forEachTempFeature(
        SENSORS_BUS_TYPE_ANY, [&](const sensors_chip_name* chip, const sensors_feature* feat, const QByteArray& label) {
            if (labelStartsWith(label, "Package id ") || labelEquals(label, "Tdie")) {
                if (auto v = readTempInput(chip, feat))
                    primary = v;
            } else if (labelEquals(label, "Tctl")) {
                if (auto v = readTempInput(chip, feat))
                    fallback = v;
            }
        });

    return primary.has_value() ? primary : fallback;
}

std::optional<double> gpuPciAverageTemp() {
    ensureInit();
    if (!g_initOk.load(std::memory_order_acquire))
        return std::nullopt;

    TempAccum primary;
    TempAccum fallback;

    forEachTempFeature(
        SENSORS_BUS_TYPE_PCI, [&](const sensors_chip_name* chip, const sensors_feature* feat, const QByteArray& label) {
            const auto kind = classifyGpuTempLabel(label);
            if (kind == GpuTempKind::None)
                return;

            const auto v = readTempInput(chip, feat);
            if (!v)
                return;

            if (kind == GpuTempKind::Primary)
                primary.add(*v);
            else
                fallback.add(*v);
        });

    if (const auto avg = primary.average())
        return avg;
    return fallback.average();
}

} // namespace caelestia::services::sensorslib
