pragma ComponentBehavior: Bound

import ".."
import "../components"
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

    SettingsHeader {
        icon: "wifi"
        title: qsTr("Network settings")
    }

    SectionHeader {
        Layout.topMargin: Appearance.spacing.large
        title: qsTr("WiFi status")
        description: qsTr("General WiFi settings")
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
        title: qsTr("Network information")
        description: qsTr("Current network connection")
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.small / 2

        PropertyRow {
            label: qsTr("Connected network")
            value: Nmcli.active ? Nmcli.active.ssid : qsTr("Not connected")
        }

        PropertyRow {
            showTopMargin: true
            label: qsTr("Signal strength")
            value: Nmcli.active ? qsTr("%1%").arg(Nmcli.active.strength) : qsTr("N/A")
        }

        PropertyRow {
            showTopMargin: true
            label: qsTr("Security")
            value: Nmcli.active ? (Nmcli.active.isSecure ? qsTr("Secured") : qsTr("Open")) : qsTr("N/A")
        }

        PropertyRow {
            showTopMargin: true
            label: qsTr("Frequency")
            value: Nmcli.active ? qsTr("%1 MHz").arg(Nmcli.active.frequency) : qsTr("N/A")
        }
    }
}