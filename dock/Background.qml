import qs.services
import qs.config
import QtQuick
import QtQuick.Shapes

ShapePath {
    id: root

    required property Item wrapper
    required property real startX
    required property real startY

    readonly property real rounding: Config.border.rounding
    readonly property real borderWidth: Config.border.thickness

    fillColor: Colours.tPalette.m3surfaceContainer
    strokeColor: Colours.tPalette.m3outline
    strokeWidth: borderWidth

    startX: root.startX
    startY: root.startY

    PathLine {
        x: root.startX + root.wrapper.width + root.rounding
        y: root.startY
    }

    PathQuad {
        x: root.startX + root.wrapper.width + root.rounding
        y: root.startY - root.rounding
        controlX: root.startX + root.wrapper.width + root.rounding
        controlY: root.startY
    }

    PathLine {
        x: root.startX + root.wrapper.width + root.rounding
        y: root.startY - root.wrapper.height
    }

    PathQuad {
        x: root.startX + root.wrapper.width
        y: root.startY - root.wrapper.height - root.rounding
        controlX: root.startX + root.wrapper.width + root.rounding
        controlY: root.startY - root.wrapper.height - root.rounding
    }

    PathLine {
        x: root.startX - root.rounding
        y: root.startY - root.wrapper.height - root.rounding
    }

    PathQuad {
        x: root.startX - root.rounding
        y: root.startY - root.wrapper.height
        controlX: root.startX - root.rounding
        controlY: root.startY - root.wrapper.height - root.rounding
    }

    PathLine {
        x: root.startX - root.rounding
        y: root.startY - root.rounding
    }

    PathQuad {
        x: root.startX
        y: root.startY
        controlX: root.startX - root.rounding
        controlY: root.startY
    }
}