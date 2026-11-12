import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell.Widgets
import qs.components
import qs.services

Item {
    id: root

    property real level
    property color colour: Hallownest.soul
    property bool running
    property real phase
    property bool ornate: true
    property real shown: Math.max(0, Math.min(1, level))

    function wave(offset: real, amp: real): string {
        const w = width;
        const h = height;
        const y0 = h * (1 - shown);
        // Sloshing: the surface rocks around the centre, with a small ripple on top
        const tilt = Math.sin(phase - offset * 0.3) * h * 0.09;
        const y = t => y0 + (t - 0.5) * 2 * tilt + Math.sin(phase * 2 + offset + t * Math.PI) * amp * 0.6;
        let d = `M 0 ${y(0)}`;
        for (let i = 1; i <= 16; i++)
            d += ` L ${w * i / 16} ${y(i / 16)}`;
        return d + ` L ${w} ${h} L 0 ${h} Z`;
    }

    implicitWidth: 112
    implicitHeight: 112

    Behavior on shown {
        Anim {
            type: Anim.DefaultSpatial
        }
    }

    NumberAnimation on phase {
        running: root.running && root.visible
        loops: Animation.Infinite
        from: 0
        to: Math.PI * 2
        duration: 3200
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -6
        visible: root.ornate
        radius: width / 2
        color: "transparent"
        border.width: 1
        border.color: Qt.alpha(Hallownest.steel, 0.25)
    }

    Item {
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: root.colour
            shadowOpacity: root.ornate ? 0.5 : 0.35
            shadowBlur: 1
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
            blurMax: 20
        }

        ClippingRectangle {
            anchors.fill: parent
            radius: width / 2
            color: Hallownest.card
            border.width: root.ornate ? 2 : 1.5
            border.color: root.ornate ? Qt.alpha(Hallownest.steel, 0.45) : Qt.alpha(root.colour, 0.8)

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: Qt.alpha(root.colour, 0.35)
                    strokeWidth: -1

                    PathSvg {
                        path: root.wave(Math.PI, root.height / 37)
                    }
                }

                ShapePath {
                    fillColor: root.colour
                    strokeWidth: -1

                    PathSvg {
                        path: root.wave(0, root.height / 45)
                    }
                }
            }
        }
    }
}
