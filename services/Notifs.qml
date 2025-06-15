pragma Singleton
pragma ComponentBehavior: Bound

import "root:/widgets"
import "root:/config"
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick

Singleton {
    id: root

    readonly property list<Notif> list: []
    readonly property list<Notif> popups: list.filter(n => n.popup)
    property list<Notification> pending: []
    property bool notificationsEnabled: true

    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true

        onNotification: notif => {
            notif.tracked = true;
            if (root.notificationsEnabled) {
                root.list.push(notifComp.createObject(root, {
                    popup: true,
                    notification: notif
                }));
            } else {
                root.pending.push(notif);
            }
        }
    }

    function toggleNotifications(newState) {
        if (root.notificationsEnabled === newState)
            return;
        if (!newState) {
            for (const notif of root.list)
                notif.popup = false;
        }
        root.notificationsEnabled = newState;
        if (newState) {
            for (const notif of root.pending) {
                root.list.push(notifComp.createObject(root, {
                    popup: true,
                    notification: notif
                }));
            }
            root.pending = [];
        }
    }

    CustomShortcut {
        name: "clearNotifs"
        description: "Clear all notifications"
        onPressed: {
            for (const notif of root.list)
                notif.popup = false;
        }
    }

    CustomShortcut {
        name: "toggleNotifs"
        description: "Toggle notifications enabled/disabled"
        onPressed: root.toggleNotifications(!root.notificationsEnabled);
    }

    IpcHandler {
        target: "notifs"

        function clear(): void {
            for (const notif of root.list)
                notif.popup = false;
        }
    }

    component Notif: QtObject {
        id: notif

        property bool popup
        readonly property date time: new Date()
        readonly property string timeStr: {
            const diff = Time.date.getTime() - time.getTime();
            const m = Math.floor(diff / 60000);
            const h = Math.floor(m / 60);

            if (h < 1 && m < 1)
                return "now";
            if (h < 1)
                return `${m}m`;
            return `${h}h`;
        }

        required property Notification notification
        readonly property string summary: notification.summary
        readonly property string body: notification.body
        readonly property string appIcon: notification.appIcon
        readonly property string appName: notification.appName
        readonly property string image: notification.image
        readonly property var urgency: notification.urgency // Idk why NotificationUrgency doesn't work
        readonly property list<NotificationAction> actions: notification.actions

        readonly property Timer timer: Timer {
            running: true
            interval: notif.notification.expireTimeout > 0 ? notif.notification.expireTimeout : Config.notifs.defaultExpireTimeout
            onTriggered: {
                if (Config.notifs.expire)
                    notif.popup = false;
            }
        }

        readonly property Connections conn: Connections {
            target: notif.notification.Retainable

            function onDropped(): void {
                root.list.splice(root.list.indexOf(notif), 1);
            }

            function onAboutToDestroy(): void {
                notif.destroy();
            }
        }
    }

    Component {
        id: notifComp

        Notif {}
    }
}
