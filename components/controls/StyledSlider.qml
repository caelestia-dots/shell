import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Templates

Slider {
    id: root

    enum SliderType {
        Default = 0,
        Error = 1
    }
    property int type: StyledSlider.SliderType.Default

    function getBarColour() {
        if (type === StyledSlider.SliderType.Default) return Colours.palette.m3primary;
        if (type === StyledSlider.SliderType.Error) return Colours.palette.m3error;
    }
    function getHandleColour() {
        if (type === StyledSlider.SliderType.Default) return Colours.palette.m3surfaceContainer;
        if (type === StyledSlider.SliderType.Error) return Colours.palette.m3errorContainer;
    }

    background: Item {
        StyledRect {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.topMargin: root.implicitHeight / 3
            anchors.bottomMargin: root.implicitHeight / 3

            implicitWidth: root.handle.x - root.implicitHeight / 6

            color: root.getBarColour()
            radius: Appearance.rounding.full
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

            color: root.getHandleColour()
            radius: Appearance.rounding.full
            topLeftRadius: root.implicitHeight / 15
            bottomLeftRadius: root.implicitHeight / 15
        }
    }

    handle: StyledRect {
        x: root.visualPosition * root.availableWidth - implicitWidth / 2

        implicitWidth: root.implicitHeight / 4.5
        implicitHeight: root.implicitHeight

        color: root.getBarColour()
        radius: Appearance.rounding.full

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            cursorShape: Qt.PointingHandCursor
        }
    }
}
