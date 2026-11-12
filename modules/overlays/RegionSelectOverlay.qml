pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.components.containers
import qs.services

LazyLoader {
    id: root

    property bool open
    property real contentOpacity: open ? 1 : 0

    signal selected(region: rect)
    signal cancelled

    onSelected: open = false
    onCancelled: open = false

    activeAsync: contentOpacity > 0

    Behavior on contentOpacity {
        Anim {
            type: Anim.SlowEffects
        }
    }

    Scope {
        id: scope

        readonly property RegionState rState: RegionState {
            onCancelled: root.cancelled()
        }

        Connections {
            function onOpenChanged(): void {
                if (root.open)
                    scope.rState.clear();
            }

            target: root
        }

        Variants {
            model: Screens.screens

            StyledWindow {
                id: win

                required property ShellScreen modelData

                anchors.left: true
                anchors.right: true
                anchors.top: true
                anchors.bottom: true

                screen: modelData
                name: "region-select-overlay"
                WlrLayershell.exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
                mask: root.open ? null : empty

                Region {
                    id: empty
                }

                RegionSelectSurface {
                    anchors.fill: parent
                    rState: scope.rState
                    screen: win.modelData
                    open: root.open
                    contentOpacity: root.contentOpacity
                    onSelected: region => root.selected(region)
                }
            }
        }
    }
}
