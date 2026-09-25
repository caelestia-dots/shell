#include "service.hpp"

namespace caelestia::services {

Service::Service(QObject* parent)
    : QObject(parent) {}

void Service::ref(QObject* sender) {
    if (!sender) {
        return;
    }

    if (m_refs.isEmpty()) {
        start();
    }

    QObject::connect(sender, &QObject::destroyed, this, &Service::unref, Qt::UniqueConnection);
    m_refs << sender;
}

void Service::unref(QObject* sender) {
    if (!sender) {
        return;
    }

    QObject::disconnect(sender, &QObject::destroyed, this, &Service::unref);
    if (m_refs.remove(sender) && m_refs.isEmpty()) {
        stop();
    }
}

} // namespace caelestia::services
