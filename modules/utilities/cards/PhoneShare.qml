pragma ComponentBehavior: Bound

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

    readonly property bool primaryMounted: primaryDevice !== null && KdeConnect.isMounted(primaryDevice.id)

    readonly property bool primaryMountBusy: primaryDevice !== null && KdeConnect.isMountBusy(primaryDevice.id)

    readonly property real nonAnimHeight: layout.implicitHeight + Tokens.padding.extraLargeIncreased

    implicitHeight: nonAnimHeight

    radius: Tokens.rounding.large

    color: Colours.tPalette.m3surfaceContainer

    clip: true

    Component.onCompleted: KdeConnect.refresh()

    // Component.onDestruction: screenState.utilities = false

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

    ColumnLayout {
        id: layout

        anchors.top: parent.top

        anchors.left: parent.left

        anchors.right: parent.right

        anchors.margins: Tokens.padding.large

        spacing: Tokens.spacing.small

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

                    text: "smartphone"

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

                        if (KdeConnect.devices.length === 0)
                            return qsTr("No phone connected");

                        return qsTr("Drop files on a device");
                    }

                    color: Colours.palette.m3onSurfaceVariant

                    font: Tokens.font.body.small

                    elide: Text.ElideRight
                }
            }

            //
            // Browse
            //
            StyledRect {
                id: browseButton

                visible: root.primaryDevice !== null && root.primaryMounted

                implicitWidth: 34
                implicitHeight: 34

                radius: Tokens.rounding.full

                color: browseHover.hovered ? Colours.palette.m3secondaryContainer : "transparent"

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

                //
                // IMPORTANT:
                //
                // This now covers BOTH directions:
                //
                // PC -> Phone
                // Phone -> PC
                //
                readonly property bool transferringHere: (KdeConnect.sharing && KdeConnect.sharingDevice === deviceCard.modelData.id) || (KdeConnect.receiving && KdeConnect.receivingDevice === deviceCard.modelData.id)

                //
                // Keep height stable during transfer.
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
                // Layer 0: transfer progress
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
                                if (deviceCard.storageBusy)
                                    return "hourglass_top";

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
                    // Cancel
                    //
                    // This remains specifically for the
                    // PC -> Phone drag transfer.
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
                    // Do NOT set utilities=false here when
                    // containsDrag becomes false.
                    //
                    // Interactions.qml owns closing.
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
}
