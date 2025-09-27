pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config
import Caelestia.Services
import Caelestia

Singleton {
    id: root

    property bool connected: false
    readonly property string connectionName: Config.utilities.vpn.connectionName
    readonly property bool connecting: connectProc.running || disconnectProc.running
    readonly property bool enabled: Config.utilities.vpn.enabled

    onConnectedChanged: {
        if (!Config.utilities.toasts.vpnChanged)
            return;

        if (connected) {
            Toaster.toast(qsTr("VPN connected"), qsTr("Connected to %1").arg(connectionName), "vpn_key");
        } else {
            Toaster.toast(qsTr("VPN disconnected"), qsTr("Disconnected from %1").arg(connectionName), "vpn_key_off");
        }
    }

    function connect(): void {
        if (!connected && !connecting) {
            connectProc.exec(["pkexec", "wg-quick", "up", connectionName]);
        }
    }

    function disconnect(): void {
        if (connected && !connecting) {
            disconnectProc.exec(["pkexec", "wg-quick", "down", connectionName]);
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
        if (enabled) {
            statusProc.running = true;
        }
    }

    Process {
        id: nmMonitor
        running: enabled
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: statusCheckTimer.restart()
        }
    }

    Process {
        id: statusProc

        command: ["nmcli", "-g", "NAME,DEVICE", "connection", "show", "--active"]
        environment: ({
            LANG: "C.UTF-8",
            LC_ALL: "C.UTF-8"
        })
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                root.connected = lines.some(line => {
                    const [name, device] = line.split(":");
                    return name === connectionName && device && device !== "--";
                });
            }
        }
    }

    Process {
        id: connectProc
        onExited: statusCheckTimer.start()
        stderr: StdioCollector {
            onStreamFinished: {
                const error = text.trim();
                if (error && !error.includes("[#]") && !error.includes("already exists")) {
                    console.warn("VPN connection error:", error);
                } else if (error.includes("already exists")) {
                    root.connected = true;
                }
            }
        }
    }

    Process {
        id: disconnectProc
        onExited: statusCheckTimer.start()
        stderr: StdioCollector {
            onStreamFinished: {
                const error = text.trim();
                if (error && !error.includes("[#]")) {
                    console.warn("VPN disconnection error:", error);
                }
            }
        }
    }

    Timer {
        id: statusCheckTimer
        interval: 500
        onTriggered: root.checkStatus()
    }

    Component.onCompleted: enabled && statusCheckTimer.start()
}
