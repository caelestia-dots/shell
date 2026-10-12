import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.utils
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

    readonly property string barPos: bar.position
    readonly property bool barOnRight: BarPosition.isRight(barPos)
    readonly property bool barOnTop: BarPosition.isTop(barPos)
    readonly property bool barOnBottom: BarPosition.isBottom(barPos)
    readonly property bool barOnLeft: BarPosition.isLeft(barPos)

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

    readonly property rect dashboardRect: exposedRect(dashboard)
    readonly property rect launcherRect: exposedRect(launcher)
    readonly property rect utilitiesRect: exposedRect(utilities)
    readonly property rect sidebarRect: exposedRect(sidebar)
    readonly property rect popoutsRect: exposedRect(popoutsWrapper)
    readonly property rect osdRect: exposedRect(osd)
    readonly property rect sessionRect: exposedRect(session)
    readonly property rect notificationsRect: exposedRect(notifications)

    // One window-coordinate ownership region for the top-bar title and dashboard.
    // Keep it through the full bar depth and any currently exposed dashboard body.
    readonly property rect dashboardHitRect: {
        if (!barOnTop || bar.disabled || bar.fullscreen || !Config.dashboard.enabled)
            return Qt.rect(0, 0, 0, 0);

        const bounds = dashboard.visible ? dashboardRect : panelGeometry(dashboard);
        const rounding = Config.border.rounding;
        return Qt.rect(bounds.x - rounding, 0, bounds.width + rounding * 2, Math.max(Config.border.minThickness, borderThickness, bar.implicitHeight, dashboard.visible ? bounds.y + bounds.height : 0));
    }
    property Matrix4x4 dashboardTransform
    property Matrix4x4 launcherTransform
    property Matrix4x4 sessionTransform
    property Matrix4x4 sidebarTransform
    property Matrix4x4 osdTransform
    property Matrix4x4 notificationsTransform
    property Matrix4x4 utilitiesTransform
    property bool dashboardOpenedLast: false
    property bool launcherOpenedLast: false
    property bool closingLauncherForCollision: false

    // All rectangles are in the containing window's coordinate space. The side
    // drawers have one positioning wrapper; its child carries the slide offset.
    function panelGeometry(panel: Item): rect {
        const nested = panel.parent !== root;
        return Qt.rect(root.x + panel.x + (nested ? panel.parent.x : 0), root.y + panel.y + (nested ? panel.parent.y : 0), panel.width, panel.height);
    }

    function intersect(a: rect, b: rect): rect {
        const left = Math.max(a.x, b.x);
        const top = Math.max(a.y, b.y);
        return Qt.rect(left, top, Math.max(0, Math.min(a.x + a.width, b.x + b.width) - left), Math.max(0, Math.min(a.y + a.height, b.y + b.height) - top));
    }

    function overlaps(a: rect, b: rect): bool {
        return a.width > 0 && a.height > 0 && b.width > 0 && b.height > 0 && a.x < b.x + b.width && b.x < a.x + a.width && a.y < b.y + b.height && b.y < a.y + a.height;
    }

    function exposedRect(panel: Item): rect {
        if (!panel.visible)
            return Qt.rect(0, 0, 0, 0);

        const geometry = panelGeometry(panel);
        // Reading the matrix makes deformation changes invalidate this binding;
        // mapToItem also includes the actual slide and parent coordinates.
        const transform = panel === dashboard ? dashboardTransform : panel === launcher ? launcherTransform : panel === session ? sessionTransform : panel === sidebar ? sidebarTransform : panel === osd ? osdTransform : panel === notifications ? notificationsTransform : panel === utilities ? utilitiesTransform : null;
        const matrix = transform?.matrix;
        let bounds = matrix ? panel.mapToItem(root.parent, Qt.rect(0, 0, geometry.width, geometry.height)) : geometry;
        if (panel.parent !== root && panel.parent.clip)
            bounds = intersect(bounds, panelGeometry(panel.parent));
        return intersect(bounds, Qt.rect(0, 0, root.parent.width, root.parent.height));
    }

    function resolveCollisions(): void {
        if (barOnTop && dashboard.visible && Config.dashboard.enabled && !bar.disabled && !bar.fullscreen && popouts.hasCurrent && !popouts.isDetached && popouts.currentName === "activewindow" && overlaps(dashboardRect, popoutsRect))
            popouts.hasCurrent = false;

        if (dashboard.shouldBeActive && utilities.shouldBeActive && overlaps(dashboardRect, utilitiesRect)) {
            if (dashboardOpenedLast) {
                screenState.utilities = false;
                // Attached Utilities belong to the open sidebar.
                screenState.sidebar = false;
            } else {
                screenState.dashboard = false;
            }
        }
        if (launcher.shouldBeActive && (popouts.hasCurrent || popouts.isDetached) && overlaps(launcherRect, popoutsRect)) {
            if (launcherOpenedLast) {
                popouts.close();
            } else {
                // Only the conflicting launcher is dismissed; this is not a
                // user request to close its shortcut/showall companions.
                closingLauncherForCollision = true;
                screenState.launcher = false;
                closingLauncherForCollision = false;
            }
        }
    }

    onDashboardRectChanged: Qt.callLater(resolveCollisions)
    onUtilitiesRectChanged: Qt.callLater(resolveCollisions)
    onLauncherRectChanged: Qt.callLater(resolveCollisions)
    onPopoutsRectChanged: Qt.callLater(resolveCollisions)

    anchors.fill: parent
    anchors.margins: borderThickness
    anchors.leftMargin: barOnLeft ? bar.implicitWidth : borderThickness
    anchors.rightMargin: barOnRight ? bar.implicitWidth : borderThickness
    anchors.topMargin: barOnTop ? bar.implicitHeight : borderThickness
    anchors.bottomMargin: barOnBottom ? bar.implicitHeight : borderThickness

    Connections {
        function onHasCurrentChanged(): void {
            if (root.popouts.hasCurrent) {
                root.launcherOpenedLast = false;
                Qt.callLater(root.resolveCollisions);
            }
        }

        function onCurrentNameChanged(): void {
            if (root.popouts.hasCurrent) {
                root.launcherOpenedLast = false;
                Qt.callLater(root.resolveCollisions);
            }
        }

        function onIsDetachedChanged(): void {
            if (root.popouts.isDetached) {
                root.launcherOpenedLast = false;
                Qt.callLater(root.resolveCollisions);
            }
        }

        target: root.popouts
    }

    // Mirrored panels use x instead of switching anchors, which can stretch their backgrounds on live edge changes.
    Item {
        id: osdWrapper

        readonly property real sideOffset: sessionWrapper.sideOffset + session.width * (1 - session.offsetScale)

        anchors.verticalCenter: parent.verticalCenter
        x: root.barOnRight ? sideOffset : parent.width - width - sideOffset
        clip: sidebar.visible || session.visible

        implicitWidth: osd.implicitWidth * (1 - osd.offsetScale)
        implicitHeight: osd.implicitHeight

        Osd.Wrapper {
            id: osd

            screen: root.screen
            screenState: root.screenState
            sidebarOrSessionVisible: sidebar.visible || session.visible

            anchors.verticalCenter: parent.verticalCenter
            x: root.barOnRight ? slideOffset : parent.width - width - slideOffset
        }
    }

    Notifications.Wrapper {
        id: notifications

        screenState: root.screenState
        sidebarPanel: sidebar
        osdPanel: osdWrapper
        sessionPanel: sessionWrapper
        utilitiesPanel: utilities
        utilitiesOnTop: root.barOnBottom
        mirrored: root.barOnRight

        anchors.top: root.barOnBottom ? utilities.bottom : parent.top
        anchors.topMargin: -5
        x: root.barOnRight ? 0 : parent.width - width
    }

    Item {
        id: sessionWrapper

        readonly property real sideOffset: sidebar.width * (1 - sidebar.offsetScale)

        anchors.verticalCenter: parent.verticalCenter
        x: root.barOnRight ? sideOffset : parent.width - width - sideOffset
        clip: sidebar.visible

        implicitWidth: session.implicitWidth * (1 - session.offsetScale)
        implicitHeight: session.implicitHeight

        Session.Wrapper {
            id: session

            screenState: root.screenState
            sidebarVisible: sidebar.visible
            mirrored: root.barOnRight

            anchors.verticalCenter: parent.verticalCenter
            x: root.barOnRight ? slideOffset : parent.width - width - slideOffset
        }
    }

    Launcher.Wrapper {
        id: launcher

        screenState: root.screenState
        panels: root

        onShouldBeActiveChanged: {
            if (shouldBeActive) {
                root.launcherOpenedLast = true;
                Qt.callLater(root.resolveCollisions);
            }
        }

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
    }

    Dashboard.Wrapper {
        id: dashboard

        screenState: root.screenState

        onShouldBeActiveChanged: {
            if (shouldBeActive) {
                root.dashboardOpenedLast = true;
                Qt.callLater(root.resolveCollisions);
            }
        }

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
    }

    BarPopouts.ClipWrapper {
        id: popoutsWrapper

        screen: root.screen
        borderThickness: root.borderThickness
        position: root.barPos
    }

    Utilities.Wrapper {
        id: utilities

        screenState: root.screenState
        sidebar: sidebar
        popouts: popoutsWrapper.content
        mirrored: root.barOnRight

        onShouldBeActiveChanged: {
            if (shouldBeActive) {
                root.dashboardOpenedLast = false;
                Qt.callLater(root.resolveCollisions);
            }
        }

        onTop: root.barOnBottom
        // Switching opposing anchors can leave a stretched explicit height after a live edge change.
        height: implicitHeight
        y: onTop ? slideOffset : parent.height - height - slideOffset
        x: root.barOnRight ? 0 : parent.width - width
    }

    Toasts.Toasts {
        id: toasts

        anchors.bottom: root.barOnBottom || sidebar.visible ? parent.bottom : utilities.top
        x: root.barOnRight ? sidebar.x + sidebar.width + anchors.margins : sidebar.x - width - anchors.margins
        anchors.margins: Tokens.padding.medium
    }

    Sidebar.Wrapper {
        id: sidebar

        screenState: root.screenState
        mirrored: root.barOnRight

        anchors.top: notifications.bottom
        anchors.bottom: root.barOnBottom ? parent.bottom : utilities.top
        x: root.barOnRight ? slideOffset : parent.width - width - slideOffset
        anchors.topMargin: root.barOnBottom ? Math.min(-notifications.anchors.topMargin, parent.height - notifications.y - notifications.height) : -notifications.anchors.topMargin
    }
}
