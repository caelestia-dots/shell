pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Caelestia
import qs.services
import qs.config
import qs.utils

QtObject {
    id: notif

    property bool popup
    property bool closed
    property var locks: new Set()

    property date time: new Date()
    property string timeStr: qsTr("now")

    readonly property Timer timeStrTimer: Timer {
        running: !notif.closed
        repeat: true
        interval: 5000
        onTriggered: notif.updateTimeStr()
    }

    property Notification notification
    property string id
    property string summary
    property string body
    property string appIcon
    property string appName
    property string image
    property var hints // Hints are not persisted across restarts
    property real expireTimeout: Config.notifs.defaultExpireTimeout
    property int urgency: NotificationUrgency.Normal
    property bool resident
    property bool hasActionIcons
    property list<var> actions

    readonly property Timer timer: Timer {
        running: true
        interval: notif.expireTimeout > 0 ? notif.expireTimeout : Config.notifs.defaultExpireTimeout
        onTriggered: {
            if (Config.notifs.expire)
                notif.popup = false;
        }
    }

    readonly property LazyLoader dummyImageLoader: LazyLoader {
        active: false

        // qmllint disable uncreatable-type
        PanelWindow {
            // qmllint enable uncreatable-type
            implicitWidth: Config.notifs.sizes.image
            implicitHeight: Config.notifs.sizes.image
            color: "transparent"
            mask: Region {}

            Image {
                function tryCache(): void {
                    if (status !== Image.Ready || width != Config.notifs.sizes.image || height != Config.notifs.sizes.image)
                        return;

                    const cacheKey = notif.appName + notif.summary + notif.id;
                    let h1 = 0xdeadbeef, h2 = 0x41c6ce57, ch;
                    for (let i = 0; i < cacheKey.length; i++) {
                        ch = cacheKey.charCodeAt(i);
                        h1 = Math.imul(h1 ^ ch, 2654435761);
                        h2 = Math.imul(h2 ^ ch, 1597334677);
                    }
                    h1 = Math.imul(h1 ^ (h1 >>> 16), 2246822507);
                    h1 ^= Math.imul(h2 ^ (h2 >>> 13), 3266489909);
                    h2 = Math.imul(h2 ^ (h2 >>> 16), 2246822507);
                    h2 ^= Math.imul(h1 ^ (h1 >>> 13), 3266489909);
                    const hash = (h2 >>> 0).toString(16).padStart(8, 0) + (h1 >>> 0).toString(16).padStart(8, 0);

                    const cache = `${Paths.notifimagecache}/${hash}.png`;
                    CUtils.saveItem(this, Paths.resolve(cache), () => {
                        notif.image = cache;
                        notif.dummyImageLoader.active = false;
                    });
                }

                anchors.fill: parent
                source: Paths.resolve(notif.image)
                fillMode: Image.PreserveAspectCrop
                cache: false
                asynchronous: true
                opacity: 0

                onStatusChanged: tryCache()
                onWidthChanged: tryCache()
                onHeightChanged: tryCache()
            }
        }
    }

    readonly property Connections conn: Connections {
        function onClosed(): void {
            notif.close();
        }

        function onSummaryChanged(): void {
            notif.summary = notif.notification.summary;
        }

        function onBodyChanged(): void {
            notif.body = notif.notification.body;
        }

        function onAppIconChanged(): void {
            notif.appIcon = notif.notification.appIcon;
        }

        function onAppNameChanged(): void {
            notif.appName = notif.notification.appName;
        }

        function onImageChanged(): void {
            notif.image = notif.notification.image;
            if (notif.notification?.image)
                notif.dummyImageLoader.active = true;
        }

        function onExpireTimeoutChanged(): void {
            notif.expireTimeout = notif.notification.expireTimeout;
        }

        function onUrgencyChanged(): void {
            notif.urgency = notif.notification.urgency;
        }

        function onResidentChanged(): void {
            notif.resident = notif.notification.resident;
        }

        function onHasActionIconsChanged(): void {
            notif.hasActionIcons = notif.notification.hasActionIcons;
        }

        function onActionsChanged(): void {
            // qmllint disable unresolved-type
            notif.actions = notif.notification.actions.map(a => ({
                        // qmllint enable unresolved-type
                        identifier: a.identifier,
                        text: a.text,
                        invoke: () => a.invoke()
                    }));
        }

        function onHintsChanged(): void {
            notif.hints = notif.notification.hints;
        }

        target: notif.notification
    }

    function updateTimeStr(): void {
        const diff = Date.now() - time.getTime();
        const m = Math.floor(diff / 60000);

        if (m < 1) {
            timeStr = qsTr("now");
            timeStrTimer.interval = 5000;
        } else {
            const h = Math.floor(m / 60);
            const d = Math.floor(h / 24);

            if (d > 0) {
                timeStr = `${d}d`;
                timeStrTimer.interval = 3600000;
            } else if (h > 0) {
                timeStr = `${h}h`;
                timeStrTimer.interval = 300000;
            } else {
                timeStr = `${m}m`;
                timeStrTimer.interval = m < 10 ? 30000 : 60000;
            }
        }
    }

    function lock(item: Item): void {
        locks.add(item);
    }

    function unlock(item: Item): void {
        locks.delete(item);
        if (closed)
            close();
    }

    function close(): void {
        closed = true;
        if (locks.size === 0 && Notifs.list.includes(this)) {
            Notifs.list = Notifs.list.filter(n => n !== this);
            notification?.dismiss();
            destroy();
        }
    }

    Component.onCompleted: {
        if (!notification)
            return;

        id = notification.id;
        summary = notification.summary;
        body = notification.body;
        appIcon = notification.appIcon;
        appName = notification.appName;
        image = notification.image;
        if (notification?.image)
            dummyImageLoader.active = true;
        expireTimeout = notification.expireTimeout;
        hints = notification.hints;
        urgency = notification.urgency;
        resident = notification.resident;
        hasActionIcons = notification.hasActionIcons;
        // qmllint disable unresolved-type
        actions = notification.actions.map(a => ({
                    // qmllint enable unresolved-type
                    identifier: a.identifier,
                    text: a.text,
                    invoke: () => a.invoke()
                }));
    }
}
