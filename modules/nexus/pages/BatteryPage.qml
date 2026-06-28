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

        ConnectedRect {
            Layout.fillWidth: true
            implicitHeight: addLayout.implicitHeight + addLayout.anchors.margins * 2
            last: true

            StateLayer {
                // This is for the add new level.
                onClicked: root.nState.openSubPage(2)
            }                       

            RowLayout {
                id: addLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium
                opacity: lowWarnToggle.checked ? 1 : 0.5

                Behavior on opacity {
                    Anim {}
                }

                MaterialIcon {
                    text: "add"
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Add new warning")
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }
            } 
        }

        ToggleRow {
            id: highWarnToggle

            Layout.topMargin: Tokens.spacing.large
            first: true
            text: qsTr("Overcharge Battery Warnings")
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
