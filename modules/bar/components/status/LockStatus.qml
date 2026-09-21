import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

GridLayout {
    id: root

    required property color colour
    required property int parentSpacing
    required property bool horizontal

    property real gap: Hypr.capsLock && Hypr.numLock ? parentSpacing : 0
    property real capsWidth: Hypr.capsLock ? capslockIcon.implicitWidth : 0
    property real numWidth: Hypr.numLock ? numlockIcon.implicitWidth : 0
    property real capsHeight: Hypr.capsLock ? capslockIcon.implicitHeight : 0
    property real numHeight: Hypr.numLock ? numlockIcon.implicitHeight : 0

    columns: root.horizontal ? -1 : 1
    rowSpacing: Math.round(root.horizontal ? 0 : root.gap)
    columnSpacing: Math.round(root.horizontal ? root.gap : 0)

    Behavior on gap {
        Anim {
            type: Anim.SlowEffects
        }
    }

    Behavior on capsWidth {
        Anim {
            type: Anim.SlowEffects
        }
    }

    Behavior on numWidth {
        Anim {
            type: Anim.SlowEffects
        }
    }

    Behavior on capsHeight {
        Anim {
            type: Anim.SlowEffects
        }
    }

    Behavior on numHeight {
        Anim {
            type: Anim.SlowEffects
        }
    }

    Item {
        implicitWidth: root.horizontal ? Math.round(root.capsWidth) : capslockIcon.implicitWidth
        implicitHeight: root.horizontal ? capslockIcon.implicitHeight : Math.round(root.capsHeight)

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
        implicitWidth: root.horizontal ? Math.round(root.numWidth) : numlockIcon.implicitWidth
        implicitHeight: root.horizontal ? numlockIcon.implicitHeight : Math.round(root.numHeight)

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
