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
            cpuTemp.running = true;
        }
    }

    Timer {
        id: gpuTimer
        running: true
        interval: 5000  // Update GPU metrics every 5 seconds instead of 3
        repeat: true
        onTriggered: {
            gpuMetrics.running = true;
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
                const idle = stats[3];

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
        command: ["sh", "-c", "df | grep '^/dev/' | awk '{print $3, $4}'"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                let used = 0;
                let avail = 0;
                for (const line of data.trim().split("\n")) {
                    const [u, a] = line.split(" ");
                    used += parseInt(u, 10);
                    avail += parseInt(a, 10);
                }
                root.storageUsed = used;
                root.storageTotal = used + avail;
            }
        }
    }

    Process {
        id: cpuTemp

        running: true
        command: ["sh", "-c", "sensors | awk '/Package id/ {print $4}' | sed 's/+//;s/°C.*//' | head -1"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                const temp = parseFloat(data.trim());
                root.cpuTemp = isNaN(temp) ? 0 : temp;
            }
        }
    }

    Process {
        id: gpuMetrics

        running: true
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu", "--format=csv,noheader,nounits"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                const values = data.trim().split(",");
                if (values.length >= 2) {
                    const usage = parseInt(values[0].trim(), 10);
                    const temp = parseFloat(values[1].trim());
                    root.gpuPerc = isNaN(usage) ? 0 : usage / 100;
                    root.gpuTemp = isNaN(temp) ? 0 : temp;
                }
            }
        }
    }
}
