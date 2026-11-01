#include "notifgroup.hpp"

#include <algorithm>
#include <utility>

namespace caelestia::shell::models {

NotifGroup::NotifGroup(QString appName, QObject* parent)
    : util::RefGated(parent)
    , m_appName(std::move(appName)) {}

QString NotifGroup::appName() const {
    return m_appName;
}

QString NotifGroup::image() const {
    return m_imageSource ? m_imageSource->image() : QString();
}

QString NotifGroup::icon() const {
    return m_iconSource ? m_iconSource->appIcon() : QString();
}

NotifData::Urgency NotifGroup::urgency() const {
    return m_urgency;
}

QQmlListProperty<NotifData> NotifGroup::notifs() {
    return { this, nullptr,
        [](auto* p) {
            return static_cast<NotifGroup*>(p->object)->m_notifs.size();
        },
        [](auto* p, qsizetype i) {
            return static_cast<NotifGroup*>(p->object)->m_notifs.at(i);
        } };
}

void NotifGroup::add(NotifData* notif) {
    const auto pos = std::ranges::find_if(m_notifs, [notif](const NotifData* n) {
        return n->createdAt() <= notif->createdAt();
    });
    m_notifs.insert(pos, notif);
    QObject::connect(notif, &NotifData::imageChanged, this, &NotifGroup::sync);
    QObject::connect(notif, &NotifData::appIconChanged, this, &NotifGroup::sync);
    QObject::connect(notif, &NotifData::urgencyChanged, this, &NotifGroup::sync);
    sync();
    emit notifsChanged();
}

void NotifGroup::remove(NotifData* notif) {
    m_notifs.removeOne(notif);
    QObject::disconnect(notif, nullptr, this, nullptr);
    if (m_notifs.isEmpty()) {
        m_imageSource = nullptr;
        m_iconSource = nullptr;
    } else {
        sync();
    }
    emit notifsChanged();
}

void NotifGroup::sync() {
    NotifData* imageSource = nullptr;
    NotifData* iconSource = nullptr;
    auto urgency = NotifData::Urgency::Low;

    for (auto* const notif : std::as_const(m_notifs)) {
        if (!imageSource && !notif->image().isEmpty())
            imageSource = notif;
        if (!iconSource && !notif->appIcon().isEmpty())
            iconSource = notif;
        urgency = std::max(urgency, notif->urgency());
    }

    if (m_imageSource != imageSource) {
        m_imageSource = imageSource;
        emit imageChanged();
    }
    if (m_iconSource != iconSource) {
        m_iconSource = iconSource;
        emit iconChanged();
    }
    if (m_urgency != urgency) {
        m_urgency = urgency;
        emit urgencyChanged();
    }
}

} // namespace caelestia::shell::models
