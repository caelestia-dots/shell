pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property int current
    required property var notches
    readonly property bool expanded: hover.hovered

    signal selected(index: int)
    signal stepped(delta: int)

    implicitWidth: row.implicitWidth
    implicitHeight: 26

    HoverHandler {
        id: hover
    }

    Row {
        id: row

        anchors.centerIn: parent
        spacing: root.expanded ? 3 : 6

        Behavior on spacing {
            Anim {
                type: Anim.FastSpatial
            }
        }

        Arrow {
            icon: "chevron_left"
            onClicked: root.stepped(-1)
        }

        Repeater {
            model: root.notches

            Item {
                id: slot

                required property var modelData
                required property int index
                readonly property bool active: index === root.current

                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: root.expanded ? 26 : 11
                implicitHeight: root.expanded ? 26 : 14

                Behavior on implicitWidth {
                    Anim {
                        type: Anim.FastSpatial
                    }
                }

                Behavior on implicitHeight {
                    Anim {
                        type: Anim.FastSpatial
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: slot.active ? 8 : 6
                    height: width
                    rotation: slot.active ? 135 : 45
                    color: slot.active ? Hallownest.soul : "transparent"
                    border.width: 1
                    border.color: slot.active ? Hallownest.soul : Qt.alpha(Hallownest.steel, 0.5)
                    opacity: root.expanded ? 0 : 1
                    layer.enabled: slot.active
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Hallownest.soul
                        shadowBlur: 0.8
                        shadowHorizontalOffset: 0
                        shadowVerticalOffset: 0
                        blurMax: 12
                    }

                    Behavior on width {
                        Anim {
                            type: Anim.FastSpatial
                        }
                    }

                    Behavior on rotation {
                        Anim {
                            type: Anim.FastSpatial
                        }
                    }

                    Behavior on opacity {
                        Anim {
                            type: Anim.FastEffects
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: slot.active ? Qt.alpha(Hallownest.soul, 0.12) : "transparent"
                    border.width: 1
                    border.color: slot.active ? Qt.alpha(Hallownest.soul, 0.45) : Hallownest.border
                    opacity: root.expanded ? 1 : 0

                    Behavior on opacity {
                        Anim {
                            type: Anim.FastEffects
                        }
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: slot.modelData.icon
                        color: slot.active ? Hallownest.soul : Hallownest.subtext
                        fontStyle: Tokens.font.icon.small
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selected(slot.index)
                }
            }
        }

        Arrow {
            icon: "chevron_right"
            onClicked: root.stepped(1)
        }
    }

    component Arrow: Rectangle {
        id: arrow

        required property string icon

        signal clicked

        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: 20
        implicitHeight: 20
        radius: 10
        color: area.containsMouse ? Hallownest.raise(Hallownest.button, 1.6) : Hallownest.button
        border.width: 1
        border.color: Hallownest.border

        Behavior on color {
            CAnim {}
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: arrow.icon
            color: Hallownest.soul
            fontStyle: Tokens.font.icon.small
        }

        MouseArea {
            id: area

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: arrow.clicked()
        }
    }
}
