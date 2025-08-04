import qs.components
import qs.config
import qs.services
import QtQuick.Controls
import QtQuick

Slider {
    id: slider

    background: Item {
        StyledRect {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.topMargin: slider.implicitHeight / 3
            anchors.bottomMargin: slider.implicitHeight / 3

            implicitWidth: slider.handle.x - slider.implicitHeight / 6

            color: Colours.palette.m3primary
            radius: Appearance.rounding.full
            topRightRadius: slider.implicitHeight / 15
            bottomRightRadius: slider.implicitHeight / 15
        }

        StyledRect {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.topMargin: slider.implicitHeight / 3
            anchors.bottomMargin: slider.implicitHeight / 3

            implicitWidth: parent.width - slider.handle.x - slider.handle.implicitWidth - slider.implicitHeight / 6

            color: Colours.palette.m3surfaceContainer
            radius: Appearance.rounding.full
            topLeftRadius: slider.implicitHeight / 15
            bottomLeftRadius: slider.implicitHeight / 15
        }
    }

    handle: StyledRect {
        id: rect

        x: slider.visualPosition * slider.availableWidth

        implicitWidth: slider.implicitHeight / 4.5
        implicitHeight: slider.implicitHeight

        color: Colours.palette.m3primary
        radius: Appearance.rounding.full

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onPressed: event => event.accepted = false
        }
    }
}
