#include "service.hpp"

#include <QDebug>
#include <QObject>
#include <qqmlintegration.h>

int Service::refCount() const {
    return m_refCount;
}

void Service::setRefCount(int refCount) {
    if (refCount < 0) {
        qWarning() << "Service::setRefCount: refCount must be >= 0";
        refCount = 0;
    }

    if (m_refCount == refCount) {
        return;
    }

    const int oldRefCount = m_refCount;

    m_refCount = refCount;
    emit refCountChanged();

    if (refCount == 0) {
        stop();
    } else if (oldRefCount == 0) {
        start();
    }
}
