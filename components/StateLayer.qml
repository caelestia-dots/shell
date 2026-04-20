import QtQuick
import QtQuick.Shapes
import Caelestia.Config
import qs.services

MouseArea {
    id: root

    property bool disabled
    property bool showHoverBackground: true
    readonly property alias rect: base

    property bool shapeMorph
    property real stateOpacity: pressed ? 0.1 : containsMouse ? 0.08 : 0

    property real pressX: width / 2
    property real pressY: height / 2
    property real circleRadius

    property alias color: base.color
    property alias radius: base.radius
    property alias topLeftRadius: base.topLeftRadius
    property alias topRightRadius: base.topRightRadius
    property alias bottomLeftRadius: base.bottomLeftRadius
    property alias bottomRightRadius: base.bottomRightRadius

    readonly property real endRadius: {
        const d1 = distSq(0, 0);
        const d2 = distSq(width, 0);
        const d3 = distSq(0, height);
        const d4 = distSq(width, height);
        return Math.sqrt(Math.max(d1, d2, d3, d4)) * (shapeMorph ? 1.16 : 1);
    }
    property real endRadiusAtPress

    function distSq(x: real, y: real): real {
        return (pressX - x) ** 2 + (pressY - y) ** 2;
    }

    function clamp(r: real): real {
        return Math.max(0, Math.min(r, width / 2, height / 2));
    }

    function press(x: real, y: real): void {
        pressX = x;
        pressY = y;
        fadeAnim.complete();
        circleRadius = 0;
        circle.opacity = 0.1;
        rippleAnim.restart();
        endRadiusAtPress = endRadius;
    }

    anchors.fill: parent
    enabled: !disabled
    cursorShape: disabled ? undefined : Qt.PointingHandCursor
    hoverEnabled: true

    onPressed: e => press(e.x, e.y)

    onPressedChanged: {
        if (!pressed && !rippleAnim.running && circle.opacity > 0)
            fadeAnim.start();
    }

    onCircleRadiusChanged: {
        if (!pressed && circleRadius > endRadiusAtPress * 0.99 && !fadeAnim.running)
            fadeAnim.start();
    }

    Anim {
        id: rippleAnim

        alwaysRunToEnd: true
        target: root
        property: "circleRadius"
        to: root.endRadius
        easing: Tokens.anim.expressiveSlowEffects
        duration: Tokens.anim.durations.expressiveSlowEffects * 2
    }

    Anim {
        id: fadeAnim

        target: circle
        property: "opacity"
        to: 0
        easing: Tokens.anim.expressiveSlowEffects
        duration: Tokens.anim.durations.expressiveSlowEffects
    }

    StyledRect {
        id: base

        anchors.fill: parent
        opacity: root.stateOpacity
        color: Colours.palette.m3onSurface
        // Pick up radius from parent if it has one (parent can be anything with a radius property)
        radius: root.parent?.radius ?? 0 // qmllint disable missing-property
    }

    Shape {
        id: circle

        anchors.fill: parent
        opacity: 0
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: base.color
            fillGradient: RadialGradient {
                centerX: root.pressX
                centerY: root.pressY
                centerRadius: root.circleRadius
                focalX: centerX
                focalY: centerY

                GradientStop {
                    position: 0
                    color: Qt.alpha(base.color, 1)
                }
                GradientStop {
                    position: 0.99
                    color: Qt.alpha(base.color, 1)
                }
                GradientStop {
                    position: 1
                    color: Qt.alpha(base.color, 0)
                }
            }

            startX: root.clamp(base.topLeftRadius)
            startY: 0

            PathLine {
                x: root.width - root.clamp(base.topLeftRadius)
                y: 0
            }
            PathArc {
                relativeX: root.clamp(base.topLeftRadius)
                relativeY: root.clamp(base.topLeftRadius)
                radiusX: root.clamp(base.topLeftRadius)
                radiusY: root.clamp(base.topLeftRadius)
            }
            PathLine {
                x: root.width
                y: root.height - root.clamp(base.bottomRightRadius)
            }
            PathArc {
                relativeX: -root.clamp(base.bottomRightRadius)
                relativeY: root.clamp(base.bottomRightRadius)
                radiusX: root.clamp(base.bottomRightRadius)
                radiusY: root.clamp(base.bottomRightRadius)
            }
            PathLine {
                x: root.clamp(base.bottomLeftRadius)
                y: root.height
            }
            PathArc {
                relativeX: -root.clamp(base.bottomLeftRadius)
                relativeY: -root.clamp(base.bottomLeftRadius)
                radiusX: root.clamp(base.bottomLeftRadius)
                radiusY: root.clamp(base.bottomLeftRadius)
            }
            PathLine {
                x: 0
                y: root.clamp(base.topLeftRadius)
            }
            PathArc {
                x: root.clamp(base.topLeftRadius)
                y: 0
                radiusX: root.clamp(base.topLeftRadius)
                radiusY: root.clamp(base.topLeftRadius)
            }
        }
    }

    Behavior on stateOpacity {
        Anim {
            easing: Tokens.anim.expressiveDefaultEffects
            duration: Tokens.anim.durations.expressiveDefaultEffects
        }
    }
}
