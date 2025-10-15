pragma ComponentBehavior: Bound

import qs.components
import qs.components.containers
import qs.services
import qs.config
import qs.modules.bar
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects

Variants {
    model: Quickshell.screens

    Scope {
        id: scope

        required property ShellScreen modelData

        readonly property bool hasFullscreen: Hypr.monitorFor(modelData)?.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen === 2) ?? false
        property int borderThickness: Config.border.effectiveThickness(hasFullscreen)

        onBorderThicknessChanged: Visibilities.borderThickness.set(modelData, borderThickness)

        Behavior on borderThickness {
            Anim {}
        }

        Component.onCompleted: Visibilities.borderThickness.set(modelData, borderThickness)

        Exclusions {
            screen: scope.modelData
            bar: bar
            borderThickness: scope.borderThickness
        }

        StyledWindow {
            id: win

            readonly property int dragMaskPadding: {
                if (focusGrab.active || panels.popouts.isDetached)
                    return 0;

                const mon = Hypr.monitorFor(screen);
                if (mon?.lastIpcObject.specialWorkspace.name || mon?.activeWorkspace?.lastIpcObject.windows > 0)
                    return 0;

                const thresholds = [];
                for (const panel of ["dashboard", "launcher", "session", "sidebar"])
                    if (Config[panel].enabled)
                        thresholds.push(Config[panel].dragThreshold);
                return Math.max(...thresholds);
            }

            Connections {
                target: scope
                function onHasFullscreenChanged() {
                    visibilities.launcher = false;
                    visibilities.session = false;
                    visibilities.dashboard = false;
                }
            }

            screen: scope.modelData
            name: "drawers"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: visibilities.launcher || visibilities.session ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            mask: Region {
                x: bar.implicitWidth + win.dragMaskPadding
                y: scope.borderThickness + win.dragMaskPadding
                width: win.width - bar.implicitWidth - scope.borderThickness - win.dragMaskPadding * 2
                height: win.height - scope.borderThickness * 2 - win.dragMaskPadding * 2
                intersection: Intersection.Xor

                regions: regions.instances
            }

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            Variants {
                id: regions

                model: panels.children

                Region {
                    required property Item modelData

                    x: modelData.x + bar.implicitWidth
                    y: modelData.y + scope.borderThickness
                    width: modelData.width
                    height: modelData.height
                    intersection: Intersection.Subtract
                }
            }

            HyprlandFocusGrab {
                id: focusGrab

                active: (visibilities.launcher && Config.launcher.enabled) || (visibilities.session && Config.session.enabled) || (visibilities.sidebar && Config.sidebar.enabled) || (!Config.dashboard.showOnHover && visibilities.dashboard && Config.dashboard.enabled) || (panels.popouts.currentName.startsWith("traymenu") && panels.popouts.current?.depth > 1)
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
                    shadowColor: Qt.alpha(Colours.palette.m3shadow, 0.7)
                }

                Border {
                    bar: bar
                    borderThickness: scope.borderThickness
                }

                Backgrounds {
                    panels: panels
                    bar: bar
                    borderThickness: scope.borderThickness
                }
            }

            PersistentProperties {
                id: visibilities

                property bool bar
                property bool osd
                property bool session
                property bool launcher
                property bool dashboard
                property bool utilities
                property bool sidebar

                Component.onCompleted: Visibilities.load(scope.modelData, this)
            }

            Interactions {
                screen: scope.modelData
                popouts: panels.popouts
                visibilities: visibilities
                panels: panels
                bar: bar
                borderThickness: scope.borderThickness

                Panels {
                    id: panels

                    screen: scope.modelData
                    visibilities: visibilities
                    bar: bar
                    borderThickness: scope.borderThickness
                }

                BarWrapper {
                    id: bar

                    anchors.top: parent.top
                    anchors.bottom: parent.bottom

                    screen: scope.modelData
                    visibilities: visibilities
                    popouts: panels.popouts
                    borderThickness: scope.borderThickness

                    Component.onCompleted: Visibilities.bars.set(scope.modelData, this)
                }
            }
        }
    }
}
