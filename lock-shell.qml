//@ pragma Env QS_CRASHREPORT_URL=https://github.com/caelestia-dots/shell/issues/new?template=crash.yml
//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
//@ pragma DefaultEnv QS_DROP_EXPENSIVE_FONTS=1

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Services
import qs.modules.lock

ShellRoot {
    id: root

    readonly property string statePath: Quickshell.env("XDG_RUNTIME_DIR") + "/caelestia-lock.state"

    property bool started

    Lock {
        id: lockRoot
    }

    Connections {
        function onLockedChanged(): void {
            if (!root.started)
                return;

            if (lockRoot.lock.locked) {
                root.started = true;
            } else {
                stateFile.setText("unlocked");
                exitTimer.start();
            }
        }

        function onSecureChanged(): void {
            if (lockRoot.lock.secure)
                stateFile.setText("locked");
        }

        target: lockRoot.lock
    }

    Connections {
        function onUnlockRequested(): void {
            lockRoot.lock.unlock();
        }

        target: SessionManager
    }

    FileView {
        id: stateFile

        path: root.statePath
        blockWrites: false
        atomicWrites: true
        printErrors: false

        Component.onCompleted: setText("starting")
    }

    Timer {
        id: exitTimer

        interval: 500
        onTriggered: Qt.exit(0)
    }

    Component.onCompleted: {
        lockRoot.lock.locked = true;
        root.started = true;
    }
}
