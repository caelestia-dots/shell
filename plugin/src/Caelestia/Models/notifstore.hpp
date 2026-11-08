#pragma once

#include <qobject.h>
#include <qqmlintegration.h>
#include <qqmllist.h>
#include <qset.h>
#include <qtimer.h>

#include <functional>

#include "notifdata.hpp"
#include "notifgroup.hpp"
#include "notifgroupindex.hpp"

namespace caelestia::shell::models {

class NotifPopups;

class NotifStore : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QQmlListProperty<caelestia::shell::models::NotifData> notifs READ notifs NOTIFY notifsChanged)
    Q_PROPERTY(QQmlListProperty<caelestia::shell::models::NotifGroup> groups READ groups NOTIFY groupsChanged)

public:
    explicit NotifStore(QObject* parent = nullptr);
    ~NotifStore() override;

    [[nodiscard]] QQmlListProperty<NotifData> notifs();
    [[nodiscard]] QQmlListProperty<NotifGroup> groups();

    Q_INVOKABLE caelestia::shell::models::NotifData* add(QObject* backer, bool popup = true);
    Q_INVOKABLE void clear();
    Q_INVOKABLE void closePopups();

signals:
    void notifsChanged();
    void groupsChanged();

private:
    QString m_connectionName;

    QList<NotifData*> m_notifs;
    NotifGroupIndex m_groups;
    QList<NotifPopups*> m_popups;
    QSet<NotifData*> m_dirty;
    QTimer m_flushTimer;
    QTimer m_timeStrTimer;

    void track(NotifData* notif);
    void closePopup(NotifData* notif);
    void regroup(NotifData* notif);
    void markDirty(NotifData* notif);
    void flush();
    void save(const NotifData* notif);
    void remove(NotifData* notif);
    void enforceLimits(const QSet<QString>& groups);
    void evict(qsizetype limit, const std::function<bool(const NotifData*)>& inScope);
    void loadNotifs();
    void refreshTimeStrs();

    friend class NotifPopups;
};

} // namespace caelestia::shell::models
