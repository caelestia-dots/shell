pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property var groups
    property string current

    readonly property int currentIndex: groups.findIndex(g => g.id === current)
    readonly property real tabWidth: groups.length > 0 ? width / groups.length : 0

    signal selected(string id)

    implicitHeight: Tokens.sizes.launcher.itemHeight * 0.8

    Row {
        Repeater {
            model: root.groups

            Item {
                id: tab

                required property var modelData
                required property int index

                readonly property bool active: index === root.currentIndex

                implicitWidth: root.tabWidth
                implicitHeight: root.height

                StateLayer {
                    radius: Tokens.rounding.large
                    onClicked: root.selected(tab.modelData.id)
                }

                MaterialIcon {
                    anchors.centerIn: parent

                    text: tab.modelData.icon
                    fill: tab.active ? 1 : 0
                    fontStyle: Tokens.font.icon.large
                    color: tab.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                }
            }
        }
    }

    StyledRect {
        anchors.bottom: parent.bottom

        visible: root.currentIndex >= 0
        implicitWidth: Math.min(root.tabWidth * 0.5, 32)
        implicitHeight: 3
        radius: Tokens.rounding.full
        color: Colours.palette.m3primary
        x: root.currentIndex * root.tabWidth + (root.tabWidth - implicitWidth) / 2

        Behavior on x {
            Anim {}
        }
    }
}
