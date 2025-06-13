import "root:/services"
import "root:/config"
import "root:/modules/bar/popouts" as BarPopouts
import "root:/modules/osd" as Osd
import Quickshell
import QtQuick

MouseArea {
    id: root

    required property ShellScreen screen
    required property BarPopouts.Wrapper popouts
    required property PersistentProperties visibilities
    required property Panels panels
    required property Item bar

    property bool osdHovered
    property point dragStart
    property bool dashboardShortcutActive
    property bool osdShortcutActive

    function withinPanelHeight(panel: Item, x: real, y: real): bool {
        const panelY = BorderConfig.thickness + panel.y;
        return y >= panelY - BorderConfig.rounding && y <= panelY + panel.height + BorderConfig.rounding;
    }

    function inRightPanel(panel: Item, x: real, y: real): bool {
        return x > bar.implicitWidth + panel.x && withinPanelHeight(panel, x, y);
    }

    function inTopPanel(panel: Item, x: real, y: real): bool {
        const panelX = bar.implicitWidth + panel.x;
        return y < BorderConfig.thickness + panel.y + panel.height && x >= panelX - BorderConfig.rounding && x <= panelX + panel.width + BorderConfig.rounding;
    }

    anchors.fill: parent
    hoverEnabled: true

    onPressed: event => dragStart = Qt.point(event.x, event.y)
    onContainsMouseChanged: {
        if (!containsMouse) {
            // Only hide if not activated by shortcut
            if (!osdShortcutActive) {
                visibilities.osd = false;
                osdHovered = false;
            }
            if (!dashboardShortcutActive) {
                visibilities.dashboard = false;
            }
            popouts.hasCurrent = false;
        }
    }

    onPositionChanged: ({x, y}) => {
        // Show osd on hover
        const showOsd = inRightPanel(panels.osd, x, y);

        // Always update visibility based on hover if not in shortcut mode
        if (!osdShortcutActive) {
            visibilities.osd = showOsd;
            osdHovered = showOsd;
        } else if (showOsd) {
            // If hovering over OSD area while in shortcut mode, transition to hover control
            osdShortcutActive = false;
            osdHovered = true;
        }

        // Show/hide session on drag
        if (pressed && withinPanelHeight(panels.session, x, y)) {
            const dragX = x - dragStart.x;
            if (dragX < -SessionConfig.dragThreshold)
                visibilities.session = true;
            else if (dragX > SessionConfig.dragThreshold)
                visibilities.session = false;
        }

        // Show dashboard on hover
        const showDashboard = inTopPanel(panels.dashboard, x, y);

        // Always update visibility based on hover if not in shortcut mode
        if (!dashboardShortcutActive) {
            visibilities.dashboard = showDashboard;
        } else if (showDashboard) {
            // If hovering over dashboard area while in shortcut mode, transition to hover control
            dashboardShortcutActive = false;
        }

        // Show popouts on hover
        const popout = panels.popouts;
        if (x < bar.implicitWidth + popout.width) {
            if (x < bar.implicitWidth)
                // Handle like part of bar
                bar.checkPopout(y);
            else
                // Keep on hover
                popouts.hasCurrent = withinPanelHeight(popout, x, y);
        } else
            popouts.hasCurrent = false;
    }

    // Monitor individual visibility changes
    Connections {
        target: root.visibilities

        function onLauncherChanged() {
            // If launcher is hidden, clear shortcut flags for dashboard and OSD
            if (!root.visibilities.launcher) {
                root.dashboardShortcutActive = false;
                root.osdShortcutActive = false;

                // Also hide dashboard and OSD if they're not being hovered
                const inDashboardArea = root.inTopPanel(root.panels.dashboard, root.mouseX, root.mouseY);
                const inOsdArea = root.inRightPanel(root.panels.osd, root.mouseX, root.mouseY);

                if (!inDashboardArea) {
                    root.visibilities.dashboard = false;
                }
                if (!inOsdArea) {
                    root.visibilities.osd = false;
                    root.osdHovered = false;
                }
            }
        }

        function onDashboardChanged() {
            if (root.visibilities.dashboard) {
                // Dashboard became visible, immediately check if this should be shortcut mode
                const inDashboardArea = root.inTopPanel(root.panels.dashboard, root.mouseX, root.mouseY);
                if (!inDashboardArea) {
                    root.dashboardShortcutActive = true;
                }
            } else {
                // Dashboard hidden, clear shortcut flag
                root.dashboardShortcutActive = false;
            }
        }

        function onOsdChanged() {
            if (root.visibilities.osd) {
                // OSD became visible, immediately check if this should be shortcut mode
                const inOsdArea = root.inRightPanel(root.panels.osd, root.mouseX, root.mouseY);
                if (!inOsdArea) {
                    root.osdShortcutActive = true;
                }
            } else {
                // OSD hidden, clear shortcut flag
                root.osdShortcutActive = false;
            }
        }
    }

    Osd.Interactions {
        screen: root.screen
        visibilities: root.visibilities
        hovered: root.osdHovered
    }
}
