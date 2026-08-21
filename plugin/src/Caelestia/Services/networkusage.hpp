#pragma once

#include "../Internal/circularbuffer.hpp"
#include "tickingservice.hpp"

#include <qelapsedtimer.h>
#include <qqmlintegration.h>
#include <qvariant.h>

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

    Q_PROPERTY(internal::CircularBuffer* downloadBuffer READ downloadBuffer CONSTANT)
    Q_PROPERTY(internal::CircularBuffer* uploadBuffer READ uploadBuffer CONSTANT)

public:
    explicit NetworkUsage(QObject* parent = nullptr);

    [[nodiscard]] qreal downloadSpeed() const;
    [[nodiscard]] qreal uploadSpeed() const;
    [[nodiscard]] qreal downloadTotal() const;
    [[nodiscard]] qreal uploadTotal() const;
    [[nodiscard]] int historyLength() const;

    Q_INVOKABLE [[nodiscard]] QVariantMap formatBytes(qreal bytes) const;
    Q_INVOKABLE [[nodiscard]] QVariantMap formatBytesTotal(qreal bytes) const;

    [[nodiscard]] internal::CircularBuffer* downloadBuffer() const;
    [[nodiscard]] internal::CircularBuffer* uploadBuffer() const;

signals:
    void changed();

protected:
    void tick() override;

private:
    qreal m_downloadSpeed = 0.0;
    qreal m_uploadSpeed = 0.0;
    qreal m_downloadTotal = 0.0;
    qreal m_uploadTotal = 0.0;
    int m_historyLength = 30;

    internal::CircularBuffer* m_downloadBuffer = nullptr;
    internal::CircularBuffer* m_uploadBuffer = nullptr;

    quint64 m_prevRx = 0;
    quint64 m_prevTx = 0;
    quint64 m_initialRx = 0;
    quint64 m_initialTx = 0;
    bool m_initialized = false;
    QElapsedTimer m_timer;
};

} // namespace caelestia::services
