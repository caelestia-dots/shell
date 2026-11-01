#pragma once

#include <qhash.h>
#include <qlist.h>
#include <qobject.h>

#include "notifdata.hpp"
#include "notifgroup.hpp"

namespace caelestia::shell::models {

class NotifGroupIndex {
public:
    explicit NotifGroupIndex(QObject* owner);

    [[nodiscard]] const QList<NotifGroup*>& list() const;
    [[nodiscard]] bool contains(const NotifData* notif) const;

    void add(NotifData* notif);
    // Returns whether the group list itself changed
    bool remove(NotifData* notif);

private:
    QObject* m_owner;
    QList<NotifGroup*> m_list;
    QHash<QString, NotifGroup*> m_byName;
    QHash<const NotifData*, NotifGroup*> m_byNotif;

    bool reposition(NotifGroup* group, bool tiesFirst);
};

} // namespace caelestia::shell::models
