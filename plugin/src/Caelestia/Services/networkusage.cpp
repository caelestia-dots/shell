#include "networkusage.hpp"

#include <qbytearrayview.h>
#include <qfile.h>
#include <qtypes.h>

#include <array>
#include <charconv>
#include <cmath>
#include <system_error>

namespace {

constexpr qreal k_bytesPerKib = 1024.0;
constexpr qreal k_bytesPerMib = 1024.0 * 1024.0;
constexpr qreal k_bytesPerGib = 1024.0 * 1024.0 * 1024.0;

} // namespace

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

NetworkFormatResult NetworkUsage::formatBytesRate(qreal bytes) {
    NetworkFormatResult result = formatBytes(bytes);
    result.unit = result.unit + u"/s"_s;
    return result;
}

NetworkFormatResult NetworkUsage::formatBytes(qreal bytes) {
    NetworkFormatResult result;

    if (bytes < 0 || std::isnan(bytes) || !std::isfinite(bytes)) {
        result.value = 0;
        result.unit = u"B"_s;
        return result;
    }
    if (bytes < k_bytesPerKib) {
        result.value = bytes;
        result.unit = u"B"_s;
    } else if (bytes < k_bytesPerMib) {
        result.value = bytes / k_bytesPerKib;
        result.unit = u"KB"_s;
    } else if (bytes < k_bytesPerGib) {
        result.value = bytes / k_bytesPerMib;
        result.unit = u"MB"_s;
    } else {
        result.value = bytes / k_bytesPerGib;
        result.unit = u"GB"_s;
    }
    return result;
}

void NetworkUsage::tick() {
    QFile f(u"/proc/net/dev"_s);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return;
    }
    // Skip headers
    f.readLine();
    f.readLine();

    quint64 totalRx = 0;
    quint64 totalTx = 0;

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

        totalRx += static_cast<quint64>(fields[0]);
        totalTx += static_cast<quint64>(fields[8]);
    }
    f.close();

    if (!m_initialized) {
        m_prevRx = totalRx;
        m_prevTx = totalTx;
        m_timer.start();
        m_initialized = true;
        return;
    }

    const qreal elapsed = static_cast<qreal>(m_timer.restart()) / 1000.0;
    const quint64 rxDelta = totalRx >= m_prevRx ? totalRx - m_prevRx : 0;
    const quint64 txDelta = totalTx >= m_prevTx ? totalTx - m_prevTx : 0;

    m_downloadTotal += static_cast<qreal>(rxDelta);
    m_uploadTotal += static_cast<qreal>(txDelta);

    if (elapsed > 0.0) {
        // Calculate speeds
        m_downloadSpeed = static_cast<qreal>(rxDelta) / elapsed;
        m_uploadSpeed = static_cast<qreal>(txDelta) / elapsed;

        m_downloadBuffer->push(m_downloadSpeed);
        m_uploadBuffer->push(m_uploadSpeed);
    }

    m_prevRx = totalRx;
    m_prevTx = totalTx;

    emit changed();
}

} // namespace caelestia::services
