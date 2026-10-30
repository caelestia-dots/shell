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
    return m_image;
}

QString NotifGroup::icon() const {
    return m_icon;
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

void NotifGroup::sync() {
    QString image;
    QString icon;
    auto urgency = NotifData::Urgency::Low;

    for (const auto* notif : std::as_const(m_notifs)) {
        if (image.isEmpty())
            image = notif->image();
        if (icon.isEmpty())
            icon = notif->appIcon();
        urgency = std::max(urgency, notif->urgency());
    }

    if (m_image != image) {
        m_image = std::move(image);
        emit imageChanged();
    }
    if (m_icon != icon) {
        m_icon = std::move(icon);
        emit iconChanged();
    }
    if (m_urgency != urgency) {
        m_urgency = urgency;
        emit urgencyChanged();
    }
}

} // namespace caelestia::shell::models
