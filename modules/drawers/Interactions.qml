import QtQuick
import QtQuick.Controls
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.modules.bar as Bar
import qs.modules.bar.popouts as BarPopouts

CustomMouseArea {
    id: root

    required property ShellScreen screen
    required property BarPopouts.Wrapper popouts
    required property ScreenState screenState
    required property Panels panels
    required property Bar.BarWrapper bar
    required property real borderThickness
    required property bool fullscreen

    property point dragStart
    property bool dashboardShortcutActive
    property bool osdShortcutActive
    property bool utilitiesShortcutActive

    readonly property string barEdge: Config.bar.alignment
    readonly property bool isTop: barEdge === "top"
    readonly property bool isBottom: barEdge === "bottom"
    readonly property bool isLeft: barEdge === "left"
    readonly property bool isRight: barEdge === "right"
    readonly property bool isHorizontal: isTop || isBottom

    readonly property real barThickness: isHorizontal ? bar.implicitHeight : bar.implicitWidth
    readonly property real barHitbox: Math.max(Config.border.minThickness, barThickness)

    readonly property real barOffsetX: isLeft ? bar.implicitWidth : root.borderThickness
    readonly property real barOffsetY: isTop ? bar.implicitHeight : root.borderThickness
    readonly property real rightEdge: isRight ? bar.implicitWidth : Config.border.thickness

    function distanceToBar(x: real, y: real): real {
        if (isTop) return y;
        if (isBottom) return height - y;
        if (isLeft) return x;
        return width - x;
    }

    function coordAlongBar(x: real, y: real): real {
        return isHorizontal ? x : y;
    }

    function withinPanelHeight(panel: Item, x: real, y: real): bool {
        const panelY = barOffsetY + panel.y;
        return y >= panelY - Config.border.rounding && y <= panelY + panel.height + Config.border.rounding;
    }

    function withinPanelWidth(panel: Item, x: real, y: real): bool {
        const panelX = barOffsetX + panel.x;
        return x >= panelX - Config.border.rounding && x <= panelX + panel.width + Config.border.rounding;
    }

    function inBarPopoutPanel(panel: Item, x: real, y: real): bool {
        if (isBottom)
            return y > barOffsetY + panel.y && withinPanelWidth(panel, x, y);
        return y < barOffsetY + panel.y + panel.height && withinPanelWidth(panel, x, y);
    }

    function inSidebarPanel(panel: Item, x: real, y: real, forceRight = false): bool {
        const onLeft = forceRight ? false : panels.sidebar.onLeft;
        if (onLeft) {
            if (isLeft && x < barOffsetX) return false;
            return x < Math.max(Config.border.minThickness, barOffsetX + panel.x + panel.width) && withinPanelHeight(panel, x, y);
        } else {
            if (isRight && x > width - rightEdge) return false;
            return x > Math.min(width - Config.border.minThickness, barOffsetX + panel.x) && withinPanelHeight(panel, x, y);
        }
    }

    function inPlacedPanel(panel: Item, panelEdge: string, x: real, y: real, isCorner: bool, stripOnly = false): bool {
        const extra = isCorner ? Config.border.rounding : 0;
        const scale = stripOnly ? 0 : 1 - (panel.offsetScale ?? 0);

        if (panelEdge === "top" || panelEdge === "bottom") {
            if (!withinPanelWidth(panel, x, y)) return false;
            const depth = Math.max(Config.border.minThickness, panel.height * scale + Config.border.thickness) + extra;
            if (panelEdge === "top") {
                const start = isTop ? barThickness : 0;
                return y >= start && y < start + depth;
            }
            const end = height - (isBottom ? barThickness : 0);
            return y <= end && y > end - depth;
        }

        if (!withinPanelHeight(panel, x, y)) return false;
        const depth = Math.max(Config.border.minThickness, panel.width * scale + Config.border.thickness) + extra;
        if (panelEdge === "left") {
            const start = isLeft ? barThickness : 0;
            return x >= start && x < start + depth;
        }
        const end = width - (isRight ? barThickness : 0);
        return x <= end && x > end - depth;
    }

    function alongPanel(panel: Item, panelEdge: string, x: real, y: real): bool {
        if (panelEdge === "top" || panelEdge === "bottom")
            return withinPanelWidth(panel, x, y);
        return withinPanelHeight(panel, x, y);
    }

    function dragOutOf(panelEdge: string, dragX: real, dragY: real): real {
        if (panelEdge === "top")
            return dragY;
        if (panelEdge === "bottom")
            return -dragY;
        if (panelEdge === "left")
            return dragX;
        return -dragX;
    }

    function onWheel(event: WheelEvent): void {
        if (fullscreen)
            return;
        if (distanceToBar(event.x, event.y) < barThickness) {
            bar.handleWheel(coordAlongBar(event.x, event.y), event.angleDelta);
        }
    }

    anchors.fill: parent
    acceptedButtons: fullscreen ? Qt.NoButton : Qt.AllButtons
    hoverEnabled: true

    onPressed: event => dragStart = Qt.point(event.x, event.y)
    onContainsMouseChanged: {
        if (!containsMouse) {
            // Only hide if not activated by shortcut
            if (!osdShortcutActive) {
                screenState.osd = false;
                root.panels.osd.hovered = false;
            }

            if (!dashboardShortcutActive)
                screenState.dashboard = false;

            if (!utilitiesShortcutActive)
                screenState.utilities = false;

            if (!popouts.currentName.startsWith("traymenu") || ((popouts.current as StackView)?.depth ?? 0) <= 1) {
                popouts.hasCurrent = false;
                bar.closeTray();
            }

            if (Config.bar.showOnHover)
                bar.isHovered = false;

            if (Config.sidebar.showOnHover)
                screenState.sidebar = false;
        }
    }

    onPositionChanged: event => {
        if (popouts.isDetached)
            return;

        const x = event.x;
        const y = event.y;
        const dragX = x - dragStart.x;
        const dragY = y - dragStart.y;

        if (fullscreen) {
            root.panels.osd.hovered = inPlacedPanel(panels.osd, panels.osd.edge, x, y, false);
            return;
        }

        if (!screenState.bar && Config.bar.showOnHover && distanceToBar(x, y) < barHitbox) bar.isHovered = true;

        const dragStartInBar = distanceToBar(dragStart.x, dragStart.y) < barHitbox;
        const barDrag = (isHorizontal ? dragY : dragX) * (isTop || isLeft ? 1 : -1);
        if (pressed && dragStartInBar) {
            if (barDrag > Config.bar.dragThreshold) screenState.bar = true;
            else if (barDrag < -Config.bar.dragThreshold) screenState.bar = false;
        }

        const sidebarOnLeft = panels.sidebar.onLeft;

        if (panels.sidebar.offsetScale === 1) {
            const showOsd = inPlacedPanel(panels.osd, panels.osd.edge, x, y, false);
            if (!osdShortcutActive) { screenState.osd = showOsd; root.panels.osd.hovered = showOsd; }
            else if (showOsd) { osdShortcutActive = false; root.panels.osd.hovered = true; }

            const showSidebar = pressed && (sidebarOnLeft 
                ? dragStart.x < Math.max(Config.border.minThickness, barOffsetX + panels.sidebar.width)
                : dragStart.x > Math.min(width - Config.border.minThickness, barOffsetX + panels.sidebar.x));

            if (Config.sidebar.showOnHover) {
                const sidebarTriggerY = Math.max(Config.sidebar.minHoverThreshold, panels.notifications.y + panels.notifications.height + borderThickness);
                const showSidebarHover = (sidebarOnLeft 
                    ? x < Math.max(Config.border.minThickness, barOffsetX + panels.sidebar.width)
                    : x > Math.min(width - Config.border.minThickness, barOffsetX + panels.sidebar.x)) 
                    && y <= sidebarTriggerY;
                if (showSidebarHover && !screenState.sidebar) screenState.sidebar = true;
            }

            if (pressed && inSidebarPanel(panels.sessionWrapper, dragStart.x, dragStart.y) && withinPanelHeight(panels.sessionWrapper, x, y)) {
                if (dragX < -Config.session.dragThreshold) screenState.session = true;
                else if (dragX > Config.session.dragThreshold) screenState.session = false;
                
                if (showSidebar && panels.session.offsetScale <= 0) {
                    if (sidebarOnLeft && dragX > Config.sidebar.dragThreshold) screenState.sidebar = true;
                    else if (!sidebarOnLeft && dragX < -Config.sidebar.dragThreshold) screenState.sidebar = true;
                }
            } else if (showSidebar) {
                if (sidebarOnLeft && dragX > Config.sidebar.dragThreshold) screenState.sidebar = true;
                else if (!sidebarOnLeft && dragX < -Config.sidebar.dragThreshold) screenState.sidebar = true;
            }
        } else {
            const outOfSidebar = sidebarOnLeft 
                ? x > panels.sidebar.width * (1 - panels.sidebar.offsetScale)
                : x < width - panels.sidebar.width * (1 - panels.sidebar.offsetScale);
                
            const showOsd = (outOfSidebar || panels.osd.edge !== (sidebarOnLeft ? "left" : "right")) && inPlacedPanel(panels.osd, panels.osd.edge, x, y, false);

            if (!osdShortcutActive) { screenState.osd = showOsd; root.panels.osd.hovered = showOsd; }
            else if (showOsd) { osdShortcutActive = false; root.panels.osd.hovered = true; }

            if (pressed && outOfSidebar && inSidebarPanel(panels.sessionWrapper, dragStart.x, dragStart.y) && withinPanelHeight(panels.sessionWrapper, x, y)) {
                if (dragX < -Config.session.dragThreshold) screenState.session = true;
                else if (dragX > Config.session.dragThreshold) screenState.session = false;
            }

            // Show/hide sidebar on hover
            if (Config.sidebar.showOnHover && !pressed) {
                const sidebarTriggerY = Math.max(Config.sidebar.minHoverThreshold, panels.notifications.y + panels.notifications.height + borderThickness);
                const showSidebarHover = (sidebarOnLeft
                    ? x < Math.max(Config.border.minThickness, barOffsetX + panels.sidebar.width)
                    : x > Math.min(width - Config.border.minThickness, barOffsetX + panels.sidebar.x)) 
                    && y <= sidebarTriggerY;
                
                if (showSidebarHover && !screenState.sidebar) { 
                    screenState.sidebar = true; 
                } else {
                    const inSidebarArea = inSidebarPanel(panels.sidebar, x, y) || inSidebarPanel(panels.sessionWrapper, x, y);
                    if (!inSidebarArea) screenState.sidebar = false;
                }
            }

            if (pressed && inSidebarPanel(panels.sidebar, dragStart.x, 0)) {
                if (sidebarOnLeft && dragX < -Config.sidebar.dragThreshold) screenState.sidebar = false;
                else if (!sidebarOnLeft && dragX > Config.sidebar.dragThreshold) screenState.sidebar = false;
            }
        }

        const launcherEdge = panels.launcher.edge;
        const launcherTrigger = launcherEdge === "top" ? "top" : "bottom";
        const launcherStrip = launcherEdge === "center";

        if (Config.launcher.showOnHover) {
            if (!screenState.launcher && inPlacedPanel(panels.launcher, launcherTrigger, x, y, false, launcherStrip)) screenState.launcher = true;
        } else if (pressed && inPlacedPanel(panels.launcher, launcherTrigger, dragStart.x, dragStart.y, false, launcherStrip) && withinPanelWidth(panels.launcher, x, y)) {
            const launcherDrag = dragOutOf(launcherTrigger, dragX, dragY);
            if (launcherDrag > Config.launcher.dragThreshold) screenState.launcher = true;
            else if (launcherDrag < -Config.launcher.dragThreshold) screenState.launcher = false;
        }

        const dashEdge = panels.dashboard.edge;
        const showDashboard = Config.dashboard.showOnHover && inPlacedPanel(panels.dashboard, dashEdge, x, y, false);
        if (!dashboardShortcutActive) { screenState.dashboard = showDashboard; }
        else if (showDashboard) { dashboardShortcutActive = false; }

        if (pressed && inPlacedPanel(panels.dashboard, dashEdge, dragStart.x, dragStart.y, false) && alongPanel(panels.dashboard, dashEdge, x, y)) {
            const dashDrag = dragOutOf(dashEdge, dragX, dragY);
            if (dashDrag > Config.dashboard.dragThreshold) screenState.dashboard = true;
            else if (dashDrag < -Config.dashboard.dragThreshold) screenState.dashboard = false;
        }

        const showUtilities = inPlacedPanel(panels.utilities, panels.utilities.edge, x, y, true);
        if (!utilitiesShortcutActive) { screenState.utilities = showUtilities; }
        else if (showUtilities) { utilitiesShortcutActive = false; }

        if (distanceToBar(x, y) < barThickness) {
            bar.checkPopout(coordAlongBar(x, y));
        } else if ((!popouts.currentName.startsWith("traymenu") || ((popouts.current as StackView)?.depth ?? 0) <= 1) && !inBarPopoutPanel(panels.popoutsWrapper, x, y)) {
            popouts.hasCurrent = false; bar.closeTray();
        }
    }

    Connections {
        function onLauncherChanged() {
            if (!root.screenState.launcher) {
                root.dashboardShortcutActive = false; root.osdShortcutActive = false; root.utilitiesShortcutActive = false;
                const inDashboardArea = root.inPlacedPanel(root.panels.dashboard, root.panels.dashboard.edge, root.mouseX, root.mouseY, false);
                const inOsdArea = root.inPlacedPanel(root.panels.osd, root.panels.osd.edge, root.mouseX, root.mouseY, false);
                if (!inDashboardArea) root.screenState.dashboard = false;
                if (!inOsdArea) { root.screenState.osd = false; root.panels.osd.hovered = false; }
            }
        }

        function onDashboardChanged() {
            if (root.screenState.dashboard) {
                const inDashboardArea = root.inPlacedPanel(root.panels.dashboard, root.panels.dashboard.edge, root.mouseX, root.mouseY, false);
                if (!inDashboardArea) root.dashboardShortcutActive = true;
            } else root.dashboardShortcutActive = false;
        }

        function onOsdChanged() {
            if (root.screenState.osd) {
                const inOsdArea = root.inPlacedPanel(root.panels.osd, root.panels.osd.edge, root.mouseX, root.mouseY, false);
                if (!inOsdArea) root.osdShortcutActive = true;
            } else root.osdShortcutActive = false;
        }

        function onUtilitiesChanged() {
            if (root.screenState.utilities) {
                const inUtilitiesArea = root.inPlacedPanel(root.panels.utilities, root.panels.utilities.edge, root.mouseX, root.mouseY, false);
                if (!inUtilitiesArea) root.utilitiesShortcutActive = true;
            } else root.utilitiesShortcutActive = false;
        }

        target: root.screenState
    }
}
