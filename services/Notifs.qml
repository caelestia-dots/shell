pragma Singleton
pragma ComponentBehavior: Bound

import qs.components.misc
import qs.config
import qs.utils
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick

Singleton {
    id: root

    readonly property list<Notif> list: []
    readonly property list<Notif> popups: list.filter(n => n.popup)
    property alias dnd: props.dnd

    property bool loaded

    onListChanged: {
        if (!loaded)
            return;

        storage.setText(JSON.stringify(list.filter(n => !n.closed).map(n => ({
                    id: n.id,
                    summary: n.summary,
                    body: n.body,
                    appIcon: n.appIcon,
                    appName: n.appName,
                    image: n.image,
                    expireTimeout: n.expireTimeout,
                    urgency: n.urgency,
                    resident: n.resident,
                    hasActionIcons: n.hasActionIcons,
                    actions: n.actions
                }))));
    }

    PersistentProperties {
        id: props

        property bool dnd

        reloadableId: "notifs"
    }

    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => {
            notif.tracked = true;

            root.list.push(notifComp.createObject(root, {
                popup: !props.dnd && ![...Visibilities.screens.values()].some(v => v.sidebar),
                notification: notif
            }));
        }
    }

    FileView {
        id: storage

        path: `${Paths.state}/notifs.json`
        onLoaded: {
            const data = JSON.parse(text());
            for (const notif of data)
                root.list.push(notifComp.createObject(root, notif));
            root.loaded = true;
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                root.loaded = true;
                setText("[]");
            }
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

    IpcHandler {
        target: "notifs"

        function clear(): void {
            for (const notif of root.list)
                notif.popup = false;
        }

        function isDndEnabled(): bool {
            return props.dnd;
        }

        function toggleDnd(): void {
            props.dnd = !props.dnd;
        }

        function enableDnd(): void {
            props.dnd = true;
        }

        function disableDnd(): void {
            props.dnd = false;
        }
    }

    component Notif: QtObject {
        id: notif

        property bool popup
        property bool closed
        property var locks: new Set()

        property date time: new Date()
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

        property Notification notification
        property string id: notification?.id ?? ""
        property string summary: notification?.summary ?? ""
        property string body: notification?.body ?? ""
        property string appIcon: notification?.appIcon ?? ""
        property string appName: notification?.appName ?? ""
        property string image: notification?.image ?? ""
        property real expireTimeout: notification?.expireTimeout ?? Config.notifs.defaultExpireTimeout
        property int urgency: notification?.urgency ?? NotificationUrgency.Normal
        property bool resident: notification?.resident ?? false
        property bool hasActionIcons: notification?.hasActionIcons ?? false
        property list<var> actions: notification?.actions.map(a => ({
                identifier: a.identifier,
                text: a.text,
                invoke: () => a.invoke()
            })) ?? []

        readonly property Timer timer: Timer {
            running: true
            interval: notif.expireTimeout > 0 ? notif.expireTimeout : Config.notifs.defaultExpireTimeout
            onTriggered: {
                if (Config.notifs.expire)
                    notif.popup = false;
            }
        }

        readonly property Connections conn: Connections {
            target: notif.notification

            function onClosed(): void {
                notif.close();
            }
        }

        function lock(item: Item): void {
            locks.add(item);
        }

        function unlock(item: Item): void {
            locks.delete(item);

            if (closed && locks.size === 0 && root.list.includes(this)) {
                root.list.splice(root.list.indexOf(this), 1);
                notification?.dismiss();
                destroy();
            }
        }

        function close(): void {
            closed = true;
            if (locks.size === 0 && root.list.includes(this)) {
                root.list.splice(root.list.indexOf(this), 1);
                notification?.dismiss();
                destroy();
            }
        }
    }

    Component {
        id: notifComp

        Notif {}
    }
}
