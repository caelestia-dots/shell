pragma Singleton

import Quickshell

Singleton {
    id: root

    readonly property real defaultGap: 5

    function edge(placement: string): string {
        const e = (placement ?? "").toLowerCase().trim().split("-")[0];
        if (e === "top" || e === "bottom" || e === "left" || e === "right")
            return e;
        return "top";
    }

    function align(placement: string): string {
        const parts = (placement ?? "").toLowerCase().trim().split("-");
        if (parts.length < 2)
            return "center";
        const a = parts[1];
        if (a === "left" || a === "top" || a === "start")
            return "start";
        if (a === "right" || a === "bottom" || a === "end")
            return "end";
        return "center";
    }

    function isHorizontalEdge(placement: string): bool {
        const e = edge(placement);
        return e === "top" || e === "bottom";
    }

    function isVerticalEdge(placement: string): bool {
        return !isHorizontalEdge(placement);
    }

    function baseX(placement: string, containerWidth: real, itemWidth: real): real {
        const e = edge(placement);
        if (e === "left")
            return 0;
        if (e === "right")
            return containerWidth - itemWidth;
        return alignedPos(align(placement), containerWidth, itemWidth);
    }

    function baseY(placement: string, containerHeight: real, itemHeight: real): real {
        const e = edge(placement);
        if (e === "top")
            return 0;
        if (e === "bottom")
            return containerHeight - itemHeight;
        return alignedPos(align(placement), containerHeight, itemHeight);
    }

    function alignedPos(alignment: string, containerSize: real, itemSize: real): real {
        if (alignment === "start")
            return 0;
        if (alignment === "end")
            return containerSize - itemSize;
        return (containerSize - itemSize) / 2;
    }

    function offsetX(placement: string, itemWidth: real, offsetScale: real): real {
        const e = edge(placement);
        if (e === "left")
            return (-itemWidth - defaultGap) * offsetScale;
        if (e === "right")
            return (itemWidth + defaultGap) * offsetScale;
        return 0;
    }

    function offsetY(placement: string, itemHeight: real, offsetScale: real): real {
        const e = edge(placement);
        if (e === "top")
            return (-itemHeight - defaultGap) * offsetScale;
        if (e === "bottom")
            return (itemHeight + defaultGap) * offsetScale;
        return 0;
    }
}
