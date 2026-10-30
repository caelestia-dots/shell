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
    Q_PROPERTY(QString image READ image NOTIFY imageChanged)
    Q_PROPERTY(QString icon READ icon NOTIFY iconChanged)
    Q_PROPERTY(caelestia::shell::models::NotifData::Urgency urgency READ urgency NOTIFY urgencyChanged)
    Q_PROPERTY(QQmlListProperty<caelestia::shell::models::NotifData> notifs READ notifs NOTIFY notifsChanged)

public:
    NotifGroup(QString appName, QObject* parent);

    [[nodiscard]] QString appName() const;
    [[nodiscard]] QString image() const;
    [[nodiscard]] QString icon() const;
    [[nodiscard]] NotifData::Urgency urgency() const;
    [[nodiscard]] QQmlListProperty<NotifData> notifs();

signals:
    void imageChanged();
    void iconChanged();
    void urgencyChanged();
    void notifsChanged();

private:
    QString m_appName;
    QString m_image;
    QString m_icon;
    NotifData::Urgency m_urgency = NotifData::Urgency::Normal;
    QList<NotifData*> m_notifs;

    void sync();

    friend class NotifStore;
};

} // namespace caelestia::shell::models
