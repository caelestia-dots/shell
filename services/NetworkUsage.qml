pragma Singleton

import qs.config

import Quickshell
import Quickshell.Io

import QtQuick

Singleton {
    id: root

    property int refCount: 0

    // Current speeds in bytes per second
    readonly property real downloadSpeed: _downloadSpeed
    readonly property real uploadSpeed: _uploadSpeed

    // Total bytes transferred since tracking started
    readonly property real downloadTotal: _downloadTotal
    readonly property real uploadTotal: _uploadTotal

    // History of speeds for sparkline (most recent at end)
    readonly property var downloadHistory: _downloadHistory
    readonly property var uploadHistory: _uploadHistory
    readonly property int historyLength: 30

    // Private properties
    property real _downloadSpeed: 0
    property real _uploadSpeed: 0
    property real _downloadTotal: 0
    property real _uploadTotal: 0
    property var _downloadHistory: []
    property var _uploadHistory: []

    // Previous readings for calculating speed
    property real _prevRxBytes: 0
    property real _prevTxBytes: 0
    property real _prevTimestamp: 0

    // Initial readings for calculating totals
    property real _initialRxBytes: 0
    property real _initialTxBytes: 0
    property bool _initialized: false

    function formatBytes(bytes: real): var {
        // Handle negative or invalid values
        if (bytes < 0 || isNaN(bytes) || !isFinite(bytes)) {
            return {
                value: 0,
                unit: "B/s"
            };
        }

        if (bytes < 1024) {
            return {
                value: bytes,
                unit: "B/s"
            };
        } else if (bytes < 1024 * 1024) {
            return {
                value: bytes / 1024,
                unit: "KB/s"
            };
        } else if (bytes < 1024 * 1024 * 1024) {
            return {
                value: bytes / (1024 * 1024),
                unit: "MB/s"
            };
        } else {
            return {
                value: bytes / (1024 * 1024 * 1024),
                unit: "GB/s"
            };
        }
    }

    function formatBytesTotal(bytes: real): var {
        // Handle negative or invalid values
        if (bytes < 0 || isNaN(bytes) || !isFinite(bytes)) {
            return {
                value: 0,
                unit: "B"
            };
        }

        if (bytes < 1024) {
            return {
                value: bytes,
                unit: "B"
            };
        } else if (bytes < 1024 * 1024) {
            return {
                value: bytes / 1024,
                unit: "KB"
            };
        } else if (bytes < 1024 * 1024 * 1024) {
            return {
                value: bytes / (1024 * 1024),
                unit: "MB"
            };
        } else {
            return {
                value: bytes / (1024 * 1024 * 1024),
                unit: "GB"
            };
        }
    }

    function parseNetDev(content: string): var {
        const lines = content.split("\n");
        let totalRx = 0;
        let totalTx = 0;

        for (let i = 2; i < lines.length; i++) {
            const line = lines[i].trim();
            if (!line)
                continue;

            const parts = line.split(/\s+/);
            if (parts.length < 10)
                continue;

            const iface = parts[0].replace(":", "");
            // Skip loopback interface
            if (iface === "lo")
                continue;

            const rxBytes = parseFloat(parts[1]) || 0;
            const txBytes = parseFloat(parts[9]) || 0;

            totalRx += rxBytes;
            totalTx += txBytes;
        }

        return {
            rx: totalRx,
            tx: totalTx
        };
    }

    FileView {
        id: netDevFile
        path: "/proc/net/dev"
    }

    Timer {
        interval: Config.dashboard.resourceUpdateInterval
        running: root.refCount > 0
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            netDevFile.reload();
            const content = netDevFile.text();
            if (!content)
                return;

            const data = root.parseNetDev(content);
            const now = Date.now();

            if (!root._initialized) {
                root._initialRxBytes = data.rx;
                root._initialTxBytes = data.tx;
                root._prevRxBytes = data.rx;
                root._prevTxBytes = data.tx;
                root._prevTimestamp = now;
                root._initialized = true;
                return;
            }

            const timeDelta = (now - root._prevTimestamp) / 1000; // seconds
            if (timeDelta > 0) {
                // Calculate byte deltas
                let rxDelta = data.rx - root._prevRxBytes;
                let txDelta = data.tx - root._prevTxBytes;

                // Handle counter overflow (when counters wrap around from max to 0)
                // This happens when counters exceed 32-bit or 64-bit limits
                if (rxDelta < 0) {
                    // Counter wrapped around - assume 64-bit counter
                    rxDelta += Math.pow(2, 64);
                }
                if (txDelta < 0) {
                    txDelta += Math.pow(2, 64);
                }

                // Calculate speeds
                root._downloadSpeed = rxDelta / timeDelta;
                root._uploadSpeed = txDelta / timeDelta;

                const maxHistory = root.historyLength + 1;

                if (root._downloadSpeed >= 0 && isFinite(root._downloadSpeed)) {
                    let newDownHist = root._downloadHistory.slice();
                    newDownHist.push(root._downloadSpeed);
                    if (newDownHist.length > maxHistory) {
                        newDownHist.shift();
                    }
                    root._downloadHistory = newDownHist;
                }

                if (root._uploadSpeed >= 0 && isFinite(root._uploadSpeed)) {
                    let newUpHist = root._uploadHistory.slice();
                    newUpHist.push(root._uploadSpeed);
                    if (newUpHist.length > maxHistory) {
                        newUpHist.shift();
                    }
                    root._uploadHistory = newUpHist;
                }
            }

            // Calculate totals with overflow handling
            let downTotal = data.rx - root._initialRxBytes;
            let upTotal = data.tx - root._initialTxBytes;

            // Handle counter overflow for totals
            if (downTotal < 0) {
                downTotal += Math.pow(2, 64);
            }
            if (upTotal < 0) {
                upTotal += Math.pow(2, 64);
            }

            root._downloadTotal = downTotal;
            root._uploadTotal = upTotal;

            root._prevRxBytes = data.rx;
            root._prevTxBytes = data.tx;
            root._prevTimestamp = now;
        }
    }
}
