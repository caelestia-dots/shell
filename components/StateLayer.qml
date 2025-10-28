import qs.services
import qs.config
import QtQuick

MouseArea {
    id: root

    property bool disabled
    property color color: Colours.palette.m3onSurface
    property real radius: parent?.radius ?? 0
    property alias rect: hoverLayer

    function onClicked(): void {
    }

    anchors.fill: parent

    enabled: !disabled
    cursorShape: disabled ? undefined : Qt.PointingHandCursor
    hoverEnabled: true

    onPressed: event => {
        if (disabled)
            return;

        rippleAnim.x = event.x;
        rippleAnim.y = event.y;

        const dist = (ox, oy) => ox * ox + oy * oy;
        rippleAnim.radius = Math.sqrt(Math.max(dist(event.x, event.y), dist(event.x, height - event.y), dist(width - event.x, event.y), dist(width - event.x, height - event.y)));

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
            value: 0.08
        }
        Anim {
            target: ripple
            properties: "implicitWidth,implicitHeight"
            from: 0
            to: rippleAnim.radius * 2
            easing.bezierCurve: Appearance.anim.curves.standardDecel
        }
        Anim {
            target: ripple
            property: "opacity"
            to: 0
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
}
