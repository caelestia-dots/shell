#pragma once

#include <qhash.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qqmllist.h>
#include <qtimer.h>

#include "notifdata.hpp"
#include "notifgroup.hpp"
#include "notifgroupindex.hpp"
#include "notifstore.hpp"

namespace caelestia::shell::models {

class NotifPopups : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(caelestia::shell::models::NotifStore* store READ store WRITE setStore NOTIFY storeChanged)
    Q_PROPERTY(bool fullscreen READ fullscreen WRITE setFullscreen NOTIFY fullscreenChanged)
    Q_PROPERTY(QQmlListProperty<caelestia::shell::models::NotifGroup> groups READ groups NOTIFY groupsChanged)

public:
    explicit NotifPopups(QObject* parent = nullptr);
    ~NotifPopups() override;

    [[nodiscard]] NotifStore* store() const;
    void setStore(NotifStore* store);

    [[nodiscard]] bool fullscreen() const;
    void setFullscreen(bool fullscreen);

    [[nodiscard]] QQmlListProperty<NotifGroup> groups();

    Q_INVOKABLE void hold(caelestia::shell::models::NotifData* notif);
    Q_INVOKABLE void release(caelestia::shell::models::NotifData* notif);
    Q_INVOKABLE void dismiss(caelestia::shell::models::NotifData* notif);

signals:
    void storeChanged();
    void fullscreenChanged();
    void groupsChanged();

private:
    struct Popup {
        QTimer* timer = nullptr;
        int remaining = -1;
    };

    NotifStore* m_store = nullptr;
    bool m_fullscreen = false;
    NotifGroupIndex m_groups;
    QHash<NotifData*, Popup> m_popups;

    void offer(NotifData* notif);
    void close(NotifData* notif);
    void closeAll();
    void regroup(NotifData* notif);

    friend class NotifStore;
};

} // namespace caelestia::shell::models
