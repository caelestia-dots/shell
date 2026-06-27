pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.utils
import qs.modules.nexus.common

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

        ItemList {
            id: lowWarnList

            showList: lowWarnToggle.checked
            placeholderIcon: lowWarnToggle.checked ? "plug_connect" : "power_off"
            placeholderText: lowWarnToggle.checked ? qsTr("No low battery warning found") : qsTr("Low battery warning disabled")

            model: ScriptModel {
                values: {
                    const values = [...GlobalConfig.general.battery.lowBatteryWarnLevels].sort((a, b) => b.level - a.level);
                    console.log(values);
                    return values;
                }
            }

            delegate: StateLayer {
                id: lowWarning

                required property var modelData

                anchors.left: lowWarnList.list.contentItem.left
                anchors.right: lowWarnList.list.contentItem.right
                implicitHeight: lowWarnLayout.implicitHeight + lowWarnLayout.anchors.margins * 2
                radius: Tokens.rounding.extraSmall
                anchors.fill: undefined


                RowLayout {
                    id: lowWarnLayout

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.large
                    anchors.leftMargin: Tokens.padding.extraLarge
                    anchors.rightMargin: Tokens.padding.extraLarge
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        text: lowWarning.modelData.icon
                        color: lowWarning.modelData.critical ? Colours.palette.m3error : Colours.palette.m3primary 
                        fontStyle: Tokens.font.icon.medium
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("%1 % Battery").arg(lowWarning.modelData.level)
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        } 

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("%1 • %2").arg(lowWarning.modelData.title).arg(lowWarning.modelData.message)
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                        }
                    }
                }
            }

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

        ItemList {
            id: highWarnList

            showList: highWarnToggle.checked
            placeholderIcon: highWarnToggle.checked ? "plug_connect" : "power_off"
            placeholderText: highWarnToggle.checked ? qsTr("No high battery warning found") : qsTr("High battery warning disabled")
        }
    }
}
