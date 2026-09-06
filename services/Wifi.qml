pragma Singleton

import QtQuick
import Quickshell
import Caelestia.Services
import Caelestia.Config
import qs.services

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
    readonly property list<var> accessPoints: {
        const found = [];
        if (root.device)
            for (const ap of root.device.accessPoints)
                found.push(ap);
        return found;
    }

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

    // Active IPv4 details, or null when nothing is connected. Same shape the
    // parsed `nmcli device show` output produced, minus the subnet mask and
    // link speed, which nothing read.
    readonly property var details: {
        const device = root.device;
        if (!device?.connected)
            return null;

        return {
            ipAddress: device.address,
            gateway: device.gateway,
            dns: device.dns,
            macAddress: device.hwAddress
        };
    }
    readonly property bool enabled: NetworkManager.wirelessEnabled

    // NetworkManager runs device states 40 through 90 as the activation
    // sequence; 100 is up.
    readonly property bool connecting: {
        const state = root.device?.state ?? 0;
        return state >= 40 && state < 100;
    }

    // The profile being activated, which is the SSID for the profiles
    // NetworkManager names after the network.
    readonly property string connectingSsid: root.connecting ? (root.device?.connection ?? "") : ""

    readonly property real lastScan: root.device?.lastScan ?? -1

    // `nmcli device wifi rescan` asks NetworkManager for a scan and returns
    // straight away, so a running process says nothing about whether a scan is
    // still going. NetworkManager publishes no scanning flag either, so track
    // the request instead: the scan is in flight from asking until lastScan
    // moves off where it stood when we asked.
    //
    // Set rather than bound: a binding that read scanBaseline while the
    // handler wrote it would be a loop.
    property bool scanning: false
    property real scanBaseline: -1

    function findNetwork(ssid: string): var {
        return root.networks.find(n => n.ssid === ssid) ?? null;
    }

    function setEnabled(enabled: bool, callback: var): void {
        // No refetch afterwards: wirelessEnabled is a live binding on
        // NetworkManager, so it updates itself once NM applies the change.
        NmAction.run(["radio", "wifi", enabled ? "on" : "off"], callback);
    }

    function toggle(callback: var): void {
        setEnabled(!root.enabled, callback);
    }

    function scan(): void {
        if (root.scanning)
            return;

        root.scanBaseline = root.lastScan;
        root.scanning = true;
        scanTimeout.restart();
        NmAction.run(["device", "wifi", "rescan"], null);
    }

    // Brings down the profile on the wifi device, falling back to
    // disconnecting the device itself when nothing is named.
    function disconnect(callback: var): void {
        const connection = root.device?.connection ?? "";
        if (connection) {
            NmAction.run(["connection", "down", connection], callback);
            return;
        }

        const iface = root.device?.iface ?? "";
        if (!iface) {
            if (callback)
                callback(false);
            return;
        }
        NmAction.run(["device", "disconnect", iface], callback);
    }

    function forget(connectionName: string, callback: var): void {
        if (!connectionName) {
            if (callback)
                callback(false);
            return;
        }
        NmAction.run(["connection", "delete", connectionName], callback);
    }

    // The only word NetworkManager gives that a scan finished.
    onLastScanChanged: {
        if (root.scanning && root.lastScan !== root.scanBaseline) {
            root.scanning = false;
            scanTimeout.stop();
        }
    }

    // A scan that never reports back would otherwise leave the indicator
    // spinning for good.
    Timer {
        id: scanTimeout

        interval: 20000
        onTriggered: root.scanning = false
    }
}
