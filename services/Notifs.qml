pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Caelestia
import qs.components.misc
import qs.services
import qs.config
import qs.utils

Singleton {
    id: root

    property list<NotifData> list: []
    readonly property list<NotifData> notClosed: list.filter(n => !n.closed)
    readonly property list<NotifData> popups: list.filter(n => n.popup)
    property list<NotifData> closingSidebarNotifs: []
    readonly property list<string> sidebarGroupKeys: {
        const seen = new Set();
        const keys = [];

        for (const notif of root.notClosed) {
            if (!seen.has(notif.appName)) {
                seen.add(notif.appName);
                keys.push(notif.appName);
            }
        }

        for (const notif of root.list) {
            if (!seen.has(notif.appName)) {
                seen.add(notif.appName);
                keys.push(notif.appName);
            }
        }

        return keys;
    }
    readonly property var sidebarGroups: {
        const groups = Object.create(null);
        const closingNotifs = new Set(root.closingSidebarNotifs);

        for (const notif of root.list) {
            const key = notif.appName;
            let group = groups[key];

            if (!group) {
                group = groups[key] = {
                    appName: key,
                    count: 0,
                    notifs: [],
                    latestOpen: null,
                    latestAny: notif,
                    image: "",
                    appIcon: "",
                    urgency: NotificationUrgency.Low
                };
            }

            // Keep a closing group collapsed in the sidebar until its notifications are cleaned up.
            if (closingNotifs.has(notif))
                continue;

            group.notifs.push(notif);

            if (notif.closed)
                continue;

            if (!group.latestOpen)
                group.latestOpen = notif;

            group.count++;

            if (!group.image && notif.image.length > 0)
                group.image = notif.image;
            if (!group.appIcon && notif.appIcon.length > 0)
                group.appIcon = notif.appIcon;

            if (notif.urgency === NotificationUrgency.Critical) {
                group.urgency = NotificationUrgency.Critical;
            } else if (notif.urgency === NotificationUrgency.Normal && group.urgency !== NotificationUrgency.Critical) {
                group.urgency = NotificationUrgency.Normal;
            }
        }

        return groups;
    }
    property alias dnd: props.dnd

    property bool loaded

    function scheduleSave(): void {
        if (loaded)
            saveTimer.restart();
    }

    function scheduleCompactClosed(): void {
        compactTimer.restart();
    }

    function scheduleSidebarCleanup(): void {
        sidebarCleanupTimer.restart();
    }

    function beginSidebarClose(targetNotifs: var): void {
        const closingNotifs = new Set(root.closingSidebarNotifs);
        const pending = targetNotifs.filter(notif => !closingNotifs.has(notif));
        if (pending.length === 0)
            return;

        // Hide the target snapshot first so large group dismissals collapse as one sidebar update.
        root.closingSidebarNotifs = root.closingSidebarNotifs.concat(pending);
        scheduleSidebarCleanup();
    }

    function compactClosed(): void {
        const remaining = [];
        const removed = [];

        for (const notif of root.list) {
            if (notif.closed && notif.locks.size === 0)
                removed.push(notif);
            else
                remaining.push(notif);
        }

        if (removed.length === 0)
            return;

        root.list = remaining;
        const remainingNotifs = new Set(remaining);
        root.closingSidebarNotifs = root.closingSidebarNotifs.filter(notif => remainingNotifs.has(notif));

        for (const notif of removed) {
            notif.notification?.dismiss();
            notif.destroy();
        }
    }

    function closeGroup(appName: string): void {
        const targetNotifs = root.list.filter(notif => !notif.closed && notif.appName === appName);
        if (targetNotifs.length === 0)
            return;

        beginSidebarClose(targetNotifs);
    }

    function processSidebarCleanup(): void {
        if (root.closingSidebarNotifs.length === 0)
            return;

        const closingNotifs = new Set(root.closingSidebarNotifs);
        const remaining = [];
        const removed = [];
        const stillClosing = [];

        for (const notif of root.list) {
            if (!closingNotifs.has(notif)) {
                remaining.push(notif);
                continue;
            }

            notif.popup = false;
            if (notif.locks.size === 0) {
                removed.push(notif);
            } else {
                notif.closed = true;
                stillClosing.push(notif);
                remaining.push(notif);
            }
        }

        if (removed.length > 0)
            root.list = remaining;
        else if (stillClosing.length > 0)
            scheduleSave();

        root.closingSidebarNotifs = stillClosing;

        for (const notif of removed) {
            notif.notification?.dismiss();
            notif.destroy();
        }
    }

    onDndChanged: {
        if (!Config.utilities.toasts.dndChanged)
            return;

        if (dnd)
            Toaster.toast(qsTr("Do not disturb enabled"), qsTr("Popup notifications are now disabled"), "do_not_disturb_on");
        else
            Toaster.toast(qsTr("Do not disturb disabled"), qsTr("Popup notifications are now enabled"), "do_not_disturb_off");
    }

    onListChanged: scheduleSave()

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

    Timer {
        id: compactTimer

        interval: 0
        onTriggered: root.compactClosed()
    }

    Timer {
        id: sidebarCleanupTimer

        interval: 0
        onTriggered: root.processSidebarCleanup()
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
                popup: !props.dnd && ![...Visibilities.screens.values()].some(v => v.sidebar),
                notification: notif
            });
            root.list = [comp, ...root.list];
        }
    }

    FileView {
        id: storage

        path: `${Paths.state}/notifs.json`
        onLoaded: {
            const data = JSON.parse(text());
            for (const notif of data)
                root.list.push(notifComp.createObject(root, notif));
            root.list.sort((a, b) => b.time - a.time);
            root.loaded = true;
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                root.loaded = true;
                setText("[]");
            }
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "clearNotifs"
        description: "Clear all notifications"
        onPressed: {
            root.beginSidebarClose(root.list.filter(notif => !notif.closed));
        }
    }

    IpcHandler {
        function clear(): void {
            root.beginSidebarClose(root.list.filter(notif => !notif.closed));
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
