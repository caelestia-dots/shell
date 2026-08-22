pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

QtObject {
    id: root

    property var secureCommand: []
    property var releaseCommand: []
    property bool initialized: false

    property bool wasLocked: false
    property bool cycleActive: false
    property bool secureFired: false
    property bool releaseFired: false

    signal secureHookRequested(var command)
    signal releaseHookRequested(var command)

    function initialize(locked, secure): bool {
        if (initialized) {
            console.warn(lc, "Lock lifecycle controller initialized more than once");
            return false;
        }

        initialized = true;
        wasLocked = locked;
        cycleActive = locked;
        secureFired = locked && secure;
        releaseFired = false;
        return true;
    }

    function update(locked, secure): void {
        if (!initialized) {
            console.warn(lc, "Lock lifecycle update before initialization");
            return;
        }

        if (locked && !wasLocked) {
            cycleActive = true;
            secureFired = false;
            releaseFired = false;
        }

        if (cycleActive && locked && secure && !secureFired) {
            secureFired = true;
            if (canRun(secureCommand))
                secureHookRequested(secureCommand);
        }

        if (cycleActive && wasLocked && !locked) {
            if (!releaseFired) {
                releaseFired = true;
                if (canRun(releaseCommand))
                    releaseHookRequested(releaseCommand);
            }
            cycleActive = false;
        }

        wasLocked = locked;
    }

    function canRun(command): bool {
        if (command.length === 0)
            return false;

        if (command[0].trim().length === 0) {
            console.warn(lc, "Ignoring lock lifecycle hook with blank argv[0]");
            return false;
        }

        return true;
    }

    LoggingCategory {
        id: lc

        name: "caelestia.qml.lock.lifecycle"
        defaultLogLevel: LoggingCategory.Info
    }
}
