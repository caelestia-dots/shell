pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Status icons")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Visible icons
        SectionHeader {
            first: true
            text: qsTr("Visible icons")
        }

        ToggleRow {
            first: true
            settingAnchor: "bar-si-speakers"
            text: qsTr("Speakers")
            checked: Config.bar.status.showAudio
            onToggled: GlobalConfig.bar.status.showAudio = checked
        }

        ToggleRow {
            settingAnchor: "bar-si-microphone"
            text: qsTr("Microphone")
            checked: Config.bar.status.showMicrophone
            onToggled: GlobalConfig.bar.status.showMicrophone = checked
        }

        ToggleRow {
            settingAnchor: "bar-si-keyboard-layout"
            text: qsTr("Keyboard layout")
            checked: Config.bar.status.showKbLayout
            onToggled: GlobalConfig.bar.status.showKbLayout = checked
        }

        ToggleRow {
            settingAnchor: "bar-si-network"
            text: qsTr("Network")
            checked: Config.bar.status.showNetwork
            onToggled: GlobalConfig.bar.status.showNetwork = checked
        }

        ToggleRow {
            settingAnchor: "bar-si-wi-fi"
            text: qsTr("Wi-Fi")
            checked: Config.bar.status.showWifi
            onToggled: GlobalConfig.bar.status.showWifi = checked
        }

        ToggleRow {
            settingAnchor: "bar-si-bluetooth"
            text: qsTr("Bluetooth")
            checked: Config.bar.status.showBluetooth
            onToggled: GlobalConfig.bar.status.showBluetooth = checked
        }

        ToggleRow {
            settingAnchor: "bar-si-battery"
            text: qsTr("Battery")
            checked: Config.bar.status.showBattery
            onToggled: GlobalConfig.bar.status.showBattery = checked
        }

        ToggleRow {
            last: true
            settingAnchor: "bar-si-caps-lock"
            text: qsTr("Caps lock")
            checked: Config.bar.status.showLockStatus
            onToggled: GlobalConfig.bar.status.showLockStatus = checked
        }

        // Behaviour
        SectionHeader {
            text: qsTr("Behaviour")
        }

        ToggleRow {
            first: true
            last: true
            settingAnchor: "bar-si-popout-on-hover"
            text: qsTr("Popout on hover")
            subtext: qsTr("Show a details popout when hovering the status icons")
            checked: Config.bar.popouts.statusIcons
            onToggled: GlobalConfig.bar.popouts.statusIcons = checked
        }
    }
}
