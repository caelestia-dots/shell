pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components.containers
import qs.components.misc
import qs.services

Scope {
    id: scope

    function openPopup(): void {
        loader.activeAsync = true;
    }

    LazyLoader {
        id: loader

        Variants {
            model: Screens.screens

            StyledWindow {
                id: win

                required property ShellScreen modelData

                screen: modelData
                name: "display-popup"
                WlrLayershell.exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: content.closing ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive
                mask: content.closing ? empty : null

                anchors.top: true
                anchors.bottom: true
                anchors.left: true
                anchors.right: true

                Region {
                    id: empty
                }

                Content {
                    id: content

                    loader: loader
                    screen: win.modelData
                }
            }
        }
    }

    Connections {
        function onMonitorAdded(): void {
            if (Date.now() - Hypr.lastMonitorApplyMs < 4000)
                return;
            hotplugDelay.restart();
        }

        target: Hypr
    }

    Timer {
        id: hotplugDelay

        interval: 600
        onTriggered: {
            if (Hypr.monitors.values.length > 1)
                scope.openPopup();
        }
    }

    IpcHandler {
        function open(): void {
            scope.openPopup();
        }

        target: "display"
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "displayPopup"
        description: "Open display projection popup"
        onPressed: scope.openPopup()
    }
}
