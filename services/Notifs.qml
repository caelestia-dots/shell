pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Services.SystemTray
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

    function resolveDesktopEntry(hints: var): var {
        const desktopEntry = hints?.desktopEntry || "";
        if (desktopEntry) {
            const byId = DesktopEntries.byId(desktopEntry) || DesktopEntries.byId(`${desktopEntry}.desktop`);
            if (byId)
                return byId;
        }

        for (const key of [hints?.appName, hints?.appIcon]) {
            if (!key)
                continue;
            const entry = DesktopEntries.heuristicLookup(key);
            if (entry)
                return entry;
        }

        return null;
    }

    function scoreTrayItem(item: var, tokens: list<string>): int {
        if (!item)
            return -1;

        const fields = [item.id, item.title, item.tooltipTitle, item.tooltipDescription].map(v => Hypr.normalizeAppToken(v)).filter(Boolean);
        if (fields.length === 0)
            return -1;

        let best = -1;
        for (const token of tokens) {
            if (!token)
                continue;
            for (const field of fields) {
                if (field === token)
                    return 100;
                if (field.includes(token) || token.includes(field))
                    best = Math.max(best, 60);
            }
        }
        return best;
    }

    function findTrayItem(hints: var): var {
        const tokens = Hypr.collectAppTokens(hints);
        if (tokens.length === 0)
            return null;

        let best = null;
        let bestScore = -1;
        for (const item of SystemTray.items.values) {
            const score = root.scoreTrayItem(item, tokens);
            if (score > bestScore) {
                bestScore = score;
                best = item;
            }
        }
        return bestScore >= 0 ? best : null;
    }

    function focusSource(notif: var): bool {
        if (!notif)
            return false;

        const hints = {
            desktopEntry: notif.desktopEntry || notif.notification?.desktopEntry || "",
            appName: notif.appName || "",
            appIcon: notif.appIcon || ""
        };

        const toplevel = Hypr.findAppToplevel(hints);
        const trayItem = toplevel ? null : root.findTrayItem(hints);
        const desktopEntry = (!toplevel && !trayItem) ? root.resolveDesktopEntry(hints) : null;

        // Dismiss UI first so layer-shell doesn't restore the previous workspace/window.
        if (notif.popup)
            notif.popup = false;

        let opened = false;
        if (toplevel) {
            Hypr.focusToplevel(toplevel, true);
            opened = true;
        } else if (trayItem) {
            // Background apps (e.g. Teams minimized to tray): show their window.
            trayItem.activate();
            opened = true;
        } else if (desktopEntry) {
            desktopEntry.execute();
            opened = true;
        }

        // Clear the notification after activating its source.
        notif.close();
        return opened;
    }

    onListChanged: {
        if (loaded)
            saveTimer.restart();
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

    function pushLocal(properties: var): var {
        const props = Object.assign({
                popup: root.shouldShowPopup()
            }, properties);
        const comp = notifComp.createObject(root, props);
        root.list = [comp, ...root.list];
        return comp;
    }

    Timer {
        id: saveTimer

        interval: 1000
        onTriggered: storage.setText(JSON.stringify(root.notClosed.filter(n => !(n.notificationId || "").startsWith("local:")).map(n => ({
                    time: n.time,
                    id: n.id,
                    summary: n.summary,
                    body: n.body,
                    appIcon: n.appIcon,
                    appName: n.appName,
                    desktopEntry: n.desktopEntry,
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
        onPressed: {
            for (const notif of root.list.slice())
                notif.close();
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "toggleDnd"
        description: "Toggle do not disturb"
        onPressed: {
            PersistentState.doNotDisturb = !PersistentState.doNotDisturb;
        }
    }

    IpcHandler {
        function clear(): void {
            for (const notif of root.list.slice())
                notif.close();
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
