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
import qs.modules.nexus.pages.battery

PageBase {
    id: root

    title: qsTr("Power")

    function toggleLowWarns(){
        GlobalConfig.general.battery.enableLowBatteryWarning = !GlobalConfig.general.battery.enableLowBatteryWarning; 
    }

    function toggleHighWarns(){
        GlobalConfig.general.battery.enableHighBatteryWarning = !GlobalConfig.general.battery.enableHighBatteryWarning; 
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        ToggleRow {
            id: lowWarnToggle

            Layout.topMargin: Tokens.spacing.large
            first: true
            text: qsTr("Low Battery Warnings")
            font: Tokens.font.body.medium
            horizontalPadding: Tokens.padding.largeIncreased
            checked: GlobalConfig.general.battery.enableLowBatteryWarning
            onToggled: toggleLowWarns()
        }

        BatteryWarningList {
            isToggled: lowWarnToggle.checked
            isLowWarning: true
            nState: root.nState
        }

        ToggleRow {
            id: highWarnToggle

            Layout.topMargin: Tokens.spacing.large
            first: true
            text: qsTr("High Battery Warnings")
            font: Tokens.font.body.medium
            horizontalPadding: Tokens.padding.largeIncreased
            checked: GlobalConfig.general.battery.enableHighBatteryWarning
            onToggled: toggleHighWarns()
        }

        BatteryWarningList {
            isToggled: highWarnToggle.checked
            isLowWarning: false
            nState: root.nState
        } 
    }
}
