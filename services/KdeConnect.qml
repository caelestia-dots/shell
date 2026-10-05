pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Services

Singleton {
    id: root

    readonly property bool available: daemon.available
    // Only paired devices can share, mount and browse
    readonly property var devices: daemon.devices.filter(d => d.paired)
    // Reachable devices which are not paired yet, including ones with a pairing request
    readonly property var unpairedDevices: daemon.devices.filter(d => !d.paired)
    readonly property bool downloading: daemon.downloading
    readonly property string downloadDevice: daemon.downloadDevice
    readonly property real downloadProgress: daemon.downloadProgress
    // Kept here rather than in the UI, which is recreated whenever utilities reopens
    property string downloadName

    // Values of a device's pairState, matching KDE Connect's PairState
    readonly property int pairNotPaired: 0
    readonly property int pairRequested: 1
    readonly property int pairRequestedByPeer: 2
    readonly property int pairPaired: 3

    // The shell runs kdeconnectd as this systemd user unit, so the daemon outlives
    // shell restarts and can be told apart from one started elsewhere
    readonly property string unitName: "caelestia-kdeconnect"
    readonly property bool runDaemon: GlobalConfig.services.kdeConnect
    // Whether the running daemon is the shell's own unit
    property bool managed
    // True while the daemon is being started or stopped
    property bool daemonBusy
    // The setting changed while busy, so sync again afterwards
    property bool syncPending
    // Running, but started by something else, e.g. the compositor or a systemd service
    readonly property bool external: available && !managed

    // Keyed by device id
    property var mounts: ({})
    property var mountBusy: ({})

    signal shared(string device, int count)
    signal shareFailed(string device, string error)
    signal downloaded(string device, string destinationPath)
    signal downloadFailed(string device, string error)
    signal downloadCancelled(string device)
    signal mountChecked(string device, string path, bool reachable)
    signal pairingFailed(string device, string error)

    function refresh(): void {
        daemon.refresh();
    }

    function isPaired(deviceId: string): bool {
        return devices.some(d => d.id === deviceId);
    }

    function share(deviceId: string, urls: var): void {
        if (isPaired(deviceId) && urls.length > 0)
            daemon.share(deviceId, urls);
    }

    function download(deviceId: string, sourcePath: string): void {
        if (!isPaired(deviceId) || !sourcePath)
            return;

        // The storage may disappear under the copy while it is being unmounted
        if (isMountBusy(deviceId)) {
            downloadFailed(deviceId, Tr.tr("Phone storage is busy"));
            return;
        }

        downloadName = sourcePath.split("/").pop();
        daemon.download(deviceId, sourcePath);
    }

    function cancelDownload(): void {
        daemon.cancelDownload();
    }

    function mount(deviceId: string): void {
        if (!isPaired(deviceId) || isMountBusy(deviceId))
            return;

        setMountBusy(deviceId, true);
        daemon.mount(deviceId);
    }

    function unmount(deviceId: string): void {
        if (!deviceId || isMountBusy(deviceId))
            return;

        setMountBusy(deviceId, true);
        daemon.unmount(deviceId);
    }

    function refreshMount(deviceId: string): void {
        if (deviceId)
            daemon.refreshMount(deviceId);
    }

    // Checks that the mounted storage still responds, without blocking the UI.
    // A dead mount is unmounted, so check before touching the filesystem.
    function checkMount(deviceId: string, path: string): void {
        if (deviceId && path)
            daemon.checkMount(deviceId, path);
    }

    function isMounted(deviceId: string): bool {
        return mounts[deviceId]?.mounted === true;
    }

    function isMountBusy(deviceId: string): bool {
        return mountBusy[deviceId] === true;
    }

    function mountPoint(deviceId: string): string {
        return mounts[deviceId]?.mountPoint ?? "";
    }

    function directories(deviceId: string): var {
        return mounts[deviceId]?.directories ?? {};
    }

    // The shortest directory is the storage root, the others are inside it
    function storageRoot(deviceId: string): string {
        return Object.keys(directories(deviceId)).sort((a, b) => a.length - b.length)[0] ?? "";
    }

    function setMountBusy(deviceId: string, busy: bool): void {
        const next = Object.assign({}, mountBusy);
        next[deviceId] = busy;
        mountBusy = next;
    }

    function setMountState(deviceId: string, mounted: bool, mountPoint: string, directories: var): void {
        const next = Object.assign({}, mounts);
        next[deviceId] = {
            mounted,
            mountPoint,
            directories
        };
        mounts = next;
    }

    // Drops state for devices that went away and refreshes the rest
    // Sends a pairing request, which the device has to accept
    function requestPairing(deviceId: string): void {
        if (deviceId)
            daemon.requestPairing(deviceId);
    }

    // Accepts a pairing request the device sent
    function acceptPairing(deviceId: string): void {
        if (deviceId)
            daemon.acceptPairing(deviceId);
    }

    // Rejects a pairing request the device sent, or cancels one we sent
    function cancelPairing(deviceId: string): void {
        if (deviceId)
            daemon.cancelPairing(deviceId);
    }

    function unpair(deviceId: string): void {
        if (!isPaired(deviceId))
            return;

        // Unpairing unloads the SFTP plugin, which unmounts the storage under the copy
        if (downloading && downloadDevice === deviceId)
            cancelDownload();

        daemon.unpair(deviceId);
    }

    function command(args: list<string>, callback: var): void {
        const proc = commandComp.createObject(root, {
            command: args,
            callback
        });
        proc.running = true;
    }

    function checkManaged(): void {
        command(["systemctl", "--user", "is-active", "--quiet", unitName], code => managed = code === 0);
    }

    function finishSync(): void {
        daemonBusy = false;
        checkManaged();

        if (syncPending) {
            syncPending = false;
            syncDaemon();
        }
    }

    // Starts or stops the shell's daemon to match the setting. Only runs on shell
    // start and when the setting changes, so a daemon that fails to start is not
    // retried in a loop.
    function syncDaemon(): void {
        if (daemonBusy) {
            syncPending = true;
            return;
        }

        daemonBusy = true;
        command(["systemctl", "--user", "is-active", "--quiet", unitName], unitCode => {
            managed = unitCode === 0;

            if (runDaemon && !managed) {
                // A daemon started elsewhere is left alone instead of starting a second one
                command(["busctl", "--user", "status", "org.kde.kdeconnect"], busCode => {
                    if (busCode === 0) {
                        finishSync();
                        return;
                    }

                    command(["systemd-run", "--user", `--unit=${unitName}`, "--collect", "--quiet", "kdeconnectd"], startCode => {
                        if (startCode !== 0)
                            console.warn(lc, "Failed to start kdeconnectd");
                        finishSync();
                    });
                });
            } else if (!runDaemon && managed) {
                command(["systemctl", "--user", "stop", unitName], stopCode => {
                    if (stopCode !== 0)
                        console.warn(lc, "Failed to stop kdeconnectd");
                    finishSync();
                });
            } else {
                finishSync();
            }
        });
    }

    function syncMounts(): void {
        const ids = devices.map(d => d.id);
        const keep = state => {
            const next = {};
            for (const id of ids)
                if (state[id] !== undefined)
                    next[id] = state[id];
            return next;
        };

        mounts = keep(mounts);
        mountBusy = keep(mountBusy);

        for (const id of ids)
            refreshMount(id);
    }

    Component.onCompleted: syncDaemon()
    onRunDaemonChanged: syncDaemon()

    KdeConnectDaemon {
        id: daemon

        // Whoever started or stopped the daemon, find out whether it is ours
        onAvailableChanged: root.checkManaged()
        onDevicesChanged: root.syncMounts()
        onShared: (device, count) => root.shared(device, count)
        onShareFailed: (device, error) => {
            console.warn(lc, `Failed to share with ${device}: ${error}`);
            root.shareFailed(device, error);
        }
        onDownloaded: (device, destinationPath) => root.downloaded(device, destinationPath)
        onDownloadFailed: (device, error) => {
            console.warn(lc, `Failed to download from ${device}: ${error}`);
            root.downloadFailed(device, error);
        }
        onDownloadCancelled: device => root.downloadCancelled(device)
        onMountStateChanged: (device, mounted, mountPoint, directories) => {
            root.setMountBusy(device, false);
            root.setMountState(device, mounted, mountPoint, directories);
        }
        onMountChecked: (device, path, reachable) => root.mountChecked(device, path, reachable)
        onMountFailed: (device, error) => {
            root.setMountBusy(device, false);
            console.warn(lc, `Failed to change mount state for ${device}: ${error}`);
        }
        onPairingFailed: (device, error) => {
            console.warn(lc, `Pairing with ${device} failed: ${error}`);
            root.pairingFailed(device, error);
        }
    }

    Component {
        id: commandComp

        Process {
            id: proc

            property var callback

            onExited: code => { // qmllint disable signal-handler-parameters
                Qt.callLater(() => {
                    proc.callback?.(code);
                    proc.destroy();
                });
            }
        }
    }

    LoggingCategory {
        id: lc

        name: "caelestia.qml.services.kdeconnect"
        defaultLogLevel: LoggingCategory.Info
    }
}
