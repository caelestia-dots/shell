import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

ColumnLayout {
    id: root

    required property color colour
    required property int parentSpacing

    spacing: Hypr.capsLock && Hypr.numLock ? root.parentSpacing : 0

    Behavior on spacing {
        Anim {
            type: Anim.SlowEffects
        }
    }

    Item {
        implicitWidth: capslockIcon.implicitWidth
        implicitHeight: Hypr.capsLock ? capslockIcon.implicitHeight : 0

        MaterialIcon {
            id: capslockIcon

            anchors.centerIn: parent

            scale: Hypr.capsLock ? 1 : 0.5
            opacity: Hypr.capsLock ? 1 : 0

            text: "keyboard_capslock_badge"
            color: root.colour

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on scale {
                Anim {}
            }
        }

        Behavior on implicitHeight {
            Anim {
                type: Anim.SlowEffects
            }
        }
    }

    Item {
        implicitWidth: numlockIcon.implicitWidth
        implicitHeight: Hypr.numLock ? numlockIcon.implicitHeight : 0

        MaterialIcon {
            id: numlockIcon

            anchors.centerIn: parent

            scale: Hypr.numLock ? 1 : 0.5
            opacity: Hypr.numLock ? 1 : 0

            text: "looks_one"
            color: root.colour

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on scale {
                Anim {}
            }
        }

        Behavior on implicitHeight {
            Anim {
                type: Anim.SlowEffects
            }
        }
    }
}
