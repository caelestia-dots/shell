import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Templates

Slider {
    id: root

    wheelEnabled: true

    background: Item {
        readonly property real normalRangeEnd: root.availableWidth * (1.0 / root.to)
        readonly property real trackMargin: root.implicitHeight / 3
        readonly property real handleOffset: root.implicitHeight / 6
        
        // Normal range filled (0-100%)
        StyledRect {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.topMargin: parent.trackMargin
            anchors.bottomMargin: parent.trackMargin

            implicitWidth: Math.min(root.handle.x - parent.handleOffset, parent.normalRangeEnd)

            color: Colours.palette.m3primary
            radius: Appearance.rounding.full
            topRightRadius: root.value > 1.0 ? 0 : Appearance.rounding.full
            bottomRightRadius: root.value > 1.0 ? 0 : Appearance.rounding.full
        }

        // Boost range filled (100-150%) - different color
        StyledRect {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.leftMargin: parent.normalRangeEnd
            anchors.topMargin: parent.trackMargin
            anchors.bottomMargin: parent.trackMargin

            visible: root.value > 1.0
            implicitWidth: root.handle.x - parent.handleOffset - parent.normalRangeEnd

            color: Colours.palette.m3tertiary
            radius: Appearance.rounding.full
            topLeftRadius: 0
            bottomLeftRadius: 0
        }

        // Unfilled track
        StyledRect {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.topMargin: parent.trackMargin
            anchors.bottomMargin: parent.trackMargin

            implicitWidth: parent.width - root.handle.x - root.handle.implicitWidth - parent.handleOffset

            color: Colours.palette.m3surfaceContainerHighest
            radius: Appearance.rounding.full
            topLeftRadius: root.implicitHeight / 15
            bottomLeftRadius: root.implicitHeight / 15
        }
    }

    handle: StyledRect {
        x: root.visualPosition * root.availableWidth - implicitWidth / 2

        implicitWidth: root.implicitHeight / 4.5
        implicitHeight: root.implicitHeight

        color: root.value > 1.0 ? Colours.palette.m3tertiary : Colours.palette.m3primary
        radius: Appearance.rounding.full

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            cursorShape: Qt.PointingHandCursor
        }
    }

    Behavior on value {
        Anim {
            duration: Appearance.anim.durations.large
        }
    }
}
