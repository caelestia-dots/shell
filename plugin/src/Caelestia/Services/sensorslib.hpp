#pragma once

#include <optional>

namespace caelestia::services::sensorslib {

void ensureInit();

[[nodiscard]] std::optional<double> cpuPackageTemp();
[[nodiscard]] std::optional<double> gpuPciAverageTemp();

} // namespace caelestia::services::sensorslib
