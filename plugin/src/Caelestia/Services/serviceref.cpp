#include "serviceref.hpp"

#include "service.hpp"

namespace caelestia::services {

ServiceRef::ServiceRef(Service* service, QObject* parent)
    : QObject(parent)
    , m_service(service) {
    if (m_service) {
        m_service->ref(this);
    }
}

ServiceRef::~ServiceRef() {
    if (m_service) {
        m_service->unref(this);
    }
}

Service* ServiceRef::service() const {
    return m_service;
}

void ServiceRef::setService(Service* service) {
    if (m_service == service) {
        return;
    }

    Service* const oldService = m_service;
    m_service = service;

    if (m_service) {
        m_service->ref(this);
    }
    if (oldService) {
        oldService->unref(this);
    }

    emit serviceChanged();
}

} // namespace caelestia::services
