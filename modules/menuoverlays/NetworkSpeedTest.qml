import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.I18n
import qs.modules.launcher.services

// Download and upload speed test overlay.
// Adapted from Omarchy's network speedtest panel (MIT License).
Scope {
    id: root

    property bool opened: false
    property string connectionName: ""

    property int stackCount: 1
    property int stackRank: 0
    property real stackCenter: 0.5

    readonly property alias overlay: overlayInstance
    readonly property string binPath: `${MenuService.userBinDir}:${MenuService.bundledBinDir}`

    property bool running: false
    property bool expectedStop: false
    property bool pendingRun: false
    property string phase: ""
    property string stderrText: ""
    property string downloadMbps: ""
    property string uploadMbps: ""
    property string error: ""

    readonly property real downloadValue: toMbps(downloadMbps)
    readonly property real uploadValue: toMbps(uploadMbps)

    function toMbps(raw: string): real {
        const value = parseFloat(raw);
        return isFinite(value) && value > 0 ? value : 0;
    }

    function open(): void {
        refreshConnectionName();
        root.opened = true;
        runSpeedTest();
    }

    function close(): void {
        root.opened = false;
        root.pendingRun = false;
        phaseTimer.stop();
        root.phase = "";
        root.running = false;
        if (speedTestProc.running) {
            root.expectedStop = true;
            speedTestProc.running = false;
        }
    }

    function refreshConnectionName(): void {
        root.connectionName = "";
        statusProc.running = false;
        statusProc.command = ["bash", "-c", `export PATH="${root.binPath}:$PATH"; exec menu-network-status`];
        statusProc.running = true;
    }

    function updateSpeedTestLine(line: string): void {
        const value = parseFloat(line);
        if (!isFinite(value) || value < 0)
            return;

        if (phase === "down")
            downloadMbps = String(value);
        else if (phase === "up")
            uploadMbps = String(value);
    }

    function runSpeedTest(): void {
        if (speedTestProc.running) {
            if (expectedStop)
                pendingRun = true;
            return;
        }
        error = "";
        downloadMbps = "";
        uploadMbps = "";
        running = true;
        startPhase("down");
    }

    function startPhase(nextPhase: string): void {
        expectedStop = false;
        phase = nextPhase;
        stderrText = "";
        speedTestProc.command = ["bash", "-c", `export PATH="${root.binPath}:$PATH"; exec menu-network-speedtest "$1"`, "menu-network-speedtest", nextPhase];
        speedTestProc.running = true;
        phaseTimer.restart();
    }

    function stopPhase(): void {
        phaseTimer.stop();
        if (speedTestProc.running) {
            expectedStop = true;
            speedTestProc.running = false;
            return;
        }
        finishPhase();
    }

    function finishPhase(): void {
        if (phase === "down") {
            startPhase("up");
            return;
        }

        phase = "";
        running = false;
        expectedStop = false;
    }

    Process {
        id: speedTestProc

        stdout: SplitParser {
            onRead: line => root.updateSpeedTestLine(line)
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
            phaseTimer.stop();

            if (root.pendingRun) {
                root.pendingRun = false;
                root.expectedStop = false;
                if (root.opened)
                    Qt.callLater(root.runSpeedTest);
                return;
            }

            if (!root.expectedStop && exitCode !== 0) {
                root.error = root.stderrText || Tr.tr("Speed test failed");
                root.phase = "";
                root.running = false;
                return;
            }

            root.expectedStop = false;
            root.finishPhase();
        }
    }

    Timer {
        id: phaseTimer

        interval: 8000
        repeat: false
        onTriggered: root.stopPhase()
    }

    Process {
        id: statusProc

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const fields = String(text || "").trim().split("\t");
                if (fields[0] === "wifi")
                    root.connectionName = fields[1] || Tr.tr("Wi-Fi");
                else if (fields[0] === "ethernet")
                    root.connectionName = Tr.tr("Ethernet");
            }
        }
    }

    SpeedTestOverlay {
        id: overlayInstance

        layerNamespace: "caelestia-menu-network-speedtest"
        title: root.connectionName
        leftLabel: Tr.tr("DOWNLOAD")
        rightLabel: Tr.tr("UPLOAD")
        stackCount: root.stackCount
        stackRank: root.stackRank
        stackCenter: root.stackCenter
        runAgainTooltip: Tr.tr("Measure again via fast.com")
        running: root.running
        leftValue: root.downloadValue
        rightValue: root.uploadValue
        leftLive: root.running && root.phase === "down"
        rightLive: root.running && root.phase === "up"
        error: root.error
        open: root.opened
    }
}
