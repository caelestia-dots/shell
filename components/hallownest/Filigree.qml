import QtQuick
import QtQuick.Shapes
import qs.components
import qs.services

Shape {
    id: root

    property real radius: 26
    property real inset: 7
    property color colour: Hallownest.steel
    // 0-1: how much of the stroke is traced; the gems fade in at the end
    property real drawn: 1

    function corner(mirror: bool): string {
        const d = inset;
        const r = radius;
        const h = height;
        const x = v => mirror ? width - v : v;
        const sweep = mirror ? 1 : 0;
        return `M ${x(d)} ${h - r - 12} L ${x(d)} ${h - r} A ${r - d} ${r - d} 0 0 ${sweep} ${x(r)} ${h - d} L ${x(r + 16)} ${h - d}`;
    }

    function gems(mirror: bool): string {
        const d = inset;
        const r = radius;
        const h = height;
        const x = v => mirror ? width - v : v;
        const gem = (cx, cy, s) => `M ${cx} ${cy - s} L ${cx + s} ${cy} L ${cx} ${cy + s} L ${cx - s} ${cy} Z`;
        return `${gem(x(r + 21), h - d, 2.5)} ${gem(x(d), h - r - 15, 2.5)} ${gem(x(d + 5), h - d - 5, 1.5)}`;
    }

    visible: opacity > 0
    preferredRendererType: Shape.CurveRenderer

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    ShapePath {
        fillColor: "transparent"
        strokeColor: root.colour
        strokeWidth: 1
        capStyle: ShapePath.RoundCap
        trim.end: root.drawn

        PathSvg {
            path: `${root.corner(false)} ${root.corner(true)}`
        }
    }

    ShapePath {
        fillColor: Qt.alpha(root.colour, Math.max(0, (root.drawn - 0.7) / 0.3))
        strokeWidth: -1

        PathSvg {
            path: `${root.gems(false)} ${root.gems(true)}`
        }
    }
}
