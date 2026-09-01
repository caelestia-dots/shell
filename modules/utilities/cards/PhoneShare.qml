pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.services

// Drop files here to send them to a paired phone. Each reachable device is its
// own drop target, so with more than one paired there's no guessing which gets
// the files.
StyledRect {
    id: root

    required property ScreenState screenState

    readonly property real nonAnimHeight: layout.implicitHeight + Tokens.padding.extraLargeIncreased

    implicitHeight: nonAnimHeight

    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer
    clip: true

    // Refreshed when the card appears rather than on a timer: the list only
    // changes when a phone comes or goes, and the card is short-lived.
    Component.onCompleted: KdeConnect.refresh()
    Component.onDestruction: screenState.utilities = false

    ColumnLayout {
        id: layout

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.small

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

        Repeater {
            model: KdeConnect.devices

            StyledRect {
                id: deviceCard

                required property var modelData

                property real shareProgress: 0
                property bool showCancel: false
                property bool cancelRequested: false

                Layout.fillWidth: true
                implicitHeight: deviceLayout.implicitHeight + Tokens.padding.medium * 2

                radius: Tokens.rounding.medium
                clip: true

                color: dropArea.containsDrag ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh

                CAnim on color {}

                StyledRect {
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
                        if (KdeConnect.sharingDevice === deviceCard.modelData.id)
                            deviceCard.shareProgress = KdeConnect.progress;
                    }

                    function onShared(device, count) {
                        if (device === deviceCard.modelData.id) {
                            cancelTimer.stop();
                            deviceCard.shareProgress = 1;
                            deviceCard.showCancel = false;
                            deviceCard.cancelRequested = false;
                        }
                    }

                    function onShareFailed(device, error) {
                        if (device === deviceCard.modelData.id) {
                            cancelTimer.stop();
                            deviceCard.shareProgress = 0;
                            deviceCard.showCancel = false;
                            deviceCard.cancelRequested = false;
                        }
                    }

                    function onShareCancelled(device) {
                        if (device === deviceCard.modelData.id) {
                            cancelTimer.stop();
                            deviceCard.shareProgress = 0;
                            deviceCard.showCancel = false;
                            deviceCard.cancelRequested = false;
                        }
                    }
                }

                Timer {
                    id: cancelTimer

                    interval: 900
                    repeat: false

                    onTriggered: {
                        if (KdeConnect.sharing && KdeConnect.sharingDevice === deviceCard.modelData.id && !deviceCard.cancelRequested) {
                            deviceCard.showCancel = true;
                        }
                    }
                }

                DropArea {
                    id: dropArea

                    anchors.fill: parent
                    keys: ["text/uri-list"]

                    onContainsDragChanged: root.screenState.utilities = containsDrag

                    onDropped: drop => {
                        if (drop.hasUrls) {
                            deviceCard.shareProgress = 0;
                            deviceCard.showCancel = false;
                            deviceCard.cancelRequested = false;

                            KdeConnect.share(deviceCard.modelData.id, drop.urls);

                            cancelTimer.restart();

                            drop.acceptProposedAction();
                        }
                    }
                }

                RowLayout {
                    id: deviceLayout

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

                    StyledRect {
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
            }
        }
    }
}
