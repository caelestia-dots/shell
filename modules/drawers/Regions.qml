pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.modules.bar as Bar

Region {
    id: root

    required property Bar.BarWrapper bar
    required property Panels panels
    required property var win

    readonly property real borderThickness: win.contentItem.Config.border.thickness
    readonly property real clampedThickness: win.contentItem.Config.border.clampedThickness

    x: bar.clampedWidth + win.dragMaskPadding
    y: clampedThickness + win.dragMaskPadding
    width: win.width - bar.clampedWidth - clampedThickness - win.dragMaskPadding * 2
    height: win.height - clampedThickness * 2 - win.dragMaskPadding * 2
    intersection: Intersection.Xor

    R {
        panel: root.panels.dashboard.geometry
        y: 0
        height: panel.visibleHeight + root.borderThickness
    }

    R {
        panel: root.panels.launcher.geometry
        y: root.win.height - height
        height: panel.visibleHeight + root.borderThickness
    }

    R {
        id: sessionRegion

        panel: root.panels.sessionWrapper.geometry
        x: root.win.width - width
        width: panel.visibleWidth + root.borderThickness + sidebarRegion.width
    }

    R {
        id: sidebarRegion

        panel: root.panels.sidebar.geometry
        x: root.win.width - width
        width: panel.visibleWidth + root.borderThickness
    }

    R {
        panel: root.panels.osdWrapper.geometry
        x: root.win.width - width
        width: panel.visibleWidth + root.borderThickness + sessionRegion.width
    }

    R {
        panel: root.panels.notifications.geometry
        y: 0
        height: panel.height + root.borderThickness
    }

    R {
        panel: root.panels.utilities.geometry
        y: root.win.height - height
        height: panel.visibleHeight + root.borderThickness
    }

    R {
        panel: root.panels.popoutsWrapper.geometry
        width: panel.visibleWidth
    }

    component R: Region {
        required property PanelGeometry panel

        x: panel.x + root.bar.implicitWidth
        y: panel.y + root.borderThickness
        width: panel.width
        height: panel.height
        intersection: Intersection.Subtract
    }
}
