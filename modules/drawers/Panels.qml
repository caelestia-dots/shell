import qs.config
import qs.modules.osd as Osd
import qs.modules.notifications as Notifications
import qs.modules.session as Session
import qs.modules.launcher as Launcher
import qs.modules.launcher.items.contextmenu as LauncherItems
import qs.modules.dashboard as Dashboard
import qs.modules.bar.popouts as BarPopouts
import qs.modules.utilities as Utilities
import qs.modules.utilities.toasts as Toasts
import qs.modules.sidebar as Sidebar
import Quickshell
import QtQuick

Item {
    id: root
    
    required property ShellScreen screen
    required property PersistentProperties visibilities
    required property Item bar

    readonly property alias osd: osd
    readonly property alias notifications: notifications
    readonly property alias session: session
    readonly property alias launcher: launcher
    readonly property alias dashboard: dashboard
    readonly property alias popouts: popouts
    readonly property alias utilities: utilities
    readonly property alias toasts: toasts
    readonly property alias sidebar: sidebar

    anchors.fill: parent
    anchors.margins: Config.border.thickness
    anchors.leftMargin: bar.implicitWidth

    Osd.Wrapper {
        id: osd

        clip: session.width > 0 || sidebar.width > 0
        screen: root.screen
        visibilities: root.visibilities

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: session.width + sidebar.width
    }

    Notifications.Wrapper {
        id: notifications

        visibilities: root.visibilities
        panels: root

        anchors.top: parent.top
        anchors.right: parent.right
    }

    Session.Wrapper {
        id: session

        clip: sidebar.width > 0
        visibilities: root.visibilities
        panels: root

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: sidebar.width
    }

    Launcher.Wrapper {
        id: launcher

        screen: root.screen
        visibilities: root.visibilities
        panels: root

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        

        onRequestShowContextMenu: (app, clickX, clickY) => {
            // Map coordinates from launcher to panels
            const panelsPos = launcher.mapToItem(root, clickX, clickY);
            launcherContextMenu.showAt(app, panelsPos.x, panelsPos.y, launcher);
        }
        
        onContextMenuClosed: launcher.restoreFocus()
        
        onVisibleChanged: {
            if (!visible && launcherContextMenu.visible) {
                launcherContextMenu.hide();
            }
        }
    }
    
    LauncherItems.ContextMenu {
        id: launcherContextMenu
        
        property real menuX: -10000
        property real menuY: -10000
        
        x: menuX
        y: menuY
        z: 10000
        visible: false
        enabled: visible
        visibilities: root.visibilities
        
        onVisibleChanged: {
            if (!visible) {
                menuX = -10000;
                menuY = -10000;
            }
        }
        
        function showAt(app: var, x: real, y: real, launcherWrapper: var): void {
            if (launcherContextMenu.visible) {
                launcherContextMenu.toggle();
                return;
            }
            
            launcherContextMenu.app = app;
            
            const menuWidth = 250;
            const menuHeight = Math.max(launcherContextMenu.implicitHeight || 300, 100);
            const padding = 16;
            const spacing = 4;
            
            // Position left-aligned at cursor
            let posX = Math.max(padding, Math.min(x, root.width - menuWidth - padding));
            
            if (menuWidth + padding * 2 > root.width) {
                launcherContextMenu.menuX = padding;
                launcherContextMenu.width = root.width - padding * 2;
            } else {
                launcherContextMenu.menuX = posX;
                launcherContextMenu.width = menuWidth;
            }
            
            // Check if there's enough space below for the menu
            const spaceBelow = root.height - y;
            
            if (spaceBelow >= menuHeight + spacing) {
                // Enough space below - show below
                launcherContextMenu.menuY = y + spacing;
                launcherContextMenu.showAbove = false;
            } else {
                // Not enough space below - show above
                launcherContextMenu.menuY = Math.max(0, y - menuHeight - spacing);
                launcherContextMenu.showAbove = true;
            }
            
            launcherContextMenu.toggle();
        }
        
        onClosed: launcher.contextMenuClosed()
    }

    Dashboard.Wrapper {
        id: dashboard

        visibilities: root.visibilities

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
    }

    BarPopouts.Wrapper {
        id: popouts

        screen: root.screen

        x: isDetached ? (root.width - nonAnimWidth) / 2 : 0
        y: {
            if (isDetached)
                return (root.height - nonAnimHeight) / 2;

            const off = currentCenter - Config.border.thickness - nonAnimHeight / 2;
            const diff = root.height - Math.floor(off + nonAnimHeight);
            if (diff < 0)
                return off + diff;
            return Math.max(off, 0);
        }
    }

    Utilities.Wrapper {
        id: utilities

        visibilities: root.visibilities
        sidebar: sidebar
        popouts: popouts

        anchors.bottom: parent.bottom
        anchors.right: parent.right
    }

    Toasts.Toasts {
        id: toasts

        anchors.bottom: sidebar.visible ? parent.bottom : utilities.top
        anchors.right: sidebar.left
        anchors.margins: Appearance.padding.normal
    }

    Sidebar.Wrapper {
        id: sidebar

        visibilities: root.visibilities
        panels: root

        anchors.top: notifications.bottom
        anchors.bottom: utilities.top
        anchors.right: parent.right
    }
}
