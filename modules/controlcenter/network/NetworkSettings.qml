pragma ComponentBehavior: Bound

import ".."
import "../components"
import qs.components
import qs.components.controls
import qs.components.containers
import qs.components.effects
import qs.services
import qs.config
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property Session session

    spacing: Appearance.spacing.normal

    SettingsHeader {
        icon: "router"
        title: qsTr("Network Settings")
    }

    SectionHeader {
        Layout.topMargin: Appearance.spacing.large
        title: qsTr("Ethernet")
        description: qsTr("Ethernet device information")
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.small / 2

        PropertyRow {
            label: qsTr("Total devices")
            value: qsTr("%1").arg(Nmcli.ethernetDevices.length)
        }

        PropertyRow {
            showTopMargin: true
            label: qsTr("Connected devices")
            value: qsTr("%1").arg(Nmcli.ethernetDevices.filter(d => d.connected).length)
        }
    }

    SectionHeader {
        Layout.topMargin: Appearance.spacing.large
        title: qsTr("Wireless")
        description: qsTr("WiFi network settings")
    }

    SectionContainer {
        ToggleRow {
            label: qsTr("WiFi enabled")
            checked: Nmcli.wifiEnabled
            toggle.onToggled: {
                Nmcli.enableWifi(checked);
            }
        }
    }

    SectionHeader {
        Layout.topMargin: Appearance.spacing.large
        title: qsTr("VPN")
        description: qsTr("VPN provider settings")
        visible: Config.utilities.vpn.enabled || Config.utilities.vpn.provider.length > 0
    }

    SectionContainer {
        visible: Config.utilities.vpn.enabled || Config.utilities.vpn.provider.length > 0

        ToggleRow {
            label: qsTr("VPN enabled")
            checked: Config.utilities.vpn.enabled
            toggle.onToggled: {
                Config.utilities.vpn.enabled = checked;
                Config.save();
            }
        }

        PropertyRow {
            showTopMargin: true
            label: qsTr("Providers")
            value: qsTr("%1").arg(Config.utilities.vpn.provider.length)
        }

        TextButton {
            Layout.fillWidth: true
            Layout.topMargin: Appearance.spacing.normal
            Layout.minimumHeight: Appearance.font.size.normal + Appearance.padding.normal * 2
            text: qsTr("⚙ Manage VPN Providers")
            inactiveColour: Colours.palette.m3secondaryContainer
            inactiveOnColour: Colours.palette.m3onSecondaryContainer

            onClicked: {
                vpnSettingsDialog.open();
            }
        }
    }

    SectionHeader {
        Layout.topMargin: Appearance.spacing.large
        title: qsTr("Current connection")
        description: qsTr("Active network connection information")
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.small / 2

        PropertyRow {
            label: qsTr("Network")
            value: Nmcli.active ? Nmcli.active.ssid : (Nmcli.activeEthernet ? Nmcli.activeEthernet.interface : qsTr("Not connected"))
        }

        PropertyRow {
            showTopMargin: true
            visible: Nmcli.active !== null
            label: qsTr("Signal strength")
            value: Nmcli.active ? qsTr("%1%").arg(Nmcli.active.strength) : qsTr("N/A")
        }

        PropertyRow {
            showTopMargin: true
            visible: Nmcli.active !== null
            label: qsTr("Security")
            value: Nmcli.active ? (Nmcli.active.isSecure ? qsTr("Secured") : qsTr("Open")) : qsTr("N/A")
        }

        PropertyRow {
            showTopMargin: true
            visible: Nmcli.active !== null
            label: qsTr("Frequency")
            value: Nmcli.active ? qsTr("%1 MHz").arg(Nmcli.active.frequency) : qsTr("N/A")
        }
    }

    Popup {
        id: vpnSettingsDialog

        parent: Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(600, parent.width - Appearance.padding.large * 2)
        height: Math.min(700, parent.height - Appearance.padding.large * 2)

        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: StyledRect {
            color: Colours.palette.m3surface
            radius: Appearance.rounding.large
        }

        StyledFlickable {
            anchors.fill: parent
            anchors.margins: Appearance.padding.large * 1.5
            flickableDirection: Flickable.VerticalFlick
            contentHeight: vpnSettingsContent.height
            clip: true

            VpnSettings {
                id: vpnSettingsContent

                anchors.left: parent.left
                anchors.right: parent.right
                session: root.session
            }
        }
    }
}
