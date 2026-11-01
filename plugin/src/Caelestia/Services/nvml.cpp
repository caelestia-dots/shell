#include "nvml.hpp"

#include <qlibrary.h>
#include <qloggingcategory.h>

namespace {

Q_LOGGING_CATEGORY(lcNvml, "caelestia.services.nvml", QtInfoMsg)

// Minimal subset of the NVML API (nvml.h), declared here because the header isn't a build
// dependency. The ABI for these calls has been stable across driver releases.
struct nvmlDevice_st;
using Device = nvmlDevice_st*;

struct Utilization {
    unsigned int gpu;
    unsigned int memory;
};

constexpr unsigned int k_success = 0;
constexpr unsigned int k_temperatureGpu = 0;

using InitFn = unsigned int (*)();
using ShutdownFn = unsigned int (*)();
using HandleFn = unsigned int (*)(unsigned int, Device*);
using UtilizationFn = unsigned int (*)(Device, Utilization*);
using TemperatureFn = unsigned int (*)(Device, unsigned int, unsigned int*);

struct Api {
    InitFn init = nullptr;
    HandleFn handleByIndex = nullptr;
    UtilizationFn utilization = nullptr;
    TemperatureFn temperature = nullptr;
    Device device = nullptr;
};

// Loaded once. Stays empty when the library or any symbol is missing.
const Api& api() {
    static const Api k_api = [] {
        Api a;

        // Static so the library stays mapped for the life of the process: the resolved function
        // pointers would dangle if it were unloaded when this lambda returns
        static QLibrary s_lib(QStringLiteral("libnvidia-ml.so.1"));
        if (!s_lib.load()) {
            qCDebug(lcNvml) << "NVML not available:" << s_lib.errorString();
            return a;
        }

        a.init = reinterpret_cast<InitFn>(s_lib.resolve("nvmlInit_v2"));
        a.handleByIndex = reinterpret_cast<HandleFn>(s_lib.resolve("nvmlDeviceGetHandleByIndex_v2"));
        a.utilization = reinterpret_cast<UtilizationFn>(s_lib.resolve("nvmlDeviceGetUtilizationRates"));
        a.temperature = reinterpret_cast<TemperatureFn>(s_lib.resolve("nvmlDeviceGetTemperature"));
        if (!a.init || !a.handleByIndex || !a.utilization || !a.temperature) {
            qCDebug(lcNvml) << "NVML is missing required symbols";
            return Api{};
        }

        if (a.init() != k_success || a.handleByIndex(0, &a.device) != k_success) {
            qCDebug(lcNvml) << "NVML found no usable GPU 0";
            return Api{};
        }
        return a;
    }();
    return k_api;
}

} // namespace

namespace caelestia::services::nvml {

std::optional<Sample> sample() {
    const auto& a = api();
    if (!a.device)
        return std::nullopt;

    Utilization util{};
    unsigned int temp = 0;
    if (a.utilization(a.device, &util) != k_success || a.temperature(a.device, k_temperatureGpu, &temp) != k_success)
        return std::nullopt;

    return Sample{ .utilization = util.gpu, .temperature = temp };
}

} // namespace caelestia::services::nvml
