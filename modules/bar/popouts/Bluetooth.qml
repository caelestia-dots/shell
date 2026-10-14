pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Caelestia.Components
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.utils

ColumnLayout {
    id: root

    required property PopoutState popouts

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter // qmllint disable unresolved-type
    readonly property bool adapterEnabled: adapter?.enabled ?? false

    spacing: Tokens.spacing.small
    width: Tokens.sizes.bar.bluetoothWidth

    PopoutHeader {
        icon: {
            if (!root.adapterEnabled)
                return "bluetooth_disabled";
            return Bluetooth.devices.values.some(d => d.connected) ? "bluetooth_connected" : "bluetooth"; // qmllint disable unresolved-type
        }
        title: Tr.tr("Bluetooth")
        subtitle: {
            if (!root.adapterEnabled)
                return Tr.trCtx("Off", "bluetooth disabled");

            const devices = Bluetooth.devices.values; // qmllint disable unresolved-type
            const connected = devices.filter(d => d.connected).length;
            if (connected > 0)
                // TRANSLATORS: number of connected bluetooth devices
                return Tr.trN("%n connected", "%n connected", connected);
            return Tr.trN("%n device", "%n devices", devices.length);
        }
        active: root.adapterEnabled
        hasToggle: true
        checked: root.adapterEnabled
        onToggled: checked => {
            if (root.adapter)
                root.adapter.enabled = checked;
        }
    }

    ConnectionList {
        showList: root.adapterEnabled
        placeholderIcon: root.adapterEnabled ? "bluetooth_searching" : "bluetooth_disabled"
        placeholderText: root.adapterEnabled ? Tr.tr("No devices found") : Tr.tr("Bluetooth disabled")

        model: ScriptModel {
            values: [...Bluetooth.devices.values].sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name)).slice(0, 5) // qmllint disable unresolved-type
        }

        delegate: ConnectionRow {
            id: device

            required property int index
            required property BluetoothDevice modelData
            readonly property bool connecting: modelData.state === BluetoothDeviceState.Connecting // qmllint disable unresolved-type
            readonly property bool disconnecting: modelData.state === BluetoothDeviceState.Disconnecting // qmllint disable unresolved-type

            width: ListView.view.width
            first: index === 0
            last: index === ListView.view.count - 1

            active: modelData.state === BluetoothDeviceState.Connected // qmllint disable unresolved-type
            loading: connecting || disconnecting
            warning: modelData.connected && modelData.batteryAvailable && modelData.battery < 0.2
            icon: Icons.getBluetoothIcon(modelData.icon)
            title: modelData.name
            subtitle: {
                if (connecting)
                    return Tr.trCtx("Connecting...", "bluetooth device state");
                if (disconnecting)
                    return Tr.trCtx("Disconnecting...", "bluetooth device state");
                if (modelData.connected) {
                    if (modelData.batteryAvailable)
                        // TRANSLATORS: %1 = battery percentage of a connected device, e.g. 80%
                        return Tr.tr("%1 battery").arg(Strings.percentOne(modelData.battery));
                    return Tr.trCtx("Connected", "bluetooth device state");
                }
                if (modelData.paired)
                    return Tr.trCtx("Paired", "bluetooth device state");
                return Tr.trCtx("Not paired", "bluetooth device state");
            }

            IconButton {
                icon: device.modelData.connected ? "link_off" : "link"
                type: IconButton.Text
                disabled: device.loading
                label.animate: true

                onClicked: device.modelData.connected = !device.modelData.connected
            }

            Loader {
                active: device.modelData.bonded
                visible: active

                sourceComponent: IconButton {
                    icon: "delete"
                    type: IconButton.Text
                    onClicked: device.modelData.forget()
                }
            }
        }
    }

    ButtonRow {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.extraSmall
        spacing: Tokens.spacing.small

        IconTextButton {
            fillWidth: true
            type: TextButton.Tonal
            shapeMorph: true
            isToggle: true
            checked: root.adapter?.discovering ?? false
            disabled: !root.adapterEnabled
            icon: "bluetooth_searching"
            // TRANSLATORS: verb, toggles searching for nearby bluetooth devices
            text: Tr.trCtx("Discover", "bluetooth adapter action")

            onClicked: {
                if (root.adapter)
                    root.adapter.discovering = !root.adapter.discovering;
            }
        }

        IconTextButton {
            fillWidth: true
            type: TextButton.Tonal
            shapeMorph: true
            icon: "settings"
            text: Tr.tr("Settings")

            onClicked: root.popouts.detachRequested("bluetooth")
        }
    }
}
