import QtQuick
import QtQuick.Shapes
import qs.components
import qs.services

Shape {
    id: root

    property color color: Colours.palette.m3surfaceContainer
    property int waves: 4
    property real amplitude: 3

    readonly property real waveHeight: amplitude * 2

    preferredRendererType: Shape.CurveRenderer
    asynchronous: true

    ShapePath {
        strokeWidth: 0
        strokeColor: "transparent"
        fillColor: root.color

        PathSvg {
            path: {
                const w = root.width;
                const h = root.height;
                const a = root.amplitude;
                const n = Math.max(1, root.waves);
                const wl = w / n;
                const half = wl / 2;

                let d = `M 0,${a} `;
                for (let i = 0; i < n; ++i) {
                    const x = i * wl;
                    d += `Q ${x + half / 2},${-a} ${x + half},${a} `;
                    d += `Q ${x + half + half / 2},${3 * a} ${x + wl},${a} `;
                }
                d += `L ${w},${h} L 0,${h} Z`;
                return d;
            }
        }

        Behavior on fillColor {
            CAnim {}
        }
    }
}
