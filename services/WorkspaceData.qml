pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

/**
 * Provides access to some Hyprland data not available in Quickshell.Hyprland.
 */
Singleton {
    id: root

    property var windowByAddress
    property var monitorById
    property var addresses
    property var clientsRevision: 1
    property var windowList
    property var monitorList

    function updateWindowList() {
        getClients.running = true;
    }
    function updateMonitors() {
        getMonitors.running = true;
    }
    function updateAll() {
        console.log("Reloading Monitor and Window Information");
        updateWindowList();
        updateMonitors();
    }

    // Get Window Data from hypctl
    Process {
        id: getClients
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            id: clientsCollector
            onStreamFinished: {
                let parsed;
                try {
                    parsed = JSON.parse(clientsCollector.text);
                } catch (error) {
                    console.warn("overview: failed to parse hyprctl clients output", error);
                    return;
                }
                root.windowList = parsed;
                let tempWinByAddress = {};
                for (var i = 0; i < root.windowList.length; ++i) {
                    var win = root.windowList[i];
                    tempWinByAddress[win.address] = win;
                }
                root.windowByAddress = tempWinByAddress;
                root.addresses = root.windowList.map(win => win.address);
                root.clientsRevision += 1;
            }
        }
    }
    //  Get Monitordata from hyprctl
    Process {
        id: getMonitors
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            id: monitorCollector
            onStreamFinished: {
                let parsed;
                try {
                    parsed = JSON.parse(monitorCollector.text);
                } catch (error) {
                    console.warn("overview: failed to parse hyprctl monitors output", error);
                    return;
                }
                root.monitorList = parsed;
                let tempMonById = {};
                for (var i = 0; i < root.monitorList.length; ++i) {
                    var mon = root.monitorList[i];
                    tempMonById[mon.id] = mon;
                }
                root.monitorById = tempMonById;
                root.clientsRevision += 1;
            }
        }
    }
    Component.onCompleted: {
        updateAll();
    }
}
