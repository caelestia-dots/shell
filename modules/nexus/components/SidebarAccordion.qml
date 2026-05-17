pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus

Item {
    id: root

    required property NexusSession session
    required property var childItems
    required property bool open

    width: parent ? parent.width + 2 : 0
    height: open ? col.implicitHeight : 0
    clip: true

    Behavior on height {
        Anim {
            type: Anim.DefaultSpatial
        }
    }

    // Vertical line indicator
    Rectangle {
        x: Tokens.padding.large + 16
        y: 0
        width: 1
        height: root.open ? col.height : 0
        color: Qt.alpha(Colours.palette.m3onSurface, 0.12)

        Behavior on height {
            Anim {
                type: Anim.DefaultSpatial
            }
        }
    }

    Column {
        id: col

        width: parent.width - (Tokens.padding.large / 2)
        topPadding: Tokens.spacing.small
        leftPadding: Tokens.padding.large
        spacing: Tokens.spacing.small

        Repeater {
            model: root.childItems

            delegate: Item {
                id: childDelegate

                required property var modelData

                readonly property bool isActive: root.session.activeCategory === childDelegate.modelData.id

                width: col.width
                height: 36

                StyledRect {
                    anchors.fill: parent
                    anchors.leftMargin: Tokens.padding.larger * 2
                    anchors.rightMargin: Tokens.padding.normal

                    radius: Tokens.rounding.full
                    color: childDelegate.isActive ? Qt.alpha(Colours.palette.m3primary, 0.16) : "transparent"

                    Behavior on color {
                        CAnim {}
                    }

                    StateLayer {
                        color: childDelegate.isActive ? Colours.palette.m3primary : Colours.palette.m3onSurface
                        onClicked: root.session.setCategory(childDelegate.modelData.id)
                    }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Tokens.padding.large
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Tokens.spacing.normal

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: childDelegate.modelData.icon
                            color: childDelegate.isActive ? Colours.palette.m3primary : Colours.palette.m3onSurface
                            font.pointSize: Tokens.font.size.normal
                            fill: childDelegate.isActive ? 1 : 0
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: childDelegate.modelData.label
                            color: childDelegate.isActive ? Colours.palette.m3primary : Colours.palette.m3onSurface
                            font.pointSize: Tokens.font.size.smaller
                            font.capitalization: Font.Capitalize
                        }
                    }
                }
            }
        }
    }
}
