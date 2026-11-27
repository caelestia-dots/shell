import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.I18n
import qs.modules.launcher.services

// Read and write disk speed test overlay.
// Adapted from Omarchy's disk speedtest panel (MIT License).
Scope {
    id: root

    property bool opened: false
    property bool running: false
    property bool expectedStop: false
    property bool pendingRun: false
    property string phase: ""
    property string diskName: ""
    property string writeMBps: ""
    property string readMBps: ""
    property string error: ""
    property string stderrText: ""

    property int stackCount: 1
    property int stackRank: 0
    property real stackCenter: 0.5

    readonly property alias overlay: overlayInstance
    readonly property string binPath: `${MenuService.userBinDir}:${MenuService.bundledBinDir}`

    function open(): void {
        opened = true;
        runTest();
    }

    function close(): void {
        opened = false;
        pendingRun = false;
        phase = "";
        running = false;
        if (proc.running) {
            expectedStop = true;
            proc.running = false;
        }
    }

    function runTest(): void {
        if (proc.running) {
            if (expectedStop)
                pendingRun = true;
            return;
        }
        error = "";
        diskName = "";
        writeMBps = "";
        readMBps = "";
        stderrText = "";
        phase = "read";
        running = true;
        proc.command = ["bash", "-c", `export PATH="${root.binPath}:$PATH"; exec menu-disk-speedtest`];
        proc.running = true;
    }

    function toRate(raw: string): real {
        const value = parseFloat(raw);
        return isFinite(value) && value > 0 ? value : 0;
    }

    function updateLine(line: string): void {
        const parts = String(line).trim().split(/\s+/);
        if (parts.length < 2)
            return;
        if (parts[0] === "disk") {
            diskName = parts.slice(1).join(" ");
            return;
        }
        const value = parseFloat(parts[1]);
        if (!isFinite(value) || value < 0)
            return;
        if (parts[0] === "write") {
            phase = "write";
            writeMBps = String(value);
        } else if (parts[0] === "read") {
            phase = "read";
            readMBps = String(value);
        }
    }

    Process {
        id: proc

        stdout: SplitParser {
            onRead: line => root.updateLine(line)
        }

        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                root.stderrText = String(text || "").trim();
                if (root.error !== "" && root.stderrText !== "")
                    root.error = root.stderrText;
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (root.pendingRun) {
                root.pendingRun = false;
                root.expectedStop = false;
                if (root.opened)
                    Qt.callLater(root.runTest);
                return;
            }

            if (!root.expectedStop && exitCode !== 0) {
                root.error = root.stderrText || Tr.tr("Disk speed test failed");
                root.phase = "";
                root.running = false;
                return;
            }

            root.expectedStop = false;
            root.phase = "";
            root.running = false;
        }
    }

    SpeedTestOverlay {
        id: overlayInstance

        layerNamespace: "caelestia-menu-disk-speedtest"
        title: root.diskName
        leftLabel: Tr.tr("READ")
        rightLabel: Tr.tr("WRITE")
        unit: "MB/s"
        stackCount: root.stackCount
        stackRank: root.stackRank
        stackCenter: root.stackCenter
        running: root.running
        leftValue: root.toRate(root.readMBps)
        rightValue: root.toRate(root.writeMBps)
        leftLive: root.running && root.phase === "read"
        rightLive: root.running && root.phase === "write"
        error: root.error
        open: root.opened
        scaleStops: [500, 1000, 2500, 5000, 10000, 15000]
    }
}
