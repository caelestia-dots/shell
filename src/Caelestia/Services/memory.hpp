#pragma once

#include "tickingservice.hpp"

#include <qqmlintegration.h>
#include <qvariant.h>

namespace caelestia::services {

class Memory : public TickingService {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(qreal used READ used NOTIFY changed)
    Q_PROPERTY(qreal total READ total NOTIFY changed)
    Q_PROPERTY(qreal percentage READ percentage NOTIFY changed)

public:
    explicit Memory(QObject* parent = nullptr);

    [[nodiscard]] qreal used() const;
    [[nodiscard]] qreal total() const;
    [[nodiscard]] qreal percentage() const;

signals:
    void changed();

protected:
    void tick() override;

private:
    qreal m_used = 0.0;
    qreal m_total = 1.0;
    quint64 m_lastUsed = 0;
    quint64 m_lastTotal = 0;
};

} // namespace caelestia::services
