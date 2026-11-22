pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import Caelestia.State
import qs.components.misc
import qs.services
import qs.utils

Singleton {
    id: root

    property list<NotifData> list: []
    readonly property list<NotifData> notClosed: list.filter(n => !n.closed)
    readonly property list<NotifData> popups: list.filter(n => n.popup)

    property bool loaded

    function clear(): void {
        for (const notif of list.slice())
            notif.close();
    }

    // History is only for what was missed: drop notifications older than a day
    function prune(): void {
        const cutoff = Date.now() - 24 * 3600 * 1000;
        for (const notif of list.slice())
            if (notif.time.getTime() < cutoff)
                notif.close();
    }

    function hasFullscreen(): bool {
        for (const monitor of Hypr.monitors.values) {
            if (monitor?.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1))
                return true;
        }
        return false;
    }

    function shouldShowPopup(): bool {
        if (PersistentState.doNotDisturb || ShellState.anySidebarOpen())
            return false;
        if (GlobalConfig.notifs.fullscreen === NotifsFullscreen.Off && hasFullscreen())
            return false;
        return true;
    }

    onListChanged: {
        if (loaded)
            saveTimer.restart();
    }

    Timer {
        running: root.loaded
        repeat: true
        interval: 600000
        onTriggered: root.prune()
    }

    Connections {
        function onDoNotDisturbChanged(): void {
            if (!GlobalConfig.utilities.toasts.dndChanged)
                return;

            if (PersistentState.doNotDisturb)
                Toaster.toast(Tr.tr("Do not disturb enabled"), Tr.tr("Popup notifications are now disabled"), "do_not_disturb_on");
            else
                Toaster.toast(Tr.tr("Do not disturb disabled"), Tr.tr("Popup notifications are now enabled"), "do_not_disturb_off");
        }

        target: PersistentState
    }

    Timer {
        id: saveTimer

        interval: 1000
        onTriggered: storage.setText(JSON.stringify(root.notClosed.map(n => ({
                    time: n.time,
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
                }))))
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

            const comp = notifComp.createObject(root, {
                popup: root.shouldShowPopup(),
                notification: notif
            });
            root.list = [comp, ...root.list];
        }
    }

    FileView {
        id: storage

        printErrors: false
        path: `${Paths.state}/notifs.json`
        onLoaded: {
            const data = JSON.parse(text());
            for (const notif of data) {
                const properties = Object.assign({}, notif);

                // Backwards compatibility for old notifications
                if (properties.notificationId === undefined && properties.id !== undefined)
                    properties.notificationId = properties.id;

                delete properties.id;
                root.list.push(notifComp.createObject(root, properties));
            }
            root.list.sort((a, b) => b.time - a.time);
            root.loaded = true;
            root.prune();
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                root.loaded = true;
                Qt.callLater(() => setText("[]"));
            }
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "clearNotifs"
        description: "Clear all notifications"
        onPressed: root.clear()
    }

    IpcHandler {
        function clear(): void {
            root.clear();
        }

        function isDndEnabled(): bool {
            return PersistentState.doNotDisturb;
        }

        function toggleDnd(): void {
            PersistentState.doNotDisturb = !PersistentState.doNotDisturb;
        }

        function enableDnd(): void {
            PersistentState.doNotDisturb = true;
        }

        function disableDnd(): void {
            PersistentState.doNotDisturb = false;
        }

        target: "notifs"
    }

    Component {
        id: notifComp

        NotifData {}
    }
}
