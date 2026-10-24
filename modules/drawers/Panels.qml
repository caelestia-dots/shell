import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.modules.bar as Bar
import qs.modules.dashboard as Dashboard
import qs.modules.launcher as Launcher
import qs.modules.notifications as Notifications
import qs.modules.osd as Osd
import qs.modules.session as Session
import qs.modules.sidebar as Sidebar
import qs.modules.utilities as Utilities
import qs.modules.bar.popouts as BarPopouts
import qs.modules.utilities.toasts as Toasts

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property Bar.BarWrapper bar
    required property real borderThickness

    readonly property alias osd: osd
    readonly property alias osdWrapper: osdWrapper
    readonly property alias notifications: notifications
    readonly property alias session: session
    readonly property alias sessionWrapper: sessionWrapper
    readonly property alias launcher: launcher
    readonly property alias dashboard: dashboard
    readonly property alias popouts: popoutsWrapper.content
    readonly property alias popoutsWrapper: popoutsWrapper
    readonly property alias utilities: utilities
    readonly property alias toasts: toasts
    readonly property alias sidebar: sidebar

    // The LayoutManager is a singleton but this object is instantiated once per
    // screen, so every registry key has to be scoped by screen name.
    readonly property var panelKeys: ({
            dashboard: LayoutManager.panelKey(screen.name, "dashboard"),
            launcher: LayoutManager.panelKey(screen.name, "launcher"),
            session: LayoutManager.panelKey(screen.name, "session"),
            osd: LayoutManager.panelKey(screen.name, "osd"),
            notifications: LayoutManager.panelKey(screen.name, "notifications"),
            sidebar: LayoutManager.panelKey(screen.name, "sidebar"),
            utilities: LayoutManager.panelKey(screen.name, "utilities"),
            popouts: LayoutManager.panelKey(screen.name, "popouts"),
            toasts: LayoutManager.panelKey(screen.name, "toasts")
        })

    // Register all panels with LayoutManager on component completion.
    //
    // The edges tell the manager which way each panel is allowed to be nudged, and
    // have to match the anchors each panel actually declares. Panels that are
    // positioned relative to another panel rather than to a screen edge (toasts
    // follow the sidebar, popouts float) are registered as "none" and take part as
    // blockers only. The bar is left out on purpose: it owns an exclusive zone
    // derived from its own width, which a cap would invalidate.
    Component.onCompleted: {
        LayoutManager.registerPanel(panelKeys.dashboard, dashboard, LayoutManager.priorityHigh, "none", "top");
        LayoutManager.registerPanel(panelKeys.launcher, launcher, LayoutManager.priorityHigh, "none", "bottom");
        LayoutManager.registerPanel(panelKeys.osd, osd, LayoutManager.priorityHigh, "right", "none");
        LayoutManager.registerPanel(panelKeys.session, session, LayoutManager.priorityHigh, "right", "none");
        LayoutManager.registerPanel(panelKeys.notifications, notifications, LayoutManager.priorityMedium, "right", "top");
        LayoutManager.registerPanel(panelKeys.sidebar, sidebar, LayoutManager.priorityMedium, "right", "none");
        LayoutManager.registerPanel(panelKeys.utilities, utilities, LayoutManager.priorityMedium, "none", "bottom");
        LayoutManager.registerPanel(panelKeys.popouts, popoutsWrapper, LayoutManager.priorityLow, "none", "none");
        LayoutManager.registerPanel(panelKeys.toasts, toasts, LayoutManager.priorityMedium, "none", "none");

        LayoutManager.requestLayoutUpdate();
    }

    // Trigger layout recalculation when panel visibility/size changes
    anchors.fill: parent
    anchors.margins: borderThickness
    anchors.leftMargin: bar.implicitWidth

    // Cleanup on destruction
    Component.onDestruction: {
        for (const key in panelKeys)
            LayoutManager.unregisterPanel(panelKeys[key]);
    }

    // Trigger layout recalculation when panel visibility/size changes
    Connections {
        function onOffsetScaleChanged() {
            LayoutManager.requestLayoutUpdate();
        }

        // Cycling tabs resizes the dashboard: every tab has its own width and
        // height, and both are animated. Watching the geometry rather than the tab
        // itself means a pass runs for each frame of the transition, so panels
        // measured against the dashboard follow it the whole way instead of
        // settling on the old size.
        function onWidthChanged() {
            LayoutManager.requestLayoutUpdate();
        }

        function onHeightChanged() {
            LayoutManager.requestLayoutUpdate();
        }

        target: dashboard
    }

    Connections {
        function onOffsetScaleChanged() {
            LayoutManager.requestLayoutUpdate();
        }

        target: launcher
    }

    Connections {
        function onOffsetScaleChanged() {
            LayoutManager.requestLayoutUpdate();
        }

        target: session
    }

    Connections {
        function onOffsetScaleChanged() {
            LayoutManager.requestLayoutUpdate();
        }

        target: osd
    }

    Connections {
        function onVisibleChanged() {
            LayoutManager.requestLayoutUpdate();
        }

        // The sidebar is anchored to the bottom of the notifications panel, so a
        // notification arriving or expiring moves the sidebar without changing
        // anything the manager would otherwise be notified about. That is enough
        // to start a new overlap on its own.
        function onHeightChanged() {
            LayoutManager.requestLayoutUpdate();
        }

        target: notifications
    }

    Connections {
        function onOffsetScaleChanged() {
            LayoutManager.requestLayoutUpdate();
        }

        target: sidebar
    }

    Connections {
        function onOffsetScaleChanged() {
            LayoutManager.requestLayoutUpdate();
        }

        target: utilities
    }

    Connections {
        function onOffsetScaleChanged() {
            LayoutManager.requestLayoutUpdate();
        }

        target: popoutsWrapper
    }

    Connections {
        function onGeometryChanged() {
            LayoutManager.requestLayoutUpdate();
        }

        target: root.screen
    }

    Item {
        id: osdWrapper

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: sessionWrapper.anchors.rightMargin + session.width * (1 - session.offsetScale)
        clip: sidebar.visible || session.visible

        implicitWidth: osd.implicitWidth * (1 - osd.offsetScale)
        implicitHeight: osd.implicitHeight

        Osd.Wrapper {
            id: osd

            screen: root.screen
            screenState: root.screenState
            sidebarOrSessionVisible: sidebar.visible || session.visible

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
        }
    }

    Notifications.Wrapper {
        id: notifications

        screenState: root.screenState
        sidebarPanel: sidebar
        osdPanel: osdWrapper
        sessionPanel: sessionWrapper
        utilitiesPanel: utilities

        anchors.top: parent.top
        anchors.right: parent.right
    }

    Item {
        id: sessionWrapper

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: sidebar.width * (1 - sidebar.offsetScale)
        clip: sidebar.visible

        implicitWidth: session.implicitWidth * (1 - session.offsetScale)
        implicitHeight: session.implicitHeight

        Session.Wrapper {
            id: session

            screenState: root.screenState
            sidebarVisible: sidebar.visible

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
        }
    }

    Launcher.Wrapper {
        id: launcher

        screen: root.screen
        screenState: root.screenState
        panels: root

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
    }

    Dashboard.Wrapper {
        id: dashboard

        screenState: root.screenState

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
    }

    BarPopouts.ClipWrapper {
        id: popoutsWrapper

        screen: root.screen
        borderThickness: root.borderThickness
    }

    Utilities.Wrapper {
        id: utilities

        screenState: root.screenState
        sidebar: sidebar
        popouts: popoutsWrapper.content

        anchors.bottom: parent.bottom
        anchors.right: parent.right
    }

    Toasts.Toasts {
        id: toasts

        anchors.bottom: sidebar.visible ? parent.bottom : utilities.top
        anchors.right: sidebar.left
        anchors.margins: Tokens.padding.medium
    }

    Sidebar.Wrapper {
        id: sidebar

        screenState: root.screenState

        anchors.top: notifications.bottom
        anchors.bottom: utilities.top
        anchors.right: parent.right
        anchors.topMargin: -notifications.anchors.topMargin
    }
}
