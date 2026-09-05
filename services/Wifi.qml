pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Services
import Caelestia.Config

// Wifi networking, split out of Nmcli along its own boundary.
//
// State comes from NetworkManager over dbus: access points arrive as typed
// objects that track their own signal strength, so there's no `nmcli device
// wifi list` output to parse and no rescan needed just to refresh a bar. Actions
// stay on the CLI - the connect flow has to read nmcli's stderr to tell a wrong
// password from a dropped link, and dbus wouldn't make that any easier.
Singleton {
    id: root

    readonly property var device: {
        for (const device of NetworkManager.devices)
            if (device.type === NetworkTransport.Wifi)
                return device;
        return null;
    }

    // Every access point in range, including several per SSID when a network is
    // on more than one band or radio.
    readonly property list<var> accessPoints: device?.accessPoints ?? []

    // One entry per SSID: the active access point if there is one, otherwise the
    // strongest. Same rule Nmcli's deduplicateNetworks applied to nmcli output.
    readonly property list<var> networks: {
        const best = new Map();
        for (const ap of root.accessPoints) {
            if (!ap.ssid)
                continue;

            const existing = best.get(ap.ssid);
            if (!existing || (ap.active && !existing.active) || (!existing.active && ap.strength > existing.strength))
                best.set(ap.ssid, ap);
        }
        return Array.from(best.values());
    }

    readonly property var active: root.accessPoints.find(ap => ap.active) ?? null
    readonly property bool enabled: NetworkManager.wirelessEnabled
    readonly property bool scanning: scanProc.running

    function findNetwork(ssid: string): var {
        return root.networks.find(n => n.ssid === ssid) ?? null;
    }

    // One-shot nmcli call; only the exit code matters, so there's nothing to
    // parse and no shared state to race.
    function run(args: list<string>, callback: var): void {
        const proc = actionProc.createObject(root, {
            command: ["nmcli", ...args],
            callback: callback ?? null
        });
        proc.running = true;
    }

    function setEnabled(enabled: bool, callback: var): void {
        // No refetch afterwards: wirelessEnabled is a live binding on
        // NetworkManager, so it updates itself once NM applies the change.
        run(["radio", "wifi", enabled ? "on" : "off"], callback);
    }

    function toggle(callback: var): void {
        setEnabled(!root.enabled, callback);
    }

    function scan(): void {
        if (!scanProc.running)
            scanProc.running = true;
    }

    function disconnect(callback: var): void {
        const iface = root.device?.iface ?? "";
        if (!iface) {
            if (callback)
                callback(false);
            return;
        }
        run(["device", "disconnect", iface], callback);
    }

    function forget(connectionName: string, callback: var): void {
        if (!connectionName) {
            if (callback)
                callback(false);
            return;
        }
        run(["connection", "delete", connectionName], callback);
    }

    Component {
        id: actionProc

        Process {
            id: proc

            property var callback: null

            environment: ({
                    LANG: "C.UTF-8",
                    LC_ALL: "C.UTF-8"
                })

            onExited: code => {
                const callback = proc.callback;
                proc.destroy();
                callback?.(code === 0);
            }
        }
    }

    Process {
        id: scanProc

        command: ["nmcli", "device", "wifi", "rescan"]
    }
}
