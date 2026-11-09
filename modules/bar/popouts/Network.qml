pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
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
    property string captiveState: "none"
    property string captiveUrl: ""
    property string captiveCheckNetwork: ""
    readonly property string currentWifiKey: Nmcli.active ? Nmcli.active.ssid + "|" + Nmcli.active.bssid : ""
    readonly property bool checkCaptivePortal: root.popouts.hasCurrent && root.popouts.currentName === "network" && Nmcli.active !== null

    function refreshCaptivePortal(): void {
        if (!checkCaptivePortal || portalCheck.running)
            return;
        captiveCheckNetwork = currentWifiKey;
        portalCheck.running = true;
    }

    function openCaptivePortal(): void {
        if (captiveState !== "portal" || !checkCaptivePortal || captiveCheckNetwork !== currentWifiKey)
            return;

        Quickshell.execDetached(["bash", Quickshell.shellPath("assets/captive-portal/open"), captiveUrl]);
    }

    spacing: Tokens.spacing.small
    width: Tokens.sizes.bar.networkWidth

    onCheckCaptivePortalChanged: {
        if (!checkCaptivePortal) {
            captiveState = "none";
            captiveUrl = "";
            captiveCheckNetwork = "";
        }
    }

    // Wireless section
    StyledText {
        visible: root.view === "wireless"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: visible ? Tokens.padding.medium : 0
        Layout.rightMargin: Tokens.padding.extraSmall
        text: Tr.tr("Wireless")
        font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
    }

    Toggle {
        visible: root.view === "wireless"
        Layout.preferredHeight: visible ? implicitHeight : 0
        label: Tr.trCtx("Enabled", "toggle label")
        checked: Nmcli.wifiEnabled
        toggle.onToggled: Nmcli.enableWifi(checked)
    }

    StyledText {
        visible: root.view === "wireless"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: visible ? Tokens.spacing.small : 0
        Layout.rightMargin: Tokens.padding.extraSmall
        text: Tr.trN("%n network available", "%n networks available", Nmcli.networks.length)
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
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
            Layout.rightMargin: Tokens.padding.extraSmall
            spacing: Tokens.spacing.small

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

            MaterialIcon {
                text: Icons.getNetworkIcon(networkItem.modelData.strength)
                color: networkItem.modelData.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            }

            MaterialIcon {
                visible: networkItem.modelData.isSecure
                text: "lock"
                fontStyle: Tokens.font.icon.small
            }

            StyledText {
                Layout.leftMargin: Tokens.spacing.extraSmall
                Layout.rightMargin: Tokens.spacing.extraSmall
                Layout.fillWidth: true
                text: networkItem.modelData.ssid
                elide: Text.ElideRight
                font: Tokens.font.body.builders.medium.weight(networkItem.modelData.active ? Font.Medium : Font.Normal).build()
                color: networkItem.modelData.active ? Colours.palette.m3primary : Colours.palette.m3onSurface
            }

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: wirelessConnectIcon.implicitHeight + Tokens.padding.extraSmall

                radius: Tokens.rounding.full
                color: Qt.alpha(Colours.palette.m3primary, networkItem.modelData.active ? 1 : 0)

                CircularIndicator {
                    anchors.fill: parent
                    running: networkItem.loading
                }

                StateLayer {
                    color: networkItem.modelData.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                    disabled: networkItem.loading || !Nmcli.wifiEnabled

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

                MaterialIcon {
                    id: wirelessConnectIcon

                    anchors.centerIn: parent
                    animate: true
                    text: networkItem.modelData.active ? "link_off" : "link"
                    color: networkItem.modelData.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface

                    opacity: networkItem.loading ? 0 : 1

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }
            }
        }
    }

    StyledRect {
        visible: root.checkCaptivePortal && root.captiveState === "portal"
        Layout.preferredHeight: visible ? captiveAction.implicitHeight + Tokens.padding.small : 0
        Layout.topMargin: visible ? Tokens.spacing.small : 0
        Layout.fillWidth: true

        radius: Tokens.rounding.full
        color: Colours.palette.m3primaryContainer

        StateLayer {
            color: Colours.palette.m3onPrimaryContainer
            onClicked: root.openCaptivePortal()
        }

        RowLayout {
            id: captiveAction

            anchors.centerIn: parent
            spacing: Tokens.spacing.small

            MaterialIcon {
                id: captiveIcon

                Layout.topMargin: Math.round(fontInfo.pointSize * 0.0575)
                text: "wifi_password"
                color: Colours.palette.m3onPrimaryContainer
            }

            StyledText {
                Layout.topMargin: -Math.round(captiveIcon.fontInfo.pointSize * 0.0575)
                text: Tr.tr("Sign in to Wi-Fi")
                color: Colours.palette.m3onPrimaryContainer
            }

            MaterialIcon {
                text: "open_in_new"
                fontStyle: Tokens.font.icon.small
                color: Colours.palette.m3onPrimaryContainer
            }
        }
    }

    Process {
        id: portalCheck

        command: ["bash", Quickshell.shellPath("assets/captive-portal/check")]

        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.checkCaptivePortal || root.captiveCheckNetwork !== currentWifiKey)
                    return;
                const fields = text.trim().split("\t");
                root.captiveState = ["portal", "full", "limited", "offline", "none"].includes(fields[0]) ? fields[0] : "none";
                root.captiveUrl = root.captiveState === "portal" && fields.length > 1 ? fields.slice(1).join("\t").trim() : "";
            }
        }
    }

    Timer {
        interval: root.captiveState === "full" ? 60000 : 12000
        running: root.checkCaptivePortal
        triggeredOnStart: true
        repeat: true
        onTriggered: root.refreshCaptivePortal()
    }

    StyledRect {
        visible: root.view === "wireless"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: visible ? Tokens.spacing.small : 0
        Layout.fillWidth: true
        implicitHeight: rescanBtn.implicitHeight + Tokens.padding.small

        radius: Tokens.rounding.full
        color: Colours.palette.m3primaryContainer

        StateLayer {
            color: Colours.palette.m3onPrimaryContainer
            disabled: Nmcli.scanning || !Nmcli.wifiEnabled
            onClicked: Nmcli.rescanWifi()
        }

        RowLayout {
            id: rescanBtn

            anchors.centerIn: parent
            spacing: Tokens.spacing.small
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
                text: Tr.tr("Rescan networks")
                color: Colours.palette.m3onPrimaryContainer
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        CircularIndicator {
            anchors.centerIn: parent
            strokeWidth: Tokens.padding.extraSmall / 2
            bgColour: "transparent"
            implicitSize: parent.implicitHeight - Tokens.padding.large
            running: Nmcli.scanning
        }
    }

    // Ethernet section
    StyledText {
        visible: root.view === "ethernet"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: visible ? Tokens.padding.medium : 0
        Layout.rightMargin: Tokens.padding.extraSmall
        text: Tr.tr("Ethernet")
        font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
    }

    StyledText {
        visible: root.view === "ethernet"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: visible ? Tokens.spacing.small : 0
        Layout.rightMargin: Tokens.padding.extraSmall
        text: Tr.trN("%n device available", "%n devices available", Nmcli.ethernetDevices.length)
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
    }

    Repeater {
        visible: root.view === "ethernet"
        model: ScriptModel {
            values: [...Nmcli.ethernetDevices].sort((a, b) => {
                if (a.connected !== b.connected)
                    return b.connected - a.connected;
                return (a.iface || "").localeCompare(b.iface || "");
            }).slice(0, 8)
        }

        RowLayout {
            id: ethernetItem

            required property var modelData
            readonly property bool loading: false

            visible: root.view === "ethernet"
            Layout.preferredHeight: visible ? implicitHeight : 0
            Layout.fillWidth: true
            Layout.rightMargin: Tokens.padding.extraSmall
            spacing: Tokens.spacing.small

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

            MaterialIcon {
                text: "cable"
                color: ethernetItem.modelData.connected ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                Layout.leftMargin: Tokens.spacing.extraSmall
                Layout.rightMargin: Tokens.spacing.extraSmall
                Layout.fillWidth: true
                text: ethernetItem.modelData.iface || Tr.trCtx("Unknown", "unknown network interface")
                elide: Text.ElideRight
                font: Tokens.font.body.builders.medium.weight(ethernetItem.modelData.connected ? Font.Medium : Font.Normal).build()
                color: ethernetItem.modelData.connected ? Colours.palette.m3primary : Colours.palette.m3onSurface
            }

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: connectIcon.implicitHeight + Tokens.padding.extraSmall

                radius: Tokens.rounding.full
                color: Qt.alpha(Colours.palette.m3primary, ethernetItem.modelData.connected ? 1 : 0)

                CircularIndicator {
                    anchors.fill: parent
                    running: ethernetItem.loading
                }

                StateLayer {
                    color: ethernetItem.modelData.connected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                    disabled: ethernetItem.loading

                    onClicked: {
                        if (ethernetItem.modelData.connected && ethernetItem.modelData.connection) {
                            Nmcli.disconnectEthernet(ethernetItem.modelData.connection, () => {});
                        } else {
                            Nmcli.connectEthernet(ethernetItem.modelData.connection || "", ethernetItem.modelData.iface || "", () => {});
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
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }
            }
        }
    }

    Connections {
        function onActiveChanged(): void {
            root.captiveState = "none";
            root.captiveUrl = "";
            root.refreshCaptivePortal();
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

        function onScanningChanged(): void {
            if (!Nmcli.scanning)
                scanIcon.rotation = 0;
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

    component Toggle: RowLayout {
        required property string label
        property alias checked: toggle.checked
        property alias toggle: toggle

        Layout.fillWidth: true
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
