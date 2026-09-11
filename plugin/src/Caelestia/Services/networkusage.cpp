#include "networkusage.hpp"

#include <qbytearray.h>
#include <qbytearrayview.h>
#include <qfile.h>
#include <qhash.h>
#include <qtypes.h>

#include <array>
#include <charconv>
#include <system_error>
#include <utility>

namespace caelestia::services {

using Qt::StringLiterals::operator""_s;

NetworkUsage::NetworkUsage(QObject* parent)
    : TickingService(parent)
    , m_downloadBuffer(new CircularBuffer(this))
    , m_uploadBuffer(new CircularBuffer(this)) {
    m_downloadBuffer->setCapacity(m_historyLength + 1);
    m_uploadBuffer->setCapacity(m_historyLength + 1);
}

qreal NetworkUsage::downloadSpeed() const {
    return m_downloadSpeed;
}

qreal NetworkUsage::uploadSpeed() const {
    return m_uploadSpeed;
}

qreal NetworkUsage::downloadTotal() const {
    return m_downloadTotal;
}

qreal NetworkUsage::uploadTotal() const {
    return m_uploadTotal;
}

int NetworkUsage::historyLength() const {
    return m_historyLength;
}

CircularBuffer* NetworkUsage::downloadBuffer() const {
    return m_downloadBuffer;
}

CircularBuffer* NetworkUsage::uploadBuffer() const {
    return m_uploadBuffer;
}

bool NetworkUsage::readCounters(QHash<QByteArray, std::pair<quint64, quint64>>& counters) {
    QFile f(u"/proc/net/dev"_s);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return false;
    }
    // Skip headers
    f.readLine();
    f.readLine();

    while (!f.atEnd()) {
        const QByteArray line = f.readLine();
        const qsizetype splitIdx = line.indexOf(':');
        if (splitIdx == -1) {
            continue;
        }
        const QByteArray iface = line.left(splitIdx).trimmed();
        if (iface == QByteArrayView("lo")) {
            continue; // Skip loopback interface
        }

        // Parse every counter through tx bytes to validate the row
        const char* pos = line.constData() + splitIdx + 1;
        const char* const end = line.constData() + line.size();

        std::array<unsigned long long, 9> fields{};
        bool valid = true;
        for (unsigned long long& field : fields) {
            while (pos < end && (*pos == ' ' || *pos == '\t'))
                ++pos;

            const auto [next, ec] = std::from_chars(pos, end, field);
            if (ec != std::errc{}) {
                valid = false;
                break;
            }
            pos = next;
        }

        if (!valid)
            continue;

        counters.insert(iface, { static_cast<quint64>(fields[0]), static_cast<quint64>(fields[8]) });
    }
    f.close();

    return true;
}

void NetworkUsage::tick() {
    QHash<QByteArray, std::pair<quint64, quint64>> current;
    if (!readCounters(current)) {
        return;
    }

    if (!m_initialized) {
        m_prev = current;
        m_timer.start();
        m_initialized = true;
        return;
    }

    const qreal elapsed = static_cast<qreal>(m_timer.restart()) / 1000.0;

    // Diff each interface separately so a NIC appearing or disappearing between ticks cannot spike the total
    quint64 rxDelta = 0;
    quint64 txDelta = 0;
    for (auto it = current.cbegin(); it != current.cend(); ++it) {
        const auto prev = m_prev.constFind(it.key());
        if (prev == m_prev.cend()) {
            continue;
        }
        if (it.value().first >= prev.value().first) {
            rxDelta += it.value().first - prev.value().first;
        }
        if (it.value().second >= prev.value().second) {
            txDelta += it.value().second - prev.value().second;
        }
    }

    m_downloadTotal += static_cast<qreal>(rxDelta);
    m_uploadTotal += static_cast<qreal>(txDelta);

    if (elapsed > 0.0) {
        // Calculate speeds
        m_downloadSpeed = static_cast<qreal>(rxDelta) / elapsed;
        m_uploadSpeed = static_cast<qreal>(txDelta) / elapsed;

        m_downloadBuffer->push(m_downloadSpeed);
        m_uploadBuffer->push(m_uploadSpeed);
    }

    m_prev = current;

    emit changed();
}

} // namespace caelestia::services
