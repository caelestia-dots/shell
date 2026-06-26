#include "tickingservice.hpp"

#include "../Config/config.hpp"
#include "../Config/dashboardconfig.hpp"

namespace caelestia::services {

TickingService::TickingService(QObject* parent)
    : Service(parent)
    , m_timer(new QTimer(this)) {
    m_timer->setSingleShot(false);
    QObject::connect(m_timer, &QTimer::timeout, this, [this] {
        tick();
    });

    auto* dash = caelestia::config::GlobalConfig::instance()->dashboard();
    applyInterval(dash->resourceUpdateInterval());
    QObject::connect(dash, &caelestia::config::DashboardConfig::resourceUpdateIntervalChanged, this, [this, dash] {
        applyInterval(dash->resourceUpdateInterval());
    });
}

int TickingService::updateInterval() const {
    return m_interval;
}

void TickingService::start() {
    m_running = true;
    if (m_interval > 0) {
        m_timer->start(m_interval);
    }
    tick();
}

void TickingService::stop() {
    m_running = false;
    m_timer->stop();
}

void TickingService::applyInterval(int ms) {
    if (ms <= 0 || ms == m_interval) {
        return;
    }
    m_interval = ms;
    if (m_running) {
        m_timer->start(m_interval);
    }
    emit updateIntervalChanged();
}

} // namespace caelestia::services
