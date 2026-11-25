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
    Q_PROPERTY(QQmlListProperty<caelestia::shell::models::NotifData> popups READ popups NOTIFY popupsChanged)
    Q_PROPERTY(QQmlListProperty<caelestia::shell::models::NotifGroup> groups READ groups NOTIFY groupsChanged)

public:
    explicit NotifStore(QObject* parent = nullptr);
    ~NotifStore() override;

    [[nodiscard]] QQmlListProperty<NotifData> notifs();
    [[nodiscard]] QQmlListProperty<NotifData> popups();
    [[nodiscard]] QQmlListProperty<NotifGroup> groups();

    Q_INVOKABLE caelestia::shell::models::NotifData* add(QObject* backer, bool popup = true);
    Q_INVOKABLE void clear();

signals:
    void notifsChanged();
    void popupsChanged();
    void groupsChanged();

private:
    QString m_connectionName;
    QList<NotifData*> m_notifs;
    QList<NotifData*> m_popups;
    QList<NotifGroup*> m_groups;
    QHash<QString, NotifGroup*> m_groupsByName;
    QSet<NotifData*> m_dirty;
    QTimer m_flushTimer;
    QTimer m_timeStrTimer;

    void track(NotifData* notif);
    void addToGroup(NotifData* notif);
    void removeFromGroup(NotifData* notif);
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
