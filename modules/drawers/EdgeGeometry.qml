pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.modules.bar as Bar

QtObject {
    id: root

    required property Bar.BarWrapper bar
    required property var win
    required property int configPosition

    readonly property int position: normalize(configPosition)
    readonly property bool horizontal: position === BarPosition.Top || position === BarPosition.Bottom
    readonly property bool barOnLeft: position === BarPosition.Left
    readonly property bool barOnTop: position === BarPosition.Top
    readonly property bool barOnBottom: position === BarPosition.Bottom
    // A dashboard on the bar's own edge can never be revealed: closed, its hover zone is exactly
    // the strip the bar occupies, and hovering the bar has to open popouts instead. Use the other
    // edge when the two would collide.
    readonly property bool dashboardOnLeft: horizontal

    readonly property real barExtent: bar.extent
    readonly property real barClamped: bar.clampedExtent

    function normalize(pos: int): int {
        if (pos === BarPosition.Top || pos === BarPosition.Bottom)
            return pos;
        if (pos === BarPosition.Right)
            console.warn("Right bar position is not supported, falling back to left");
        return BarPosition.Left;
    }

    function insetLeft(border: real, clamped = false): real {
        return barOnLeft ? (clamped ? barClamped : barExtent) : border;
    }

    function insetTop(border: real, clamped = false): real {
        return barOnTop ? (clamped ? barClamped : barExtent) : border;
    }

    function insetBottom(border: real, clamped = false): real {
        return barOnBottom ? (clamped ? barClamped : barExtent) : border;
    }

    function barContains(x: real, y: real, clamped = false): bool {
        const extent = clamped ? barClamped : barExtent;
        if (barOnTop)
            return y < extent;
        if (barOnBottom)
            return y > win.height - extent;
        return x < extent;
    }

    function inwardDrag(dragX: real, dragY: real): real {
        if (barOnTop)
            return dragY;
        if (barOnBottom)
            return -dragY;
        return dragX;
    }

    function axisPos(x: real, y: real): real {
        return horizontal ? x : y;
    }
}
