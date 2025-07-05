import "root:/widgets"
import "root:/services"
import "root:/config"
import QtQuick

MouseArea {
    id: root

    property bool disabled
    property color color: Colours.palette.m3onSurface
    property real radius: parent?.radius ?? 0

    function onClicked(): void {
    }

    anchors.fill: parent

    cursorShape: disabled ? undefined : Qt.PointingHandCursor
    hoverEnabled: true

    onPressed: event => {
        rippleAnim.x = event.x;
        rippleAnim.y = event.y;

        const dist = (ox, oy) => ox * ox + oy * oy;
        rippleAnim.radius = Math.sqrt(Math.max(dist(0, 0), dist(0, width), dist(width, 0), dist(width, height)));

        rippleAnim.restart();
    }

    onClicked: event => !disabled && onClicked(event)

    SequentialAnimation {
        id: rippleAnim

        property real x
        property real y
        property real radius

        PropertyAction {
            target: ripple
            property: "x"
            value: rippleAnim.x
        }
        PropertyAction {
            target: ripple
            property: "y"
            value: rippleAnim.y
        }
        PropertyAction {
            target: ripple
            property: "opacity"
            value: 0.1
        }
        ParallelAnimation {
            Anim {
                target: ripple
                properties: "implicitWidth,implicitHeight"
                from: 0
                to: rippleAnim.radius * 2
                duration: Appearance.anim.durations.large
                easing.bezierCurve: Appearance.anim.curves.standardDecel
            }
            Anim {
                target: ripple
                property: "opacity"
                to: 0
                duration: Appearance.anim.durations.large
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.standard
            }
        }
    }

    StyledClippingRect {
        id: hoverLayer

        anchors.fill: parent

        color: Qt.alpha(root.color, root.disabled ? 0 : root.pressed ? 0.1 : root.containsMouse ? 0.08 : 0)
        radius: root.radius

        StyledRect {
            id: ripple

            radius: Appearance.rounding.full
            color: root.color
            opacity: 0

            transform: Translate {
                x: -ripple.width / 2
                y: -ripple.height / 2
            }
        }
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}
