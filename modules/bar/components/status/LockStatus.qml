import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

GridLayout {
    id: root

    required property color colour
    required property int parentSpacing
    property bool isHorizontal: false

    property real gap: Hypr.capsLock && Hypr.numLock ? parentSpacing : 0
    property real capsSize: Hypr.capsLock ? (isHorizontal ? capslockIcon.implicitWidth : capslockIcon.implicitHeight) : 0
    property real numSize: Hypr.numLock ? (isHorizontal ? numlockIcon.implicitWidth : numlockIcon.implicitHeight) : 0

    rows: isHorizontal ? 1 : -1
    columns: isHorizontal ? -1 : 1
    rowSpacing: isHorizontal ? 0 : Math.round(gap)
    columnSpacing: isHorizontal ? Math.round(gap) : 0

    Behavior on gap {
        Anim {
            type: Anim.SlowEffects
        }
    }

    Behavior on capsSize {
        Anim {
            type: Anim.SlowEffects
        }
    }

    Behavior on numSize {
        Anim {
            type: Anim.SlowEffects
        }
    }

    Item {
        implicitWidth: root.isHorizontal ? Math.round(root.capsSize) : capslockIcon.implicitWidth
        implicitHeight: root.isHorizontal ? capslockIcon.implicitHeight : Math.round(root.capsSize)

        MaterialIcon {
            id: capslockIcon

            anchors.centerIn: parent

            scale: Hypr.capsLock ? 1 : 0.5
            opacity: Hypr.capsLock ? 1 : 0

            text: "keyboard_capslock_badge"
            color: root.colour
            fill: 1
            grade: 25

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on scale {
                Anim {}
            }
        }
    }

    Item {
        implicitWidth: root.isHorizontal ? Math.round(root.numSize) : numlockIcon.implicitWidth
        implicitHeight: root.isHorizontal ? numlockIcon.implicitHeight : Math.round(root.numSize)

        MaterialIcon {
            id: numlockIcon

            anchors.centerIn: parent

            scale: Hypr.numLock ? 1 : 0.5
            opacity: Hypr.numLock ? 1 : 0

            text: "looks_one"
            color: root.colour
            fill: 1
            grade: 25

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on scale {
                Anim {}
            }
        }
    }
}
