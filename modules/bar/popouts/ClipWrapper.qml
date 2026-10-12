pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components
import qs.utils
import qs.modules.bar.popouts

Item {
    id: root

    required property ShellScreen screen
    required property real borderThickness
    required property string position

    readonly property bool isHorizontal: BarPosition.isHorizontal(position)

    readonly property alias content: content
    property real offsetScale: content.isDetached || content.hasCurrent ? 0 : 1

    visible: width > 0 && height > 0
    clip: true

    implicitWidth: isHorizontal ? content.implicitWidth : (content.implicitWidth * (1 - offsetScale))
    implicitHeight: isHorizontal ? (content.implicitHeight * (1 - offsetScale)) : content.implicitHeight

    x: {
        if (content.isDetached)
            return (parent.width - content.nonAnimWidth) / 2;
        if (!isHorizontal)
            return BarPosition.isRight(position) ? (parent.width - width) : 0;

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
            return BarPosition.isBottom(position) ? (parent.height - height) : 0;

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
        enabled: !BarPosition.isRight(root.position) || content.isDetached

        Anim {
            duration: content.animLength
            easing: content.animCurve
        }
    }

    Behavior on y {
        enabled: root.offsetScale < 1 && (!BarPosition.isBottom(root.position) || content.isDetached)

        Anim {
            duration: content.animLength
            easing: content.animCurve
        }
    }

    Wrapper {
        id: content

        screen: root.screen
        offsetScale: root.offsetScale

        x: {
            if (root.isHorizontal)
                return (parent.width - width) / 2;
            const slide = (-implicitWidth - 5) * root.offsetScale;
            return BarPosition.isRight(root.position) ? parent.width - width - slide : slide;
        }
        y: {
            if (!root.isHorizontal)
                return (parent.height - height) / 2;
            const slide = (-implicitHeight - 5) * root.offsetScale;
            return BarPosition.isBottom(root.position) ? parent.height - height - slide : slide;
        }
    }
}
