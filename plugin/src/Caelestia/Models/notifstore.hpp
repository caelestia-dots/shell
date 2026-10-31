#pragma once

#include <qhash.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qqmllist.h>
#include <qset.h>
#include <qtimer.h>

#include <functional>

#include "notifdata.hpp"
#include "notifgroup.hpp"

namespace caelestia::shell::models {

class NotifStore : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QQmlListProperty<caelestia::shell::models::NotifData> notifs READ notifs NOTIFY notifsChanged)
    Q_PROPERTY(QQmlListProperty<caelestia::shell::models::NotifGroup> groups READ groups NOTIFY groupsChanged)
    Q_PROPERTY(
        QQmlListProperty<caelestia::shell::models::NotifGroup> popupGroups READ popupGroups NOTIFY popupGroupsChanged)

public:
    explicit NotifStore(QObject* parent = nullptr);
    ~NotifStore() override;

    [[nodiscard]] QQmlListProperty<NotifData> notifs();
    [[nodiscard]] QQmlListProperty<NotifGroup> groups();
    [[nodiscard]] QQmlListProperty<NotifGroup> popupGroups();

    Q_INVOKABLE caelestia::shell::models::NotifData* add(QObject* backer, bool popup = true);
    Q_INVOKABLE void clear();

signals:
    void notifsChanged();
    void groupsChanged();
    void popupGroupsChanged();

private:
    QString m_connectionName;

    struct GroupIndex {
        QList<NotifGroup*> list;
        QHash<QString, NotifGroup*> byName;
    };

    QList<NotifData*> m_notifs;
    GroupIndex m_groups;
    GroupIndex m_popupGroups;
    QSet<NotifData*> m_dirty;
    QTimer m_flushTimer;
    QTimer m_timeStrTimer;

    void track(NotifData* notif);
    void addToGroup(GroupIndex& index, NotifGroup*& slot, NotifData* notif);
    bool removeFromGroup(GroupIndex& index, NotifGroup*& slot, NotifData* notif);
    void regroup(NotifData* notif);
    void markDirty(NotifData* notif);
    void flush();
    void save(const NotifData* notif);
    void remove(NotifData* notif);
    void enforceLimits(const QSet<QString>& groups);
    void evict(qsizetype limit, const std::function<bool(const NotifData*)>& inScope);
    void loadNotifs();
    void refreshTimeStrs();
};

} // namespace caelestia::shell::models
