#include "notifgroup.hpp"

namespace caelestia::shell::models {

NotifGroup::NotifGroup(QString appName, QObject* parent)
    : util::RefGated(parent)
    , m_appName(std::move(appName)) {}

QString NotifGroup::appName() const {
    return m_appName;
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

} // namespace caelestia::shell::models
