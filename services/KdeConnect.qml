pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Services

Singleton {
    id: root

    readonly property list<var> devices: []
    property bool available: true

    readonly property bool sharing:
        transfer.running && !transfer.receiving

    readonly property bool receiving:
        transfer.running && transfer.receiving

    readonly property bool transferring:
        transfer.running

    readonly property real progress:
        transfer.progress

    readonly property string sharingDevice:
        root.sharing ? transfer.deviceId : ""

    readonly property string receivingDevice:
        root.receiving ? transfer.deviceId : ""

    property var mounts: ({})
    property var mountBusy: ({})

    signal shared(string device, int count)
    signal shareFailed(string device, string error)
    signal shareCancelled(string device)

    signal downloaded(string device, string destinationPath)
    signal downloadFailed(string device, string error)
    signal downloadCancelled(string device)

    function refresh(): void {
        listProc.running = true;
    }

    function share(deviceId: string, urls: var): void {
        if (!deviceId || urls.length === 0)
            return;

        transfer.share(deviceId, urls);
    }

    function download(deviceId: string, sourcePath: string): void {
        if (!deviceId || !sourcePath)
            return;

        transfer.download(deviceId, sourcePath);
    }

    function cancel(): void {
        transfer.cancel();
    }

    function mount(deviceId: string): void {
        if (!deviceId || root.isMountBusy(deviceId))
            return;

        root.setMountBusy(deviceId, true);
        transfer.mount(deviceId);
    }

    function unmount(deviceId: string): void {
        if (!deviceId || root.isMountBusy(deviceId))
            return;

        root.setMountBusy(deviceId, true);
        transfer.unmount(deviceId);
    }

    function refreshMount(deviceId: string): void {
        if (!deviceId)
            return;

        transfer.refreshMount(deviceId);
    }

    function isMounted(deviceId: string): bool {
        const state = root.mounts[deviceId];

        return state !== undefined
            && state.mounted === true;
    }

    function isMountBusy(deviceId: string): bool {
        return root.mountBusy[deviceId] === true;
    }

    function mountPoint(deviceId: string): string {
        const state = root.mounts[deviceId];

        if (state === undefined)
            return "";

        return state.mountPoint;
    }

    function directories(deviceId: string): var {
        const state = root.mounts[deviceId];

        if (state === undefined)
            return {};

        return state.directories;
    }

    function setMountBusy(
        deviceId: string,
        busy: bool
    ): void {
        const next =
            Object.assign({}, root.mountBusy);

        next[deviceId] = busy;
        root.mountBusy = next;
    }

    function setMountState(
        deviceId: string,
        mounted: bool,
        mountPoint: string,
        directories: var
    ): void {
        const next =
            Object.assign({}, root.mounts);

        next[deviceId] = {
            mounted: mounted,
            mountPoint: mountPoint,
            directories: directories
        };

        root.mounts = next;
    }

    KdeConnectTransfer {
        id: transfer

        onShared: (device, count) => {
            root.shared(device, count);
            root.refreshMount(device);
        }

        onFailed: (device, error) => {
            console.warn(
                lc,
                `Failed to share with ${device}: ${error}`
            );

            root.shareFailed(device, error);
            root.refreshMount(device);
        }

        onCancelled: device => {
            root.shareCancelled(device);
            root.refreshMount(device);
        }

        onDownloaded: (device, destinationPath) => {
            root.downloaded(
                device,
                destinationPath
            );
        }

        onDownloadFailed: (device, error) => {
            console.warn(
                lc,
                `Failed to download from ${device}: ${error}`
            );

            root.downloadFailed(
                device,
                error
            );
        }

        onDownloadCancelled: device => {
            root.downloadCancelled(device);
        }

        onMountStateChanged: (
            device,
            mounted,
            mountPoint,
            directories
        ) => {
            root.setMountBusy(
                device,
                false
            );

            root.setMountState(
                device,
                mounted,
                mountPoint,
                directories
            );
        }

        onMountFailed: (device, error) => {
            root.setMountBusy(
                device,
                false
            );

            console.warn(
                lc,
                `Failed to change mount state for ${device}: ${error}`
            );
        }
    }

    Process {
        id: listProc

        command: [
            "kdeconnect-cli",
            "-a",
            "--id-name-only"
        ]

        stdout: StdioCollector {
            id: listOut
        }

        onExited: code => { // qmllint disable
            if (code !== 0) {
                root.available = false;
                root.devices = []; // qmllint disable
                return;
            }

            root.available = true;

            const found = [];

            for (const line of
                    listOut.text.trim().split("\n")) {
                const split =
                    line.indexOf(" ");

                if (split < 0)
                    continue;

                found.push({
                    id: line.slice(0, split),
                    name: line.slice(split + 1).trim()
                });
            }

            root.devices = found; // qmllint disable

            for (const device of found)
                root.refreshMount(device.id);
        }
    }

    LoggingCategory {
        id: lc

        name: "caelestia.qml.services.kdeconnect"
        defaultLogLevel: LoggingCategory.Info
    }
}
