#include "usagefmt.hpp"

namespace {

constexpr qreal k_kib = 1024.0;
constexpr qreal k_mib = k_kib * 1024.0;
constexpr qreal k_gib = k_mib * 1024.0;

bool finitePositive(qreal v) {
    return std::isfinite(v) && v >= 0.0;
}

} // namespace

namespace caelestia::services::usagefmt {

using Qt::StringLiterals::operator""_s;

FormatResult UsageFmt::formatKib(qreal kib, qreal total) {
    if (!finitePositive(kib) || !finitePositive(total))
        return { .value = 0.0, .total = 0.0, .unit = u"KiB"_s };

    if (total >= k_gib)
        return { .value = kib / k_gib, .total = total / k_gib, .unit = u"TiB"_s };
    if (total >= k_mib)
        return { .value = kib / k_mib, .total = total / k_mib, .unit = u"GiB"_s };
    if (total >= k_kib)
        return { .value = kib / k_kib, .total = total / k_kib, .unit = u"MiB"_s };
    return { .value = kib, .total = total, .unit = u"KiB"_s };
}

} // namespace caelestia::services::usagefmt
