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
import qs.modules.bar

StyledWindow {
    id: root

    readonly property alias bar: bar
    readonly property alias interactionWrapper: interactions

    readonly property ScreenState screenState: ShellState.forScreen(screen)

    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)
    readonly property bool hasSpecialWorkspace: (monitor?.lastIpcObject.specialWorkspace?.name.length ?? 0) > 0
    readonly property string barEdge: contentItem.Config.bar.alignment
    readonly property bool isTop: barEdge === "top"
    readonly property bool isBottom: barEdge === "bottom"
    readonly property bool isLeft: barEdge === "left"
    readonly property bool isRight: barEdge === "right"
    readonly property bool isHorizontal: isTop || isBottom
    readonly property real barThickness: isHorizontal ? bar.implicitHeight : bar.implicitWidth

    readonly property real contentOffsetX: isLeft ? barThickness : borderThickness
    readonly property real contentOffsetY: isTop ? barThickness : borderThickness
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
        return Math.max(...thresholds);
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
        x: panels.notifications.x + root.contentOffsetX
        y: panels.notifications.y + root.contentOffsetY
        width: panels.notifications.width
        height: panels.notifications.height

        Region {
            x: panels.osd.x + root.contentOffsetX
            y: panels.osd.y + root.contentOffsetY
            width: panels.osd.width
            height: panels.osd.height
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
            if ((s.launcher && conf.launcher.enabled) || 
                (s.session && conf.session.enabled) || 
                (s.sidebar && conf.sidebar.enabled) ||
                (s.utilities && conf.utilities.enabled))
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
            root.screenState.utilities = false;
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
            borderLeft: root.contentOffsetX - anchors.margins - root.sdfBorderOffset
            borderRight: (root.isRight ? root.barThickness : root.borderThickness) - anchors.margins - root.sdfBorderOffset
            borderTop: root.contentOffsetY - anchors.margins - root.sdfBorderOffset
            borderBottom: (root.isBottom ? root.barThickness : root.borderThickness) - anchors.margins - root.sdfBorderOffset
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
            opacity: 1 - panels.launcher.offsetScale
            implicitWidth: panel.width * (panel.edge === "center" ? (1 - panel.offsetScale) : 1)
            implicitHeight: panel.height * (panel.edge === "center" ? (1 - panel.offsetScale) : 1)
            x: panel.x + root.contentOffsetX + (panel.width - implicitWidth) / 2
            y: panel.y + root.contentOffsetY + (panel.height - implicitHeight) / 2
        }

        PanelBg {
            id: sessionBg

            panel: panels.sessionWrapper
            deformAmount: 0.2
            x: panels.sessionWrapper.x + root.contentOffsetX
            y: panels.sessionWrapper.y + root.contentOffsetY + panels.session.y
            implicitWidth: panels.sessionWrapper.width
            implicitHeight: panels.session.height
        }

        PanelBg {
            id: sidebarBg

            panel: panels.sidebar
            deformAmount: 0.03
            implicitHeight: panel.height * (1 / rawDeformMatrix.m22) + 2
            exclude: panels.sidebar.offsetScale > 0.08 ? [] : [utilsBg]

            property real dynamicRadius: Math.max(0, Math.min(1, panels.sidebar.offsetScale / 0.3)) * radius
            topLeftRadius: (panels.sidebar.docked && panels.sidebar.dockedAbove) ? dynamicRadius : radius
            topRightRadius: (panels.sidebar.docked && panels.sidebar.dockedAbove) ? dynamicRadius : radius
            bottomLeftRadius: (panels.sidebar.docked && !panels.sidebar.dockedAbove) ? dynamicRadius : radius
            bottomRightRadius: (panels.sidebar.docked && !panels.sidebar.dockedAbove) ? dynamicRadius : radius
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

            property real dynamicRadius: Math.max(0, Math.min(1, panels.sidebar.offsetScale / 0.3)) * radius
            topLeftRadius: (panels.sidebar.docked && !panels.sidebar.dockedAbove) ? dynamicRadius : radius
            topRightRadius: (panels.sidebar.docked && !panels.sidebar.dockedAbove) ? dynamicRadius : radius
            bottomLeftRadius: (panels.sidebar.docked && panels.sidebar.dockedAbove) ? dynamicRadius : radius
            bottomRightRadius: (panels.sidebar.docked && panels.sidebar.dockedAbove) ? dynamicRadius : radius
        }

        PanelBg {
            id: popoutBg

            // Extra width to prevent vertical movement deformation partially detaching panel from bar
            property real extra: panels.popouts.isDetached ? 0 : 0.2

            panel: panels.popoutsWrapper
            deformAmount: panels.popouts.isDetached ? 0.05 : panels.popouts.hasCurrent ? 0.15 : 0.1
            x: panels.popoutsWrapper.x + panels.popouts.x + root.contentOffsetX - (root.isLeft ? panels.popouts.width * extra : 0)
            y: panels.popoutsWrapper.y + panels.popouts.y + root.contentOffsetY - (root.isTop ? panels.popouts.height * extra : 0)
            implicitWidth: root.isHorizontal ? panels.popoutsWrapper.width : panels.popouts.width * (1 + extra)
            implicitHeight: root.isHorizontal ? panels.popouts.height * (1 + extra) : panels.popoutsWrapper.height

            Behavior on extra {
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

            utilities.horizontalStretch: (sidebarBg.rawDeformMatrix.m11 - 1) / 2 + 1
            utilities.deformMatrix: utilsBg.rawDeformMatrix

            dashboard.transform: Matrix4x4 {
                matrix: dashBg.deformMatrix
            }
            launcher.transform: Matrix4x4 {
                matrix: launcherBg.deformMatrix
            }
            session.transform: Matrix4x4 {
                matrix: sessionBg.deformMatrix
            }
            sidebar.transform: Matrix4x4 {
                matrix: sidebarBg.deformMatrix
            }
            osd.transform: Matrix4x4 {
                matrix: osdBg.deformMatrix
            }
            notifications.transform: Matrix4x4 {
                matrix: notifsBg.deformMatrix
            }
            utilities.transform: Matrix4x4 {
                matrix: utilsBg.deformMatrix
            }
            popouts.transform: Matrix4x4 {
                matrix: popoutBg.deformMatrix
            }
        }

        BarWrapper {
            id: bar
            x: root.isRight ? parent.width - width : 0
            y: root.isBottom ? parent.height - height : 0
            width: isHorizontal ? parent.width : implicitWidth
            height: isHorizontal ? implicitHeight : parent.height
            screen: root.screen
            screenState: root.screenState
            popouts: panels.popouts

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
        property real deformAmount: 0.15

        group: blobGroup
        
        x: panel ? (panel.x + root.contentOffsetX) : 0
        y: panel ? (panel.y + root.contentOffsetY) : 0
        implicitWidth: panel ? panel.width : 0
        implicitHeight: panel ? panel.height : 0
        
        radius: Tokens.rounding.extraLarge
        deformScale: (deformAmount * Config.appearance.deformScale) / 10000
    }
}
