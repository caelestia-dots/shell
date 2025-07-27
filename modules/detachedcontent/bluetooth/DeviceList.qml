pragma ComponentBehavior: Bound

import ".."
import qs.widgets
import qs.services
import qs.config
import qs.utils
import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ColumnLayout {
    id: root

    required property Session session

    anchors.fill: parent
    spacing: Appearance.spacing.small

    StyledText {
        text: qsTr("Settings")
        font.pointSize: Appearance.font.size.large
        font.weight: 500
    }

    StyledText {
        text: qsTr("General bluetooth settings")
        color: Colours.palette.m3outline
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: settingsText.implicitHeight + Appearance.padding.normal * 2

        radius: Appearance.rounding.normal
        color: Colours.palette.m3surfaceContainer

        StateLayer {
            function onClicked(): void {
                root.session.bt.active = null;
            }
        }

        StyledText {
            id: settingsText

            anchors.centerIn: parent
            text: qsTr("Bluetooth settings")
        }
    }

    RowLayout {
        Layout.topMargin: Appearance.spacing.large
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Devices (%1)").arg(Bluetooth.devices.values.length)
                font.pointSize: Appearance.font.size.large
                font.weight: 500
            }

            StyledText {
                Layout.fillWidth: true
                text: qsTr("All available bluetooth devices")
                color: Colours.palette.m3outline
            }
        }

        StyledRect {
            implicitWidth: implicitHeight
            implicitHeight: scanIcon.implicitHeight + Appearance.padding.normal * 2

            radius: Bluetooth.defaultAdapter?.discovering ? Appearance.rounding.normal : implicitHeight / 2
            color: Bluetooth.defaultAdapter?.discovering ? Colours.palette.m3secondary : Colours.palette.m3secondaryContainer

            StateLayer {
                color: Bluetooth.defaultAdapter?.discovering ? Colours.palette.m3onSecondary : Colours.palette.m3onSecondaryContainer

                function onClicked(): void {
                    const adapter = Bluetooth.defaultAdapter;
                    if (adapter)
                        adapter.discovering = !adapter.discovering;
                }
            }

            MaterialIcon {
                id: scanIcon

                anchors.centerIn: parent
                animate: true
                text: "bluetooth_searching"
                color: Bluetooth.defaultAdapter?.discovering ? Colours.palette.m3onSecondary : Colours.palette.m3onSecondaryContainer
                fill: Bluetooth.defaultAdapter?.discovering ? 1 : 0
            }

            Behavior on radius {
                Anim {}
            }
        }
    }

    StyledListView {
        model: ScriptModel {
            values: [...Bluetooth.devices.values].sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired))
        }

        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        ScrollBar.vertical: StyledScrollBar {}

        delegate: Item {
            id: device

            required property BluetoothDevice modelData
            readonly property bool loading: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting
            readonly property bool connected: modelData.state === BluetoothDeviceState.Connected

            anchors.left: parent.left
            anchors.right: parent.right
            implicitHeight: deviceInner.implicitHeight + Appearance.padding.normal * 2

            StateLayer {
                id: stateLayer

                radius: Appearance.rounding.small

                function onClicked(): void {
                    root.session.bt.active = device.modelData;
                }
            }

            RowLayout {
                id: deviceInner

                anchors.fill: parent
                anchors.margins: Appearance.padding.normal

                spacing: Appearance.spacing.normal

                StyledRect {
                    implicitWidth: implicitHeight
                    implicitHeight: icon.implicitHeight + Appearance.padding.normal * 2

                    radius: Appearance.rounding.normal
                    color: device.connected ? Colours.palette.m3primaryContainer : device.modelData.bonded ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerHigh

                    StyledRect {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Qt.alpha(device.connected ? Colours.palette.m3onPrimaryContainer : device.modelData.bonded ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface, stateLayer.pressed ? 0.1 : stateLayer.containsMouse ? 0.08 : 0)
                    }

                    MaterialIcon {
                        id: icon

                        anchors.centerIn: parent
                        text: Icons.getBluetoothIcon(device.modelData.icon)
                        color: device.connected ? Colours.palette.m3onPrimaryContainer : device.modelData.bonded ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                        font.pointSize: Appearance.font.size.large
                        fill: device.connected ? 1 : 0

                        Behavior on fill {
                            Anim {}
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true

                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: device.modelData.name
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: device.modelData.address + (device.connected ? qsTr(" (Connected)") : device.modelData.bonded ? qsTr(" (Paired)") : "")
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                        elide: Text.ElideRight
                    }
                }

                StyledRect {
                    id: connectBtn

                    implicitWidth: implicitHeight
                    implicitHeight: connectIcon.implicitHeight + Appearance.padding.small * 2

                    radius: Appearance.rounding.full
                    color: device.connected ? Colours.palette.m3primaryContainer : "transparent"

                    StyledBusyIndicator {
                        anchors.centerIn: parent

                        implicitWidth: implicitHeight
                        implicitHeight: connectIcon.implicitHeight

                        running: opacity > 0
                        opacity: device.loading ? 1 : 0

                        Behavior on opacity {
                            Anim {}
                        }
                    }

                    StateLayer {
                        color: device.connected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                        disabled: device.loading

                        function onClicked(): void {
                            device.modelData.connected = !device.modelData.connected;
                        }
                    }

                    MaterialIcon {
                        id: connectIcon

                        anchors.centerIn: parent
                        animate: true
                        text: device.modelData.connected ? "link_off" : "link"
                        color: device.connected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface

                        opacity: device.loading ? 0 : 1

                        Behavior on opacity {
                            Anim {}
                        }
                    }
                }
            }
        }
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}
