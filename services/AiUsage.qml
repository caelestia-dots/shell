pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Plan limits (5-hour session and weekly) of Claude Code and Antigravity, fetched by assets/ai-usage.py
Singleton {
    id: root

    property var claude: ({})
    property var agy: ({})
    property real fetchedAt: 0
    readonly property bool loading: claudeProc.running || agyProc.running

    // The providers rate-limit these endpoints, so refresh at most every 5 minutes unless forced
    function refresh(force: bool): void {
        if (loading || (!force && Date.now() - fetchedAt < 5 * 60000))
            return;
        fetchedAt = Date.now();
        claudeProc.running = true;
        agyProc.running = true;
    }

    function parse(text: string): var {
        try {
            return JSON.parse(text);
        } catch (e) {
            return {
                error: "invalid"
            };
        }
    }

    Process {
        id: claudeProc

        command: ["python3", "-I", Quickshell.shellPath("assets/ai-usage.py"), "claude"]
        stdout: StdioCollector {
            onStreamFinished: root.claude = root.parse(text)
        }
    }

    Process {
        id: agyProc

        command: ["python3", "-I", Quickshell.shellPath("assets/ai-usage.py"), "agy"]
        stdout: StdioCollector {
            onStreamFinished: root.agy = root.parse(text)
        }
    }
}
