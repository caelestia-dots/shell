pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Caelestia.Blobs
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services
import qs.utils
import qs.modules.bar

StyledWindow {
    id: root

    readonly property alias bar: bar
    readonly property alias interactionWrapper: interactions

    readonly property ScreenState screenState: ShellState.forScreen(screen)

    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)
    readonly property bool hasSpecialWorkspace: (monitor?.lastIpcObject.specialWorkspace?.name.length ?? 0) > 0
    readonly property bool hasFullscreenOnNormalWs: monitor?.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false
    readonly property bool hasFullscreen: {
        if (hasSpecialWorkspace) {
            const specialName = monitor?.lastIpcObject.specialWorkspace?.name;
            if (!specialName)
                return false;
            const specialWs = Hypr.workspaces.values.find(ws => ws.name === specialName);
            return specialWs?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false;
        }
        return hasFullscreenOnNormalWs;
    }

    property real fsTransitionProg: hasFullscreen ? 1 : 0
    readonly property real sdfBorderOffset: 2 * fsTransitionProg // SDFs joins are not exact, so offset by 2px to ensure nothing shows
    readonly property real borderThickness: contentItem.Config.border.thickness * (1 - fsTransitionProg)
    readonly property real borderRounding: contentItem.Config.border.rounding * (1 - fsTransitionProg)
    readonly property real shadowOpacity: 0.7 * (1 - fsTransitionProg)
    readonly property real borderLayoutThickness: hasFullscreen ? 0 : contentItem.Config.border.thickness

    property color surfaceColour: Colours.tPalette.m3surface

    readonly property int dragMaskPadding: {
        if (focusGrab.active || panels.popouts.isDetached)
            return 0;

        if (monitor?.lastIpcObject.specialWorkspace?.name || monitor?.activeWorkspace?.lastIpcObject.windows > 0)
            return 0;

        const thresholds = [];
        for (const panel of ["dashboard", "launcher", "session", "sidebar"])
            if (contentItem.Config[panel].enabled)
                thresholds.push(contentItem.Config[panel].dragThreshold);
        return thresholds.length ? Math.max(...thresholds) : 0;
    }

    onHasFullscreenChanged: {
        screenState.launcher = false;
        screenState.session = false;
        screenState.dashboard = false;
        panels.popouts.close();
    }

    name: "drawers"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: (fsTransitionProg > 0 && contentItem.Config.general.showOverFullscreen) || (hasSpecialWorkspace && hasFullscreenOnNormalWs) ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.keyboardFocus: screenState.launcher || screenState.session ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    mask: hasFullscreen ? emptyRegion : regions

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    Behavior on fsTransitionProg {
        Anim {}
    }

    Behavior on surfaceColour {
        CAnim {}
    }

    Region {
        id: emptyRegion

        readonly property rect bounds: panels.notificationsRect

        x: bounds.x
        y: bounds.y
        width: bounds.width
        height: bounds.height

        Region {
            readonly property rect bounds: panels.osdRect

            x: bounds.x
            y: bounds.y
            width: bounds.width
            height: bounds.height
        }
    }

    Regions {
        id: regions

        bar: bar
        panels: panels
        win: root
    }

    HyprlandFocusGrab {
        id: focusGrab

        active: {
            const s = root.screenState;
            const conf = root.contentItem.Config;
            if ((s.launcher && conf.launcher.enabled) || (s.session && conf.session.enabled) || (s.sidebar && conf.sidebar.enabled))
                return true;
            if (!conf.dashboard.showOnHover && s.dashboard && conf.dashboard.enabled)
                return true;
            if (panels.popouts.currentName.startsWith("traymenu") && (panels.popouts.current as StackView)?.depth > 1)
                return true;
            return false;
        }
        windows: [root]
        onCleared: {
            root.screenState.launcher = false;
            root.screenState.session = false;
            root.screenState.sidebar = false;
            root.screenState.dashboard = false;
            panels.popouts.hasCurrent = false;
            bar.closeTray();
        }
    }

    StyledRect {
        anchors.fill: parent
        opacity: (root.screenState.session && Config.session.enabled) || panels.popouts.detachedMode !== "" ? 0.5 : 0
        color: Colours.palette.m3scrim

        Behavior on opacity {
            Anim {
                type: Anim.SlowEffects
            }
        }
    }

    Item {
        anchors.fill: parent
        opacity: root.surfaceColour.a
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            blurMax: 15
            shadowColor: Qt.alpha(Colours.palette.m3shadow, Math.max(0, root.shadowOpacity))
        }

        BlobGroup {
            id: blobGroup

            color: root.surfaceColour
            smoothing: root.contentItem.Config.border.smoothing
        }

        BlobInvertedRect {
            anchors.fill: parent
            anchors.margins: -50 // Make border thicker to smooth out bulge from closed drawers
            group: blobGroup
            radius: root.borderRounding
            borderLeft: (BarPosition.isLeft(bar.position) ? bar.implicitWidth : root.borderThickness) - anchors.margins - root.sdfBorderOffset
            borderRight: (BarPosition.isRight(bar.position) ? bar.implicitWidth : root.borderThickness) - anchors.margins - root.sdfBorderOffset
            borderTop: (BarPosition.isTop(bar.position) ? bar.implicitHeight : root.borderThickness) - anchors.margins - root.sdfBorderOffset
            borderBottom: (BarPosition.isBottom(bar.position) ? bar.implicitHeight : root.borderThickness) - anchors.margins - root.sdfBorderOffset
        }

        PanelBg {
            id: dashBg

            panel: panels.dashboard
            deformAmount: 0.1
        }

        PanelBg {
            id: launcherBg

            panel: panels.launcher
            deformAmount: 0.1
        }

        PanelBg {
            id: sessionBg

            panel: panels.session
            deformAmount: 0.2
        }

        PanelBg {
            id: sidebarBg

            readonly property real joinRadius: Math.max(0, Math.min(1, panels.sidebar.offsetScale / 0.3)) * radius

            panel: panels.sidebar
            deformAmount: 0.03
            implicitHeight: panel.height * (1 / rawDeformMatrix.m22) + 2
            exclude: panels.sidebar.offsetScale > 0.08 ? [] : [utilsBg]
            topLeftRadius: !panels.barOnRight && panels.barOnBottom ? joinRadius : radius
            bottomLeftRadius: !panels.barOnRight && !panels.barOnBottom ? joinRadius : radius
            topRightRadius: panels.barOnRight && panels.barOnBottom ? joinRadius : radius
            bottomRightRadius: panels.barOnRight && !panels.barOnBottom ? joinRadius : radius
        }

        PanelBg {
            id: osdBg

            panel: panels.osd
            deformAmount: 0.25
        }

        PanelBg {
            id: notifsBg

            panel: panels.notifications
        }

        PanelBg {
            id: utilsBg

            panel: panels.utilities
            deformAmount: panels.sidebar.visible ? 0.1 : 0.15
            exclude: panels.sidebar.offsetScale > 0.08 ? [] : [sidebarBg]
            topLeftRadius: !panels.barOnRight && !panels.barOnBottom ? sidebarBg.joinRadius : radius
            bottomLeftRadius: !panels.barOnRight && panels.barOnBottom ? sidebarBg.joinRadius : radius
            topRightRadius: panels.barOnRight && !panels.barOnBottom ? sidebarBg.joinRadius : radius
            bottomRightRadius: panels.barOnRight && panels.barOnBottom ? sidebarBg.joinRadius : radius
        }

        PanelBg {
            id: popoutBg

            readonly property bool barLeft: BarPosition.isLeft(bar.position)
            readonly property bool barRight: BarPosition.isRight(bar.position)
            readonly property bool barTop: BarPosition.isTop(bar.position)
            readonly property bool barBottom: BarPosition.isBottom(bar.position)
            property real extraScale: panels.popouts.isDetached ? 0 : 0.15

            panel: panels.popoutsWrapper
            deformAmount: panels.popouts.isDetached ? 0.05 : panels.popouts.hasCurrent ? 0.15 : 0.1

            x: geometry.x - (barLeft ? panels.popoutsWrapper.width * extraScale : 0)
            y: geometry.y - (barTop ? panels.popoutsWrapper.height * extraScale : 0)

            implicitWidth: panels.popoutsWrapper.width * (1 + (barLeft || barRight ? extraScale : 0))
            implicitHeight: panels.popoutsWrapper.height * (1 + (barTop || barBottom ? extraScale : 0))

            Behavior on extraScale {
                Anim {}
            }
        }
    }

    Interactions {
        id: interactions

        screen: root.screen
        popouts: panels.popouts
        screenState: root.screenState
        panels: panels
        bar: bar
        borderThickness: root.borderLayoutThickness
        fullscreen: root.hasFullscreen

        Panels {
            id: panels

            screen: root.screen
            screenState: root.screenState
            bar: bar
            borderThickness: root.borderThickness

            dashboardTransform: dashTransform
            launcherTransform: launchTransform
            sessionTransform: sessTransform
            sidebarTransform: sideTransform
            osdTransform: volumeTransform
            notificationsTransform: notifsTransform
            utilitiesTransform: utilsTransform

            utilities.horizontalStretch: (sidebarBg.rawDeformMatrix.m11 - 1) / 2 + 1
            utilities.deformMatrix: utilsBg.rawDeformMatrix

            dashboard.transform: Matrix4x4 {
                id: dashTransform

                matrix: dashBg.deformMatrix
            }
            launcher.transform: Matrix4x4 {
                id: launchTransform

                matrix: launcherBg.deformMatrix
            }
            session.transform: Matrix4x4 {
                id: sessTransform

                matrix: sessionBg.deformMatrix
            }
            sidebar.transform: Matrix4x4 {
                id: sideTransform

                matrix: sidebarBg.deformMatrix
            }
            osd.transform: Matrix4x4 {
                id: volumeTransform

                matrix: osdBg.deformMatrix
            }
            notifications.transform: Matrix4x4 {
                id: notifsTransform

                matrix: notifsBg.deformMatrix
            }
            utilities.transform: Matrix4x4 {
                id: utilsTransform

                matrix: utilsBg.deformMatrix
            }
            popouts.transform: Matrix4x4 {
                matrix: popoutBg.deformMatrix
            }
        }

        BarWrapper {
            id: bar

            // Direct coordinates avoid opposing anchors constraining a live position switch.
            x: BarPosition.isRight(position) ? parent.width - width : 0
            y: BarPosition.isBottom(position) ? parent.height - height : 0
            screen: root.screen
            screenState: root.screenState
            popouts: panels.popouts
            dashboardHitRect: panels.dashboardHitRect

            fullscreen: root.hasFullscreen
        }
    }

    ShellState.ComponentRef {
        screen: root.screen
        slot: "rootWindow"
        component: root
    }

    ShellState.ComponentRef {
        screen: root.screen
        slot: "interactionWrapper"
        component: interactions
    }

    ShellState.ComponentRef {
        screen: root.screen
        slot: "bar"
        component: bar
    }

    ShellState.ComponentRef {
        screen: root.screen
        slot: "panels"
        component: panels
    }

    component PanelBg: BlobRect {
        required property Item panel
        readonly property rect geometry: panels.panelGeometry(panel)
        property real deformAmount: 0.15

        group: blobGroup
        x: geometry.x
        y: geometry.y
        implicitWidth: panel.width
        implicitHeight: panel.height
        radius: Tokens.rounding.extraLarge
        deformScale: (deformAmount * Config.appearance.deformScale) / 10000
    }
}
