pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
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
    property string enterpriseNoticeSsid: ""

    spacing: Tokens.spacing.small
    width: Tokens.sizes.bar.networkWidth

    // Wireless section
    StyledText {
        visible: root.view === "wireless"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: visible ? Tokens.padding.medium : 0
        Layout.rightMargin: Tokens.padding.extraSmall
        text: qsTr("Wireless")
        font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
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
        Layout.topMargin: visible ? Tokens.spacing.small : 0
        Layout.rightMargin: Tokens.padding.extraSmall
        text: qsTr("%1 networks available").arg(Nmcli.networks.length) // qmllint disable missing-property
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
    }

    Repeater {
        visible: root.view === "wireless"
        model: ScriptModel {
            values: {
                const rank = n => n.active ? 0 : Nmcli.hasSavedProfile(n.ssid) ? 1 : 2;
                return [...Nmcli.networks].sort((a, b) => rank(a) - rank(b) || b.strength - a.strength).slice(0, 8);
            }
        }

        StyledRect {
            id: networkItem

            required property Nmcli.AccessPoint modelData
            readonly property bool isConnecting: root.connectingToSsid === modelData.ssid
            readonly property bool loading: networkItem.isConnecting

            visible: root.view === "wireless"
            Layout.preferredHeight: visible ? implicitHeight : 0
            Layout.fillWidth: true
            Layout.rightMargin: Tokens.padding.extraSmall
            implicitHeight: rowLayout.implicitHeight + Tokens.padding.extraSmall
            radius: Tokens.rounding.medium
            color: modelData.active ? Qt.alpha(Colours.palette.m3primary, 0.12) : "transparent"

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

            Behavior on color {
                CAnim {}
            }

            RowLayout {
                id: rowLayout

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Tokens.spacing.small
                anchors.rightMargin: Tokens.spacing.small
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: Icons.getNetworkIcon(networkItem.modelData.strength)
                    color: networkItem.modelData.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                }

                MaterialIcon {
                    readonly property bool saved: Nmcli.hasSavedProfile(networkItem.modelData.ssid)

                    visible: networkItem.modelData.isSecure
                    text: saved ? "wifi_lock" : "lock"
                    fill: saved ? 1 : 0
                    color: saved ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
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
                    id: actionPill

                    readonly property bool saved: Nmcli.hasSavedProfile(networkItem.modelData.ssid)

                    implicitWidth: pillRow.implicitWidth
                    implicitHeight: pillRow.implicitHeight
                    radius: Tokens.rounding.full
                    color: networkItem.modelData.active ? Colours.palette.m3primary : actionPill.saved ? Colours.palette.m3surfaceContainerHigh : "transparent"

                    Behavior on color {
                        CAnim {}
                    }

                    Row {
                        id: pillRow

                        Item {
                            id: connectSegment

                            width: wirelessConnectIcon.implicitHeight + Tokens.padding.extraSmall
                            height: width

                            CircularIndicator {
                                anchors.fill: parent
                                running: networkItem.loading
                            }

                            StateLayer {
                                anchors.fill: parent
                                radius: Tokens.rounding.full
                                color: networkItem.modelData.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                                disabled: networkItem.loading || !Nmcli.wifiEnabled

                                onClicked: {
                                    if (networkItem.modelData.active) {
                                        Nmcli.disconnectFromNetwork();
                                    } else if (networkItem.modelData.isEnterprise && !Nmcli.hasSavedProfile(networkItem.modelData.ssid)) {
                                        root.enterpriseNoticeSsid = networkItem.modelData.ssid;
                                        enterpriseNoticeTimer.restart();
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
                                fill: !networkItem.modelData.active && actionPill.saved ? 1 : 0
                                color: networkItem.modelData.active ? Colours.palette.m3onPrimary : (actionPill.saved ? Colours.palette.m3primary : Colours.palette.m3onSurface)

                                opacity: networkItem.loading ? 0 : 1

                                Behavior on opacity {
                                    Anim {
                                        type: Anim.DefaultEffects
                                    }
                                }
                            }
                        }

                        Item {
                            visible: actionPill.saved
                            width: visible ? 1 : 0
                            height: connectSegment.height

                            Rectangle {
                                anchors.centerIn: parent
                                width: 1
                                height: parent.height * 0.5
                                color: Qt.alpha(networkItem.modelData.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant, 0.3)
                            }
                        }

                        Item {
                            visible: actionPill.saved
                            width: visible ? connectSegment.width : 0
                            height: connectSegment.height

                            StateLayer {
                                id: forgetState

                                anchors.fill: parent
                                radius: Tokens.rounding.full
                                disabled: networkItem.loading
                                onClicked: Nmcli.forgetNetwork(networkItem.modelData.ssid)
                            }

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: "delete"
                                fontStyle: Tokens.font.icon.small
                                color: forgetState.containsMouse ? Colours.palette.m3error : (networkItem.modelData.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant)
                                opacity: forgetState.containsMouse ? 1 : 0.7

                                Behavior on color {
                                    CAnim {}
                                }

                                Behavior on opacity {
                                    Anim {
                                        type: Anim.DefaultEffects
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    StyledRect {
        id: enterpriseNotice

        visible: root.view === "wireless" && root.enterpriseNoticeSsid.length > 0
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: visible ? Tokens.spacing.small : 0
        Layout.fillWidth: true
        implicitHeight: enterpriseNoticeLayout.implicitHeight + Tokens.padding.medium

        radius: Tokens.rounding.large
        color: Colours.palette.m3secondaryContainer

        Timer {
            id: enterpriseNoticeTimer

            interval: 4000
            onTriggered: root.enterpriseNoticeSsid = ""
        }

        RowLayout {
            id: enterpriseNoticeLayout

            anchors.centerIn: parent
            width: parent.width - Tokens.padding.large * 2
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "school"
                color: Colours.palette.m3onSecondaryContainer
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                Layout.fillWidth: true
                text: qsTr("“%1” needs institutional credentials — configure it in Settings → Network.").arg(root.enterpriseNoticeSsid)
                color: Colours.palette.m3onSecondaryContainer
                font: Tokens.font.body.small
                wrapMode: Text.WordWrap
            }
        }
    }

    // Ethernet section
    StyledText {
        visible: root.view === "ethernet"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: visible ? Tokens.padding.medium : 0
        Layout.rightMargin: Tokens.padding.extraSmall
        text: qsTr("Ethernet")
        font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
    }

    StyledText {
        visible: root.view === "ethernet"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: visible ? Tokens.spacing.small : 0
        Layout.rightMargin: Tokens.padding.extraSmall
        text: qsTr("%1 devices available").arg(Nmcli.ethernetDevices.length)
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
                text: ethernetItem.modelData.iface || qsTr("Unknown")
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

    StyledRect {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.medium
        implicitHeight: footerRow.implicitHeight + Tokens.padding.small

        radius: Tokens.rounding.full
        color: Colours.palette.m3primaryContainer

        RowLayout {
            id: footerRow

            anchors.fill: parent
            spacing: 0

            Item {
                visible: root.view === "wireless"
                Layout.fillWidth: true
                Layout.preferredHeight: rescanRow.implicitHeight + Tokens.padding.small

                StateLayer {
                    anchors.fill: parent
                    color: Colours.palette.m3onPrimaryContainer
                    disabled: Nmcli.scanning || !Nmcli.wifiEnabled
                    onClicked: Nmcli.rescanWifi()
                }

                RowLayout {
                    id: rescanRow

                    anchors.centerIn: parent
                    spacing: Tokens.spacing.small
                    opacity: Nmcli.scanning ? 0 : 1

                    MaterialIcon {
                        id: scanIcon

                        animate: true
                        text: "wifi_find"
                        color: Colours.palette.m3onPrimaryContainer
                    }

                    StyledText {
                        text: qsTr("Rescan")
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
                    implicitSize: rescanRow.implicitHeight
                    running: Nmcli.scanning
                }
            }

            Rectangle {
                visible: root.view === "wireless"
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                Layout.topMargin: Tokens.padding.small
                Layout.bottomMargin: Tokens.padding.small
                color: Qt.alpha(Colours.palette.m3onPrimaryContainer, 0.3)
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: settingsRow.implicitHeight + Tokens.padding.small

                StateLayer {
                    anchors.fill: parent
                    color: Colours.palette.m3onPrimaryContainer
                    onClicked: root.popouts.detachRequested("network")
                }

                RowLayout {
                    id: settingsRow

                    anchors.centerIn: parent
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        text: "settings"
                        color: Colours.palette.m3onPrimaryContainer
                    }

                    StyledText {
                        text: qsTr("Settings")
                        color: Colours.palette.m3onPrimaryContainer
                    }
                }
            }
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
