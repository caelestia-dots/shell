pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.modules.bar as Bar

Region {
    id: root

    required property Bar.BarWrapper bar
    required property Panels panels
    required property var win

    readonly property string barEdge: win.contentItem.Config.bar.alignment
    readonly property bool isTop: barEdge === "top"
    readonly property bool isBottom: barEdge === "bottom"
    readonly property bool isLeft: barEdge === "left"
    readonly property bool isRight: barEdge === "right"
    readonly property bool isHorizontal: isTop || isBottom

    readonly property real borderThickness: win.contentItem.Config.border.thickness
    readonly property real clampedThickness: win.contentItem.Config.border.clampedThickness
    readonly property real barThickness: Math.max(clampedThickness, isHorizontal ? bar.implicitHeight : bar.implicitWidth)

    readonly property real maskEdgeLeft: isLeft ? barThickness : clampedThickness
    readonly property real maskEdgeTop: isTop ? barThickness : clampedThickness
    readonly property real maskEdgeRight: isRight ? barThickness : clampedThickness
    readonly property real maskEdgeBottom: isBottom ? barThickness : clampedThickness

    readonly property real contentOffsetX: isLeft ? bar.implicitWidth : borderThickness
    readonly property real contentOffsetY: isTop ? bar.implicitHeight : borderThickness

    readonly property real bottomEdgeExtra: isBottom ? bar.implicitHeight : borderThickness
    readonly property real rightEdgeExtra: isRight ? bar.implicitWidth : borderThickness

    width: root.win.width
    height: root.win.height

    Region {
        x: maskEdgeLeft + win.dragMaskPadding
        y: maskEdgeTop + win.dragMaskPadding
        width: win.width - maskEdgeLeft - maskEdgeRight - win.dragMaskPadding * 2
        height: win.height - maskEdgeTop - maskEdgeBottom - win.dragMaskPadding * 2
        intersection: Intersection.Subtract
    }

    PlacedR {
        panel: root.panels.dashboard
        panelEdge: root.panels.dashboard.edge
    }

    PlacedR {
        panel: root.panels.utilities
        panelEdge: root.panels.utilities.edge
    }

    PlacedR {
        panel: root.panels.osd
        panelEdge: root.panels.osd.edge
    }

    PlacedR {
        panel: root.panels.launcher
        panelEdge: root.panels.launcher.edge
        visibleScale: 1 - root.panels.launcher.offsetScale
    }

    R {
        id: sessionRegion
        panel: root.panels.sessionWrapper
        x: root.win.width - width
        width: panel.width * (1 - root.panels.session.offsetScale) + root.rightEdgeExtra * (1 - root.panels.session.offsetScale) + (root.panels.sidebar.onLeft ? 0 : sidebarRegion.width)
        height: root.panels.session.offsetScale < 1 ? panel.height : 0
    }

    R {
        id: sidebarRegion
        panel: root.panels.sidebar
        x: root.panels.sidebar.onLeft ? 0 : root.win.width - width
        width: panel.width * (1 - root.panels.sidebar.offsetScale) + (root.panels.sidebar.onLeft ? root.maskEdgeLeft : root.rightEdgeExtra) * (1 - root.panels.sidebar.offsetScale)
        height: root.panels.sidebar.offsetScale < 1 ? panel.height : 0
    }

    R {
        panel: root.panels.notifications
        y: root.isTop ? root.bar.implicitHeight : 0
        height: panel.height + (root.isTop ? 0 : root.borderThickness)
    }

    R {
        panel: root.panels.popoutsWrapper
        height: panel.height * (1 - root.panels.popoutsWrapper.offsetScale)
    }

    component R: Region {
        required property Item panel

        x: panel.x + root.contentOffsetX
        y: panel.y + root.contentOffsetY
        width: panel.width
        height: panel.height
        intersection: Intersection.Combine
    }

    component PlacedR: Region {
        required property Item panel
        required property string panelEdge
        property real visibleScale: 1

        readonly property bool isValid: panelEdge !== undefined && panelEdge !== ""
        readonly property bool onEdge: panelEdge === "top" || panelEdge === "bottom" || panelEdge === "left" || panelEdge === "right"
        readonly property real innerX: panel.x + root.contentOffsetX
        readonly property real innerY: panel.y + root.contentOffsetY

        x: isValid ? (panelEdge === "left" ? 0 : (panelEdge === "right" ? Math.min(innerX, root.win.width - root.rightEdgeExtra) : innerX)) : 0
        y: isValid ? (panelEdge === "top" ? 0 : (panelEdge === "bottom" ? Math.min(innerY, root.win.height - root.bottomEdgeExtra) : innerY)) : 0
        width: isValid ? (panelEdge === "left" ? Math.max(root.contentOffsetX, innerX + panel.width) : (panelEdge === "right" ? root.win.width - x : panel.width * (onEdge ? 1 : visibleScale))) : 0
        height: isValid ? (panelEdge === "top" ? Math.max(root.contentOffsetY, innerY + panel.height) : (panelEdge === "bottom" ? root.win.height - y : panel.height * (onEdge ? 1 : visibleScale))) : 0
        intersection: Intersection.Combine
    }
}
