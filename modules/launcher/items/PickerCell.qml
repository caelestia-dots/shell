import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property var modelData
    required property int index

    property int start
    property int currentIndex
    property real cellWidth
    property real cellHeight
    property bool wide

    readonly property int flatIndex: start + index
    readonly property bool current: flatIndex === currentIndex

    signal activated

    implicitWidth: cellWidth
    implicitHeight: cellHeight

    StyledRect {
        anchors.fill: parent
        anchors.margins: Tokens.spacing.extraSmall / 2

        radius: Tokens.rounding.medium
        color: Colours.palette.m3onSurface
        opacity: root.current ? 0.12 : 0

        Behavior on opacity {
            Anim {
                type: Anim.FastEffects
            }
        }
    }

    StateLayer {
        radius: Tokens.rounding.medium
        onClicked: root.activated()
    }

    // Plain Text rather than StyledText so the size can be set without fighting the default font binding
    Text {
        anchors.centerIn: parent

        // Wide text shrinks to fit the cell instead of overflowing
        width: root.wide ? parent.width - Tokens.padding.small * 2 : implicitWidth
        height: root.wide ? parent.height : implicitHeight
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        text: root.modelData.c
        color: Colours.palette.m3onSurface
        renderType: Text.QtRendering
        elide: root.wide ? Text.ElideRight : Text.ElideNone
        fontSizeMode: root.wide ? Text.Fit : Text.FixedSize
        minimumPixelSize: 10
        font.pixelSize: root.wide ? 18 : Math.round(root.cellWidth * 0.56)
    }
}
