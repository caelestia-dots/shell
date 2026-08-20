pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils

ColumnLayout {
    id: root

    required property PopoutState popouts
    readonly property int indicatorType: {
        const mode = GlobalConfig.services ? GlobalConfig.services.bluetoothBatteryIndicatorType : undefined;
        return Number.isFinite(mode) ? mode : 2;
    }
    readonly property bool showBatteryIcon: Boolean(GlobalConfig.services && GlobalConfig.services.bluetoothBatteryIcon)
    readonly property bool showBatteryText: Boolean(GlobalConfig.services && GlobalConfig.services.bluetoothBatteryText)
    readonly property bool showBatteryRing: Boolean(GlobalConfig.services && GlobalConfig.services.bluetoothBatteryRing)
    readonly property bool swapIconText: Boolean(GlobalConfig.services && GlobalConfig.services.bluetoothBatterySwapIconText)
    function batteryColorForLevel(levelPercent) {
        const palette = GlobalConfig.services && GlobalConfig.services.bluetoothBatteryUseCustomColors
            ? (GlobalConfig.services.bluetoothBatteryColors || [])
            : [
                "#22c55e",
                "#22c55e",
                "#4ade80",
                "#84cc16",
                "#facc15",
                "#f59e0b",
                "#fb923c",
                "#f97316",
                "#f87171",
                "#ef4444"
            ];
        const clamp = Math.max(0, Math.min(100, Number(levelPercent) || 0));
        if (clamp >= 100)
            return palette[0] || palette[0] || Colours.palette.m3primary;
        const idx = Math.min(9, Math.max(0, 9 - Math.floor(clamp / 10)));
        return palette[idx] || palette[0] || Colours.palette.m3primary;
    }

    width: 320
    spacing: Tokens.spacing.small

    StyledText {
        Layout.topMargin: Tokens.padding.medium
        Layout.leftMargin: Tokens.padding.extraSmall
        Layout.rightMargin: Tokens.padding.extraSmall
        text: qsTr("Bluetooth")
        font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
    }

    Toggle {
        label: qsTr("Enabled")
        checked: Bluetooth.defaultAdapter?.enabled ?? false // qmllint disable unresolved-type
        toggle.onToggled: {
            const adapter = Bluetooth.defaultAdapter; // qmllint disable unresolved-type
            if (adapter)
                adapter.enabled = checked;
        }
    }

    Toggle {
        label: qsTr("Discovering")
        checked: Bluetooth.defaultAdapter?.discovering ?? false // qmllint disable unresolved-type
        toggle.onToggled: {
            const adapter = Bluetooth.defaultAdapter; // qmllint disable unresolved-type
            if (adapter)
                adapter.discovering = checked;
        }
    }

    StyledText {
        Layout.topMargin: Tokens.spacing.small
        Layout.leftMargin: Tokens.padding.extraSmall
        Layout.rightMargin: Tokens.padding.extraSmall
        text: {
            const devices = Bluetooth.devices.values; // qmllint disable unresolved-type
            let available = qsTr("%1 device%2 available").arg(devices.length).arg(devices.length === 1 ? "" : "s");
            const connected = devices.filter(d => d.connected).length;
            if (connected > 0)
                available += qsTr(" (%1 connected)").arg(connected);
            return available;
        }
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
    }

    Repeater {
        model: ScriptModel {
            values: [...Bluetooth.devices.values].sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name)).slice(0, 5) // qmllint disable unresolved-type
        }

        ColumnLayout {
            id: device

            required property BluetoothDevice modelData
            readonly property bool loading: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting // qmllint disable unresolved-type

            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.extraSmall
            Layout.rightMargin: Tokens.padding.extraSmall
            spacing: 0

            opacity: 0
            scale: 0.7

            Component.onCompleted: {
                opacity = 1;
                scale = 1;
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on scale {
                Anim {}
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                MaterialIcon {
                    visible: true
                    text: Icons.getBluetoothIcon(device.modelData.icon)
                }

                MaterialIcon {
                    visible: root.showBatteryIcon && root.swapIconText && device.modelData.state === BluetoothDeviceState.Connected  // qmllint disable unresolved-type
                    text: device.modelData.batteryAvailable ? Icons.getBatteryIcon(device.modelData.battery) : "battery_alert"
                    color: device.modelData.batteryAvailable
                        ? root.batteryColorForLevel(device.modelData.battery * 100)
                        : Colours.palette.m3error
                }

                StyledText {
                    visible: root.showBatteryText && root.swapIconText && device.modelData.state === BluetoothDeviceState.Connected  // qmllint disable unresolved-type
                    text: device.modelData.batteryAvailable ? Math.round(device.modelData.battery * 100) + "%" : "--%"
                    color: device.modelData.batteryAvailable
                        ? root.batteryColorForLevel(device.modelData.battery * 100)
                        : Colours.palette.m3error
                    font: Tokens.font.body.small
                }

                StyledText {
                    Layout.leftMargin: Tokens.spacing.extraSmall
                    Layout.rightMargin: Tokens.spacing.extraSmall
                    Layout.fillWidth: true
                    text: device.modelData.name
                    elide: Text.ElideRight
                }

                StyledText {
                    visible: root.showBatteryText && !root.swapIconText && device.modelData.state === BluetoothDeviceState.Connected  // qmllint disable unresolved-type
                    text: device.modelData.batteryAvailable ? Math.round(device.modelData.battery * 100) + "%" : "--%"
                    color: device.modelData.batteryAvailable
                        ? root.batteryColorForLevel(device.modelData.battery * 100)
                        : Colours.palette.m3error
                    font: Tokens.font.body.small
                }

                MaterialIcon {
                    visible: root.showBatteryIcon && !root.swapIconText && device.modelData.state === BluetoothDeviceState.Connected  // qmllint disable unresolved-type
                    text: device.modelData.batteryAvailable ? Icons.getBatteryIcon(device.modelData.battery) : "battery_alert"
                    color: device.modelData.batteryAvailable
                        ? root.batteryColorForLevel(device.modelData.battery * 100)
                        : Colours.palette.m3error
                }

                StyledRect {
                    id: connectBtn

                    implicitWidth: implicitHeight
                    implicitHeight: connectIcon.implicitHeight + Tokens.padding.extraSmall

                    radius: Tokens.rounding.full
                    color: Qt.alpha(Colours.palette.m3primary, device.modelData.state === BluetoothDeviceState.Connected ? 1 : 0) // qmllint disable unresolved-type

                    CircularIndicator {
                        anchors.fill: parent
                        running: device.loading
                    }

                    StateLayer {
                        color: device.modelData.state === BluetoothDeviceState.Connected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface // qmllint disable unresolved-type
                        disabled: device.loading
                        onClicked: device.modelData.connected = !device.modelData.connected
                    }

                    MaterialIcon {
                        id: connectIcon

                        anchors.centerIn: parent
                        animate: true
                        text: device.modelData.connected ? "link_off" : "link"
                        color: device.modelData.state === BluetoothDeviceState.Connected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface // qmllint disable unresolved-type

                        opacity: device.loading ? 0 : 1

                        Behavior on opacity {
                            Anim {
                                type: Anim.DefaultEffects
                            }
                        }
                    }
                }

                Loader {
                    visible: status === Loader.Ready
                    asynchronous: true
                    active: device.modelData.bonded
                    sourceComponent: Item {
                        implicitWidth: connectBtn.implicitWidth
                        implicitHeight: connectBtn.implicitHeight

                        StateLayer {
                            radius: Tokens.rounding.full
                            onClicked: device.modelData.forget()
                        }

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "delete"
                        }
                    }
                }
            }

            Loader {
                visible: status === Loader.Ready
                active: root.showBatteryRing && device.modelData.connected && (
                    (BbmService.available && BbmService.dataFor(device.modelData.address) !== null)
                    || (GlobalConfig.services && GlobalConfig.services.bluetoothBatteryUpowerSupport && device.modelData.batteryAvailable)
                )
                Layout.fillWidth: true
                sourceComponent: BbmExpandedRow {
                    bbmData: {
                        const bbm = BbmService.available ? BbmService.dataFor(device.modelData.address) : null;
                        if (bbm)
                            return bbm;
                        if (GlobalConfig.services && GlobalConfig.services.bluetoothBatteryUpowerSupport && device.modelData.batteryAvailable) {
                            return {
                                Battery1Level: Math.round(device.modelData.battery * 100),
                                Battery1Icon: "",
                                Battery1Status: "discharging",
                                Battery2Level: 0,
                                Battery3Level: 0,
                            };
                        }
                        return null;
                    }
                    address: device.modelData.address
                }
            }
        }
    }

    IconTextButton {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.medium
        inactiveColour: Colours.palette.m3primaryContainer
        inactiveOnColour: Colours.palette.m3onPrimaryContainer
        verticalPadding: Tokens.padding.extraSmall
        text: qsTr("Open settings")
        icon: "settings"

        onClicked: root.popouts.detachRequested("bluetooth")
    }

    component Toggle: RowLayout {
        required property string label
        property alias checked: toggle.checked
        property alias toggle: toggle

        Layout.fillWidth: true
        Layout.leftMargin: Tokens.padding.extraSmall
        Layout.rightMargin: Tokens.padding.extraSmall
        spacing: Tokens.spacing.medium

        StyledText {
            Layout.fillWidth: true
            text: parent.label
        }

        StyledSwitch {
            id: toggle
        }
    }
}
