pragma ComponentBehavior: Bound

import "./deps/widgets"
import "./deps/services"
import "./deps/config"
import QtQuick
import QtQuick.Shapes
import QtQuick.Effects

Item {
    id: root

    required property bool locked
    required property real buttonsWidth
    required property real buttonsHeight
    required property bool isNormal
    required property bool isLarge

    readonly property real clockBottom: innerMask.anchors.margins + clockPath.height
    readonly property real inputTop: innerMask.anchors.margins + inputPath.height
    readonly property real buttonsTop: innerMask.anchors.margins + buttonsPath.height
    readonly property real buttonsLeft: innerMask.anchors.margins + buttonsPath.width

    anchors.fill: parent

    StyledRect {
        id: base

        anchors.fill: parent
        color: Colours.alpha(Colours.palette.m3surface, false)

        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskInverted: true
            maskSource: mask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }
    }

    Item {
        id: mask

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            id: innerMask

            anchors.fill: parent
            anchors.margins: root.locked ? Config.lock.sizes.border : -radius / 2
            radius: Appearance.rounding.large * 2

            Behavior on anchors.margins {
                Anim {}
            }
        }
    }

    Shape {
        anchors.fill: parent
        anchors.margins: Math.floor(innerMask.anchors.margins)

        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            id: clockPath

            readonly property int width: Config.lock.sizes.clockWidth
            property real height: root.locked ? Config.lock.sizes.clockHeight : 0

            readonly property real rounding: Appearance.rounding.large * 4
            readonly property bool flatten: height < rounding * 2
            readonly property real roundingY: flatten ? height / 2 : rounding

            strokeWidth: -1
            fillColor: Colours.palette.m3surface

            startX: (innerMask.width - width) / 2 - rounding

            PathArc {
                relativeX: clockPath.rounding
                relativeY: clockPath.roundingY
                radiusX: clockPath.rounding
                radiusY: Math.min(clockPath.rounding, clockPath.height)
            }
            PathLine {
                relativeX: 0
                relativeY: clockPath.height - clockPath.roundingY * 2
            }
            PathArc {
                relativeX: clockPath.rounding
                relativeY: clockPath.roundingY
                radiusX: clockPath.rounding
                radiusY: Math.min(clockPath.rounding, clockPath.height)
                direction: PathArc.Counterclockwise
            }
            PathLine {
                relativeX: clockPath.width - clockPath.rounding * 2
                relativeY: 0
            }
            PathArc {
                relativeX: clockPath.rounding
                relativeY: -clockPath.roundingY
                radiusX: clockPath.rounding
                radiusY: Math.min(clockPath.rounding, clockPath.height)
                direction: PathArc.Counterclockwise
            }
            PathLine {
                relativeX: 0
                relativeY: -(clockPath.height - clockPath.roundingY * 2)
            }
            PathArc {
                relativeX: clockPath.rounding
                relativeY: -clockPath.roundingY
                radiusX: clockPath.rounding
                radiusY: Math.min(clockPath.rounding, clockPath.height)
            }

            Behavior on height {
                Anim {}
            }

            Behavior on fillColor {
                ColorAnimation {
                    duration: Appearance.anim.durations.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.standard
                }
            }
        }

        ShapePath {
            id: inputPath

            readonly property int width: Config.lock.sizes.inputWidth
            property real height: root.locked ? Config.lock.sizes.inputHeight : 0

            readonly property real rounding: Appearance.rounding.large * 2
            readonly property bool flatten: height < rounding * 2
            readonly property real roundingY: flatten ? height / 2 : rounding

            strokeWidth: -1
            fillColor: Colours.palette.m3surface

            startX: (innerMask.width - width) / 2 - rounding
            startY: Math.ceil(innerMask.height)

            PathArc {
                relativeX: inputPath.rounding
                relativeY: -inputPath.roundingY
                radiusX: inputPath.rounding
                radiusY: Math.min(inputPath.rounding, inputPath.height)
                direction: PathArc.Counterclockwise
            }
            PathLine {
                relativeX: 0
                relativeY: -(inputPath.height - inputPath.roundingY * 2)
            }
            PathArc {
                relativeX: inputPath.rounding
                relativeY: -inputPath.roundingY
                radiusX: inputPath.rounding
                radiusY: Math.min(inputPath.rounding, inputPath.height)
            }
            PathLine {
                relativeX: inputPath.width - inputPath.rounding * 2
                relativeY: 0
            }
            PathArc {
                relativeX: inputPath.rounding
                relativeY: inputPath.roundingY
                radiusX: inputPath.rounding
                radiusY: Math.min(inputPath.rounding, inputPath.height)
            }
            PathLine {
                relativeX: 0
                relativeY: inputPath.height - inputPath.roundingY * 2
            }
            PathArc {
                relativeX: inputPath.rounding
                relativeY: inputPath.roundingY
                radiusX: inputPath.rounding
                radiusY: Math.min(inputPath.rounding, inputPath.height)
                direction: PathArc.Counterclockwise
            }

            Behavior on height {
                Anim {}
            }

            Behavior on fillColor {
                ColorAnimation {
                    duration: Appearance.anim.durations.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.standard
                }
            }
        }

        ShapePath {
            id: buttonsPath

            property int width: root.locked ? root.buttonsWidth - Config.lock.sizes.border / 4 : 0
            property real height: root.locked ? root.buttonsHeight - Config.lock.sizes.border / 4 : 0

            readonly property real rounding: Appearance.rounding.large * 2
            readonly property real roundingX: width < rounding * 2 ? width / 2 : rounding
            readonly property real roundingY: height < rounding * 2 ? height / 2 : rounding

            strokeWidth: -1
            fillColor: root.isLarge ? Colours.palette.m3surface : "transparent"

            startX: Math.ceil(innerMask.width)
            startY: Math.ceil(innerMask.height) - height - rounding

            PathArc {
                relativeX: -buttonsPath.roundingX
                relativeY: buttonsPath.rounding
                radiusX: Math.min(buttonsPath.rounding, buttonsPath.width)
                radiusY: buttonsPath.rounding, buttonsPath.height
            }
            PathLine {
                relativeX: -(buttonsPath.width - buttonsPath.roundingX * 2)
                relativeY: 0
            }
            PathArc {
                relativeX: -buttonsPath.roundingX
                relativeY: buttonsPath.roundingY
                radiusX: Math.min(buttonsPath.rounding, buttonsPath.width)
                radiusY: Math.min(buttonsPath.rounding, buttonsPath.height)
                direction: PathArc.Counterclockwise
            }
            PathLine {
                relativeX: 0
                relativeY: buttonsPath.height - buttonsPath.roundingY * 2
            }
            PathArc {
                relativeX: -buttonsPath.roundingX
                relativeY: buttonsPath.roundingY
                radiusX: Math.min(buttonsPath.rounding, buttonsPath.width)
                radiusY: Math.min(buttonsPath.rounding, buttonsPath.height)
            }
            PathLine {
                relativeX: buttonsPath.width + buttonsPath.roundingX
                relativeY: 0
            }

            Behavior on width {
                Anim {}
            }

            Behavior on height {
                Anim {}
            }

            Behavior on fillColor {
                ColorAnimation {
                    duration: Appearance.anim.durations.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.standard
                }
            }
        }
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.large
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.emphasized
    }
}