#pragma once

#include <qobject.h>
#include <qqmlintegration.h>
#include <qqmllist.h>
#include <qset.h>
#include <qtimer.h>

#include <functional>

#include "notifdata.hpp"

namespace caelestia::shell::models {

class NotifStore : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QQmlListProperty<caelestia::shell::models::NotifData> notifs READ notifs NOTIFY notifsChanged)
    Q_PROPERTY(QQmlListProperty<caelestia::shell::models::NotifData> popups READ popups NOTIFY popupsChanged)

public:
    explicit NotifStore(QObject* parent = nullptr);
    ~NotifStore() override;

    [[nodiscard]] QQmlListProperty<NotifData> notifs();
    [[nodiscard]] QQmlListProperty<NotifData> popups();

    Q_INVOKABLE caelestia::shell::models::NotifData* add(QObject* backer, bool popup = true);

signals:
    void notifsChanged();
    void popupsChanged();

private:
    QString m_connectionName;
    QList<NotifData*> m_notifs;
    QSet<NotifData*> m_dirty;
    QTimer m_flushTimer;

    void track(NotifData* notif);
    void markDirty(NotifData* notif);
    void flush();
    void save(const NotifData* notif);
    void remove(NotifData* notif);
    void enforceLimits(const QSet<QString>& groups);
    void evict(qsizetype limit, const std::function<bool(const NotifData*)>& inScope);
    void loadNotifs();
};

} // namespace caelestia::shell::models
