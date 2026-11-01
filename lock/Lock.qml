pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Caelestia.Services

Scope {
    id: root

    readonly property string statePath: Quickshell.env("XDG_RUNTIME_DIR") + "/caelestia-lock.state"

    property bool finished

    function writeState(state: string): void {
        stateFile.setText(state);
    }

    function finish(): void {
        if (finished)
            return;

        finished = true;
        writeState("unlocked");
        sessionLock.locked = false;
        quitTimer.start();
    }

    WlSessionLock {
        id: sessionLock

        locked: true

        onSecureChanged: {
            if (secure)
                root.writeState("locked");
        }

        LockSurface {
            lock: sessionLock
            pam: pamService
        }
    }

    Pam {
        id: pamService

        onUnlocked: root.finish()
    }

    Connections {
        function onUnlockRequested(): void {
            root.finish();
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
        id: quitTimer

        interval: 200
        onTriggered: Qt.exit(0)
    }
}
