pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.modules.bar.popouts // Need to import this module so the Wrapper type is the same as others

Item {
    id: root

    required property ShellScreen screen
    required property real borderThickness

    readonly property alias content: content
    readonly property bool isTop: Config.bar.alignment === "top"
    readonly property bool isBottom: Config.bar.alignment === "bottom"
    readonly property bool isLeft: Config.bar.alignment === "left"
    readonly property bool isRight: Config.bar.alignment === "right"
    readonly property bool isHorizontal: isTop || isBottom

    property real offsetScale: content.isDetached || content.hasCurrent ? 0 : 1

    visible: width > 0 && height > 0
    clip: true

    implicitWidth: isHorizontal ? content.implicitWidth : content.implicitWidth * (1 - offsetScale)
    implicitHeight: isHorizontal ? content.implicitHeight * (1 - offsetScale) : content.implicitHeight

    Connections {
        target: root.Config.bar
        function onAlignmentChanged() {
            content.close();
        }
    }
    x: {
        if (content.isDetached)
            return (parent.width - content.nonAnimWidth) / 2;
        if (!isHorizontal)
            return isRight ? parent.width - implicitWidth : 0;

        const off = content.currentCenter - borderThickness - content.nonAnimWidth / 2;
        const diff = parent.width - Math.floor(off + content.nonAnimWidth);
        if (diff < 0)
            return off + diff;
        return Math.max(off, 0);
    }

    y: {
        if (content.isDetached)
            return (parent.height - content.nonAnimHeight) / 2;
        if (isHorizontal)
            return isBottom ? parent.height - implicitHeight : 0;

        const off = content.currentCenter - borderThickness - content.nonAnimHeight / 2;
        const diff = parent.height - Math.floor(off + content.nonAnimHeight);
        if (diff < 0)
            return off + diff;
        return Math.max(off, 0);
    }

    Behavior on offsetScale {
        Anim {}
    }

    Behavior on x {
        enabled: content.isDetached || (root.isHorizontal && root.offsetScale < 1)
        Anim {
            duration: content.animLength
            easing: content.animCurve
        }
    }

    Behavior on y {
        enabled: content.isDetached || (!root.isHorizontal && root.offsetScale < 1)
        Anim {
            duration: content.animLength
            easing: content.animCurve
        }
    }

    Wrapper {
        id: content

        screen: root.screen
        offsetScale: root.offsetScale

        x: root.isLeft ? -(implicitWidth + 5) * root.offsetScale : (root.isRight ? 5 * root.offsetScale : 0)
        y: root.isTop ? -(implicitHeight + 5) * root.offsetScale : (root.isBottom ? 5 * root.offsetScale : 0)
    }
}
