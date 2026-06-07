#include "usagefmt.hpp"

namespace {

constexpr qreal kKib = 1024.0;
constexpr qreal kMib = kKib * 1024.0;
constexpr qreal kGib = kMib * 1024.0;

bool finitePositive(qreal v) {
    return std::isfinite(v) && v >= 0.0;
}

} // namespace

namespace caelestia::services::usagefmt {

FormatResult UsageFmt::formatKib(qreal kib, qreal total) const {
    if (!finitePositive(kib) || !finitePositive(total)) {
        return { 0.0, 0.0, "KiB" };
    }
    if (total >= kGib) {
        return { kib / kGib, total / kGib, "TiB" };
    }
    if (total >= kMib) {
        return { kib / kMib, total / kMib, "GiB" };
    }
    if (total >= kKib) {
        return { kib / kKib, total / kKib, "MiB" };
    }
    return { kib, total, "KiB" };
}

} // namespace caelestia::services::usagefmt
