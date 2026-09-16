pragma Singleton

import QtQuick
import Quickshell
import Caelestia.I18n
import Caelestia.Services

Singleton {
    id: root

    readonly property bool available: daemon.available
    readonly property var devices: daemon.devices
    readonly property bool receiving: daemon.downloading
    readonly property string receivingDevice: daemon.downloadDevice
    readonly property real progress: daemon.downloadProgress

    // Keyed by device id
    property var mounts: ({})
    property var mountBusy: ({})

    signal shared(string device, int count)
    signal shareFailed(string device, string error)
    signal downloaded(string device, string destinationPath)
    signal downloadFailed(string device, string error)
    signal downloadCancelled(string device)

    function refresh(): void {
        daemon.refresh();
    }

    function share(deviceId: string, urls: var): void {
        if (deviceId && urls.length > 0)
            daemon.share(deviceId, urls);
    }

    function download(deviceId: string, sourcePath: string): void {
        if (!deviceId || !sourcePath)
            return;

        // The storage may disappear under the copy while it is being unmounted
        if (isMountBusy(deviceId)) {
            downloadFailed(deviceId, Tr.tr("Phone storage is busy"));
            return;
        }

        daemon.download(deviceId, sourcePath);
    }

    function cancel(): void {
        daemon.cancelDownload();
    }

    function mount(deviceId: string): void {
        if (!deviceId || isMountBusy(deviceId))
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

    KdeConnectDaemon {
        id: daemon

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
        onMountFailed: (device, error) => {
            root.setMountBusy(device, false);
            console.warn(lc, `Failed to change mount state for ${device}: ${error}`);
        }
    }

    LoggingCategory {
        id: lc

        name: "caelestia.qml.services.kdeconnect"
        defaultLogLevel: LoggingCategory.Info
    }
}
