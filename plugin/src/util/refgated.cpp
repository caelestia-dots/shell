#include "util/refgated.hpp"

namespace util {

void RefGated::ref(QObject* ref) {
    QObject::connect(
        ref, &QObject::destroyed, this,
        [this, ref] {
            if (m_refs.remove(ref) && m_released && m_refs.isEmpty())
                deleteLater();
        },
        Qt::SingleShotConnection);
    m_refs << ref;
}

void RefGated::release() {
    m_released = true;
    if (m_refs.isEmpty())
        deleteLater();
}

bool RefGated::released() const {
    return m_released;
}

} // namespace util
