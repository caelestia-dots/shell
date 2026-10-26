pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Caelestia.Config
import qs.components.containers
import qs.components.misc
import qs.services

Scope {
    id: root

    LazyLoader {
        id: loader

        activeAsync: Activities.overviewOpen && Activities.enabled

        Variants {
            model: Screens.screens

            StyledWindow {
                id: win

                required property ShellScreen modelData

                screen: modelData
                name: "activities-overview"
                WlrLayershell.exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: Activities.overviewOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

                anchors.top: true
                anchors.bottom: true
                anchors.left: true
                anchors.right: true

                OverviewContent {
                    anchors.fill: parent
                    screen: win.modelData
                }
            }
        }
    }

    Connections {
        target: Activities

        function onOverviewOpenChanged(): void {
            if (!Activities.overviewOpen)
                return;
            // Close competing drawers on the active screen
            const st = ShellState.forActive();
            if (!st)
                return;
            st.launcher = false;
            st.session = false;
            st.dashboard = false;
            st.sidebar = false;
            st.utilities = false;
        }
    }

    IpcHandler {
        function toggle(): void {
            Activities.toggleOverview();
        }

        function open(): void {
            if (Activities.enabled)
                Activities.overviewOpen = true;
        }

        function close(): void {
            Activities.closeOverview();
        }

        function isOpen(): string {
            return Activities.overviewOpen ? "1" : "0";
        }

        target: "activitiesOverview"
    }
}
