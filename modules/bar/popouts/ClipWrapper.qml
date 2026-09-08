pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components
import qs.modules.bar.popouts // Need to import this module so the Wrapper type is the same as others

Item {
    id: root

    required property ShellScreen screen
    required property real borderThickness

    readonly property alias content: content
    property real offsetScale: x > 0 || content.hasCurrent ? 0 : 1

    // Where the popout is headed, before the Behaviors below lag it there. The input mask
    // (modules/drawers/Regions.qml) is cut from these: a hole shaped from the animated geometry
    // trails what is drawn, so the pointer falls through the visible popout to the window below.
    readonly property real targetY: {
        if (content.isDetached)
            return (parent.height - content.nonAnimHeight) / 2;

        const off = content.currentCenter - borderThickness - content.nonAnimHeight / 2;
        const diff = parent.height - Math.floor(off + content.nonAnimHeight);
        if (diff < 0)
            return off + diff;
        return Math.max(off, 0);
    }
    // While closing there is nothing to settle into, so track the live size and let the hole shrink
    readonly property bool opening: content.hasCurrent || content.isDetached
    readonly property real nonAnimWidth: opening ? content.nonAnimWidth : width
    readonly property real nonAnimHeight: opening ? content.nonAnimHeight : height

    visible: width > 0 && height > 0
    clip: true

    implicitWidth: content.implicitWidth * (1 - offsetScale)
    implicitHeight: content.implicitHeight

    x: content.isDetached ? (parent.width - content.nonAnimWidth) / 2 : 0
    y: targetY

    Behavior on offsetScale {
        Anim {}
    }

    Behavior on x {
        Anim {
            duration: content.animLength
            easing: content.animCurve
        }
    }

    Behavior on y {
        enabled: root.offsetScale < 1

        Anim {
            duration: content.animLength
            easing: content.animCurve
        }
    }

    Wrapper {
        id: content

        screen: root.screen
        offsetScale: root.offsetScale

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: (-implicitWidth - 5) * root.offsetScale
    }
}
