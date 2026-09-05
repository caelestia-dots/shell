pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// One-shot nmcli calls for the network services.
//
// Only the exit code and, for the handful of callers that have to tell one
// failure from another, stderr matter: there's no output to parse and no shared
// state to race, since state comes from NetworkManager over dbus.
Singleton {
    id: root

    // Runs nmcli with `args`. The callback takes (success, error).
    function run(args: list<string>, callback: var): void {
        const proc = actionProc.createObject(root, {
            command: ["nmcli", ...args],
            callback: callback ?? null
        });
        proc.running = true;
    }

    Component {
        id: actionProc

        Process {
            id: proc

            property var callback: null
            property string error: ""

            environment: ({
                    LANG: "C.UTF-8",
                    LC_ALL: "C.UTF-8"
                })

            stderr: StdioCollector {
                onStreamFinished: proc.error = text
            }

            onExited: code => { // qmllint disable signal-handler-parameters
                const callback = proc.callback;
                const error = proc.error;
                proc.destroy();
                callback?.(code === 0, error);
            }
        }
    }
}
