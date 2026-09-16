pragma ComponentBehavior: Bound

import ".." as Utilities
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    required property ScreenState screenState

    property bool browserOpen
    property string browserDeviceId
    property string browserDeviceName
    property string browserRootPath
    // Device whose storage is being checked before its browser opens
    property string pendingBrowseDevice
    // Unmounting or losing the device leaves nothing to browse
    readonly property bool browserDeviceMounted: KdeConnect.isMounted(browserDeviceId)

    // The browser keeps a fixed height and scrolls its file list inside it
    readonly property real browserHeight: Tokens.sizes.utilities.width * 0.8
    readonly property real compactHeight: layout.implicitHeight + Tokens.padding.extraLargeIncreased
    readonly property real nonAnimHeight: browserOpen ? browserHeight : compactHeight
    // Translate is not an Item, so it cannot resolve Tokens for the screen itself
    readonly property real slideDistance: Tokens.padding.large
    // 0 shows the device list, 1 the browser
    property real browserProgress: browserOpen ? 1 : 0

    function browse(deviceId: string): void {
        const rootPath = KdeConnect.storageRoot(deviceId);
        if (!rootPath || pendingBrowseDevice)
            return;

        // The browser reads the storage on the UI thread, which would hang on a dead mount
        pendingBrowseDevice = deviceId;
        KdeConnect.checkMount(deviceId, rootPath);
    }

    function openBrowser(deviceId: string, rootPath: string): void {
        const device = KdeConnect.devices.find(d => d.id === deviceId);
        if (!device)
            return;

        browserDeviceId = deviceId;
        browserDeviceName = device.name;
        browserRootPath = rootPath;
        browserOpen = true;
        browser.reset();
    }

    implicitHeight: compactHeight
    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer
    clip: true

    // Utilities just opened, so find mounts which died while it was closed
    Component.onCompleted: {
        for (const device of KdeConnect.devices)
            if (KdeConnect.isMounted(device.id))
                KdeConnect.checkMount(device.id, KdeConnect.storageRoot(device.id));
    }

    onBrowserDeviceMountedChanged: {
        if (!browserDeviceMounted)
            browserOpen = false;
    }

    // Only animate opening and closing the browser. A Behavior would also animate
    // the height settling when the card is created, making its contents jump.
    states: State {
        name: "browsing"
        when: root.browserOpen

        PropertyChanges {
            root.implicitHeight: root.browserHeight
        }
    }

    transitions: Transition {
        Anim {
            property: "implicitHeight"
        }
    }

    // Close the browser as soon as utilities starts hiding or another panel takes
    // over. The panel keeps its last height until the card is recreated, so a card
    // destroyed with the browser open would reopen at the browser height.
    Connections {
        function onUtilitiesChanged(): void {
            if (!root.screenState.utilities)
                root.browserOpen = false;
        }

        function onSidebarChanged(): void {
            if (root.screenState.sidebar)
                root.browserOpen = false;
        }

        function onLauncherChanged(): void {
            if (root.screenState.launcher)
                root.browserOpen = false;
        }

        function onSessionChanged(): void {
            if (root.screenState.session)
                root.browserOpen = false;
        }

        function onDashboardChanged(): void {
            if (root.screenState.dashboard)
                root.browserOpen = false;
        }

        target: root.screenState
    }

    Connections {
        function onMountChecked(device: string, path: string, reachable: bool): void {
            if (device !== root.pendingBrowseDevice)
                return;

            root.pendingBrowseDevice = "";
            if (reachable && KdeConnect.isMounted(device) && path === KdeConnect.storageRoot(device))
                root.openBrowser(device, path);
        }

        target: KdeConnect
    }

    ColumnLayout {
        id: layout

        // Slides with the margins, as qmllint reads a Translate on a layout as
        // positioning an item managed by a layout
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: Tokens.padding.large
        anchors.leftMargin: Tokens.padding.large - root.slideDistance * root.browserProgress
        anchors.rightMargin: Tokens.padding.large + root.slideDistance * root.browserProgress
        spacing: Tokens.spacing.small

        enabled: !root.browserOpen
        opacity: root.browserOpen ? 0 : 1

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: icon.implicitHeight + Tokens.padding.large

                radius: Tokens.rounding.full
                color: Colours.palette.m3secondaryContainer

                MaterialIcon {
                    id: icon

                    anchors.centerIn: parent
                    text: "send_to_mobile"
                    color: Colours.palette.m3onSecondaryContainer
                    fontStyle: Tokens.font.icon.large
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: Tr.tr("Send to phone")
                    font: Tokens.font.body.medium
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: {
                        if (!KdeConnect.available)
                            return Tr.tr("KDE Connect is not running");
                        if (KdeConnect.devices.length === 0)
                            return Tr.tr("No phone connected");
                        if (KdeConnect.downloading)
                            // TRANSLATORS: %1 = download progress percentage
                            return Tr.tr("Downloading… %1%").arg(Math.round(KdeConnect.downloadProgress * 100));
                        return Tr.tr("Drop files on a device");
                    }
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }
            }

            // Same enter/exit as the keep awake card's active chip
            Loader {
                asynchronous: true
                visible: active
                opacity: KdeConnect.downloading ? 1 : 0
                scale: KdeConnect.downloading ? 1 : 0.5

                Component.onCompleted: active = Qt.binding(() => opacity > 0)

                sourceComponent: LoadingIndicator {
                    implicitSize: Math.round(Tokens.font.icon.medium.pointSize * 1.3)
                }

                Behavior on opacity {
                    Anim {
                        type: Anim.StandardSmall
                    }
                }

                Behavior on scale {
                    Anim {}
                }
            }
        }

        Repeater {
            model: KdeConnect.devices

            StyledRect {
                id: device

                required property var modelData

                readonly property bool mounted: KdeConnect.isMounted(modelData.id)
                readonly property bool mountBusy: KdeConnect.isMountBusy(modelData.id)
                readonly property bool downloadingHere: KdeConnect.downloading && KdeConnect.downloadDevice === modelData.id
                // Briefly shows the outcome of the last share: "", "sent" or "failed"
                property string shareResult

                Layout.fillWidth: true
                implicitHeight: deviceLayout.implicitHeight + Tokens.padding.small * 2

                radius: Tokens.rounding.medium
                color: dropArea.containsDrag ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh

                Behavior on color {
                    CAnim {}
                }

                Connections {
                    function onShared(deviceId: string): void {
                        if (deviceId === device.modelData.id) {
                            device.shareResult = "sent";
                            shareResultTimer.restart();
                        }
                    }

                    function onShareFailed(deviceId: string): void {
                        if (deviceId === device.modelData.id) {
                            device.shareResult = "failed";
                            shareResultTimer.restart();
                        }
                    }

                    target: KdeConnect
                }

                Timer {
                    id: shareResultTimer

                    interval: 2000
                    onTriggered: device.shareResult = ""
                }

                RowLayout {
                    id: deviceLayout

                    anchors.fill: parent
                    anchors.leftMargin: Tokens.padding.medium
                    anchors.rightMargin: Tokens.padding.small
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        text: {
                            if (dropArea.containsDrag)
                                return "file_download";
                            if (device.shareResult === "sent")
                                return "check";
                            if (device.shareResult === "failed")
                                return "error";
                            return "smartphone";
                        }
                        color: {
                            if (dropArea.containsDrag)
                                return Colours.palette.m3onPrimaryContainer;
                            if (device.shareResult === "failed")
                                return Colours.palette.m3error;
                            return Colours.palette.m3onSurfaceVariant;
                        }
                        fontStyle: Tokens.font.icon.medium
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: device.modelData.name
                        color: dropArea.containsDrag ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    IconButton {
                        visible: device.mounted
                        type: IconButton.Text
                        icon: root.pendingBrowseDevice === device.modelData.id ? "hourglass_top" : "folder_open"
                        disabled: device.mountBusy || root.pendingBrowseDevice !== ""
                        onClicked: root.browse(device.modelData.id)
                    }

                    IconButton {
                        type: IconButton.Text
                        icon: device.mountBusy ? "hourglass_top" : device.mounted ? "eject" : "link"
                        disabled: device.mountBusy || device.downloadingHere
                        onClicked: {
                            if (device.mounted)
                                KdeConnect.unmount(device.modelData.id);
                            else
                                KdeConnect.mount(device.modelData.id);
                        }
                    }
                }

                DropArea {
                    id: dropArea

                    anchors.fill: parent
                    keys: ["text/uri-list"]

                    onDropped: drop => {
                        if (!drop.hasUrls)
                            return;

                        KdeConnect.share(device.modelData.id, drop.urls);
                        drop.acceptProposedAction();
                    }
                }
            }
        }

        Behavior on opacity {
            Anim {}
        }
    }

    Utilities.PhoneBrowser {
        id: browser

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium

        deviceId: root.browserDeviceId
        deviceName: root.browserDeviceName
        rootPath: root.browserRootPath
        open: root.browserOpen
        enabled: root.browserOpen
        opacity: root.browserOpen ? 1 : 0

        onCloseRequested: root.browserOpen = false

        transform: Translate {
            x: root.slideDistance * (1 - root.browserProgress)
        }

        Behavior on opacity {
            Anim {}
        }
    }

    Behavior on browserProgress {
        Anim {}
    }
}
