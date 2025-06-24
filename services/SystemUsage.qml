pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property real cpuPerc
    property real cpuTemp
    property real gpuPerc
    property real gpuTemp
    property int memUsed
    property int memTotal
    readonly property real memPerc: memTotal > 0 ? memUsed / memTotal : 0
    property int storageUsed
    property int storageTotal
    property real storagePerc: storageTotal > 0 ? storageUsed / storageTotal : 0

    property int lastCpuIdle
    property int lastCpuTotal

    function formatKib(kib: int): var {
        const mib = 1024;
        const gib = 1024 ** 2;
        const tib = 1024 ** 3;

        if (kib >= tib)
            return {
                value: kib / tib,
                unit: "TiB"
            };
        if (kib >= gib)
            return {
                value: kib / gib,
                unit: "GiB"
            };
        if (kib >= mib)
            return {
                value: kib / mib,
                unit: "MiB"
            };
        return {
            value: kib,
            unit: "KiB"
        };
    }

    Timer {
        running: true
        interval: 3000
        repeat: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            storage.running = true;
            gpuUsage.running = true;
            sensors.running = true;
        }
    }

    FileView {
        id: stat

        path: "/proc/stat"
        onLoaded: {
            const data = text().match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/);
            if (data) {
                const stats = data.slice(1).map(n => parseInt(n, 10));
                const total = stats.reduce((a, b) => a + b, 0);
                const idle = stats[3] + (stats[4] ?? 0);

                const totalDiff = total - root.lastCpuTotal;
                const idleDiff = idle - root.lastCpuIdle;
                root.cpuPerc = totalDiff > 0 ? (1 - idleDiff / totalDiff) : 0;

                root.lastCpuTotal = total;
                root.lastCpuIdle = idle;
            }
        }
    }

    FileView {
        id: meminfo

        path: "/proc/meminfo"
        onLoaded: {
            const data = text();
            root.memTotal = parseInt(data.match(/MemTotal: *(\d+)/)[1], 10) || 1;
            root.memUsed = (root.memTotal - parseInt(data.match(/MemAvailable: *(\d+)/)[1], 10)) || 0;
        }
    }

    Process {
        id: storage

        running: true
        command: ["sh", "-c", "df | grep '^/dev/' | awk '{print $1, $3, $4}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const deviceMap = new Map();

                for (const line of text.trim().split("\n")) {
                    if (line.trim() === "")
                        continue;

                    const parts = line.trim().split(/\s+/);
                    if (parts.length >= 3) {
                        const device = parts[0];
                        const used = parseInt(parts[1], 10) || 0;
                        const avail = parseInt(parts[2], 10) || 0;

                        // Only keep the entry with the largest total space for each device
                        if (!deviceMap.has(device) || (used + avail) > (deviceMap.get(device).used + deviceMap.get(device).avail)) {
                            deviceMap.set(device, {
                                used: used,
                                avail: avail
                            });
                        }
                    }
                }

                let totalUsed = 0;
                let totalAvail = 0;

                for (const [device, stats] of deviceMap) {
                    totalUsed += stats.used;
                    totalAvail += stats.avail;
                }

                root.storageUsed = totalUsed;
                root.storageTotal = totalUsed + totalAvail;
            }
        }
    }

    Process {
        id: gpuUsage

        running: true
        command: ["sh", "-c", "cat /sys/class/drm/card*/device/gpu_busy_percent"]
        stdout: StdioCollector {
            onStreamFinished: {
                const percs = text.trim().split("\n");
                const sum = percs.reduce((acc, d) => acc + parseInt(d, 10), 0);
                root.gpuPerc = sum / percs.length / 100;
            }
        }
    }

    Process {
        id: sensors

        running: true
        command: ["sensors"]
        environment: ({
                LANG: "C",
                LC_ALL: "C"
            })
        stdout: StdioCollector {
            onStreamFinished: {
		let cpuTemp = text.match(/(?:Package id [0-9]+|Tdie):\s+((\+|-)[0-9.]+)(°| )C/);
		if (!cpuTemp) {
		    // If AMD Tdie pattern failed, try fallback on Tctl
		    cpuTemp = text.match(/Tctl:\s+((\+|-)[0-9.]+)(°| )C/);
		}
                if (cpuTemp)
                    root.cpuTemp = parseFloat(cpuTemp[1]);

                let eligible = false;
                let sum = 0;
                let count = 0;

                for (const line of text.trim().split("\n")) {
                    if (line === "Adapter: PCI adapter")
                        eligible = true;
                    else if (line === "")
                        eligible = false;
                    else if (eligible) {
                        const match = line.match(/^(temp[0-9]+|GPU core|edge)+:\s+\+([0-9]+\.[0-9]+)(°| )C/);
                        if (match) {
                            sum += parseFloat(match[2]);
                            count++;
                        }
                    }
                }

                root.gpuTemp = count > 0 ? sum / count : 0;
            }
        }
    }
}
