#include "networkusage.hpp"
#include <array>
#include <cmath>
#include <cstdio>
#include <qfile.h>
#include <qtypes.h>

namespace caelestia::services {

NetworkUsage::NetworkUsage(QObject* parent)
    : TickingService(parent)
    , m_downloadBuffer(new internal::CircularBuffer(this))
    , m_uploadBuffer(new internal::CircularBuffer(this)) {
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

caelestia::internal::CircularBuffer* NetworkUsage::downloadBuffer() const {
    return m_downloadBuffer;
}

caelestia::internal::CircularBuffer* NetworkUsage::uploadBuffer() const {
    return m_uploadBuffer;
}

QVariantMap NetworkUsage::formatBytesRate(qreal bytes) const {
    QVariantMap result = formatBytes(bytes);
    result["unit"] = result["unit"].toString() + QStringLiteral("/s");
    return result;
}

QVariantMap NetworkUsage::formatBytes(qreal bytes) const {
    QVariantMap result;

    if (bytes < 0 || std::isnan(bytes) || !std::isfinite(bytes)) {
        result["value"] = 0;
        result["unit"] = "B";
        return result;
    }
    if (bytes < 1024) {
        result["value"] = bytes;
        result["unit"] = "B";
    } else if (bytes < 1024 * 1024) {
        result["value"] = bytes / 1024.0;
        result["unit"] = "KB";
    } else if (bytes < 1024 * 1024 * 1024) {
        result["value"] = bytes / (1024.0 * 1024.0);
        result["unit"] = "MB";
    } else {
        result["value"] = bytes / (1024.0 * 1024.0 * 1024.0);
        result["unit"] = "GB";
    }
    return result;
}

void NetworkUsage::tick() {
    QFile f(QStringLiteral("/proc/net/dev"));
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return;
    }
    // skip headers
    f.readLine();
    f.readLine();

    quint64 totalRx = 0;
    quint64 totalTx = 0;

    while (!f.atEnd()) {
        QByteArray line = f.readLine();
        const qsizetype splitIdx = line.indexOf(':');
        if (splitIdx == -1) {
            continue;
        }
        const QByteArray iface = line.left(splitIdx).trimmed();
        if (iface == "lo") {
            continue; // skip loopback interface
        }

        std::array<unsigned long long, 9> fields{};
        const int parsed = std::sscanf(line.constData() + splitIdx + 1, "%llu %llu %llu %llu %llu %llu %llu %llu %llu",
            &fields[0], &fields[1], &fields[2], &fields[3], &fields[4], &fields[5], &fields[6], &fields[7], &fields[8]);

        if (parsed != static_cast<int>(fields.size())) {
            continue;
        }

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
