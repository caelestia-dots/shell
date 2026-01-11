pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import qs.utils
import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts
import "../../controlcenter/network"

ColumnLayout {
    id: root

    required property Item wrapper

    spacing: Appearance.spacing.small

    StyledText {
        Layout.topMargin: Appearance.padding.normal
        Layout.rightMargin: Appearance.padding.small
        text: qsTr("Bluetooth")
        font.weight: 500
    }

    Toggle {
        label: qsTr("Enabled")
        checked: Bluetooth.defaultAdapter?.enabled ?? false
        toggle.onToggled: {
            const adapter = Bluetooth.defaultAdapter;
            if (adapter)
                adapter.enabled = checked;
        }
    }

    Toggle {
        label: qsTr("Discovering")
        checked: Bluetooth.defaultAdapter?.discovering ?? false
        toggle.onToggled: {
            const adapter = Bluetooth.defaultAdapter;
            if (adapter)
                adapter.discovering = checked;
        }
    }

    StyledText {
        Layout.topMargin: Appearance.spacing.small
        Layout.rightMargin: Appearance.padding.small
        text: {
            const devices = Bluetooth.devices.values;
            let available = qsTr("%1 device%2 available").arg(devices.length).arg(devices.length === 1 ? "" : "s");
            const connected = devices.filter(d => d.connected).length;
            if (connected > 0)
                available += qsTr(" (%1 connected)").arg(connected);
            return available;
        }
        color: Colours.palette.m3onSurfaceVariant
        font.pointSize: Appearance.font.size.small
    }

    Repeater {
        model: ScriptModel {
            values: [...Bluetooth.devices.values].sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name)).slice(0, 5)
        }

        RowLayout {
            id: device

            required property BluetoothDevice modelData
            readonly property bool loading: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting

            Layout.fillWidth: true
            Layout.rightMargin: Appearance.padding.small
            spacing: Appearance.spacing.small

            opacity: 0
            scale: 0.7

            Component.onCompleted: {
                opacity = 1;
                scale = 1;
            }

            Behavior on opacity {
                Anim {}
            }

            Behavior on scale {
                Anim {}
            }

            MaterialIcon {
                text: Icons.getBluetoothIcon(device.modelData.icon)
            }

            StyledText {
                Layout.leftMargin: Appearance.spacing.small / 2
                Layout.rightMargin: Appearance.spacing.small / 2
                Layout.fillWidth: true
                text: device.modelData.name
            }

            StyledRect {
                id: connectBtn

                implicitWidth: implicitHeight
                implicitHeight: connectIcon.implicitHeight + Appearance.padding.small

                radius: Appearance.rounding.full
                color: Qt.alpha(Colours.palette.m3primary, device.modelData.state === BluetoothDeviceState.Connected ? 1 : 0)

                CircularIndicator {
                    anchors.fill: parent
                    running: device.loading
                }

                StateLayer {
                    color: device.modelData.state === BluetoothDeviceState.Connected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
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
                    color: device.modelData.state === BluetoothDeviceState.Connected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface

                    opacity: device.loading ? 0 : 1

                    Behavior on opacity {
                        Anim {}
                    }
                }
            }

            Loader {
                asynchronous: true
                active: device.modelData.bonded
                sourceComponent: Item {
                    implicitWidth: connectBtn.implicitWidth
                    implicitHeight: connectBtn.implicitHeight

                    StateLayer {
                        radius: Appearance.rounding.full

                        function onClicked(): void {
                            device.modelData.forget();
                        }
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "delete"
                    }
                }
            }
        }
    }

    IconTextButton {
        Layout.fillWidth: true
        Layout.topMargin: Appearance.spacing.normal
        inactiveColour: Colours.palette.m3primaryContainer
        inactiveOnColour: Colours.palette.m3onPrimaryContainer
        verticalPadding: Appearance.padding.small
        text: qsTr("Open settings")
        icon: "settings"

        onClicked: root.wrapper.detach("bluetooth")
    }

    component Toggle: RowLayout {
        required property string label
        property alias checked: toggle.checked
        property alias toggle: toggle

        Layout.fillWidth: true
        Layout.rightMargin: Appearance.padding.small
        spacing: Appearance.spacing.normal

        StyledText {
            Layout.fillWidth: true
            text: parent.label
        }

        StyledSwitch {
            id: toggle
        }
    }
}
