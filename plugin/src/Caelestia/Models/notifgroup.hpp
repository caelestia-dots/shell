#pragma once

#include <qobject.h>
#include <qqmlintegration.h>
#include <qqmllist.h>

#include "util/refgated.hpp"
#include "notifdata.hpp"

namespace caelestia::shell::models {

class NotifGroup : public util::RefGated {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("NotifGroup instances can only be retrieved from a NotifStore")

    Q_PROPERTY(QString appName READ appName CONSTANT)
    Q_PROPERTY(QQmlListProperty<caelestia::shell::models::NotifData> notifs READ notifs NOTIFY notifsChanged)

public:
    NotifGroup(QString appName, QObject* parent);

    [[nodiscard]] QString appName() const;
    [[nodiscard]] QQmlListProperty<NotifData> notifs();

signals:
    void notifsChanged();

private:
    QString m_appName;
    QList<NotifData*> m_notifs;

    friend class NotifStore;
};

} // namespace caelestia::shell::models
