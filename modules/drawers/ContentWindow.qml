pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Caelestia.Config
import Caelestia.Scheme
import qs.components
import qs.components.containers
import qs.services
import qs.modules.bar

StyledWindow {
    id: root

    readonly property alias bar: bar
    readonly property alias interactionWrapper: interactions
    readonly property alias panelBlobs: blobs

    readonly property ScreenState screenState: ShellState.forScreen(screen)

    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)
    readonly property HyprlandWorkspace specialWs: monitor?.specialWorkspace ?? null
    readonly property bool hasFullscreenOnNormalWs: monitor?.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false
    readonly property bool hasFullscreen: {
        if (specialWs)
            return specialWs.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1);
        return hasFullscreenOnNormalWs;
    }

    property real fsTransitionProg: hasFullscreen ? 1 : 0
    readonly property real sdfBorderOffset: 2 * fsTransitionProg // SDFs joins are not exact, so offset by 2px to ensure nothing shows
    readonly property real borderThickness: contentItem.Config.border.thickness * (1 - fsTransitionProg)
    readonly property real borderRounding: contentItem.Config.border.rounding * (1 - fsTransitionProg)
    readonly property real shadowOpacity: 0.7 * (1 - fsTransitionProg)
    readonly property real borderLayoutThickness: hasFullscreen ? 0 : contentItem.Config.border.thickness
    readonly property bool panelsAboveToplevels: !hasFullscreen || WlrLayershell.layer === WlrLayer.Overlay

    property color surfaceColour: Colours.tPalette.surface

    readonly property int dragMaskPadding: {
        if (focusGrab.active || panels.popouts.isDetached)
            return 0;

        if (specialWs || monitor?.activeWorkspace?.toplevels.values.length > 0)
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
    WlrLayershell.layer: (fsTransitionProg > 0 && contentItem.Config.general.showOverFullscreen) || (specialWs && hasFullscreenOnNormalWs) ? WlrLayer.Overlay : WlrLayer.Top
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

        x: panels.notifications.x + bar.implicitWidth
        y: panels.notifications.y + root.borderThickness
        width: panels.notifications.width
        height: panels.notifications.height

        Region {
            x: root.width - width
            y: panels.osdWrapper.y + root.borderThickness
            width: panels.osdWrapper.width * (1 - panels.osd.offsetScale) + root.borderThickness
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
        color: "black"

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
            shadowColor: Qt.alpha("black", Math.max(0, root.shadowOpacity))
        }

        PanelBlobs {
            id: blobs

            anchors.fill: parent
            panels: panels
            bar: bar
            color: root.surfaceColour
            smoothing: root.contentItem.Config.border.smoothing
            deformScale: Config.appearance.deformScale
            borderThickness: root.borderThickness
            borderRounding: root.borderRounding
            sdfBorderOffset: root.sdfBorderOffset
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
            fullscreen: root.hasFullscreen

            utilities.horizontalStretch: (blobs.sidebar.rawDeformMatrix.m11 - 1) / 2 + 1
            utilities.deformMatrix: blobs.utilities.rawDeformMatrix

            dashboard.transform: Matrix4x4 {
                matrix: blobs.dashboard.deformMatrix
            }
            launcher.transform: Matrix4x4 {
                matrix: blobs.launcher.deformMatrix
            }
            session.transform: Matrix4x4 {
                matrix: blobs.session.deformMatrix
            }
            sidebar.transform: Matrix4x4 {
                matrix: blobs.sidebar.deformMatrix
            }
            osd.transform: Matrix4x4 {
                matrix: blobs.osd.deformMatrix
            }
            notifications.transform: Matrix4x4 {
                matrix: blobs.notifications.deformMatrix
            }
            utilities.transform: Matrix4x4 {
                matrix: blobs.utilities.deformMatrix
            }
            popouts.transform: Matrix4x4 {
                matrix: blobs.popouts.deformMatrix
            }
        }

        BarWrapper {
            id: bar

            anchors.top: parent.top
            anchors.bottom: parent.bottom

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
}
