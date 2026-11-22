import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Rectangle {
    id: root

    property string icon
    property string text
    property color accent: Hallownest.soul
    property bool filled
    property bool tinted
    property bool disabled
    property bool iconAfter

    signal clicked

    implicitWidth: text ? content.implicitWidth + 24 : implicitHeight
    implicitHeight: 30
    radius: text ? 9 : height / 2
    color: {
        if (filled)
            return accent;
        if (tinted)
            return Qt.alpha(accent, area.containsMouse ? 0.24 : 0.16);
        return area.containsMouse ? Hallownest.raise(Hallownest.button, 1.7) : Hallownest.button;
    }
    border.width: filled ? 0 : 1
    border.color: tinted ? Qt.alpha(accent, 0.35) : Hallownest.border
    opacity: disabled ? 0.4 : 1
    scale: area.pressed ? 0.94 : 1

    Behavior on color {
        CAnim {}
    }

    Behavior on scale {
        Anim {
            type: Anim.FastSpatial
        }
    }

    // Subtle top rim highlight on raised buttons
    Rectangle {
        visible: !root.filled
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Math.min(root.radius, root.width / 3)
        anchors.rightMargin: Math.min(root.radius, root.width / 3)
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal

            GradientStop {
                position: 0
                color: "transparent"
            }
            GradientStop {
                position: 0.5
                color: Qt.alpha(root.tinted ? root.accent : Hallownest.soul, Hallownest.light ? 0.16 : 0.11)
            }
            GradientStop {
                position: 1
                color: "transparent"
            }
        }
    }

    Row {
        id: content

        anchors.centerIn: parent
        spacing: Tokens.spacing.extraSmall
        layoutDirection: root.iconAfter ? Qt.RightToLeft : Qt.LeftToRight

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.icon !== ""
            text: root.icon
            color: root.filled ? Hallownest.void_ : root.accent
            fontStyle: Tokens.font.icon.small
            fill: root.filled ? 1 : 0
            animate: true
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.text !== ""
            text: root.text
            color: root.filled ? Hallownest.void_ : root.tinted ? root.accent : Hallownest.text
            font.pointSize: 9
            font.weight: Font.DemiBold
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        enabled: !root.disabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
