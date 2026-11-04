#include "util/refgated.hpp"

#include <utility>

namespace util {

void RefGated::ref(QObject* ref) {
    if (m_refs.contains(ref))
        return;

    auto conn = QObject::connect(
        ref, &QObject::destroyed, this,
        [this, ref] {
            dropRef(ref);
        },
        Qt::SingleShotConnection);
    m_refs.insert(ref, std::move(conn));
}

void RefGated::unref(QObject* ref) {
    const auto it = m_refs.constFind(ref);
    if (it == m_refs.constEnd())
        return;

    QObject::disconnect(it.value());
    dropRef(ref);
}

void RefGated::release() {
    m_released = true;
    if (m_refs.isEmpty())
        deleteLater();
}

bool RefGated::released() const {
    return m_released;
}

void RefGated::dropRef(QObject* ref) {
    if (m_refs.remove(ref) && m_released && m_refs.isEmpty())
        deleteLater();
}

} // namespace util
