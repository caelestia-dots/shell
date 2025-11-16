pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property Session session

    spacing: Appearance.spacing.normal

    MaterialIcon {
        Layout.alignment: Qt.AlignHCenter
        text: "router"
        font.pointSize: Appearance.font.size.extraLarge * 3
        font.bold: true
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: qsTr("Network Settings")
        font.pointSize: Appearance.font.size.large
        font.bold: true
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
}

