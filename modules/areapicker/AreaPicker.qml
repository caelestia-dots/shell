pragma ComponentBehavior: Bound

import qs.widgets
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

Scope {
    LazyLoader {
        id: root

        property bool freeze
        property bool closing

        Variants {
            model: Quickshell.screens

            StyledWindow {
                id: win

                required property ShellScreen modelData

                screen: modelData
                name: "area-picker"
                WlrLayershell.exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: root.closing ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive
                mask: root.closing ? empty : null

                anchors.top: true
                anchors.bottom: true
                anchors.left: true
                anchors.right: true

                Region {
                    id: empty
                }

                Picker {
                    loader: root
                    screen: win.modelData
                }
            }
        }
    }

    IpcHandler {
        target: "picker"

        function open(): void {
            root.freeze = false;
            root.closing = false;
            root.activeAsync = true;
        }

        function openFreeze(): void {
            root.freeze = true;
            root.closing = false;
            root.activeAsync = true;
        }
    }

    CustomShortcut {
        name: "screenshot"
        description: "Open screenshot tool"
        onPressed: {
            root.freeze = false;
            root.closing = false;
            root.activeAsync = true;
        }
    }

    CustomShortcut {
        name: "screenshotFreeze"
        description: "Open screenshot tool (freeze mode)"
        onPressed: {
            root.freeze = true;
            root.closing = false;
            root.activeAsync = true;
        }
    }
}
