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
    property int loadFailureCount: 0

    function hasFullscreen(): bool {
        if (!Hypr.monitors?.values)
            return false;
        for (const monitor of Hypr.monitors.values) {
            if (monitor?.activeWorkspace?.toplevels?.values?.some(t => (t?.lastIpcObject?.fullscreen ?? 0) > 1))
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

    function persistNow(): void {
        // Self-guarding (mirrors Events.save()): future callers get the
        // failure semantics by default instead of needing timer-side guards.
        if (!root.loaded || root.loadFailed)
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

    onDndChanged: {
        if (!GlobalConfig.utilities.toasts.dndChanged)
            return;

        if (dnd)
            Toaster.toast(Tr.tr("Do not disturb enabled"), Tr.tr("Popup notifications are now disabled"), "do_not_disturb_on");
        else
            Toaster.toast(Tr.tr("Do not disturb disabled"), Tr.tr("Popup notifications are now enabled"), "do_not_disturb_off");
    }

    onListChanged: {
        // Restart unconditionally: while failed, the timer drives reload
        // retries (quarantine path) instead of writes. Safe: the failure
        // branch below never touches root.list, so no reload loop.
        saveTimer.restart();
    }

    Timer {
        id: saveTimer

        interval: 1000
        onTriggered: {
            if (!root.loaded)
                return;
            if (root.loadFailed) {
                storage.reload();
                return;
            }
            root.persistNow();
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
        // Preload on: without it reload() only marks state unprepared and
        // never starts a read, so the retry/quarantine loop below would be
        // dead code (verified against fileview.cpp updatePath/loadAsync).
        preload: true
        path: `${Paths.state}/notifs.json`
        onLoaded: {
            try {
                const raw = text();
                if (raw) {
                    const data = JSON.parse(raw);
                    if (!Array.isArray(data))
                        throw new Error("notifs.json: expected JSON array, got " + (data === null ? "null" : typeof data));
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
                // Reset only on successful parse: during quarantine dispatch
                // loadFailed must stay true so the timer keeps taking the
                // reload branch instead of racing mv with a write.
                root.loadFailed = false;
                root.loaded = true;
                root.loadFailureCount = 0;
            } catch (e) {
                root.loadFailureCount++;
                // Exact-match: fire quarantine once per corruption episode (see Events.qml).
                if (root.loadFailureCount === 3) {
                    console.warn(`Notifs: corrupt file persisted across ${root.loadFailureCount} loads; quarantining and resetting`);
                    quarantineProcess.targetPath = `${storage.path}.corrupt-${Date.now()}`;
                    quarantineProcess.running = true;
                } else {
                    console.warn(`Notifs: failed to parse notifs file (attempt ${root.loadFailureCount}/3), preserving disk file: ${e}`);
                    root.loadFailed = true;
                    // loaded stays true: the attempt completed, only the parse
                    // failed. Every reader gates on loadFailed for failure.
                    root.loaded = true;
                }
            }
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                root.loadFailed = false;
                root.loaded = true;
                Qt.callLater(() => storage.setText("[]"));
            } else {
                root.loadFailed = true;
                root.loaded = true;
                console.warn(`Notifs: failed to load notifs file: ${err}`);
            }
        }
    }

    Process {
        id: quarantineProcess

        // targetPath is set imperatively before triggering: Date.now() has no
        // property dependency, so inlining it in the binding would freeze the
        // timestamp at component-creation time and collide on repeat quarantines.
        property string targetPath: ""

        command: targetPath ? ["mv", storage.path, targetPath] : []
        onExited: code => { // qmllint disable signal-handler-parameters
            if (code === 0) {
                root.loaded = true;
                root.loadFailed = false;
                root.loadFailureCount = 0;
                // Persist current in-memory state instead of blanking: anything
                // that arrived during the read-only window survives. Immediate
                // write (not saveTimer.restart()): no 1s crash-loss window,
                // symmetric with Events' save() in the same path.
                root.persistNow();
                console.warn("Notifs: corrupt file quarantined; fresh state initialized");
            } else {
                console.error(`Notifs: quarantine rename failed (exit ${code}); staying in read-only mode`);
                root.loadFailed = true;
                root.loaded = true;
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
