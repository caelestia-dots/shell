pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.modules.bar.popouts // Need to import this module so the Wrapper type is the same as others

Item {
    id: root

    required property ShellScreen screen
    required property int position
    required property real borderThickness

    readonly property alias content: content
    readonly property bool horizontal: position === BarPosition.Top || position === BarPosition.Bottom
    property real offsetScale: {
        if (content.hasCurrent)
            return 0;
        if (position === BarPosition.Top)
            return y > 0 ? 0 : 1;
        if (position === BarPosition.Bottom)
            return content.isDetached ? 0 : 1;
        return x > 0 ? 0 : 1;
    }

    visible: width > 0 && height > 0
    clip: true

    implicitWidth: horizontal ? content.implicitWidth : content.implicitWidth * (1 - offsetScale)
    implicitHeight: horizontal ? content.implicitHeight * (1 - offsetScale) : content.implicitHeight

    x: {
        if (content.isDetached)
            return (parent.width - content.nonAnimWidth) / 2;
        if (!horizontal)
            return 0;

        const off = content.currentCenter - borderThickness - content.nonAnimWidth / 2;
        const diff = parent.width - Math.floor(off + content.nonAnimWidth);
        if (diff < 0)
            return off + diff;
        return Math.max(off, 0);
    }
    y: {
        if (content.isDetached)
            return (parent.height - content.nonAnimHeight) / 2;
        if (horizontal)
            return position === BarPosition.Bottom ? parent.height - height : 0;

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
        enabled: !root.horizontal || root.offsetScale < 1

        Anim {
            duration: content.animLength
            easing: content.animCurve
        }
    }

    Behavior on y {
        // A Behavior-lagged y would dip the clip area into the bar while height animates
        enabled: root.position === BarPosition.Bottom ? false : (root.horizontal || root.offsetScale < 1)

        Anim {
            duration: content.animLength
            easing: content.animCurve
        }
    }

    Wrapper {
        id: content

        screen: root.screen
        offsetScale: root.offsetScale

        x: root.horizontal ? (parent.width - width) / 2 : (-width - 5) * root.offsetScale
        y: root.horizontal ? (root.position === BarPosition.Bottom ? parent.height - height + (height + 5) * root.offsetScale : (-height - 5) * root.offsetScale) : (parent.height - height) / 2
    }
}