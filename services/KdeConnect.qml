pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Sends files to a phone through a running KDE Connect daemon.
//
// None of the protocol lives here - KDE Connect already handles pairing,
// encryption and transfer, and ships a CLI meant for exactly this kind of
// frontend. The daemon is optional: with it missing or stopped, `available`
// goes false and anything built on this can hide itself.
//
// Devices are listed on demand rather than polled; the list only changes when
// a phone comes or goes.
Singleton {
    id: root

    // Paired and reachable devices, as { id, name }.
    readonly property list<var> devices: []
    property bool available: true
    // True while a share request is being handed to KDE Connect.
    property bool sharing: false
    property string sharingDevice: ""

    signal shared(string device, int count)
    signal shareFailed(string device, string error)

    function refresh(): void {
        listProc.running = true;
    }

    // Sends local files to a device. Paths arrive from a drop as file:// urls.
    function share(deviceId: string, urls: var): void {
        const paths = [];
        for (const url of urls) {
            const str = url.toString();
            if (str.startsWith("file://"))
                paths.push(decodeURIComponent(str.slice(7)));
        }

        if (!deviceId || paths.length === 0)
            return;

        // One --share per file, all in a single call, so the phone shows one
        // transfer rather than one per file.
        const args = ["kdeconnect-cli", "--device", deviceId];
        for (const path of paths)
            args.push("--share", path);

        shareProc.deviceId = deviceId;
        shareProc.count = paths.length;
        shareProc.command = args;
        root.sharingDevice = deviceId;
        root.sharing = true;
        shareProc.running = true;
    }

    // -a is paired *and* reachable, which is the only set worth offering to
    // send to. --id-name-only prints "<id> <name>", one device per line.
    Process {
        id: listProc

        command: ["kdeconnect-cli", "-a", "--id-name-only"]
        // environment: ({
        //         LANG: "C.UTF-8",
        //         LC_ALL: "C.UTF-8"
        //     })

        stdout: StdioCollector {
            id: listOut
        }

        onExited: code => { // qmllint disable
            // Anything non-zero means the daemon isn't there to answer.
            if (code !== 0) {
                root.available = false;
                root.devices = []; // qmllint disable
                return;
            }

            root.available = true;

            const found = [];
            for (const line of listOut.text.trim().split("\n")) {
                const split = line.indexOf(" ");
                if (split < 0)
                    continue;
                found.push({
                    id: line.slice(0, split),
                    name: line.slice(split + 1).trim()
                });
            }
            root.devices = found; // qmllint disable
        }
    }

    Process {
        id: shareProc

        property string deviceId
        property int count

        // environment: ({
        //         LANG: "C.UTF-8",
        //         LC_ALL: "C.UTF-8"
        //     })

        stderr: StdioCollector {
            id: shareErr
        }

        onExited: code => { // qmllint disable
            root.sharing = false;
            root.sharingDevice = "";

            if (code === 0) {
                root.shared(shareProc.deviceId, shareProc.count);
                return;
            }

            const error = shareErr.text.trim() || qsTr("kdeconnect-cli exited with %1").arg(code);
            console.warn(lc, `Failed to share with ${shareProc.deviceId}: ${error}`);
            root.shareFailed(shareProc.deviceId, error);
        }
    }

    LoggingCategory {
        id: lc

        name: "caelestia.qml.services.kdeconnect"
        defaultLogLevel: LoggingCategory.Info
    }
}
