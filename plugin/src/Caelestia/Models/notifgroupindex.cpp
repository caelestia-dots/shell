#include "notifgroupindex.hpp"

namespace caelestia::shell::models {

NotifGroupIndex::NotifGroupIndex(QObject* owner)
    : m_owner(owner) {}

const QList<NotifGroup*>& NotifGroupIndex::list() const {
    return m_list;
}

QQmlListProperty<NotifGroup> NotifGroupIndex::qmlList() {
    return { m_owner, &m_list,
        [](auto* p) {
            return static_cast<const QList<NotifGroup*>*>(p->data)->size();
        },
        [](auto* p, qsizetype i) {
            return static_cast<const QList<NotifGroup*>*>(p->data)->at(i);
        } };
}

bool NotifGroupIndex::contains(const NotifData* notif) const {
    return m_byNotif.contains(notif);
}

bool NotifGroupIndex::add(NotifData* notif) {
    auto*& group = m_byName[notif->appName()];
    const auto created = !group;
    if (created) {
        group = new NotifGroup(notif->appName(), m_owner);
        m_list.prepend(group);
    }

    m_byNotif.insert(notif, group);
    group->add(notif);
    return reposition(group, true) || created;
}

bool NotifGroupIndex::remove(NotifData* notif) {
    auto* const group = m_byNotif.take(notif);
    if (!group)
        return false;

    group->remove(notif);
    if (!group->m_notifs.isEmpty())
        return reposition(group, false);

    m_list.removeOne(group);
    m_byName.remove(group->m_appName);
    group->release();
    return true;
}

bool NotifGroupIndex::reposition(NotifGroup* group, bool tiesFirst) {
    const auto from = m_list.indexOf(group);
    const auto newest = group->m_notifs.first()->createdAt();

    qsizetype to = 0;
    for (; to < m_list.size(); ++to) {
        auto* const other = m_list.at(to);
        if (other == group)
            continue;
        const auto otherNewest = other->m_notifs.first()->createdAt();
        if (otherNewest < newest || (tiesFirst && otherNewest == newest))
            break;
    }
    if (to > from)
        --to;

    if (to == from)
        return false;
    m_list.move(from, to);
    return true;
}

} // namespace caelestia::shell::models
