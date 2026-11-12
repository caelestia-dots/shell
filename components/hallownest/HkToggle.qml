import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Rectangle {
    id: root

    property string icon
    property bool checked
    property bool isToggle: true
    property color accent: Hallownest.soul
    readonly property bool lit: isToggle && checked

    signal clicked

    implicitWidth: 48
    implicitHeight: 44
    radius: 14
    color: lit ? Qt.alpha(accent, area.containsMouse ? 0.2 : 0.14) : area.containsMouse ? Hallownest.raise(Hallownest.button, 1.6) : Hallownest.button
    border.width: 1
    border.color: lit ? Qt.alpha(accent, 0.55) : Hallownest.border
    opacity: enabled ? 1 : 0.4
    scale: area.pressed ? 0.94 : 1

    Behavior on color {
        CAnim {}
    }

    Behavior on scale {
        Anim {
            type: Anim.FastSpatial
        }
    }

    MaterialIcon {
        anchors.centerIn: parent
        text: root.icon
        color: root.lit ? root.accent : Hallownest.subtext
        fill: root.lit ? 1 : 0
        fontStyle: Tokens.font.icon.medium

        Behavior on fill {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        width: 4
        height: 4
        rotation: 45
        color: root.accent
        opacity: root.lit ? 1 : 0

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
