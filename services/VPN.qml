pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

Singleton {
    id: root

    property bool connected: false
    readonly property string connectionName: Config.utilities.vpn.connectionName
    readonly property bool connecting: connectProc.running || disconnectProc.running
    readonly property bool enabled: Config.utilities.vpn.enabled

    function connect(): void {
        if (!connected && !connecting) {
            connectProc.exec(["sudo", "wg-quick", "up", connectionName]);
        }
    }

    function disconnect(): void {
        if (connected && !connecting) {
            disconnectProc.exec(["sudo", "wg-quick", "down", connectionName]);
        }
    }

    function toggle(): void {
        if (connected) {
            disconnect();
        } else {
            connect();
        }
    }

    function checkStatus(): void {
        statusProc.running = true;
    }

    Process {
        id: statusProc

        running: true
        command: ["sudo", "wg", "show", connectionName]
        stdout: StdioCollector {
            onStreamFinished: {
                root.connected = text.trim().length > 0;
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0) {
                    root.connected = false;
                }
            }
        }
    }

    Process {
        id: connectProc

        onExited: {
            statusTimer.start();
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0 && !text.includes("[#]") && !text.includes("already exists")) {
                    console.warn("VPN connection error:", text);
                } else if (text.includes("already exists")) {
                    root.connected = true;
                }
            }
        }
    }

    Process {
        id: disconnectProc

        onExited: {
            statusTimer.start();
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0 && !text.includes("[#]")) {
                    console.warn("VPN disconnection error:", text);
                }
            }
        }
    }

    Timer {
        id: statusTimer
        interval: 1000
        onTriggered: root.checkStatus()
    }

    Timer {
        running: true
        repeat: true
        interval: 30000
        onTriggered: root.checkStatus()
    }
}
