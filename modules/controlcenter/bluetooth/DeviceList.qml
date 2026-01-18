pragma ComponentBehavior: Bound

import ".."
import "../components"
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config
import qs.utils
import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

DeviceList {
    id: root

    required property Session session
    readonly property bool smallDiscoverable: width <= 540
    readonly property bool smallPairable: width <= 480

    title: qsTr("Devices (%1)").arg(Bluetooth.devices.values.length)
    description: qsTr("All available bluetooth devices")
    activeItem: session.bt.active

    model: ScriptModel {
        id: deviceModel

        values: [...Bluetooth.devices.values].sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))
    }

    headerComponent: Component {
        RowLayout {
            spacing: Appearance.spacing.smaller

            StyledText {
                text: qsTr("Bluetooth")
                font.pointSize: Appearance.font.size.large
                font.weight: 500
            }

            Item {
                Layout.fillWidth: true
            }

            ToggleButton {
                toggled: Bluetooth.defaultAdapter?.enabled ?? false
                icon: "power"
                accent: "Tertiary"
                iconSize: Appearance.font.size.normal
                horizontalPadding: Appearance.padding.normal
                verticalPadding: Appearance.padding.smaller
                tooltip: qsTr("Toggle Bluetooth")

                onClicked: {
                    const adapter = Bluetooth.defaultAdapter;
                    if (adapter)
                        adapter.enabled = !adapter.enabled;
                }
            }

            ToggleButton {
                toggled: Bluetooth.defaultAdapter?.discoverable ?? false
                icon: root.smallDiscoverable ? "group_search" : ""
                label: root.smallDiscoverable ? "" : qsTr("Discoverable")
                iconSize: Appearance.font.size.normal
                horizontalPadding: Appearance.padding.normal
                verticalPadding: Appearance.padding.smaller
                tooltip: qsTr("Make discoverable")

                onClicked: {
                    const adapter = Bluetooth.defaultAdapter;
                    if (adapter)
                        adapter.discoverable = !adapter.discoverable;
                }
            }

            ToggleButton {
                toggled: Bluetooth.defaultAdapter?.pairable ?? false
                icon: "missing_controller"
                label: root.smallPairable ? "" : qsTr("Pairable")
                iconSize: Appearance.font.size.normal
                horizontalPadding: Appearance.padding.normal
                verticalPadding: Appearance.padding.smaller
                tooltip: qsTr("Make pairable")

                onClicked: {
                    const adapter = Bluetooth.defaultAdapter;
                    if (adapter)
                        adapter.pairable = !adapter.pairable;
                }
            }

            ToggleButton {
                toggled: Bluetooth.defaultAdapter?.discovering ?? false
                icon: "bluetooth_searching"
                accent: "Secondary"
                iconSize: Appearance.font.size.normal
                horizontalPadding: Appearance.padding.normal
                verticalPadding: Appearance.padding.smaller
                tooltip: qsTr("Scan for devices")

                onClicked: {
                    const adapter = Bluetooth.defaultAdapter;
                    if (adapter)
                        adapter.discovering = !adapter.discovering;
                }
            }

            ToggleButton {
                toggled: !root.session.bt.active
                icon: "settings"
                accent: "Primary"
                iconSize: Appearance.font.size.normal
                horizontalPadding: Appearance.padding.normal
                verticalPadding: Appearance.padding.smaller
                tooltip: qsTr("Bluetooth settings")

                onClicked: {
                    if (root.session.bt.active)
                        root.session.bt.active = null;
                    else {
                        root.session.bt.active = root.model.values[0] ?? null;
                    }
                }
            }
        }
    }

    delegate: Component {
        StyledRect {
            id: device

            required property BluetoothDevice modelData
            readonly property bool loading: modelData && (modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting)
            readonly property bool connected: modelData && modelData.state === BluetoothDeviceState.Connected

            width: ListView.view ? ListView.view.width : undefined
            implicitHeight: deviceInner.implicitHeight + Appearance.padding.normal * 2

            color: Qt.alpha(Colours.tPalette.m3surfaceContainer, root.activeItem === modelData ? Colours.tPalette.m3surfaceContainer.a : 0)
            radius: Appearance.rounding.normal

            StateLayer {
                id: stateLayer

                function onClicked(): void {
                    if (device.modelData)
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
                    color: device.connected ? Colours.palette.m3primaryContainer : (device.modelData && device.modelData.bonded) ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainerHigh

                    StyledRect {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Qt.alpha(device.connected ? Colours.palette.m3onPrimaryContainer : (device.modelData && device.modelData.bonded) ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface, stateLayer.pressed ? 0.1 : stateLayer.containsMouse ? 0.08 : 0)
                    }

                    MaterialIcon {
                        id: icon

                        anchors.centerIn: parent
                        text: Icons.getBluetoothIcon(device.modelData ? device.modelData.icon : "")
                        color: device.connected ? Colours.palette.m3onPrimaryContainer : (device.modelData && device.modelData.bonded) ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
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
                        text: device.modelData ? device.modelData.name : qsTr("Unknown")
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: (device.modelData ? device.modelData.address : "") + (device.connected ? qsTr(" (Connected)") : (device.modelData && device.modelData.bonded) ? qsTr(" (Paired)") : "")
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                        elide: Text.ElideRight
                    }
                }

                StyledRect {
                    id: connectBtn

                    implicitWidth: implicitHeight
                    implicitHeight: connectIcon.implicitHeight + Appearance.padding.smaller * 2

                    radius: Appearance.rounding.full
                    color: Qt.alpha(Colours.palette.m3primaryContainer, device.connected ? 1 : 0)

                    CircularIndicator {
                        anchors.fill: parent
                        running: device.loading
                    }

                    StateLayer {
                        color: device.connected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                        disabled: device.loading

                        function onClicked(): void {
                            if (device.loading)
                                return;

                            if (device.connected) {
                                device.modelData.connected = false;
                            } else {
                                if (device.modelData.bonded) {
                                    device.modelData.connected = true;
                                } else {
                                    device.modelData.pair();
                                }
                            }
                        }
                    }

                    MaterialIcon {
                        id: connectIcon

                        anchors.centerIn: parent
                        animate: true
                        text: device.connected ? "link_off" : "link"
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

    onItemSelected: item => session.bt.active = item
}
