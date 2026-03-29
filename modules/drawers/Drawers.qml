pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.components
import qs.components.containers
import qs.services
import qs.config
import qs.utils
import qs.modules.bar

Variants {
    model: Screens.screens

    Scope {
        id: scope

        required property ShellScreen modelData
        readonly property bool barDisabled: Strings.testRegexList(Config.bar.excludedScreens, modelData.name)

        Exclusions {
            screen: scope.modelData
            bar: bar
            borderThickness: Config.border.thickness
        }

        StyledWindow {
            id: win

            readonly property var monitor: Hypr.monitorFor(screen)
            readonly property bool hasSpecialWorkspace: (monitor?.lastIpcObject?.specialWorkspace?.name.length ?? 0) > 0
            readonly property bool hasFullscreen: {
                if (hasSpecialWorkspace) {
                    const specialName = monitor?.lastIpcObject?.specialWorkspace?.name;
                    if (!specialName)
                        return false;
                    const specialWs = Hypr.workspaces.values.find(ws => ws.name === specialName);
                    return specialWs?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false;
                }
                return monitor?.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false;
            }
            property real borderThickness: hasFullscreen ? 0 : Config.border.thickness
            readonly property real borderLayoutThickness: hasFullscreen ? 0 : Config.border.thickness
            property real borderRounding: hasFullscreen ? 0 : Config.border.rounding
            property real shadowOpacity: hasFullscreen ? 0 : 0.7
            readonly property int dragMaskPadding: {
                if (focusGrab.active || panels.popouts.isDetached)
                    return 0;

                const mon = Hypr.monitorFor(screen);
                if (mon?.lastIpcObject.specialWorkspace?.name || mon?.activeWorkspace.lastIpcObject.windows > 0)
                    return 0;

                const thresholds = [];
                for (const panel of ["dashboard", "launcher", "session", "sidebar"])
                    if (Config[panel].enabled)
                        thresholds.push(Config[panel].dragThreshold);
                return Math.max(...thresholds);
            }

            onHasFullscreenChanged: {
                visibilities.launcher = false;
                visibilities.session = false;
                visibilities.dashboard = false;
            }

            screen: scope.modelData
            name: "drawers"
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: visibilities.launcher || visibilities.session || panels.dashboard.needsKeyboard ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            mask: Region {
                x: bar.clampedWidth + win.dragMaskPadding
                y: Config.border.clampedThickness + win.dragMaskPadding
                width: win.width - bar.clampedWidth - Config.border.clampedThickness - win.dragMaskPadding * 2
                height: win.height - Config.border.clampedThickness * 2 - win.dragMaskPadding * 2
                intersection: Intersection.Xor

                regions: regions.instances // qmllint disable stale-property-read
            }

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            Behavior on borderThickness {
                Anim {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }

            Behavior on borderRounding {
                Anim {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }

            Behavior on shadowOpacity {
                Anim {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }

            Variants {
                id: regions

                model: panels.children

                Region {
                    required property Item modelData

                    x: modelData.x + bar.implicitWidth
                    y: modelData.y + win.borderLayoutThickness
                    width: modelData.width
                    height: modelData.height
                    intersection: Intersection.Subtract
                }
            }

            HyprlandFocusGrab {
                id: focusGrab

                active: (visibilities.launcher && Config.launcher.enabled) || (visibilities.session && Config.session.enabled) || (visibilities.sidebar && Config.sidebar.enabled) || (!Config.dashboard.showOnHover && visibilities.dashboard && Config.dashboard.enabled) || (panels.popouts.currentName.startsWith("traymenu") && (panels.popouts.current as StackView)?.depth > 1)
                windows: [win]
                onCleared: {
                    visibilities.launcher = false;
                    visibilities.session = false;
                    visibilities.sidebar = false;
                    visibilities.dashboard = false;
                    panels.popouts.hasCurrent = false;
                    bar.closeTray();
                }
            }

            StyledRect {
                anchors.fill: parent
                opacity: visibilities.session && Config.session.enabled ? 0.5 : 0
                color: Colours.palette.m3scrim

                Behavior on opacity {
                    Anim {}
                }
            }

            Item {
                anchors.fill: parent
                opacity: Colours.transparency.enabled ? Colours.transparency.base : 1
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    blurMax: 15
                    shadowColor: Qt.alpha(Colours.palette.m3shadow, Math.max(0, win.shadowOpacity))
                }

                Border {
                    bar: bar
                    borderThickness: win.borderThickness
                    borderRounding: win.borderRounding
                }

                Backgrounds {
                    panels: panels
                    bar: bar
                    borderThickness: win.borderThickness
                    borderRounding: win.borderRounding
                }
            }

            DrawerVisibilities {
                id: visibilities

                Component.onCompleted: Visibilities.load(scope.modelData, this)
            }

            Interactions {
                screen: scope.modelData
                popouts: panels.popouts
                visibilities: visibilities
                panels: panels
                bar: bar
                borderThickness: win.borderLayoutThickness
                fullscreen: win.hasFullscreen

                Panels {
                    id: panels

                    screen: scope.modelData
                    visibilities: visibilities
                    bar: bar
                    borderThickness: win.borderLayoutThickness
                }

                BarWrapper {
                    id: bar

                    anchors.top: parent.top
                    anchors.bottom: parent.bottom

                    screen: scope.modelData
                    visibilities: visibilities
                    popouts: panels.popouts

                    disabled: scope.barDisabled
                    fullscreen: win.hasFullscreen

                    Component.onCompleted: Visibilities.bars.set(scope.modelData, this)
                }
            }
        }
    }
}
