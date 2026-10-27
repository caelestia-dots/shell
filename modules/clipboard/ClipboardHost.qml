pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import qs.components.misc
import qs.services

Scope {
    LazyLoader {
        id: loader

        activeAsync: Clipboard.open

        Panel {}
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "clipboard"
        description: "Open clipboard history"
        onPressed: {
            if (Clipboard.enabled)
                Clipboard.toggle();
        }
    }

    IpcHandler {
        function open(): void {
            if (Clipboard.enabled)
                Clipboard.openAtCursor();
        }

        function toggle(): void {
            if (Clipboard.enabled)
                Clipboard.toggle();
        }

        function close(): void {
            Clipboard.close();
        }

        target: "clipboard"
    }
}
