pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Services

// Sends files to a phone through a running KDE Connect daemon.
//
// KDE Connect handles pairing, authentication and the SFTP connection.
// Device discovery stays here, while the actual file copy is handled by
// KdeConnectTransfer so transfer progress reflects bytes actually written.
//
// Devices are listed on demand rather than polled; the list only changes when
// a phone comes or goes.
Singleton {
    id: root

    // Paired and reachable devices, as { id, name }.
    readonly property list<var> devices: []
    property bool available: true

    // Actual transfer state reported by KdeConnectTransfer.
    readonly property bool sharing: transfer.running
    readonly property real progress: transfer.progress
    readonly property string sharingDevice: transfer.running ? transfer.deviceId : ""

    signal shared(string device, int count)
    signal shareFailed(string device, string error)
    signal shareCancelled(string device)

    function refresh(): void {
        listProc.running = true;
    }

    // Sends local file URLs to the selected device.
    function share(deviceId: string, urls: var): void {
        if (!deviceId || urls.length === 0)
            return;

        transfer.share(deviceId, urls);
    }

    function cancel(): void {
        transfer.cancel();
    }

    KdeConnectTransfer {
        id: transfer

        onShared: (device, count) => {
            root.shared(device, count);
        }

        onFailed: (device, error) => {
            console.warn(lc, `Failed to share with ${device}: ${error}`);
            root.shareFailed(device, error);
        }

        onCancelled: device => {
            root.shareCancelled(device);
        }
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

    LoggingCategory {
        id: lc

        name: "caelestia.qml.services.kdeconnect"
        defaultLogLevel: LoggingCategory.Info
    }
}
