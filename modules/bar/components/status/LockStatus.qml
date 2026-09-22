pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.services

Item {
    id: root

    required property color colour
    required property int parentSpacing
    required property bool isHorizontal

    property real gap: Hypr.capsLock && Hypr.numLock ? parentSpacing : 0
 
    property real capsLength: Hypr.capsLock ? (isHorizontal ? capslockIcon.implicitWidth : capslockIcon.implicitHeight) : 0
    property real numLength: Hypr.numLock ? (isHorizontal ? numlockIcon.implicitWidth : numlockIcon.implicitHeight) : 0

Behavior on gap {
        Anim {
            type: Anim.SlowEffects
        }
    }

    Behavior on capsLength {
        Anim {
            type: Anim.SlowEffects
        }
    }

    Behavior on numLength {
        Anim {
            type: Anim.SlowEffects
        }
    }

    implicitWidth: isHorizontal ? capsLength + numLength + (capsLength > 0 && numLength > 0 ? gap : 0) : Math.max(capsLength, numLength)
    implicitHeight: !isHorizontal ? capsLength + numLength + (capsLength > 0 && numLength > 0 ? gap : 0) : Math.max(capsLength, numLength)

    Item {
        x: root.isHorizontal ? 0 : (root.implicitWidth - width) / 2
        y: root.isHorizontal ? (root.implicitHeight - height) / 2 : 0

        width: root.isHorizontal ? root.capsLength : capslockIcon.implicitWidth
        height: !root.isHorizontal ? root.capsLength : capslockIcon.implicitHeight

        clip: true

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
        x: root.isHorizontal ? root.capsLength + root.gap : (root.implicitWidth - width) / 2
        y: !root.isHorizontal ? root.capsLength + root.gap : (root.implicitHeight - height) / 2

        width: root.isHorizontal ? root.numLength : numlockIcon.implicitWidth
        height: !root.isHorizontal ? root.numLength : numlockIcon.implicitHeight

        clip: true

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
