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

    // Public IP is hidden by default; tapping the blurred value reveals it.
    property bool showPublicIp: false

    signal networkSelected(ap: Nmcli.AccessPoint)

    title: qsTr("Network")

    // Public IP / ISP lookup once on creation (onVisibleChanged alone misses the
    // initial load, since no change event fires).
    Component.onCompleted: Nmcli.getPublicIpInfo()

    onVisibleChanged: if (visible) {
        Nmcli.getPublicIpInfo();
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // The public IP / ISP changes when the VPN tunnel goes up or down, so
        // re-resolve it whenever the connection state flips (after a short delay
        // so the new route has settled).
        Connections {
            function onConnectedChanged() {
                ispRefreshTimer.restart();
            }

            target: VPN
        }

        Timer {
            id: ispRefreshTimer

            interval: 1500
            onTriggered: Nmcli.getPublicIpInfo()
        }

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

        // ---- Router ----------------------------------------------------------
        // Standalone entry that opens the active connection's router admin page
        // (gateway IP) in a browser. Uses whichever connection is active.
        ConnectedRect {
            id: routerRow

            readonly property string gateway: {
                const eth = Nmcli.activeEthernet ? (Nmcli.ethernetDeviceDetails?.gateway ?? "") : "";
                if (eth.length > 0)
                    return eth;
                return Nmcli.wirelessDeviceDetails?.gateway ?? "";
            }

            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large
            first: true
            last: true
            visible: gateway.length > 0
            implicitHeight: routerLayout.implicitHeight + Tokens.padding.medium * 2

            StateLayer {
                onClicked: if (routerRow.gateway.length > 0)
                    Qt.openUrlExternally("http://" + routerRow.gateway)
            }

            RowLayout {
                id: routerLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                StyledRect {
                    implicitWidth: implicitHeight
                    implicitHeight: routerIcon.implicitHeight + Tokens.padding.small * 2
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3surfaceContainerHighest

                    MaterialIcon {
                        id: routerIcon

                        anchors.centerIn: parent
                        text: "router"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.medium
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Manage router")
                        font: Tokens.font.body.medium
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Open %1 in your browser").arg(routerRow.gateway)
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                    }
                }

                // ISP + public IP — shown on wide panels only, right-aligned.
                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    visible: root.cappedWidth > 620 && (Nmcli.isp.length > 0 || Nmcli.publicIp.length > 0)
                    spacing: 0

                    StyledText {
                        Layout.alignment: Qt.AlignRight
                        text: Nmcli.isp.length > 0 ? qsTr("ISP: %1").arg(Nmcli.isp) : qsTr("Public IP")
                        font: Tokens.font.body.medium
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideRight
                    }

                    // Public IP row: a label and the value itself, which is
                    // blurred by default (shoulder-surfing privacy) and toggles
                    // between hidden and revealed when tapped.
                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        visible: Nmcli.publicIp.length > 0
                        spacing: Tokens.spacing.extraSmall

                        StyledText {
                            Layout.alignment: Qt.AlignVCenter
                            text: qsTr("Public IP:")
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            horizontalAlignment: Text.AlignRight
                        }

                        // The value doubles as the toggle: tap to reveal/hide.
                        Item {
                            Layout.alignment: Qt.AlignVCenter
                            implicitWidth: root.showPublicIp ? ipValue.implicitWidth : blurRow.implicitWidth
                            implicitHeight: Math.max(ipValue.implicitHeight, blurRow.implicitHeight)

                            StyledText {
                                id: ipValue

                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                visible: root.showPublicIp
                                text: Nmcli.publicIp
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.small
                                horizontalAlignment: Text.AlignRight
                                elide: Text.ElideRight
                            }

                            Row {
                                id: blurRow

                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !root.showPublicIp
                                spacing: 0

                                Repeater {
                                    model: 4

                                    MaterialIcon {
                                        text: "blur_on"
                                        color: Colours.palette.m3outline
                                        fontStyle: Tokens.font.icon.small
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.showPublicIp = !root.showPublicIp
                            }
                        }
                    }
                }

                MaterialIcon {
                    text: "open_in_new"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.small
                }
            }
        }
    }
}
