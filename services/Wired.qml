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
    // Whether any wired device is usable. NM reports state 20 (unavailable)
    // for a NIC with no carrier, so anything past that means a cable is in.
    readonly property bool available: devices.some(d => d.state > 20)

    // Negotiated link speed of the active device, e.g. "1 Gbps". NM doesn't
    // expose this, so it comes from sysfs - a plain file read, no daemon.
    property string speed: ""
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

    function refreshSpeed(interfaceName: string): void {
        if (!interfaceName) {
            root.speed = "";
            return;
        }
        speedProc.command = ["cat", `/sys/class/net/${interfaceName}/speed`];
        speedProc.running = true;
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
        refreshSpeed(active?.interface ?? "");
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

            onExited: code => {
                const callback = proc.callback;
                proc.destroy();
                callback?.(code === 0);
            }
        }
    }

    Process {
        id: speedProc

        stdout: StdioCollector {
            onStreamFinished: {
                const mbit = parseInt(text.trim(), 10);
                // Disconnected or virtual interfaces report -1, or nothing.
                if (isNaN(mbit) || mbit <= 0)
                    root.speed = "";
                else if (mbit >= 1000) {
                    const gbps = mbit / 1000;
                    root.speed = `${Number.isInteger(gbps) ? gbps : gbps.toFixed(1)} Gbps`;
                } else
                    root.speed = `${mbit} Mbps`;
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
