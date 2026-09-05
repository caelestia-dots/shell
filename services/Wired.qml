pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Services
import Caelestia.Config

// Wired networking, split out of Nmcli along its own boundary.
//
// State comes from NetworkManager over dbus: devices arrive as typed objects
// with change signals, so there's no `nmcli device status` output to parse and
// nothing to poll. Actions stay on the CLI - connecting, disconnecting and
// reading counters have nothing to parse and nothing to gain from moving.
Singleton {
    id: root

    readonly property list<var> devices: {
        const found = [];
        for (const device of NetworkManager.devices)
            if (device.type === NetworkTransport.Ethernet)
                found.push(device);
        return found;
    }

    // The wired device that finished activating, if any.
    readonly property var active: devices.find(d => d.connected) ?? null
    // Whether any wired device has a cable in it.
    readonly property bool available: devices.some(d => d.carrier)

    // Active IPv4 details, or null when nothing is connected. Same shape the
    // parsed `nmcli device show` output produced, minus the subnet mask and
    // link speed, which nothing read.
    readonly property var details: {
        const device = root.active;
        if (!device)
            return null;

        return {
            ipAddress: device.address,
            gateway: device.gateway,
            dns: device.dns,
            macAddress: device.hwAddress
        };
    }

    // Negotiated link speed of the active device, e.g. "1 Gbps".
    readonly property string speed: {
        const mbit = root.active?.speed ?? 0;
        if (mbit <= 0)
            return "";
        if (mbit < 1000)
            return `${mbit} Mbps`;

        const gbps = mbit / 1000;
        return `${Number.isInteger(gbps) ? gbps : gbps.toFixed(1)} Gbps`;
    }

    // Cumulative since-boot byte counters, which NetworkManager doesn't keep,
    // so this stays a sysfs read.
    property string dataUsage: ""

    function connect(connectionName: string, interfaceName: string, callback: var): void {
        if (connectionName)
            run(["connection", "up", connectionName], callback);
        else if (interfaceName)
            run(["device", "connect", interfaceName], callback);
        else if (callback)
            callback(false);
    }

    function disconnect(connectionName: string, callback: var): void {
        if (!connectionName) {
            if (callback)
                callback(false);
            return;
        }
        run(["connection", "down", connectionName], callback);
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

    // Kept for existing callers; the speed is a live binding on the device now.
    function refreshSpeed(interfaceName: string): void {
    }

    function refreshDataUsage(interfaceName: string): void {
        if (!interfaceName) {
            root.dataUsage = "";
            return;
        }
        usageProc.command = ["cat", `/sys/class/net/${interfaceName}/statistics/rx_bytes`, `/sys/class/net/${interfaceName}/statistics/tx_bytes`];
        usageProc.running = true;
    }

    function formatBytes(bytes: var): string {
        if (!bytes || bytes <= 0)
            return "0 B";
        const units = ["B", "KB", "MB", "GB", "TB"];
        let i = 0;
        let v = bytes;
        while (v >= 1024 && i < units.length - 1) {
            v /= 1024;
            i++;
        }
        return `${v.toFixed(v < 10 && i > 0 ? 1 : 0)} ${units[i]}`;
    }

    // Follows whichever device is active, so consumers don't have to ask.
    onActiveChanged: {
        refreshDataUsage(active?.interface ?? "");
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

            onExited: code => { // qmllint disable signal-handler-parameters
                const callback = proc.callback;
                proc.destroy();
                callback?.(code === 0);
            }
        }
    }

    Process {
        id: usageProc

        stdout: StdioCollector {
            onStreamFinished: {
                const nums = text.trim().split("\n").map(n => parseInt(n.trim(), 10)).filter(n => !isNaN(n));
                root.dataUsage = nums.length < 2 ? "" : root.formatBytes(nums[0] + nums[1]);
            }
        }
    }
}
