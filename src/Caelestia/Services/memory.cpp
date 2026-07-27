#include "memory.hpp"

#include <qfile.h>
#include <qregularexpression.h>

namespace caelestia::services {

Memory::Memory(QObject* parent)
    : TickingService(parent) {}

qreal Memory::used() const {
    return m_used;
}

qreal Memory::total() const {
    return m_total;
}

qreal Memory::percentage() const {
    return m_total > 0.0 ? m_used / m_total : 0.0;
}

void Memory::tick() {
    QFile f(QStringLiteral("/proc/meminfo"));
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return;
    }
    const QByteArray data = f.readAll();
    f.close();

    static const QRegularExpression reTotal(QStringLiteral("MemTotal: *(\\d+)"));
    static const QRegularExpression reAvail(QStringLiteral("MemAvailable: *(\\d+)"));
    const QString text = QString::fromLatin1(data);

    const auto totalMatch = reTotal.match(text);
    const auto availMatch = reAvail.match(text);
    if (!totalMatch.hasMatch() || !availMatch.hasMatch()) {
        return;
    }

    const quint64 totalKib = totalMatch.captured(1).toULongLong();
    const quint64 availKib = availMatch.captured(1).toULongLong();
    if (totalKib == 0) {
        return;
    }
    const quint64 usedKib = totalKib > availKib ? totalKib - availKib : 0;

    if (totalKib == m_lastTotal && usedKib == m_lastUsed) {
        return;
    }
    m_lastTotal = totalKib;
    m_lastUsed = usedKib;
    m_total = static_cast<qreal>(totalKib);
    m_used = static_cast<qreal>(usedKib);
    emit changed();
}

} // namespace caelestia::services
