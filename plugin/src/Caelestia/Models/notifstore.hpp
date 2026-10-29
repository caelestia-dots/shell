#pragma once

#include <qobject.h>
#include <qqmlintegration.h>
#include <qqmllist.h>
#include <qset.h>
#include <qtimer.h>

#include "notifdata.hpp"

namespace caelestia::shell::models {

class NotifStore : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QQmlListProperty<caelestia::shell::models::NotifData> notifs READ notifs NOTIFY notifsChanged)

public:
    explicit NotifStore(QObject* parent = nullptr);
    ~NotifStore() override;

    [[nodiscard]] QQmlListProperty<NotifData> notifs();

    Q_INVOKABLE caelestia::shell::models::NotifData* add(QObject* backer);

signals:
    void notifsChanged();

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
    void loadNotifs();
};

} // namespace caelestia::shell::models
