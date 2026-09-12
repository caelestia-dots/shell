pragma ComponentBehavior: Bound

import ".." as Utilities
import QtQuick
import QtQuick.Layouts
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    required property ScreenState screenState
    required property var phoneBrowser

    readonly property var primaryDevice: KdeConnect.devices.length > 0 ? KdeConnect.devices[0] : null

    readonly property bool primaryMounted: root.primaryDevice !== null && KdeConnect.isMounted(root.primaryDevice.id)

    readonly property bool primaryMountBusy: root.primaryDevice !== null && KdeConnect.isMountBusy(root.primaryDevice.id)

    readonly property bool browserOpen: root.phoneBrowser.browserOpen

    readonly property real compactHeight: compactLayout.implicitHeight + Tokens.padding.extraLargeIncreased
    readonly property real transitionDistance: Tokens.padding.large

    //
    // Keep the inline browser bounded.
    // The file list scrolls inside this area.
    //
    readonly property real browserHeight: 340

    readonly property real targetHeight: root.browserOpen ? root.browserHeight : root.compactHeight

    readonly property real nonAnimHeight: root.targetHeight

    implicitHeight: root.targetHeight

    radius: Tokens.rounding.large

    color: Colours.tPalette.m3surfaceContainer

    clip: true

    // Behavior on implicitHeight {
    //     Anim {}
    // }

    Component.onCompleted: KdeConnect.refresh()

    function browsePrimaryDevice(): void {
        if (root.primaryDevice === null)
            return;

        if (!root.primaryMounted)
            return;

        const directories = KdeConnect.directories(root.primaryDevice.id);

        const paths = Object.keys(directories);

        if (paths.length === 0)
            return;

        paths.sort((a, b) => a.length - b.length);

        root.phoneBrowser.openForDevice(root.primaryDevice.id, root.primaryDevice.name, paths[0]);
    }

    //
    // ==================================================
    // Compact phone card
    // ==================================================
    //
    ColumnLayout {
        id: compactLayout

        anchors.top: parent.top

        anchors.left: parent.left

        anchors.right: parent.right

        anchors.margins: Tokens.padding.large

        spacing: Tokens.spacing.small

        enabled: !root.browserOpen

        opacity: root.browserOpen ? 0 : 1

        transform: Translate {
            x: root.browserOpen ? -root.transitionDistance : 0

            Behavior on x {
                Anim {}
            }
        }

        Behavior on opacity {
            Anim {}
        }

        //
        // ==========================================
        // Header
        // ==========================================
        //
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

                    text: qsTr("Send to Phone")

                    font: Tokens.font.body.medium

                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true

                    text: {
                        if (KdeConnect.sharing)
                            return qsTr("Sending…");

                        if (KdeConnect.devices.length === 0) {
                            return qsTr("No phone connected");
                        }

                        return qsTr("Drop files on a device");
                    }

                    color: Colours.palette.m3onSurfaceVariant

                    font: Tokens.font.body.small

                    elide: Text.ElideRight
                }
            }

            //
            // ==========================================
            // Download progress indicator
            // ==========================================
            //
            Item {
                id: receivingIndicator

                visible: KdeConnect.receiving

                implicitWidth: 34
                implicitHeight: 34

                Item {
                    id: downloadIcon

                    anchors.centerIn: parent

                    width: 20
                    height: 20

                    //
                    // Empty / inactive portion.
                    //
                    MaterialIcon {
                        anchors.centerIn: parent

                        text: "download"

                        color: Colours.palette.m3onSurfaceVariant

                        opacity: 0.25

                        fontStyle: Tokens.font.icon.small
                    }

                    //
                    // Filled portion.
                    //
                    Item {
                        anchors.top: parent.top

                        anchors.left: parent.left

                        anchors.right: parent.right

                        height: parent.height * KdeConnect.progress

                        clip: true

                        Behavior on height {
                            NumberAnimation {
                                duration: 100
                            }
                        }

                        MaterialIcon {
                            x: (downloadIcon.width - implicitWidth) / 2

                            y: (downloadIcon.height - implicitHeight) / 2

                            text: "download"

                            color: Colours.palette.m3onSurfaceVariant

                            fontStyle: Tokens.font.icon.small
                        }
                    }
                }
            }

            //
            // ==========================================
            // Browse
            // ==========================================
            //
            StyledRect {
                id: browseButton

                visible: root.primaryDevice !== null && root.primaryMounted

                implicitWidth: 34
                implicitHeight: 34

                radius: Tokens.rounding.full

                color: browseHover.hovered ? Colours.palette.m3secondaryContainer : "transparent"

                //
                // Downloading FROM the phone does not
                // block Browse. This allows the user to
                // reopen the browser while the download
                // continues.
                //
                opacity: root.primaryMountBusy || (root.primaryDevice !== null && KdeConnect.sharing && KdeConnect.sharingDevice === root.primaryDevice.id) ? 0.5 : 1

                MaterialIcon {
                    anchors.centerIn: parent

                    text: "folder_open"

                    color: Colours.palette.m3onSurfaceVariant

                    fontStyle: Tokens.font.icon.small
                }

                HoverHandler {
                    id: browseHover
                }

                TapHandler {
                    enabled: root.primaryDevice !== null && !root.primaryMountBusy && !(KdeConnect.sharing && KdeConnect.sharingDevice === root.primaryDevice.id)

                    onTapped: root.browsePrimaryDevice()
                }
            }
        }

        //
        // ==========================================
        // Devices
        // ==========================================
        //
        Repeater {
            model: KdeConnect.devices

            StyledRect {
                id: deviceCard

                required property var modelData

                property real shareProgress: 0

                property bool showCancel: false

                property bool cancelRequested: false

                readonly property bool storageMounted: KdeConnect.isMounted(deviceCard.modelData.id)

                readonly property bool storageBusy: KdeConnect.isMountBusy(deviceCard.modelData.id)

                readonly property bool transferringHere: (KdeConnect.sharing && KdeConnect.sharingDevice === deviceCard.modelData.id) || (KdeConnect.receiving && KdeConnect.receivingDevice === deviceCard.modelData.id)

                //
                // Keep the row height stable when the
                // Mount action changes to Cancel.
                //
                readonly property real actionHeight: Math.max(mountButton.implicitHeight, cancelButton.implicitHeight)

                Layout.fillWidth: true

                implicitHeight: Math.max(deviceLayout.implicitHeight, deviceCard.actionHeight) + Tokens.padding.medium * 2

                radius: Tokens.rounding.medium

                clip: true

                color: dropArea.containsDrag ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh

                CAnim on color {}

                //
                // ======================================
                // Layer 0: upload progress
                // ======================================
                //
                StyledRect {
                    z: 0

                    anchors.top: parent.top

                    anchors.bottom: parent.bottom

                    anchors.left: parent.left

                    width: parent.width * deviceCard.shareProgress

                    radius: deviceCard.radius

                    color: Colours.palette.m3primaryContainer

                    opacity: deviceCard.shareProgress > 0 ? 0.65 : 0
                }

                Connections {
                    target: KdeConnect

                    function onProgressChanged() {
                        if (KdeConnect.sharingDevice === deviceCard.modelData.id) {
                            deviceCard.shareProgress = KdeConnect.progress;
                        }
                    }

                    function onShared(device, count) {
                        if (device !== deviceCard.modelData.id) {
                            return;
                        }

                        cancelTimer.stop();

                        deviceCard.shareProgress = 1;
                        deviceCard.showCancel = false;
                        deviceCard.cancelRequested = false;
                    }

                    function onShareFailed(device, error) {
                        if (device !== deviceCard.modelData.id) {
                            return;
                        }

                        cancelTimer.stop();

                        deviceCard.shareProgress = 0;
                        deviceCard.showCancel = false;
                        deviceCard.cancelRequested = false;
                    }

                    function onShareCancelled(device) {
                        if (device !== deviceCard.modelData.id) {
                            return;
                        }

                        cancelTimer.stop();

                        deviceCard.shareProgress = 0;
                        deviceCard.showCancel = false;
                        deviceCard.cancelRequested = false;
                    }
                }

                Timer {
                    id: cancelTimer

                    interval: 1500

                    repeat: false

                    onTriggered: {
                        if (KdeConnect.sharing && KdeConnect.sharingDevice === deviceCard.modelData.id && !deviceCard.cancelRequested) {
                            deviceCard.showCancel = true;
                        }
                    }
                }

                //
                // ======================================
                // Layer 1: normal UI
                // ======================================
                //
                RowLayout {
                    id: deviceLayout

                    z: 1

                    anchors.fill: parent

                    anchors.margins: Tokens.padding.medium

                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        text: dropArea.containsDrag ? "file_download" : "smartphone"

                        color: dropArea.containsDrag ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant

                        fontStyle: Tokens.font.icon.medium
                    }

                    StyledText {
                        Layout.fillWidth: true

                        text: deviceCard.modelData.name

                        color: dropArea.containsDrag ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface

                        font: Tokens.font.body.small

                        elide: Text.ElideRight
                    }

                    //
                    // ==================================
                    // Mount / Unmount
                    // ==================================
                    //
                    StyledRect {
                        id: mountButton

                        visible: !deviceCard.transferringHere

                        implicitWidth: 32
                        implicitHeight: 32

                        radius: Tokens.rounding.full

                        color: mountHover.hovered ? Colours.palette.m3secondaryContainer : "transparent"

                        opacity: deviceCard.storageBusy ? 0.5 : 1

                        MaterialIcon {
                            anchors.centerIn: parent

                            text: {
                                if (deviceCard.storageBusy) {
                                    return "hourglass_top";
                                }

                                return deviceCard.storageMounted ? "eject" : "link";
                            }

                            color: Colours.palette.m3onSurfaceVariant

                            fontStyle: Tokens.font.icon.medium
                        }

                        HoverHandler {
                            id: mountHover
                        }

                        TapHandler {
                            enabled: !deviceCard.storageBusy

                            onTapped: {
                                if (deviceCard.storageMounted) {
                                    KdeConnect.unmount(deviceCard.modelData.id);
                                } else {
                                    KdeConnect.mount(deviceCard.modelData.id);
                                }
                            }
                        }
                    }

                    //
                    // ==================================
                    // Upload Cancel
                    // ==================================
                    //
                    StyledRect {
                        id: cancelButton

                        visible: deviceCard.showCancel

                        implicitWidth: cancelText.implicitWidth + Tokens.padding.medium * 2

                        implicitHeight: 32

                        radius: Tokens.rounding.full

                        color: Colours.palette.m3secondaryContainer

                        StyledText {
                            id: cancelText

                            anchors.centerIn: parent

                            text: qsTr("Cancel")

                            color: Colours.palette.m3onSecondaryContainer

                            font: Tokens.font.body.small
                        }

                        TapHandler {
                            enabled: !deviceCard.cancelRequested

                            onTapped: {
                                deviceCard.cancelRequested = true;

                                deviceCard.showCancel = false;

                                KdeConnect.cancel();
                            }
                        }
                    }
                }

                //
                // ======================================
                // Layer 2: drag/drop
                // ======================================
                //
                DropArea {
                    id: dropArea

                    z: 2

                    anchors.fill: parent

                    keys: ["text/uri-list"]

                    //
                    // Interactions.qml handles closing
                    // Utilities when the drag leaves.
                    //
                    // Never set utilities=false here.
                    //
                    onContainsDragChanged: {
                        if (containsDrag)
                            root.screenState.utilities = true;
                    }

                    onDropped: drop => {
                        if (!drop.hasUrls)
                            return;

                        deviceCard.shareProgress = 0;
                        deviceCard.showCancel = false;
                        deviceCard.cancelRequested = false;

                        KdeConnect.share(deviceCard.modelData.id, drop.urls);

                        cancelTimer.restart();

                        drop.acceptProposedAction();
                    }
                }
            }
        }
    }

    //
    // ==================================================
    // Inline phone browser
    // ==================================================
    //
    Utilities.PhoneBrowser {
        id: inlineBrowser

        anchors.fill: parent

        anchors.margins: Tokens.padding.medium

        wrapper: root.phoneBrowser

        enabled: root.browserOpen

        opacity: root.browserOpen ? 1 : 0

        transform: Translate {
            x: root.browserOpen ? 0 : root.transitionDistance

            Behavior on x {
                Anim {}
            }
        }

        Behavior on opacity {
            Anim {}
        }
    }
}
