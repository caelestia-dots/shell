import QtQuick
import QtQuick.Templates
import Caelestia.Config
import qs.components
import qs.services

Slider {
    id: root

    background: Item {
        StyledRect {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.topMargin: root.implicitHeight / 3
            anchors.bottomMargin: root.implicitHeight / 3

            implicitWidth: root.handle.x - root.implicitHeight / 6

            color: Colours.palette.m3primary
            radius: Tokens.rounding.full
            topRightRadius: root.implicitHeight / 15
            bottomRightRadius: root.implicitHeight / 15
        }

        StyledRect {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.topMargin: root.implicitHeight / 3
            anchors.bottomMargin: root.implicitHeight / 3

            implicitWidth: parent.width - root.handle.x - root.handle.implicitWidth - root.implicitHeight / 6

            color: Colours.palette.m3surfaceContainerHighest
            radius: Tokens.rounding.full
            topLeftRadius: root.implicitHeight / 15
            bottomLeftRadius: root.implicitHeight / 15
        }
    }

    handle: StyledRect {
        x: root.visualPosition * root.availableWidth - implicitWidth / 2

        implicitWidth: root.implicitHeight / 4.5
        implicitHeight: root.implicitHeight

        color: Colours.palette.m3primary
        radius: Tokens.rounding.full

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            cursorShape: Qt.PointingHandCursor
        }
    }
}
