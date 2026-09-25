pragma Singleton

import Quickshell

Singleton {
    function resolvedPosition(raw: string): string {
        const p = (raw ?? "left").trim().toLowerCase();
        if (p === "top" || p === "bottom" || p === "right")
            return p;
        return "left";
    }

    function isHorizontal(pos: string): bool {
        return pos === "top" || pos === "bottom";
    }

    function isLeft(pos: string): bool {
        return pos === "left";
    }

    function isTop(pos: string): bool {
        return pos === "top";
    }

    function isRight(pos: string): bool {
        return pos === "right";
    }

    function isBottom(pos: string): bool {
        return pos === "bottom";
    }
}
