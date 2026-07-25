import QtQuick
import qs.modules.bar as Bar

QtObject {
    id: root

    required property Bar.BarWrapper bar
    required property var win
    required property string configPosition

    readonly property string position: configPosition === "top" || configPosition === "bottom" ? configPosition : "left"
    readonly property bool horizontal: position !== "left"
    readonly property bool barOnLeft: position === "left"
    readonly property bool barOnTop: position === "top"
    readonly property bool barOnBottom: position === "bottom"

    readonly property real barExtent: bar.extent
    readonly property real barClamped: bar.clampedExtent

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

    onConfigPositionChanged: {
        if (!["left", "top", "bottom"].includes(configPosition))
            console.warn(`Invalid bar position '${configPosition}', falling back to left`);
    }
}
