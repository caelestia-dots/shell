pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.utils
import qs.modules.bar as Bar

Region {
    id: root

    required property Bar.BarWrapper bar
    required property Panels panels
    required property var win

    readonly property string barPos: bar.position
    readonly property bool barOnLeft: BarPosition.isLeft(barPos)
    readonly property bool barOnRight: BarPosition.isRight(barPos)
    readonly property bool barOnTop: BarPosition.isTop(barPos)
    readonly property bool barOnBottom: BarPosition.isBottom(barPos)

    readonly property real clampedThickness: win.contentItem.Config.border.clampedThickness

    x: (barOnLeft ? bar.clampedWidth : clampedThickness) + win.dragMaskPadding
    y: (barOnTop ? bar.clampedHeight : clampedThickness) + win.dragMaskPadding
    width: win.width - (barOnLeft || barOnRight ? bar.clampedWidth : clampedThickness) - clampedThickness - win.dragMaskPadding * 2
    height: win.height - (barOnTop || barOnBottom ? bar.clampedHeight : clampedThickness) - clampedThickness - win.dragMaskPadding * 2
    intersection: Intersection.Xor

    R {
        bounds: root.panels.dashboardRect
    }

    R {
        bounds: root.panels.launcherRect
    }

    R {
        bounds: root.panels.sessionRect
    }

    R {
        bounds: root.panels.sidebarRect
    }

    R {
        bounds: root.panels.osdRect
    }

    R {
        bounds: root.panels.notificationsRect
    }

    R {
        bounds: root.panels.utilitiesRect
    }

    R {
        bounds: root.panels.popoutsRect
    }

    component R: Region {
        required property rect bounds

        x: bounds.x
        y: bounds.y
        width: bounds.width
        height: bounds.height
        intersection: Intersection.Subtract
    }
}
