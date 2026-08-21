#include "networkusage.hpp"
#include <cmath>
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

QVariantMap NetworkUsage::formatBytes(qreal bytes) const {
    QVariantMap result;

    if (bytes < 0 || std::isnan(bytes) || !std::isfinite(bytes)) {
        result["value"] = 0;
        result["unit"] = "B/s";
        return result;
    }
    if (bytes < 1024) {
        result["value"] = bytes;
        result["unit"] = "B/s";
    } else if (bytes < 1024 * 1024) {
        result["value"] = bytes / 1024.0;
        result["unit"] = "KB/s";
    } else if (bytes < 1024 * 1024 * 1024) {
        result["value"] = bytes / (1024.0 * 1024.0);
        result["unit"] = "MB/s";
    } else {
        result["value"] = bytes / (1024.0 * 1024.0 * 1024.0);
        result["unit"] = "GB/s";
    }
    return result;
}

QVariantMap NetworkUsage::formatBytesTotal(qreal bytes) const {
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
        unsigned long long rx = 0, tx = 0;
        sscanf(line.constData() + splitIdx + 1, "%llu %*u %*u %*u %*u %*u %*u %*u %llu", &rx, &tx);
        totalRx += rx;
        totalTx += tx;
    }
    f.close();

    if (!m_initialized) {
        m_prevRx = totalRx;
        m_prevTx = totalTx;
        m_initialRx = totalRx;
        m_initialTx = totalTx;
        m_timer.start();
        m_initialized = true;
        return;
    }

    const qreal elapsed = static_cast<qreal>(m_timer.restart()) / 1000.0;
    if (elapsed > 0.0) {
        // Calculate byte deltas
        quint64 rxDelta = totalRx >= m_prevRx ? totalRx - m_prevRx : 0;
        quint64 txDelta = totalTx >= m_prevTx ? totalTx - m_prevTx : 0;

        // Calculate speeds
        m_downloadSpeed = static_cast<qreal>(rxDelta) / elapsed;
        m_uploadSpeed = static_cast<qreal>(txDelta) / elapsed;

        m_downloadBuffer->push(m_downloadSpeed);
        m_uploadBuffer->push(m_uploadSpeed);
    }

    // Calculate totals
    m_downloadTotal = totalRx >= m_initialRx ? static_cast<qreal>(totalRx - m_initialRx) : 0.0;
    m_uploadTotal = totalTx >= m_initialTx ? static_cast<qreal>(totalTx - m_initialTx) : 0.0;

    m_prevRx = totalRx;
    m_prevTx = totalTx;

    emit changed();
}

} // namespace caelestia::services
