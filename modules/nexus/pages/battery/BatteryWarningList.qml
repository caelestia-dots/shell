pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus
import qs.modules.nexus.common

ItemList {
    id: root

    required property bool isToggled
    required property bool isLowWarning
    required property NexusState nState
    property string text: isLowWarning ? "low battery" : "high battery"


    showList: isToggled
    placeholderIcon: isToggled ? "plug_connect" : "power_off"
    placeholderText: isToggled ? qsTr("No %1 warning found").arg(text) : qsTr("%1 warning disabled").arg(text.charAt(0).toUpperCase() + text.slice(1))

    model: ScriptModel {
        values: {
            const data = isLowWarning ? GlobalConfig.general.battery.lowBatteryWarnLevels : GlobalConfig.general.battery.chargingWarnLevels
            const values = [...data].sort((a, b) => isLowWarning ? b.level - a.level : a.level - b.level);
            console.log(values);
            return values;
        }
    }

    delegate: StateLayer {
        id: warningLayer

        required property var modelData

        anchors.left: root.list.contentItem.left
        anchors.right: root.list.contentItem.right
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
                text: warningLayer.modelData.icon
                color: warningLayer.modelData.critical ? Colours.palette.m3error : Colours.palette.m3primary 
                fontStyle: Tokens.font.icon.medium
            }

            ColumnLayout {
                Layout.fillWidth: true 
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("%1 % Battery").arg(warningLayer.modelData.level)
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                } 

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("%1 • %2").arg(warningLayer.modelData.title).arg(warningLayer.modelData.message)
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                    elide: Text.ElideRight
                }
            }

            Item {
                Layout.fillHeight: true
                implicitHeight: height

                AnimLoader {
                    anchors.centerIn: parent
                    sourceComp: btnComp

                    Component {
                        id: btnComp
                        IconButton {
                            icon: "settings"
                            type: IconButton.Text
                            padding: Tokens.padding.small
                            inactiveOnColour: Colours.palette.m3onSurfaceVariant
                            label.fill: 0

                            onClicked: {
                                root.nState.selectedBatteryLevel = warningLayer.modelData;
                                root.nState.openSubPage(1);
                            }
                        }
                    }
                }
                
            }
        }
    }

}