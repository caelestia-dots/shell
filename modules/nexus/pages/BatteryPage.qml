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
                implicitHeight: lowWarnList.implicitHeight + lowWarnList.anchors.margins * 2
                radius: Tokens.rounding.extraSmall
                anchors.fill: undefined

                RowLayout {
                    id: lowLayout

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.large
                    anchors.leftMargin: Tokens.padding.extraLarge
                    anchors.rightMargin: Tokens.padding.extraLarge
                    spacing: Tokens.spacing.medium

                    // MaterialIcon {
                    //     text: lowWarning.modelData.icon
                    //     color: network.modelData.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    //     fontStyle: Tokens.font.icon.medium
                    //     // opacity: network.textOpacity
                    // }

                    // ColumnLayout {
                    //     Layout.fillWidth: true
                    //     spacing: 0
                    //     // opacity: network.textOpacity

                    //     StyledText {
                    //         Layout.fillWidth: true
                    //         text: qsTr("%1\%").arg(lowWarning.modelData.level)
                    //         font: Tokens.font.body.small
                    //         elide: Text.ElideRight
                    //     }

                    //     StyledText {
                    //         Layout.fillWidth: true
                    //         text: qsTr("")
                    //         // text: qsTr("Security: %1%2").arg(network.modelData.security).arg(network.modelData.active ? qsTr(" • Connected") : Nmcli.hasSavedProfile(network.modelData.ssid) ? qsTr(" • Saved") : "")
                    //         color: Colours.palette.m3outline
                    //         font: Tokens.font.label.small
                    //         elide: Text.ElideRight
                    //     }
                    // }
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