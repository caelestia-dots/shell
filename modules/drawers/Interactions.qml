import QtQuick
import QtQuick.Controls
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.utils
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

    function withinPanelHeight(panel: Item, x: real, y: real): bool {
        const bounds = panel.visible ? panels.exposedRect(panel) : panels.panelGeometry(panel);
        return y >= bounds.y - Config.border.rounding && y <= bounds.y + bounds.height + Config.border.rounding;
    }

    function withinPanelWidth(panel: Item, x: real, y: real, exposedBounds = null): bool {
        const bounds = panel.visible ? (exposedBounds ?? panels.exposedRect(panel)) : panels.panelGeometry(panel);
        return x >= bounds.x - Config.border.rounding && x <= bounds.x + bounds.width + Config.border.rounding;
    }

    function inSideEdge(panel: Item, x: real): bool {
        const bounds = panels.panelGeometry(panel);
        return bar.position === "right" ? x < Math.max(Config.border.minThickness, bounds.x + bounds.width) : x > Math.min(width - Config.border.minThickness, bounds.x);
    }

    function inSidePanel(panel: Item, x: real, y: real): bool {
        const bounds = panels.exposedRect(panel);
        if (bounds.width > 0 && bounds.height > 0) {
            const insideEdge = bar.position === "right" ? x < bounds.x + bounds.width : x > bounds.x;
            return insideEdge && y >= bounds.y - Config.border.rounding && y <= bounds.y + bounds.height + Config.border.rounding;
        }
        // A closed side drawer still opens from its positioning wrapper's
        // nominal edge, not from the content that has slid off screen.
        const trigger = panel === panels.osd ? panels.osdWrapper : panel === panels.session ? panels.sessionWrapper : panel;
        return inSideEdge(trigger, x) && withinPanelHeight(trigger, x, y);
    }
    function inTopPanel(panel: Item, x: real, y: real): bool {
        const bounds = panels.exposedRect(panel);
        const trigger = Math.max(Config.border.minThickness, borderThickness);
        return y >= 0 && y < Math.max(trigger, bounds.y + bounds.height) && withinPanelWidth(panel, x, y, bounds);
    }

    function inBottomPanel(panel: Item, x: real, y: real, isCorner = false): bool {
        const bounds = panels.exposedRect(panel);
        const bottom = height;
        // The bottom bar, not the desktop above it, receives the closed trigger.
        const trigger = bar.position === "bottom" ? bar.clampedHeight : Math.max(Config.border.minThickness, borderThickness);
        const edge = bounds.height > 0 ? bounds.y : bottom;
        return y <= bottom && y > Math.min(bottom - trigger, edge) - (isCorner ? Config.border.rounding : 0) && withinPanelWidth(panel, x, y, bounds);
    }

    function inPopouts(x: real, y: real): bool {
        const bounds = panels.popoutsRect;
        if (!popouts.hasCurrent || bounds.width <= 0 || bounds.height <= 0)
            return false;

        const r = Config.border.rounding;
        return x >= bounds.x - r && x <= bounds.x + bounds.width + r && y >= bounds.y - r && y <= bounds.y + bounds.height + r;
    }
    function inDashboardTrigger(x: real, y: real): bool {
        const bounds = panels.dashboardHitRect;
        return x >= bounds.x && x < bounds.x + bounds.width && y >= bounds.y && y < bounds.y + bounds.height;
    }
    function inDashboardArea(x: real, y: real): bool {
        if (!Config.dashboard.enabled)
            return false;
        if (bar.position === "top" && panels.dashboardHitRect.width > 0) {
            if (!inDashboardTrigger(x, y))
                return false;
            if (y < Math.max(Config.border.minThickness, borderThickness))
                return true;
            if (inBarEdge(x, y) && bar.hasNonTitleEntryAt(x))
                return false;
            return (popouts.currentName === "activewindow" && !popouts.isDetached) || !inPopouts(x, y);
        }
        return !inPopouts(x, y) && inTopPanel(panels.dashboard, x, y) && !(bar.position === "bottom" && inUtilitiesArea(x, y));
    }

    function inUtilitiesArea(x: real, y: real): bool {
        // Standalone utilities may be disabled while attached sidebar content
        // or a closing transition still owns its visible input area.
        if (!Config.utilities.enabled && !screenState.sidebar && !panels.utilities.visible)
            return false;
        return bar.position === "bottom" ? inTopPanel(panels.utilities, x, y) : inBottomPanel(panels.utilities, x, y, true);
    }
    function inBarEdge(x: real, y: real, clamped = false): bool {
        const barWidth = clamped ? bar.clampedWidth : bar.implicitWidth;
        const barHeight = clamped ? bar.clampedHeight : bar.implicitHeight;
        return bar.position === "left" ? x < barWidth : bar.position === "right" ? x > width - barWidth : bar.position === "top" ? y < barHeight : y > height - barHeight;
    }
    function onWheel(event: WheelEvent): void {
        if (fullscreen)
            return;
        const pos = bar.position;
        if (pos === "left" && event.x < bar.implicitWidth) {
            bar.handleWheel(event.y, event.angleDelta);
        } else if (pos === "right" && event.x > width - bar.implicitWidth) {
            bar.handleWheel(event.y, event.angleDelta);
        } else if (pos === "top" && event.y < bar.implicitHeight) {
            bar.handleWheel(event.x, event.angleDelta);
        } else if (pos === "bottom" && event.y > height - bar.implicitHeight) {
            bar.handleWheel(event.x, event.angleDelta);
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
            root.panels.osd.hovered = inSidePanel(panels.osd, x, y);
            return;
        }

        // Show bar in non-exclusive mode on hover
        if (!screenState.bar && Config.bar.showOnHover && inBarEdge(x, y, true))
            bar.isHovered = true;

        // Show/hide bar on drag along the edge normal
        if (pressed && inBarEdge(dragStart.x, dragStart.y, true)) {
            const inwardDrag = bar.position === "left" ? dragX : bar.position === "right" ? -dragX : bar.position === "top" ? dragY : -dragY;
            if (inwardDrag > Config.bar.dragThreshold)
                screenState.bar = true;
            else if (inwardDrag < -Config.bar.dragThreshold)
                screenState.bar = false;
        }

        const sideDrag = bar.position === "right" ? dragX : -dragX;

        if (panels.sidebar.offsetScale === 1) {
            // Show osd on hover
            const showOsd = inSidePanel(panels.osd, x, y);

            // Always update visibility based on hover if not in shortcut mode
            if (!osdShortcutActive) {
                screenState.osd = showOsd;
                root.panels.osd.hovered = showOsd;
            } else if (showOsd) {
                // If hovering over OSD area while in shortcut mode, transition to hover control
                osdShortcutActive = false;
                root.panels.osd.hovered = true;
            }

            const showSidebar = pressed && inSideEdge(panels.sidebar, dragStart.x);

            // Show sidebar on hover (top corner, bounded by notification panel height)
            if (Config.sidebar.showOnHover) {
                const sidebarTriggerY = Math.max(Config.sidebar.minHoverThreshold, panels.y + panels.notifications.y + panels.notifications.height);
                const showSidebarHover = !inBarEdge(x, y) && !inPopouts(x, y) && !(bar.position === "bottom" && inUtilitiesArea(x, y)) && inSideEdge(panels.sidebar, x) && y <= sidebarTriggerY;
                if (showSidebarHover && !screenState.sidebar)
                    screenState.sidebar = true;
            }

            // Show/hide session on drag
            if (pressed && inSidePanel(panels.session, dragStart.x, dragStart.y) && withinPanelHeight(panels.session, x, y)) {
                if (sideDrag > Config.session.dragThreshold)
                    screenState.session = true;
                else if (sideDrag < -Config.session.dragThreshold)
                    screenState.session = false;

                // Show sidebar on drag if in session area and session is nearly fully visible
                if (showSidebar && panels.session.offsetScale <= 0 && sideDrag > Config.sidebar.dragThreshold)
                    screenState.sidebar = true;
            } else if (showSidebar && sideDrag > Config.sidebar.dragThreshold) {
                // Show sidebar on drag if not in session area
                screenState.sidebar = true;
            }
        } else {
            const sidebarX = panels.x + panels.sidebar.x;
            const outOfSidebar = bar.position === "right" ? x > sidebarX + panels.sidebar.width : x < sidebarX;
            // Show osd on hover
            const showOsd = outOfSidebar && inSidePanel(panels.osd, x, y);

            // Always update visibility based on hover if not in shortcut mode
            if (!osdShortcutActive) {
                screenState.osd = showOsd;
                root.panels.osd.hovered = showOsd;
            } else if (showOsd) {
                // If hovering over OSD area while in shortcut mode, transition to hover control
                osdShortcutActive = false;
                root.panels.osd.hovered = true;
            }

            // Show/hide session on drag
            if (pressed && outOfSidebar && inSidePanel(panels.session, dragStart.x, dragStart.y) && withinPanelHeight(panels.session, x, y)) {
                if (sideDrag > Config.session.dragThreshold)
                    screenState.session = true;
                else if (sideDrag < -Config.session.dragThreshold)
                    screenState.session = false;
            }

            // Show/hide sidebar on hover
            if (Config.sidebar.showOnHover && !pressed) {
                const sidebarTriggerY = Math.max(Config.sidebar.minHoverThreshold, panels.y + panels.notifications.y + panels.notifications.height);
                const showSidebarHover = !inBarEdge(x, y) && !inPopouts(x, y) && !(bar.position === "bottom" && inUtilitiesArea(x, y)) && inSideEdge(panels.sidebar, x) && y <= sidebarTriggerY;
                if (showSidebarHover && !screenState.sidebar) {
                    screenState.sidebar = true;
                } else {
                    const inSidebarArea = inSidePanel(panels.sidebar, x, y) || inSidePanel(panels.session, x, y) || (bar.position === "bottom" && inUtilitiesArea(x, y));
                    if (!inSidebarArea)
                        screenState.sidebar = false;
                }
            }

            // Hide sidebar on drag
            if (pressed && inSideEdge(panels.sidebar, dragStart.x) && sideDrag < -Config.sidebar.dragThreshold)
                screenState.sidebar = false;
        }

        // Show launcher on hover, or show/hide on drag if hover is disabled
        if (Config.launcher.showOnHover) {
            if (!screenState.launcher && !inPopouts(x, y) && inBottomPanel(panels.launcher, x, y))
                screenState.launcher = true;
        } else if (pressed && inBottomPanel(panels.launcher, dragStart.x, dragStart.y) && withinPanelWidth(panels.launcher, x, y)) {
            if (dragY < -Config.launcher.dragThreshold)
                screenState.launcher = true;
            else if (dragY > Config.launcher.dragThreshold)
                screenState.launcher = false;
        }

        // Show dashboard on hover
        const showDashboard = Config.dashboard.showOnHover && inDashboardArea(x, y);

        // Always update visibility based on hover if not in shortcut mode
        if (!dashboardShortcutActive) {
            screenState.dashboard = showDashboard;
        } else if (showDashboard) {
            // If hovering over dashboard area while in shortcut mode, transition to hover control
            dashboardShortcutActive = false;
        }

        // Show/hide dashboard on drag (for touchscreen devices)
        if (pressed && inDashboardArea(dragStart.x, dragStart.y) && !inPopouts(x, y) && withinPanelWidth(panels.dashboard, x, y)) {
            if (dragY > Config.dashboard.dragThreshold)
                screenState.dashboard = true;
            else if (dragY < -Config.dashboard.dragThreshold)
                screenState.dashboard = false;
        }

        // Show utilities on hover
        const showUtilities = !inPopouts(x, y) && inUtilitiesArea(x, y);

        // Always update visibility based on hover if not in shortcut mode
        if (!utilitiesShortcutActive) {
            screenState.utilities = showUtilities;
        } else if (showUtilities) {
            // If hovering over utilities area while in shortcut mode, transition to hover control
            utilitiesShortcutActive = false;
        }

        // On a bottom bar, utilities open from the opposite (top) edge.
        if (bar.position === "bottom" && pressed && !inPopouts(dragStart.x, dragStart.y) && inUtilitiesArea(dragStart.x, dragStart.y) && withinPanelWidth(panels.utilities, x, y)) {
            if (dragY > Config.bar.dragThreshold)
                screenState.utilities = true;
            else if (dragY < -Config.bar.dragThreshold)
                screenState.utilities = false;
        }

        // Show popouts on hover
        const inBar = inBarEdge(x, y);
        const inDashboard = inDashboardTrigger(x, y);

        if (inDashboard && popouts.currentName === "activewindow")
            popouts.hasCurrent = false;

        // Below the edge trigger, non-title entries keep their normal hover routing.
        // Bar's title span excludes this region, so it cannot reopen the preview.
        if (inBar && (!inDashboard || y >= Math.max(Config.border.minThickness, borderThickness))) {
            bar.checkPopout(BarPosition.isHorizontal(bar.position) ? x : y);
        } else if (!inDashboard && (!popouts.currentName.startsWith("traymenu") || ((popouts.current as StackView)?.depth ?? 0) <= 1) && !inPopouts(x, y)) {
            popouts.hasCurrent = false;
            bar.closeTray();
        }
    }

    // Monitor individual visibility changes
    Connections {
        function onLauncherChanged() {
            // An ordinary launcher dismissal also releases its companions.
            // Collision arbitration dismisses only the conflicting panel.
            if (!root.screenState.launcher && !root.panels.closingLauncherForCollision) {
                root.dashboardShortcutActive = false;
                root.osdShortcutActive = false;
                root.utilitiesShortcutActive = false;

                // Also hide dashboard and OSD if they're not being hovered
                const inDashboardArea = root.inDashboardArea(root.mouseX, root.mouseY);
                const inOsdArea = root.inSidePanel(root.panels.osd, root.mouseX, root.mouseY);

                if (!inDashboardArea) {
                    root.screenState.dashboard = false;
                }
                if (!inOsdArea) {
                    root.screenState.osd = false;
                    root.panels.osd.hovered = false;
                }
            }
        }

        function onDashboardChanged() {
            if (root.screenState.dashboard) {
                // Dashboard became visible, immediately check if this should be shortcut mode
                const inDashboardArea = root.inDashboardArea(root.mouseX, root.mouseY);
                if (!inDashboardArea) {
                    root.dashboardShortcutActive = true;
                }
            } else {
                // Dashboard hidden, clear shortcut flag
                root.dashboardShortcutActive = false;
            }
        }

        function onOsdChanged() {
            if (root.screenState.osd) {
                // OSD became visible, immediately check if this should be shortcut mode
                const inOsdArea = root.inSidePanel(root.panels.osd, root.mouseX, root.mouseY);
                if (!inOsdArea) {
                    root.osdShortcutActive = true;
                }
            } else {
                // OSD hidden, clear shortcut flag
                root.osdShortcutActive = false;
            }
        }

        function onUtilitiesChanged() {
            if (root.screenState.utilities) {
                // Utilities became visible, immediately check if this should be shortcut mode
                if (!root.inUtilitiesArea(root.mouseX, root.mouseY)) {
                    root.utilitiesShortcutActive = true;
                }
            } else {
                // Utilities hidden, clear shortcut flag
                root.utilitiesShortcutActive = false;
            }
        }

        target: root.screenState
    }
}
