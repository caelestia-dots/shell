pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import qs.utils
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property Item wrapper

    property string connectingToSsid: ""
    property string view: "wireless" // "wireless" or "ethernet"
    property var passwordNetwork: null
    property bool showPasswordDialog: false

    spacing: Appearance.spacing.small
    width: Config.bar.sizes.networkWidth

    // Wireless section
    StyledText {
        visible: root.view === "wireless"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: visible ? Appearance.padding.normal : 0
        Layout.rightMargin: Appearance.padding.small
        text: qsTr("Wireless")
        font.weight: 500
    }

    Toggle {
        visible: root.view === "wireless"
        Layout.preferredHeight: visible ? implicitHeight : 0
        label: qsTr("Enabled")
        checked: Nmcli.wifiEnabled
        toggle.onToggled: Nmcli.enableWifi(checked)
    }

    StyledText {
        visible: root.view === "wireless"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: visible ? Appearance.spacing.small : 0
        Layout.rightMargin: Appearance.padding.small
        text: qsTr("%1 networks available").arg(Nmcli.networks.length)
        color: Colours.palette.m3onSurfaceVariant
        font.pointSize: Appearance.font.size.small
    }

    Repeater {
        visible: root.view === "wireless"
        model: ScriptModel {
            values: [...Nmcli.networks].sort((a, b) => {
                if (a.active !== b.active)
                    return b.active - a.active;
                return b.strength - a.strength;
            }).slice(0, 8)
        }

        RowLayout {
            id: networkItem

            required property Nmcli.AccessPoint modelData
            readonly property bool isConnecting: root.connectingToSsid === modelData.ssid
            readonly property bool loading: networkItem.isConnecting

            visible: root.view === "wireless"
            Layout.preferredHeight: visible ? implicitHeight : 0
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
                text: Icons.getNetworkIcon(networkItem.modelData.strength)
                color: networkItem.modelData.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            }

            MaterialIcon {
                visible: networkItem.modelData.isSecure
                text: "lock"
                font.pointSize: Appearance.font.size.small
            }

            StyledText {
                Layout.leftMargin: Appearance.spacing.small / 2
                Layout.rightMargin: Appearance.spacing.small / 2
                Layout.fillWidth: true
                text: networkItem.modelData.ssid
                elide: Text.ElideRight
                font.weight: networkItem.modelData.active ? 500 : 400
                color: networkItem.modelData.active ? Colours.palette.m3primary : Colours.palette.m3onSurface
            }

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: wirelessConnectIcon.implicitHeight + Appearance.padding.small

                radius: Appearance.rounding.full
                color: Qt.alpha(Colours.palette.m3primary, networkItem.modelData.active ? 1 : 0)

                CircularIndicator {
                    anchors.fill: parent
                    running: networkItem.loading
                }

                StateLayer {
                    color: networkItem.modelData.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                    disabled: networkItem.loading || !Nmcli.wifiEnabled

                    function onClicked(): void {
                        if (networkItem.modelData.active) {
                            Nmcli.disconnectFromNetwork();
                        } else {
                            root.connectingToSsid = networkItem.modelData.ssid;
                            NetworkConnection.handleConnect(
                                networkItem.modelData,
                                null,
                                (network) => {
                                    // Password is required - show password dialog
                                    root.passwordNetwork = network;
                                    root.showPasswordDialog = true;
                                    root.wrapper.currentName = "wirelesspassword";
                                }
                            );
                            
                            // Clear connecting state if connection succeeds immediately (saved profile)
                            // This is handled by the onActiveChanged connection below
                        }
                    }
                }

                MaterialIcon {
                    id: wirelessConnectIcon

                    anchors.centerIn: parent
                    animate: true
                    text: networkItem.modelData.active ? "link_off" : "link"
                    color: networkItem.modelData.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface

                    opacity: networkItem.loading ? 0 : 1

                    Behavior on opacity {
                        Anim {}
                    }
                }
            }
        }
    }

    StyledRect {
        visible: root.view === "wireless"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: visible ? Appearance.spacing.small : 0
        Layout.fillWidth: true
        implicitHeight: rescanBtn.implicitHeight + Appearance.padding.small * 2

        radius: Appearance.rounding.full
        color: Colours.palette.m3primaryContainer

        StateLayer {
            color: Colours.palette.m3onPrimaryContainer
            disabled: Nmcli.scanning || !Nmcli.wifiEnabled

            function onClicked(): void {
                Nmcli.rescanWifi();
            }
        }

        RowLayout {
            id: rescanBtn

            anchors.centerIn: parent
            spacing: Appearance.spacing.small
            opacity: Nmcli.scanning ? 0 : 1

            MaterialIcon {
                id: scanIcon

                Layout.topMargin: Math.round(fontInfo.pointSize * 0.0575)
                animate: true
                text: "wifi_find"
                color: Colours.palette.m3onPrimaryContainer
            }

            StyledText {
                Layout.topMargin: -Math.round(scanIcon.fontInfo.pointSize * 0.0575)
                text: qsTr("Rescan networks")
                color: Colours.palette.m3onPrimaryContainer
            }

            Behavior on opacity {
                Anim {}
            }
        }

        CircularIndicator {
            anchors.centerIn: parent
            strokeWidth: Appearance.padding.small / 2
            bgColour: "transparent"
            implicitHeight: parent.implicitHeight - Appearance.padding.smaller * 2
            running: Nmcli.scanning
        }
    }

    // Ethernet section
    StyledText {
        visible: root.view === "ethernet"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: visible ? Appearance.padding.normal : 0
        Layout.rightMargin: Appearance.padding.small
        text: qsTr("Ethernet")
        font.weight: 500
    }

    StyledText {
        visible: root.view === "ethernet"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: visible ? Appearance.spacing.small : 0
        Layout.rightMargin: Appearance.padding.small
        text: qsTr("%1 devices available").arg(Nmcli.ethernetDevices.length)
        color: Colours.palette.m3onSurfaceVariant
        font.pointSize: Appearance.font.size.small
    }

    Repeater {
        visible: root.view === "ethernet"
        model: ScriptModel {
            values: [...Nmcli.ethernetDevices].sort((a, b) => {
                if (a.connected !== b.connected)
                    return b.connected - a.connected;
                return (a.interface || "").localeCompare(b.interface || "");
            }).slice(0, 8)
        }

        RowLayout {
            id: ethernetItem

            required property var modelData
            readonly property bool loading: false

            visible: root.view === "ethernet"
            Layout.preferredHeight: visible ? implicitHeight : 0
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
                text: "cable"
                color: ethernetItem.modelData.connected ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                Layout.leftMargin: Appearance.spacing.small / 2
                Layout.rightMargin: Appearance.spacing.small / 2
                Layout.fillWidth: true
                text: ethernetItem.modelData.interface || qsTr("Unknown")
                elide: Text.ElideRight
                font.weight: ethernetItem.modelData.connected ? 500 : 400
                color: ethernetItem.modelData.connected ? Colours.palette.m3primary : Colours.palette.m3onSurface
            }

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: connectIcon.implicitHeight + Appearance.padding.small

                radius: Appearance.rounding.full
                color: Qt.alpha(Colours.palette.m3primary, ethernetItem.modelData.connected ? 1 : 0)

                CircularIndicator {
                    anchors.fill: parent
                    running: ethernetItem.loading
                }

                StateLayer {
                    color: ethernetItem.modelData.connected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                    disabled: ethernetItem.loading

                    function onClicked(): void {
                        if (ethernetItem.modelData.connected && ethernetItem.modelData.connection) {
                            Nmcli.disconnectEthernet(ethernetItem.modelData.connection, () => {});
                        } else {
                            Nmcli.connectEthernet(ethernetItem.modelData.connection || "", ethernetItem.modelData.interface || "", () => {});
                        }
                    }
                }

                MaterialIcon {
                    id: connectIcon

                    anchors.centerIn: parent
                    animate: true
                    text: ethernetItem.modelData.connected ? "link_off" : "link"
                    color: ethernetItem.modelData.connected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface

                    opacity: ethernetItem.loading ? 0 : 1

                    Behavior on opacity {
                        Anim {}
                    }
                }
            }
        }
    }

    Connections {
        target: Nmcli

        function onActiveChanged(): void {
            if (Nmcli.active && root.connectingToSsid === Nmcli.active.ssid) {
                root.connectingToSsid = "";
                // Close password dialog if we successfully connected
                if (root.showPasswordDialog && root.passwordNetwork && Nmcli.active.ssid === root.passwordNetwork.ssid) {
                    root.showPasswordDialog = false;
                    root.passwordNetwork = null;
                    if (root.wrapper.currentName === "wirelesspassword") {
                        root.wrapper.currentName = "network";
                    }
                }
            }
        }

        function onScanningChanged(): void {
            if (!Nmcli.scanning)
                scanIcon.rotation = 0;
        }
    }

    Connections {
        target: root.wrapper
        function onCurrentNameChanged(): void {
            // Clear password network when leaving password dialog
            if (root.wrapper.currentName !== "wirelesspassword" && root.showPasswordDialog) {
                root.showPasswordDialog = false;
                root.passwordNetwork = null;
            }
        }
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
