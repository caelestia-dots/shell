pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
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

    property string connectingToSsid: ""
    property string view: "wireless" // "wireless" or "ethernet"
    property var passwordNetwork: null
    property bool showPasswordDialog: false

    readonly property bool wireless: view === "wireless"

    spacing: Tokens.spacing.small
    width: Tokens.sizes.bar.networkWidth

    PopoutHeader {
        icon: {
            if (!root.wireless)
                return "cable";
            if (!Nmcli.wifiEnabled)
                return "wifi_off";
            return Nmcli.active ? Icons.getNetworkIcon(Nmcli.active.strength) : "wifi";
        }
        title: root.wireless ? Tr.tr("Wireless") : Tr.tr("Ethernet")
        subtitle: {
            if (!root.wireless) {
                if (Nmcli.activeEthernet)
                    // TRANSLATORS: %1 = network interface name, e.g. enp3s0
                    return Tr.tr("Connected via %1").arg(Nmcli.activeEthernet.iface);
                return Tr.trN("%n device available", "%n devices available", Nmcli.ethernetDevices.length);
            }

            if (!Nmcli.wifiEnabled)
                return Tr.trCtx("Off", "wireless disabled");
            return Tr.trN("%n network", "%n networks", Nmcli.networks.length); // qmllint disable missing-property
        }
        active: root.wireless ? Nmcli.wifiEnabled : !!Nmcli.activeEthernet
        hasToggle: root.wireless
        checked: Nmcli.wifiEnabled
        onToggled: checked => Nmcli.enableWifi(checked)
    }

    ConnectionList {
        visible: root.wireless
        showList: Nmcli.wifiEnabled
        placeholderIcon: Nmcli.wifiEnabled ? "wifi_find" : "signal_wifi_off"
        placeholderText: Nmcli.wifiEnabled ? Tr.tr("No networks found") : Tr.tr("Wi-Fi disabled")

        model: ScriptModel {
            values: root.wireless ? [...Nmcli.networks].sort((a, b) => {
                if (a.active !== b.active)
                    return b.active - a.active;
                return b.strength - a.strength;
            }).slice(0, 8) : []
        }

        delegate: ConnectionRow {
            id: networkItem

            required property int index
            required property Nmcli.AccessPoint modelData

            width: ListView.view.width
            first: index === 0
            last: index === ListView.view.count - 1

            active: modelData.active
            loading: root.connectingToSsid === modelData.ssid
            icon: Icons.getNetworkIcon(modelData.strength, modelData.isSecure)
            title: modelData.ssid
            subtitle: {
                if (modelData.active)
                    return Tr.trCtx("Connected", "network connected");
                if (loading)
                    return Tr.trCtx("Connecting...", "network connecting");
                if (Nmcli.hasSavedProfile(modelData.ssid))
                    return Tr.trCtx("Saved", "network saved");
                return modelData.isSecure ? Tr.trCtx("Secured", "network security") : Tr.trCtx("Open", "network security");
            }

            IconButton {
                icon: networkItem.modelData.active ? "link_off" : "link"
                type: IconButton.Text
                disabled: networkItem.loading || !Nmcli.wifiEnabled
                label.animate: true

                onClicked: {
                    if (networkItem.modelData.active) {
                        Nmcli.disconnectFromNetwork();
                    } else {
                        root.connectingToSsid = networkItem.modelData.ssid;
                        NetworkConnection.handleConnect(networkItem.modelData, null, network => {
                            // Password is required - show password dialog
                            root.passwordNetwork = network;
                            root.showPasswordDialog = true;
                            root.popouts.currentName = "wirelesspassword";
                        });

                        // Clear connecting state if connection succeeds immediately (saved profile)
                        // This is handled by the onActiveChanged connection below
                    }
                }
            }
        }
    }

    ConnectionList {
        visible: !root.wireless
        placeholderIcon: "lan"
        placeholderText: Tr.tr("No devices found")

        model: ScriptModel {
            values: root.wireless ? [] : [...Nmcli.ethernetDevices].sort((a, b) => {
                if (a.connected !== b.connected)
                    return b.connected - a.connected;
                return (a.iface || "").localeCompare(b.iface || "");
            }).slice(0, 8)
        }

        delegate: ConnectionRow {
            id: ethernetItem

            required property int index
            required property var modelData

            width: ListView.view.width
            first: index === 0
            last: index === ListView.view.count - 1

            active: modelData.connected
            icon: "cable"
            title: modelData.iface || Tr.trCtx("Unknown", "unknown network interface")
            subtitle: modelData.connected ? (modelData.connection || Tr.trCtx("Connected", "network connected")) : Tr.trCtx("Disconnected", "network disconnected")

            IconButton {
                icon: ethernetItem.modelData.connected ? "link_off" : "link"
                type: IconButton.Text
                label.animate: true

                onClicked: {
                    if (ethernetItem.modelData.connected && ethernetItem.modelData.connection) {
                        Nmcli.disconnectEthernet(ethernetItem.modelData.connection, () => {});
                    } else {
                        Nmcli.connectEthernet(ethernetItem.modelData.connection || "", ethernetItem.modelData.iface || "", () => {});
                    }
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
            visible: root.wireless
            type: TextButton.Tonal
            shapeMorph: true
            disabled: Nmcli.scanning || !Nmcli.wifiEnabled
            icon: "wifi_find"
            text: Nmcli.scanning ? Tr.tr("Scanning...") : Tr.tr("Rescan")
            label.animate: true

            onClicked: Nmcli.rescanWifi()
        }

        IconTextButton {
            fillWidth: true
            type: TextButton.Tonal
            shapeMorph: true
            icon: "settings"
            text: Tr.tr("Settings")

            onClicked: root.popouts.detachRequested("network")
        }
    }

    Connections {
        function onActiveChanged(): void {
            if (Nmcli.active && root.connectingToSsid === Nmcli.active.ssid) {
                root.connectingToSsid = "";
                // Close password dialog if we successfully connected
                if (root.showPasswordDialog && root.passwordNetwork && Nmcli.active.ssid === root.passwordNetwork.ssid) {
                    root.showPasswordDialog = false;
                    root.passwordNetwork = null;
                    if (root.popouts.currentName === "wirelesspassword") {
                        root.popouts.currentName = "network";
                    }
                }
            }
        }

        target: Nmcli
    }

    Connections {
        function onCurrentNameChanged(): void {
            // Clear password network when leaving password dialog
            if (root.popouts.currentName !== "wirelesspassword" && root.showPasswordDialog) {
                root.showPasswordDialog = false;
                root.passwordNetwork = null;
            }
        }

        target: root.popouts
    }
}
