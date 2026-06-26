#include "sensorslib.hpp"

#include <atomic>
#include <cctype>
#include <cstdlib>
#include <cstring>
#include <mutex>
#include <qloggingcategory.h>
#include <sensors/sensors.h>

Q_LOGGING_CATEGORY(lcSensorsLib, "caelestia.services.sensorslib", QtInfoMsg)

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
    const sensors_subfeature* sf = sensors_get_subfeature(chip, feat, SENSORS_SUBFEATURE_TEMP_INPUT);
    if (!sf) {
        return std::nullopt;
    }
    double value = 0.0;
    if (sensors_get_value(chip, sf->number, &value) != 0) {
        return std::nullopt;
    }
    return value;
}

[[nodiscard]] QByteArray featureLabel(const sensors_chip_name* chip, const sensors_feature* feat) {
    char* raw = sensors_get_label(chip, feat);
    if (!raw) {
        return {};
    }
    QByteArray out(raw);
    std::free(raw);
    return out;
}

bool labelEquals(const QByteArray& label, const char* literal) {
    return label == QByteArrayView(literal);
}

bool labelStartsWith(const QByteArray& label, const char* prefix) {
    const auto n = std::strlen(prefix);
    return static_cast<size_t>(label.size()) >= n && std::memcmp(label.constData(), prefix, n) == 0;
}

} // namespace

void ensureInit() {
    std::call_once(g_initFlag, doInit);
}

std::optional<double> cpuPackageTemp() {
    ensureInit();
    if (!g_initOk.load(std::memory_order_acquire)) {
        return std::nullopt;
    }

    std::optional<double> primary;  // Package id N / Tdie
    std::optional<double> fallback; // Tctl

    int chipNr = 0;
    while (const sensors_chip_name* chip = sensors_get_detected_chips(nullptr, &chipNr)) {
        int featNr = 0;
        while (const sensors_feature* feat = sensors_get_features(chip, &featNr)) {
            if (feat->type != SENSORS_FEATURE_TEMP) {
                continue;
            }
            const QByteArray label = featureLabel(chip, feat);
            if (label.isEmpty()) {
                continue;
            }

            if (labelStartsWith(label, "Package id ") || labelEquals(label, "Tdie")) {
                if (auto v = readTempInput(chip, feat)) {
                    primary = v;
                }
            } else if (labelEquals(label, "Tctl")) {
                if (auto v = readTempInput(chip, feat)) {
                    fallback = v;
                }
            }
        }
    }

    return primary.has_value() ? primary : fallback;
}

std::optional<double> gpuPciAverageTemp() {
    ensureInit();
    if (!g_initOk.load(std::memory_order_acquire)) {
        return std::nullopt;
    }

    double sumPrimary = 0.0;
    int countPrimary = 0;
    double sumFallback = 0.0;
    int countFallback = 0;

    int chipNr = 0;
    while (const sensors_chip_name* chip = sensors_get_detected_chips(nullptr, &chipNr)) {
        if (chip->bus.type != SENSORS_BUS_TYPE_PCI) {
            continue;
        }

        int featNr = 0;
        while (const sensors_feature* feat = sensors_get_features(chip, &featNr)) {
            if (feat->type != SENSORS_FEATURE_TEMP) {
                continue;
            }
            const QByteArray label = featureLabel(chip, feat);
            if (label.isEmpty()) {
                continue;
            }

            const bool tempIndexed = labelStartsWith(label, "temp") && label.size() > 4 &&
                                     std::isdigit(static_cast<unsigned char>(label[4]));
            const bool isPrimary = tempIndexed || labelEquals(label, "GPU core") || labelEquals(label, "edge");
            const bool isFallback = labelEquals(label, "junction") || labelEquals(label, "mem");

            if (!isPrimary && !isFallback) {
                continue;
            }

            const auto v = readTempInput(chip, feat);
            if (!v) {
                continue;
            }
            if (isPrimary) {
                sumPrimary += *v;
                ++countPrimary;
            } else {
                sumFallback += *v;
                ++countFallback;
            }
        }
    }

    if (countPrimary > 0) {
        return sumPrimary / countPrimary;
    }
    if (countFallback > 0) {
        return sumFallback / countFallback;
    }
    return std::nullopt;
}

} // namespace caelestia::services::sensorslib
