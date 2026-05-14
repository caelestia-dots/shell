pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    property bool preferIwctl: true
    property bool nmcliAvailable: false
    property bool debugEnabled: false

    readonly property bool useIwctl: preferIwctl && (!Iwctl.probeDone || Iwctl.available)
    readonly property bool useNmcli: !useIwctl && nmcliAvailable
    readonly property var backend: useIwctl ? Iwctl : (useNmcli ? Nmcli : null)

    readonly property bool wifiEnabled: backend ? backend.wifiEnabled : false
    readonly property bool scanning: backend ? backend.scanning : false
    readonly property var networks: backend ? backend.networks : []
    readonly property var active: backend ? backend.active : null
    property var pendingConnection: backend ? backend.pendingConnection : null
    property var wirelessDeviceDetails: backend ? backend.wirelessDeviceDetails : null
    property var ethernetDeviceDetails: backend ? backend.ethernetDeviceDetails : null
    readonly property var ethernetDevices: backend ? backend.ethernetDevices : []
    readonly property var activeEthernet: backend ? backend.activeEthernet : null
    readonly property var savedConnections: backend ? backend.savedConnections : []
    readonly property var savedConnectionSsids: backend ? backend.savedConnectionSsids : []

    signal connectionFailed(string ssid)

    function dbg(message: string): void {
        if (debugEnabled) {
            console.log(`[NETBACKEND-DEBUG] ${message}`);
        }
    }

    function connectToNetworkWithPasswordCheck(ssid: string, isSecure: bool, callback: var, bssid: string): void {
        if (backend)
            backend.connectToNetworkWithPasswordCheck(ssid, isSecure, callback, bssid);
    }

    function connectToNetwork(ssid: string, password: string, bssid: string, callback: var): void {
        if (backend)
            backend.connectToNetwork(ssid, password, bssid, callback);
    }

    function disconnectFromNetwork(): void {
        if (backend)
            backend.disconnectFromNetwork();
    }

    function forgetNetwork(ssid: string, callback: var): void {
        if (backend)
            backend.forgetNetwork(ssid, callback);
    }

    function enableWifi(enabled: bool, callback: var): void {
        if (backend)
            backend.enableWifi(enabled, callback);
    }

    function toggleWifi(callback: var): void {
        if (backend)
            backend.toggleWifi(callback);
    }

    function rescanWifi(): void {
        if (backend)
            backend.rescanWifi();
    }

    function getNetworks(callback: var): void {
        if (backend)
            backend.getNetworks(callback);
    }

    function getWifiStatus(callback: var): void {
        if (backend)
            backend.getWifiStatus(callback);
    }

    function hasSavedProfile(ssid: string): bool {
        return backend ? backend.hasSavedProfile(ssid) : false;
    }

    function loadSavedConnections(callback: var): void {
        if (backend)
            backend.loadSavedConnections(callback);
    }

    function getEthernetInterfaces(callback: var): void {
        if (backend)
            backend.getEthernetInterfaces(callback);
    }

    function connectEthernet(connectionName: string, interfaceName: string, callback: var): void {
        if (backend)
            backend.connectEthernet(connectionName, interfaceName, callback);
    }

    function disconnectEthernet(connectionName: string, callback: var): void {
        if (backend)
            backend.disconnectEthernet(connectionName, callback);
    }

    function getWirelessDeviceDetails(interfaceName: string, callback: var): void {
        if (backend)
            backend.getWirelessDeviceDetails(interfaceName, callback);
    }

    function getEthernetDeviceDetails(interfaceName: string, callback: var): void {
        if (backend)
            backend.getEthernetDeviceDetails(interfaceName, callback);
    }

    onBackendChanged: {
        pendingConnection = backend ? backend.pendingConnection : null;
        wirelessDeviceDetails = backend ? backend.wirelessDeviceDetails : null;
        ethernetDeviceDetails = backend ? backend.ethernetDeviceDetails : null;
        dbg(`backend changed -> ${useIwctl ? "Iwctl" : (useNmcli ? "Nmcli" : "none")}, iwctl.available=${Iwctl.available}, iwctl.probeDone=${Iwctl.probeDone}, nmcli.available=${nmcliAvailable}`);
    }

    onPendingConnectionChanged: {
        if (backend && backend.pendingConnection !== pendingConnection)
            backend.pendingConnection = pendingConnection;
    }

    onWirelessDeviceDetailsChanged: {
        if (backend && backend.wirelessDeviceDetails !== wirelessDeviceDetails)
            backend.wirelessDeviceDetails = wirelessDeviceDetails;
    }

    onEthernetDeviceDetailsChanged: {
        if (backend && backend.ethernetDeviceDetails !== ethernetDeviceDetails)
            backend.ethernetDeviceDetails = ethernetDeviceDetails;
    }

    Connections {
        target: Iwctl

        function onConnectionFailed(ssid: string): void {
            if (root.useIwctl)
                root.connectionFailed(ssid);
        }

        function onPendingConnectionChanged(): void {
            if (root.useIwctl)
                root.pendingConnection = Iwctl.pendingConnection;
        }

        function onWirelessDeviceDetailsChanged(): void {
            if (root.useIwctl)
                root.wirelessDeviceDetails = Iwctl.wirelessDeviceDetails;
        }

        function onEthernetDeviceDetailsChanged(): void {
            if (root.useIwctl)
                root.ethernetDeviceDetails = Iwctl.ethernetDeviceDetails;
        }
    }

    Connections {
        target: Nmcli

        function onConnectionFailed(ssid: string): void {
            if (root.useNmcli)
                root.connectionFailed(ssid);
        }

        function onPendingConnectionChanged(): void {
            if (root.useNmcli)
                root.pendingConnection = Nmcli.pendingConnection;
        }

        function onWirelessDeviceDetailsChanged(): void {
            if (root.useNmcli)
                root.wirelessDeviceDetails = Nmcli.wirelessDeviceDetails;
        }

        function onEthernetDeviceDetailsChanged(): void {
            if (root.useNmcli)
                root.ethernetDeviceDetails = Nmcli.ethernetDeviceDetails;
        }
    }

    Process {
        id: checkNmcliProc

        command: ["sh", "-lc", "command -v nmcli >/dev/null 2>&1"]
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: code => { // qmllint disable signal-handler-parameters
            root.nmcliAvailable = code === 0;
            root.dbg(`nmcli available=${root.nmcliAvailable}`);
        }
    }

    onWifiEnabledChanged: dbg(`wifiEnabled -> ${wifiEnabled}`)

    Component.onCompleted: {
        dbg("onCompleted: checking nmcli availability");
        checkNmcliProc.running = true;
        pendingConnection = backend ? backend.pendingConnection : null;
        wirelessDeviceDetails = backend ? backend.wirelessDeviceDetails : null;
        ethernetDeviceDetails = backend ? backend.ethernetDeviceDetails : null;
    }
}
