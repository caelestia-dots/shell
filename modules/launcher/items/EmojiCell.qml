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
    property real size

    readonly property int flatIndex: start + index
    readonly property bool current: flatIndex === currentIndex

    signal activated

    implicitWidth: size
    implicitHeight: size

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

        text: root.modelData.c
        renderType: Text.QtRendering
        font.pixelSize: Math.round(root.size * 0.56)
    }
}
