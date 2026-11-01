#pragma once

#include <qtypes.h>

#include <optional>

namespace caelestia::services::nvml {

struct Sample {
    quint32 utilization; // Percent of time the GPU was busy over the last sample period
    quint32 temperature; // Degrees Celsius
};

// Reads utilisation and temperature of the first NVIDIA GPU through NVML. The library is loaded
// at runtime, so there is no build dependency and no process is spawned: a query takes
// microseconds, where `nvidia-smi` costs a fork/exec each time. Returns nullopt when NVML or a
// GPU isn't available, so callers can fall back to nvidia-smi.
std::optional<Sample> sample();

} // namespace caelestia::services::nvml
