#pragma once

#include <qbytearray.h>
#include <qelapsedtimer.h>
#include <qhash.h>
#include <qqmlintegration.h>

#include <utility>

#include "core/circularbuffer.hpp"
#include "tickingservice.hpp"

namespace caelestia::services {

class NetworkUsage : public TickingService {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(qreal downloadSpeed READ downloadSpeed NOTIFY changed)
    Q_PROPERTY(qreal uploadSpeed READ uploadSpeed NOTIFY changed)
    Q_PROPERTY(qreal downloadTotal READ downloadTotal NOTIFY changed)
    Q_PROPERTY(qreal uploadTotal READ uploadTotal NOTIFY changed)
    Q_PROPERTY(int historyLength READ historyLength CONSTANT)

    Q_PROPERTY(caelestia::CircularBuffer* downloadBuffer READ downloadBuffer CONSTANT)
    Q_PROPERTY(caelestia::CircularBuffer* uploadBuffer READ uploadBuffer CONSTANT)

public:
    explicit NetworkUsage(QObject* parent = nullptr);

    [[nodiscard]] qreal downloadSpeed() const;
    [[nodiscard]] qreal uploadSpeed() const;
    [[nodiscard]] qreal downloadTotal() const;
    [[nodiscard]] qreal uploadTotal() const;
    [[nodiscard]] int historyLength() const;

    [[nodiscard]] CircularBuffer* downloadBuffer() const;
    [[nodiscard]] CircularBuffer* uploadBuffer() const;

signals:
    void changed();

protected:
    void tick() override;

private:
    [[nodiscard]] static bool readCounters(QHash<QByteArray, std::pair<quint64, quint64>>& counters);

    qreal m_downloadSpeed = 0.0;
    qreal m_uploadSpeed = 0.0;
    qreal m_downloadTotal = 0.0;
    qreal m_uploadTotal = 0.0;
    int m_historyLength = 30;

    CircularBuffer* m_downloadBuffer = nullptr;
    CircularBuffer* m_uploadBuffer = nullptr;

    QHash<QByteArray, std::pair<quint64, quint64>> m_prev;
    bool m_initialized = false;
    QElapsedTimer m_timer;
};

} // namespace caelestia::services
