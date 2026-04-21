pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Caelestia
import Caelestia.Config
import qs.services
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
    property real expireTimeout: GlobalConfig.notifs.defaultExpireTimeout
    property int urgency: NotificationUrgency.Normal
    property bool resident
    property bool hasActionIcons
    property list<var> actions

    readonly property Timer timer: Timer {
        running: true
        interval: notif.expireTimeout > 0 ? notif.expireTimeout : GlobalConfig.notifs.defaultExpireTimeout
        onTriggered: {
            if (GlobalConfig.notifs.expire)
                notif.popup = false;
        }
    }

    readonly property LazyLoader dummyImageLoader: LazyLoader {
        active: false

        // qmllint disable uncreatable-type
        PanelWindow {
            // qmllint enable uncreatable-type
            implicitWidth: TokenConfig.sizes.notifs.image
            implicitHeight: TokenConfig.sizes.notifs.image
            color: "transparent"
            mask: Region {}

            Image {
                function tryCache(): void {
                    if (status !== Image.Ready || width != TokenConfig.sizes.notifs.image || height != TokenConfig.sizes.notifs.image)
                        return;

                    const cacheKey = notif.appName + notif.summary + notif.id + notif.image;
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
                    CUtils.saveItem(this, Qt.resolvedUrl(cache), () => {
                        notif.image = cache;
                        notif.dummyImageLoader.active = false;
                    });
                }

                anchors.fill: parent
                source: Qt.resolvedUrl(notif.image)
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
            notif.maybeTriggerDummyImageLoader();
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

    function maybeTriggerDummyImageLoader(): void {
        if (image && !image.startsWith("image://icon/") && !image.startsWith(Paths.notifimagecache))
            dummyImageLoader.active = true;
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
        maybeTriggerDummyImageLoader();
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
