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

    readonly property real nonAnimHeight: layout.implicitHeight + Tokens.padding.extraLargeIncreased

    implicitHeight: nonAnimHeight

    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer
    clip: true

    Component.onCompleted: KdeConnect.refresh()

    Component.onDestruction: screenState.utilities = false

    ColumnLayout {
        id: layout

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Tokens.padding.large

        spacing: Tokens.spacing.small

        //
        // Header
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
        }

        //
        // Devices
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

                readonly property bool transferringHere: KdeConnect.sharing && KdeConnect.sharingDevice === deviceCard.modelData.id

                //
                // Preserve the action area's height while
                // Browse / Mount disappear during a transfer.
                //
                readonly property real actionHeight: Math.max(browseButton.implicitHeight, mountButton.implicitHeight, cancelButton.implicitHeight)

                Layout.fillWidth: true

                implicitHeight: Math.max(deviceLayout.implicitHeight, deviceCard.actionHeight) + Tokens.padding.medium * 2

                radius: Tokens.rounding.medium
                clip: true

                color: dropArea.containsDrag ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh

                CAnim on color {}

                //
                // =====================================
                // Layer 0: transfer progress
                // =====================================
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
                // =====================================
                // Layer 1: normal UI
                // =====================================
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

                        fontStyle: Tokens.font.icon.small
                    }

                    StyledText {
                        Layout.fillWidth: true

                        text: deviceCard.modelData.name

                        color: dropArea.containsDrag ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface

                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    //
                    // Browse
                    //
                    StyledRect {
                        id: browseButton

                        visible: deviceCard.storageMounted && !deviceCard.transferringHere

                        implicitWidth: browseText.implicitWidth + Tokens.padding.medium * 2

                        implicitHeight: browseText.implicitHeight + Tokens.padding.medium

                        radius: Tokens.rounding.full

                        color: Colours.palette.m3secondaryContainer

                        opacity: deviceCard.storageBusy ? 0.5 : 1

                        StyledText {
                            id: browseText

                            anchors.centerIn: parent

                            text: qsTr("Browse")

                            color: Colours.palette.m3onSecondaryContainer

                            font: Tokens.font.body.small
                        }

                        TapHandler {
                            enabled: !deviceCard.storageBusy

                            onTapped: {
                                const directories = KdeConnect.directories(deviceCard.modelData.id);

                                const paths = Object.keys(directories);

                                if (paths.length === 0)
                                    return;

                                paths.sort((a, b) => a.length - b.length);

                                root.phoneBrowser.openForDevice(deviceCard.modelData.id, deviceCard.modelData.name, paths[0]);
                            }
                        }
                    }

                    //
                    // Mount / Unmount
                    //
                    StyledRect {
                        id: mountButton

                        visible: !deviceCard.transferringHere

                        implicitWidth: mountText.implicitWidth + Tokens.padding.medium * 2

                        implicitHeight: mountText.implicitHeight + Tokens.padding.medium

                        radius: Tokens.rounding.full

                        color: Colours.palette.m3secondaryContainer

                        opacity: deviceCard.storageBusy ? 0.5 : 1

                        StyledText {
                            id: mountText

                            anchors.centerIn: parent

                            text: {
                                if (deviceCard.storageBusy)
                                    return qsTr("Wait…");

                                return deviceCard.storageMounted ? qsTr("Unmount") : qsTr("Mount");
                            }

                            color: Colours.palette.m3onSecondaryContainer

                            font: Tokens.font.body.small
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
                    // Cancel
                    //
                    StyledRect {
                        id: cancelButton

                        visible: deviceCard.showCancel

                        implicitWidth: cancelText.implicitWidth + Tokens.padding.medium * 2

                        implicitHeight: cancelText.implicitHeight + Tokens.padding.medium

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
                // =====================================
                // Layer 2: drag/drop surface
                //
                // Keep this above Browse / Mount / Unmount
                // so drag tracking does not get interrupted
                // when the cursor moves over those buttons.
                // =====================================
                //
                DropArea {
                    id: dropArea

                    z: 2

                    anchors.fill: parent

                    keys: ["text/uri-list"]

                    //
                    // IMPORTANT:
                    // This exact behaviour is needed to keep
                    // Utilities open during external dragging.
                    //
                    // onContainsDragChanged: root.screenState.utilities = containsDrag
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
