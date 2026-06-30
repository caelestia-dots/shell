pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus
import qs.modules.nexus.common

ColumnLayout {
    id: root

    required property NexusState nState
    required property int cappedWidth

    spacing: Tokens.spacing.extraSmall / 2

    // Keep ethernet state fresh while the page is visible.
    Timer {
        running: root.visible
        repeat: true
        triggeredOnStart: true
        interval: 5000
        onTriggered: {
            Nmcli.getEthernetInterfaces(() => {});
            if (Nmcli.activeEthernet) {
                Nmcli.getEthernetDeviceDetails(Nmcli.activeEthernet.iface, () => {});
                Nmcli.getEthernetDataUsage(Nmcli.activeEthernet.iface, () => {});
                Nmcli.getEthernetSpeed(Nmcli.activeEthernet.iface);
            }
        }
    }

    ConnectedRect {
        Layout.fillWidth: true
        first: true
        implicitHeight: ethHeaderLayout.implicitHeight + Tokens.padding.medium * 2

        RowLayout {
            id: ethHeaderLayout

            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            anchors.leftMargin: Tokens.padding.largeIncreased
            anchors.rightMargin: Tokens.padding.largeIncreased
            spacing: Tokens.spacing.medium

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Ethernet")
                font: Tokens.font.body.medium
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 0

                StyledText {
                    Layout.alignment: Qt.AlignRight
                    text: Nmcli.activeEthernet ? qsTr("Connected") : qsTr("Not connected")
                    color: Nmcli.activeEthernet ? Colours.palette.m3primary : Colours.palette.m3outline
                    font: Tokens.font.label.small
                }

                StyledText {
                    Layout.alignment: Qt.AlignRight
                    visible: Nmcli.activeEthernet && Nmcli.ethernetDataUsage.length > 0
                    text: qsTr("Data usage: %1").arg(Nmcli.ethernetDataUsage)
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                }
            }
        }
    }

    Repeater {
        id: ethRepeater

        model: ScriptModel {
            values: Nmcli.ethernetDevices.filter(d => d.state !== "unavailable")
        }

        delegate: ConnectedRect {
            id: ethRow

            required property Nmcli.EthernetDevice modelData
            required property int index

            readonly property bool isConnected: modelData.connected
            // IP/MAC/DNS come from the parsed device details, not the basic
            // device list (which leaves those fields blank).
            readonly property var details: ethRow.isConnected ? Nmcli.ethernetDeviceDetails : null

            Layout.fillWidth: true
            last: index === ethRepeater.count - 1
            implicitHeight: ethLayout.implicitHeight + Tokens.padding.medium * 2

            // Tap opens the detail page for this interface.
            StateLayer {
                onClicked: {
                    root.nState.selectedEthernetInterface = ethRow.modelData.iface;
                    root.nState.openSubPage(1);
                }
            }

            RowLayout {
                id: ethLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.medium
                spacing: Tokens.spacing.medium

                StyledRect {
                    implicitWidth: implicitHeight
                    implicitHeight: ethIcon.implicitHeight + Tokens.padding.small * 2
                    radius: Tokens.rounding.full
                    color: ethRow.isConnected ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHighest

                    MaterialIcon {
                        id: ethIcon

                        anchors.centerIn: parent
                        text: ethRow.isConnected ? "lan" : "settings_ethernet"
                        fill: text === "lan" ? 1 : 0
                        color: ethRow.isConnected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.medium
                        animate: true
                    }
                }

                // Name + interface
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: ethRow.modelData.connection || ethRow.modelData.iface || qsTr("Wired connection")
                        font: Tokens.font.body.medium
                        elide: Text.ElideRight
                        animate: true
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: ethRow.isConnected ? ethRow.modelData.iface : qsTr("Not connected • %1").arg(ethRow.modelData.iface)
                        color: ethRow.isConnected ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                        animate: true
                    }
                }

                Item {
                    Layout.rightMargin: Tokens.spacing.small
                    opacity: ethRow.isConnected && root?.cappedWidth > Tokens.sizes.nexus.networkShowEthDetailWidth ? 1 : 0
                    visible: opacity > 0

                    implicitWidth: ethRow.isConnected && root?.cappedWidth > Tokens.sizes.nexus.networkShowEthDetailWidth ? ethDetailRow.implicitWidth : 0
                    implicitHeight: ethDetailRow.implicitHeight

                    onVisibleChanged: {
                        if (visible) {
                            ethIpAddr.value = ethRow.details?.ipAddress ?? "";
                            ethDns.value = ethRow.details?.dns[0] ?? "";
                        }
                    }
                    Component.onCompleted: {
                        if (visible) {
                            ethIpAddr.value = ethRow.details?.ipAddress ?? "";
                            ethDns.value = ethRow.details?.dns[0] ?? "";
                        }
                    }

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }

                    RowLayout {
                        id: ethDetailRow

                        anchors.right: parent.right
                        spacing: Tokens.spacing.large

                        EthDetail {
                            id: ethIpAddr

                            label: qsTr("Local IP Address")
                        }

                        EthDetail {
                            id: ethDns

                            label: qsTr("Primary DNS")
                        }
                    }
                }

                // Connect / disconnect
                IconButton {
                    type: IconButton.Tonal
                    isToggle: true
                    isRound: true
                    checked: ethRow.isConnected
                    icon: ethRow.isConnected ? "link_off" : "link"
                    onClicked: {
                        if (ethRow.isConnected)
                            Nmcli.disconnectEthernet(ethRow.modelData.connection);
                        else
                            Nmcli.connectEthernet(ethRow.modelData.connection, ethRow.modelData.iface);
                    }
                }

                MaterialIcon {
                    text: "chevron_right"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.small
                }
            }
        }
    }

    component EthDetail: ColumnLayout {
        id: ethDetail

        required property string label
        property string value

        visible: value.length > 0
        spacing: 0

        StyledText {
            Layout.alignment: Qt.AlignRight
            text: ethDetail.label
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.small
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignRight
        }

        StyledText {
            Layout.alignment: Qt.AlignRight
            text: ethDetail.value
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignRight
        }
    }
}
