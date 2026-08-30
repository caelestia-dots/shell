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

using Qt::StringLiterals::operator""_s;

FormatResult UsageFmt::formatKib(qreal kib, qreal total) {
    if (!finitePositive(kib) || !finitePositive(total))
        return { .value = 0.0, .total = 0.0, .unit = u"KiB"_s };

    if (total >= kGib)
        return { .value = kib / kGib, .total = total / kGib, .unit = u"TiB"_s };
    if (total >= kMib)
        return { .value = kib / kMib, .total = total / kMib, .unit = u"GiB"_s };
    if (total >= kKib)
        return { .value = kib / kKib, .total = total / kKib, .unit = u"MiB"_s };
    return { .value = kib, .total = total, .unit = u"KiB"_s };
}

} // namespace caelestia::services::usagefmt
