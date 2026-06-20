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

    // Load ethernet details (IP/DNS/gateway) and data usage when shown.
    onVisibleChanged: if (visible) {
        if (Nmcli.activeEthernet) {
            Nmcli.getEthernetDeviceDetails("", () => {});
            Nmcli.getEthernetDataUsage(Nmcli.activeEthernet.interface, () => {});
            Nmcli.getEthernetSpeed(Nmcli.activeEthernet.interface);
        }
    }

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

        // Keep ethernet state fresh while the page is visible.
        Timer {
            running: root.visible
            repeat: true
            triggeredOnStart: true
            interval: 5000
            onTriggered: {
                Nmcli.getEthernetInterfaces(() => {});
                if (Nmcli.activeEthernet) {
                    Nmcli.getEthernetDeviceDetails(Nmcli.activeEthernet.interface, () => {});
                    Nmcli.getEthernetDataUsage(Nmcli.activeEthernet.interface, () => {});
                    Nmcli.getEthernetSpeed(Nmcli.activeEthernet.interface);
                }
            }
        }

        Connections {
            function onWifiEnabledChanged(): void {
                if (Nmcli.wifiEnabled)
                    wifiScanDelay.start();
            }

            target: Nmcli
        }

        // ---- Ethernet --------------------------------------------------------
        // A grouped block (no toggle — ethernet isn't switched): a header row
        // carrying the "Ethernet" label, then one row per wired device.
        ConnectedRect {
            Layout.fillWidth: true
            visible: Nmcli.ethernetDevices.length > 0
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
            model: Nmcli.ethernetDevices

            delegate: ConnectedRect {
                id: ethRow

                required property var modelData
                required property int index

                readonly property bool isConnected: modelData.connected
                // IP/MAC/DNS come from the parsed device details, not the basic
                // device list (which leaves those fields blank).
                readonly property var details: ethRow.isConnected ? Nmcli.ethernetDeviceDetails : null

                Layout.fillWidth: true
                last: index === Nmcli.ethernetDevices.length - 1
                visible: Nmcli.ethernetDevices.length > 0
                implicitHeight: ethLayout.implicitHeight + Tokens.padding.medium * 2

                // Tap opens the detail page for this interface.
                StateLayer {
                    onClicked: {
                        root.nState.selectedEthernetInterface = ethRow.modelData.interface;
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
                            fill: ethRow.isConnected ? 1 : 0
                            color: ethRow.isConnected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.medium
                        }
                    }

                    // Name + interface.
                    ColumnLayout {
                        Layout.minimumWidth: Math.round(root.cappedWidth * 0.28)
                        Layout.maximumWidth: Math.round(root.cappedWidth * 0.34)
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: ethRow.modelData.connection || ethRow.modelData.interface || qsTr("Wired connection")
                            font: Tokens.font.body.medium
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: ethRow.isConnected ? ethRow.modelData.interface : qsTr("Not connected • %1").arg(ethRow.modelData.interface)
                            color: ethRow.isConnected ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                        }
                    }

                    // Horizontal IP / DNS (when connected, wide screens),
                    // right-aligned. Static columns (no Repeater/model) so values
                    // update in place instead of rebuilding and flickering.
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.rightMargin: Tokens.spacing.small
                        visible: ethRow.isConnected && root.cappedWidth > 620
                        spacing: Tokens.spacing.large

                        Item {
                            Layout.fillWidth: true
                        }

                        EthDetail {
                            label: qsTr("Local IP Address")
                            value: ethRow.details?.ipAddress ?? ""
                        }

                        EthDetail {
                            label: qsTr("Primary DNS")
                            value: (ethRow.details?.dns ?? []).length > 0 ? ethRow.details.dns[0] : ""
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        visible: !ethRow.isConnected || root.cappedWidth <= 620
                    }

                    // Connect / disconnect.
                    IconButton {
                        type: IconButton.Tonal
                        isToggle: true
                        checked: ethRow.isConnected
                        icon: ethRow.isConnected ? "link_off" : "link"
                        onClicked: {
                            if (ethRow.isConnected)
                                Nmcli.disconnectEthernet(ethRow.modelData.connection);
                            else
                                Nmcli.connectEthernet(ethRow.modelData.connection, ethRow.modelData.interface);
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

        ToggleRow {
            Layout.topMargin: Nmcli.ethernetDevices.length > 0 ? Tokens.spacing.large : 0
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
    }

    component EthDetail: ColumnLayout {
        id: ethDetail

        required property string label
        required property string value

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
