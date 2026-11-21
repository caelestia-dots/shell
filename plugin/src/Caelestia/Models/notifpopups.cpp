#include "notifpopups.hpp"

#include "config/rootnodes.hpp"

namespace caelestia::shell::models {

NotifPopups::NotifPopups(QObject* parent)
    : QObject(parent)
    , m_groups(this) {}

NotifPopups::~NotifPopups() {
    if (m_store)
        m_store->m_popups.removeOne(this);
}

NotifStore* NotifPopups::store() const {
    return m_store;
}

void NotifPopups::setStore(NotifStore* store) {
    if (m_store == store)
        return;

    if (m_store) {
        m_store->m_popups.removeOne(this);
        QObject::disconnect(m_store, nullptr, this, nullptr);
        closeAll();
    }

    m_store = store;
    if (m_store) {
        m_store->m_popups.append(this);
        QObject::connect(m_store, &QObject::destroyed, this, [this] {
            m_store = nullptr;
            closeAll();
        });
    }

    emit storeChanged();
}

bool NotifPopups::fullscreen() const {
    return m_fullscreen;
}

void NotifPopups::setFullscreen(bool fullscreen) {
    if (m_fullscreen == fullscreen)
        return;

    m_fullscreen = fullscreen;
    emit fullscreenChanged();
}

QQmlListProperty<NotifGroup> NotifPopups::groups() {
    return m_groups.qmlList();
}

void NotifPopups::hold(NotifData* notif) {
    const auto it = m_popups.find(notif);
    if (it == m_popups.end() || !it->timer->isActive())
        return;

    it->remaining = it->timer->remainingTime();
    it->timer->stop();
}

void NotifPopups::release(NotifData* notif) {
    const auto it = m_popups.find(notif);
    if (it == m_popups.end() || it->timer->isActive() || it->remaining < 0)
        return;

    it->timer->start(it->remaining);
}

void NotifPopups::dismiss(NotifData* notif) {
    if (m_store)
        m_store->closePopup(notif);
}

void NotifPopups::offer(NotifData* notif) {
    const auto* const cfg = config::ConfigSingleton::instance()->notifs();
    if (m_fullscreen && cfg->fullscreen() == config::NotifsFullscreen::Off)
        return;

    auto* const timer = new QTimer(this);
    timer->setSingleShot(true);
    QObject::connect(timer, &QTimer::timeout, this, [this, notif] {
        close(notif);
    });
    m_popups.insert(notif, { .timer = timer });

    if (m_groups.add(notif))
        emit groupsChanged();

    if (!cfg->expire())
        return;

    const auto useFullscreenTimeout = m_fullscreen && !notif->hasCustomTimeout();
    timer->start(useFullscreenTimeout ? cfg->fullscreenExpireTimeout() : notif->expireTimeout());
}

void NotifPopups::close(NotifData* notif) {
    const auto popup = m_popups.take(notif);
    if (!popup.timer)
        return;

    popup.timer->deleteLater();
    if (m_groups.remove(notif))
        emit groupsChanged();
}

void NotifPopups::closeAll() {
    if (m_popups.isEmpty())
        return;

    for (auto it = m_popups.cbegin(); it != m_popups.cend(); ++it) {
        it->timer->deleteLater();
        m_groups.remove(it.key());
    }
    m_popups.clear();
    emit groupsChanged();
}

void NotifPopups::regroup(NotifData* notif) {
    if (!m_groups.contains(notif))
        return;

    const auto removed = m_groups.remove(notif);
    const auto added = m_groups.add(notif);
    if (removed || added)
        emit groupsChanged();
}

} // namespace caelestia::shell::models
