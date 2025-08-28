pragma Singleton

import qs.utils
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool active: false

    function getCapsLockStatus(): void {
        capsLockStatus.running = true;
    }

    Process {
        id: capsLockStatus

        running: true
        command: [`${Paths.libdir}/capslock_state`]
        stdout: StdioCollector {
            onStreamFinished: {
                root.active = parseInt(text.trim()) > 0;
            }
        }
        onExited: {
            root.getCapsLockStatus();
        }
    }
}
