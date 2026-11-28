import QtQuick
import Quickshell.Io
import qs.modules.launcher.services

// Ported from omarchy's speedtest_Panel.qml: download and upload dials in
// Mbps, titled with the connection under test. Summoning starts a fresh run,
// dismissing stops the traffic.
Item {
    id: root

    property bool opened: false
    property string connectionName: ""

    // Stacking info supplied by the menu-overlay coordinator (MenuOverlays):
    // how many overlays are open and this one's vertical position.
    property int stackCount: 1
    property int stackRank: 0
    property real stackCenter: 0.5

    property bool running: false
    property bool expectedStop: false
    property bool pendingRun: false
    property string phase: ""
    property string stderrText: ""
    property string downloadMbps: ""
    property string uploadMbps: ""
    property string error: ""

    // The underlying overlay, exposed so the coordinator in MenuOverlays can
    // observe its close/run-again requests and act on every overlay at once.
    readonly property alias overlay: overlayInstance
    readonly property string binPath: `${MenuService.userBinDir}:${MenuService.bundledBinDir}`

    readonly property real downloadValue: toMbps(downloadMbps)
    readonly property real uploadValue: toMbps(uploadMbps)

    function toMbps(raw) {
        const value = parseFloat(raw);
        return isFinite(value) && value > 0 ? value : 0;
    }

    function open() {
        refreshConnectionName();
        root.opened = true;
        runSpeedTest();
    }

    function close() {
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

    function refreshConnectionName() {
        root.connectionName = "";
        statusProc.running = false;
        statusProc.running = true;
    }

    function updateSpeedTestLine(line) {
        const value = parseFloat(line);
        if (!isFinite(value) || value < 0)
            return;

        if (phase === "down")
            downloadMbps = String(value);
        else if (phase === "up")
            uploadMbps = String(value);
    }

    function runSpeedTest() {
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

    function startPhase(nextPhase) {
        expectedStop = false;
        phase = nextPhase;
        stderrText = "";
        speedTestProc.command = ["bash", "-c", `export PATH="${root.binPath}:$PATH"; exec menu-network-speedtest "$1"`, "menu-network-speedtest", nextPhase];
        speedTestProc.running = true;
        phaseTimer.restart();
    }

    function stopPhase() {
        phaseTimer.stop();
        if (speedTestProc.running) {
            expectedStop = true;
            speedTestProc.running = false;
            return;
        }
        finishPhase();
    }

    function finishPhase() {
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
                root.error = root.stderrText || "Speed test failed";
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

        // Match the disk speed test's 8s per phase so the two open side by
        // side finish at roughly the same time.
        interval: 8000
        repeat: false
        onTriggered: root.stopPhase()
    }

    Process {
        id: statusProc

        command: ["bash", "-c", `export PATH="${root.binPath}:$PATH"; exec menu-network-status`]

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const fields = String(text || "").trim().split("\t");
                if (fields[0] === "wifi")
                    root.connectionName = fields[1] || "Wi-Fi";
                else if (fields[0] === "ethernet")
                    root.connectionName = "Ethernet";
            }
        }
    }

    SpeedTestOverlay {
        id: overlayInstance

        layerNamespace: "caelestia-menu-network-speedtest"
        title: root.connectionName
        leftLabel: "DOWNLOAD"
        rightLabel: "UPLOAD"
        stackCount: root.stackCount
        stackRank: root.stackRank
        stackCenter: root.stackCenter
        runAgainTooltip: "Measure again via fast.com"
        running: root.running
        leftValue: root.downloadValue
        rightValue: root.uploadValue
        leftLive: root.running && root.phase === "down"
        rightLive: root.running && root.phase === "up"
        error: root.error
        open: root.opened
    }
}
