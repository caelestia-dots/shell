pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    signal networkSelected(ap: Nmcli.AccessPoint)

    title: qsTr("Network")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        Timer {
            running: root.visible && Nmcli.wifiEnabled
            repeat: true
            triggeredOnStart: true
            interval: GlobalConfig.nexus.networkRescanInterval
            onTriggered: Nmcli.rescanWifi()
        }

        Timer {
            id: wifiScanDelay

            interval: 100
            onTriggered: Nmcli.rescanWifi()
        }

        Connections {
            function onWifiEnabledChanged(): void {
                if (Nmcli.wifiEnabled)
                    wifiScanDelay.start();
            }

            target: Nmcli
        }

        ToggleRow {
            first: true
            text: qsTr("Wi-Fi")
            font: Tokens.font.body.medium
            horizontalPadding: Tokens.padding.largeIncreased
            checked: Nmcli.wifiEnabled
            onToggled: Nmcli.enableWifi(checked)
        }

        ItemList {
            id: networkList

            showList: Nmcli.wifiEnabled
            placeholderIcon: Nmcli.wifiEnabled ? "wifi_find" : "signal_wifi_off"
            placeholderText: Nmcli.wifiEnabled ? qsTr("No networks found") : qsTr("Wi-Fi disabled")
            extraHeight: Nmcli.scanning ? Tokens.rounding.extraSmall : 0 // Inline so it isn't affected by anim
            list.anchors.top: scanningIndicator.bottom

            model: ScriptModel {
                values: {
                    const connecting = Nmcli.connectingSsid();
                    // Lower rank sorts higher in the list
                    const rank = n => n.active ? 0 : n.ssid === connecting ? 1 : Nmcli.hasSavedProfile(n.ssid) ? 2 : 3;
                    return [...Nmcli.networks].sort((a, b) => rank(a) - rank(b) || b.strength - a.strength);
                }
            }

            delegate: StateLayer {
                id: network

                required property Nmcli.AccessPoint modelData
                property bool currentSelected
                property real textOpacity: disabled ? 0.5 : 1

                disabled: currentSelected || Nmcli.connectingSsid() === modelData.ssid

                anchors.left: networkList.list.contentItem.left
                anchors.right: networkList.list.contentItem.right
                implicitHeight: networkLayout.implicitHeight + networkLayout.anchors.margins * 2
                radius: Tokens.rounding.extraSmall
                anchors.fill: undefined

                onClicked: {
                    if (!modelData.active) {
                        NetworkConnection.handleConnect(modelData);
                        currentSelected = true;
                        root.networkSelected(modelData);
                    }
                }

                Behavior on textOpacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }

                Connections {
                    function onActiveChanged(): void {
                        if (network.modelData.active)
                            network.currentSelected = false;
                    }

                    target: network.modelData
                }

                Connections {
                    function onNetworkSelected(ap: Nmcli.AccessPoint): void {
                        if (ap !== network.modelData)
                            network.currentSelected = false;
                    }

                    target: root
                }

                RowLayout {
                    id: networkLayout

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.large
                    anchors.leftMargin: Tokens.padding.extraLarge
                    anchors.rightMargin: Tokens.padding.extraLarge
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        text: Icons.getNetworkIcon(network.modelData.strength)
                        color: network.modelData.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.medium
                        opacity: network.textOpacity
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        opacity: network.textOpacity

                        StyledText {
                            Layout.fillWidth: true
                            text: network.modelData.ssid
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Security: %1%2").arg(network.modelData.security).arg(network.modelData.active ? qsTr(" • Connected") : Nmcli.hasSavedProfile(network.modelData.ssid) ? qsTr(" • Saved") : "")
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                        }
                    }

                    AnimLoader {
                        sourceComp: Nmcli.connectingSsid() === network.modelData.ssid ? loadingComp : iconComp

                        Component {
                            id: iconComp

                            MaterialIcon {
                                text: network.modelData.active ? "settings" : "lock"
                                color: network.modelData.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                                fontStyle: Tokens.font.icon.medium
                                opacity: network.textOpacity
                            }
                        }

                        Component {
                            id: loadingComp

                            LoadingIndicator {
                                implicitSize: Math.round(Tokens.font.icon.medium.pointSize * 1.3)
                            }
                        }
                    }
                }
            }

            StyledProgressBar {
                id: scanningIndicator

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 1
                implicitHeight: Nmcli.scanning ? Tokens.rounding.extraSmall : 0
                indeterminate: true

                Behavior on implicitHeight {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }
        }

        ConnectedRect {
            Layout.fillWidth: true
            implicitHeight: addNetworkLayout.implicitHeight + addNetworkLayout.anchors.margins * 2
            last: true

            StateLayer {}

            RowLayout {
                id: addNetworkLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased

                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: "add"
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Add network")
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }
            }
        }

        // ---- VPN -------------------------------------------------------------
        // Always present (mirrors the Wi-Fi group): a header toggle, a middle
        // info panel, and a management row. The section stays even with no
        // provider configured, so the user can always reach provider management.
        ToggleRow {
            Layout.topMargin: Tokens.spacing.large
            Layout.fillWidth: true
            first: true
            text: qsTr("VPN")
            font: Tokens.font.body.medium
            horizontalPadding: Tokens.padding.largeIncreased
            checked: VPN.connected
            // Connectable as long as there's a provider and we're not mid-switch.
            enabled: !VPN.connecting && VPN.providers().length > 0
            onToggled: VPN.toggle()

            Timer {
                running: root.visible
                repeat: true
                triggeredOnStart: true
                interval: 5000
                onTriggered: {
                    VPN.checkStatus();
                    if (VPN.connected)
                        VPN.refreshStats();
                }
            }
        }

        // Middle info panel — shows the active provider's details when connected,
        // or a context placeholder otherwise (same look as the Wi-Fi list panel).
        ConnectedRect {
            Layout.fillWidth: true
            color: Colours.tPalette.m3surfaceContainer
            clip: true
            implicitHeight: (VPN.connected ? infoLayout.implicitHeight : vpnPlaceholder.implicitHeight) + Tokens.padding.large * 2

            Behavior on implicitHeight {
                Anim {}
            }

            // Disconnected placeholder.
            ColumnLayout {
                id: vpnPlaceholder

                anchors.centerIn: parent
                spacing: Tokens.spacing.extraSmall
                opacity: VPN.connected ? 0 : 1
                visible: opacity > 0

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: VPN.providers().length === 0 ? "add_circle" : (VPN.connecting ? "vpn_lock" : "vpn_key_off")
                    color: Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.large
                    animate: true
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: {
                        if (VPN.providers().length === 0)
                            return qsTr("No VPN provider set up");
                        if (VPN.connecting)
                            return qsTr("Connecting…");
                        if (VPN.status.state === "needs-auth")
                            return VPN.status.reason || qsTr("Authentication required");
                        if (VPN.status.state === "error")
                            return VPN.status.reason || qsTr("Error");
                        return qsTr("Disconnected");
                    }
                    color: Colours.palette.m3outline
                    font: Tokens.font.body.large
                    animate: true
                }

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

            // Connected details.
            ColumnLayout {
                id: infoLayout

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.small
                opacity: VPN.connected ? 1 : 0
                visible: opacity > 0

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.medium

                    StyledRect {
                        implicitWidth: implicitHeight
                        implicitHeight: connIcon.implicitHeight + Tokens.padding.small * 2
                        radius: Tokens.rounding.full
                        color: Colours.palette.m3primaryContainer

                        MaterialIcon {
                            id: connIcon

                            anchors.centerIn: parent
                            text: "vpn_key"
                            fill: 1
                            color: Colours.palette.m3onPrimaryContainer
                            fontStyle: Tokens.font.icon.medium
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: VPN.currentConfig?.displayName || VPN.providerName || qsTr("VPN")
                            font: Tokens.font.body.medium
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Connected")
                            color: Colours.palette.m3primary
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                        }
                    }
                }

                // Compact horizontal summary: Interface (left) + Protocol (right).
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Tokens.spacing.small
                    spacing: Tokens.spacing.large
                    visible: (VPN.interfaceName || VPN.currentConfig?.interface || "").length > 0

                    ColumnLayout {
                        Layout.alignment: Qt.AlignTop
                        spacing: 0

                        StyledText {
                            text: qsTr("Interface")
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                        }

                        StyledText {
                            text: VPN.interfaceName || VPN.currentConfig?.interface || qsTr("—")
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }
                    }

                    // Current ping over the tunnel (real measurement).
                    ColumnLayout {
                        Layout.leftMargin: Tokens.spacing.large
                        Layout.alignment: Qt.AlignTop
                        visible: VPN.pingMs >= 0
                        spacing: 0

                        StyledText {
                            text: qsTr("Current Ping")
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.small
                        }

                        RowLayout {
                            spacing: Tokens.spacing.small

                            StyledRect {
                                Layout.alignment: Qt.AlignVCenter
                                implicitWidth: Math.round(Tokens.font.body.small.pointSize * 0.7)
                                implicitHeight: implicitWidth
                                radius: implicitWidth / 2
                                // Green ≤80ms, amber ≤150ms, red above.
                                color: VPN.pingMs <= 80 ? Colours.palette.m3primary : (VPN.pingMs <= 150 ? Colours.palette.m3tertiary : Colours.palette.m3error)
                            }

                            StyledText {
                                text: qsTr("%1 ms").arg(VPN.pingMs)
                                font: Tokens.font.body.small
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    ColumnLayout {
                        spacing: 0

                        StyledText {
                            Layout.alignment: Qt.AlignRight
                            text: qsTr("Protocol")
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.small
                            horizontalAlignment: Text.AlignRight
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignRight
                            text: {
                                const n = (VPN.providerName || "").toLowerCase();
                                if (n === "warp" || n === "wireguard" || n === "tailscale" || n === "netbird")
                                    return "WireGuard";
                                if (n === "openvpn")
                                    return "OpenVPN";
                                return n.length > 0 ? n.charAt(0).toUpperCase() + n.slice(1) : qsTr("—");
                            }
                            font: Tokens.font.body.small
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }
        }

        // Manage (switch provider, add/edit/delete).
        ConnectedRect {
            Layout.fillWidth: true
            last: true
            implicitHeight: manageLayout.implicitHeight + manageLayout.anchors.margins * 2

            StateLayer {
                onClicked: root.nState.openSubPage(1)
            }

            RowLayout {
                id: manageLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: "settings"
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Manage providers")
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                StyledText {
                    text: qsTr("%1 configured").arg(VPN.providers().length)
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                }

                MaterialIcon {
                    text: "chevron_right"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.small
                }
            }
        }
    }
}
