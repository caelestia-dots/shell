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
            connectProc.exec(["wg-quick", "up", connectionName]);
        }
    }

    function disconnect(): void {
        if (connected && !connecting) {
            disconnectProc.exec(["wg-quick", "down", connectionName]);
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

    // Monitor NetworkManager for connection state changes
    Process {
        id: nmMonitor
        
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: {
                statusCheckTimer.restart();
            }
        }
    }

    Process {
        id: statusProc

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
            statusCheckTimer.start();
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
            statusCheckTimer.start();
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
        id: statusCheckTimer
        interval: 500
        onTriggered: root.checkStatus()
    }

    Component.onCompleted: {
        statusCheckTimer.start();
    }
}
