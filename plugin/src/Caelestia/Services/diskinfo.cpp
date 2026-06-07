#include "diskinfo.hpp"

namespace caelestia::services {

namespace {

constexpr qreal kKib = 1024.0;

} // namespace

DiskInfo::DiskInfo(QString mount, quint64 usedBytes, quint64 totalBytes, bool hasRoot, QObject* parent)
    : QObject(parent)
    , m_mount(std::move(mount))
    , m_usedBytes(usedBytes)
    , m_totalBytes(totalBytes)
    , m_hasRoot(hasRoot) {}

QString DiskInfo::mount() const {
    return m_mount;
}

qreal DiskInfo::used() const {
    return static_cast<qreal>(m_usedBytes) / kKib;
}

qreal DiskInfo::total() const {
    return static_cast<qreal>(m_totalBytes) / kKib;
}

qreal DiskInfo::free() const {
    const quint64 freeBytes = m_totalBytes > m_usedBytes ? m_totalBytes - m_usedBytes : 0;
    return static_cast<qreal>(freeBytes) / kKib;
}

qreal DiskInfo::perc() const {
    return m_totalBytes > 0 ? static_cast<qreal>(m_usedBytes) / static_cast<qreal>(m_totalBytes) : 0.0;
}

bool DiskInfo::hasRoot() const {
    return m_hasRoot;
}

void DiskInfo::update(quint64 usedBytes, quint64 totalBytes, bool hasRoot) {
    const bool usedDiff = usedBytes != m_usedBytes;
    const bool totalDiff = totalBytes != m_totalBytes;
    const bool rootDiff = hasRoot != m_hasRoot;

    m_usedBytes = usedBytes;
    m_totalBytes = totalBytes;
    m_hasRoot = hasRoot;

    if (usedDiff) {
        Q_EMIT usedChanged();
    }
    if (totalDiff) {
        Q_EMIT totalChanged();
    }
    if (usedDiff || totalDiff) {
        Q_EMIT freeChanged();
        Q_EMIT percChanged();
    }
    if (rootDiff) {
        Q_EMIT hasRootChanged();
    }
}

} // namespace caelestia::services
