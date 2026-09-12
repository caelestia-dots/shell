pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.components.misc
import qs.services
import qs.utils

Singleton {
    id: root

    property list<NotifData> list: []
    readonly property list<NotifData> notClosed: list.filter(n => n && !n.closed)
    readonly property list<NotifData> popups: list.filter(n => n && n.popup)
    property alias dnd: props.dnd

    property bool loaded
    property bool loadFailed: false

    function hasFullscreen(): bool {
        for (const monitor of Hypr.monitors.values) {
            if (monitor?.activeWorkspace?.toplevels.values.some(t => (t?.lastIpcObject?.fullscreen ?? 0) > 1))
                return true;
        }
        return false;
    }

    function shouldShowPopup(): bool {
        if (props.dnd || ShellState.anySidebarOpen())
            return false;
        if (GlobalConfig.notifs.fullscreen === NotifsFullscreen.Off && hasFullscreen())
            return false;
        return true;
    }

    function send(summary: string, body: string, appIcon: string, appName: string): void {
        const notifData = notifComp.createObject(root, {
            summary: summary ?? "",
            body: body ?? "",
            appIcon: appIcon ?? "x-office-calendar",
            appName: appName ?? "Calendar",
            popup: root.shouldShowPopup(),
            time: new Date()
        });
        if (notifData)
            root.list = [notifData, ...root.list];
    }

    onDndChanged: {
        if (!GlobalConfig.utilities.toasts.dndChanged)
            return;

        if (dnd)
            Toaster.toast(Tr.tr("Do not disturb enabled"), Tr.tr("Popup notifications are now disabled"), "do_not_disturb_on");
        else
            Toaster.toast(Tr.tr("Do not disturb disabled"), Tr.tr("Popup notifications are now enabled"), "do_not_disturb_off");
    }

    onListChanged: {
        if (loaded && !loadFailed)
            saveTimer.restart();
    }

    Timer {
        id: saveTimer

        interval: 1000
        onTriggered: {
            if (root.loadFailed || !root.loaded)
                return;
            storage.setText(JSON.stringify(root.notClosed.map(n => ({
                        time: n.time,
                        id: n.notificationId ?? n.id,
                        summary: n.summary,
                        body: n.body,
                        appIcon: n.appIcon,
                        appName: n.appName,
                        image: n.image,
                        expireTimeout: n.expireTimeout,
                        urgency: n.urgency,
                        resident: n.resident,
                        hasActionIcons: n.hasActionIcons,
                        actions: n.actions?.map(a => ({
                                    identifier: a.identifier,
                                    text: a.text
                                })) ?? []
                    }))));
        }
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

            const comp = notifComp.createObject(root, {
                popup: root.shouldShowPopup(),
                notification: notif
            });
            if (comp)
                root.list = [comp, ...root.list];
        }
    }

    FileView {
        id: storage

        printErrors: true
        path: `${Paths.state}/notifs.json`
        onLoaded: {
            root.loadFailed = false;
            try {
                const raw = text();
                if (raw) {
                    const data = JSON.parse(raw);
                    if (Array.isArray(data)) {
                        const loadedList = [];
                        for (const notif of data) {
                            if (!notif || typeof notif !== "object")
                                continue;
                            const properties = Object.assign({}, notif);

                            // Backwards compatibility for old notifications
                            if (properties.notificationId === undefined && properties.id !== undefined)
                                properties.notificationId = properties.id;

                            delete properties.id;
                            const obj = notifComp.createObject(root, properties);
                            if (obj)
                                loadedList.push(obj);
                        }
                        loadedList.sort((a, b) => b.time - a.time);
                        root.list = loadedList;
                    }
                }
                root.loaded = true;
            } catch (e) {
                console.warn(`Notifs: failed to parse notifs file, preserving disk file: ${e}`);
                root.loadFailed = true;
                root.loaded = false;
            }
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                root.loadFailed = false;
                root.loaded = true;
                Qt.callLater(() => storage.setText("[]"));
            } else {
                root.loadFailed = true;
                root.loaded = false;
                console.warn(`Notifs: failed to load notifs file: ${err}`);
            }
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "clearNotifs"
        description: "Clear all notifications"
        onPressed: {
            for (const notif of root.list.slice())
                notif.close();
        }
    }

    IpcHandler {
        function clear(): void {
            for (const notif of root.list.slice())
                notif.close();
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

        target: "notifs"
    }

    Component {
        id: notifComp

        NotifData {}
    }
}
