pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Networking
import Caelestia.Services

Singleton {
    id: root

    readonly property WifiDevice wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property WiredDevice wiredDevice: Networking.devices.values.find(d => d.type === DeviceType.Wired) ?? null

    property bool isConnected: (wifiDevice?.connected || wiredDevice?.connected) ?? false
    readonly property bool connecting: wifiDevice?.state === ConnectionState.Connecting
    property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool scanning: wifiDevice?.scannerEnabled ?? false

    readonly property list<var> networks: wifiDevice?.networks.values ?? []
    readonly property var active: networks.find(n => n.connected) ?? null

    readonly property list<var> savedNetworks: networks.filter(n => n.known)
    readonly property list<string> savedConnectionSsids: savedNetworks.map(n => n.name)
    readonly property list<string> savedConnections: savedConnectionSsids

    readonly property var savedConnectionSecurity: {
        const map = {};
        for (const n of savedNetworks) {
            map[n.name.toLowerCase().trim()] = WifiSecurityType.toString(n.security);
        }
        return map;
    }

    property var pendingConnection: null

    readonly property var wirelessDeviceDetails: ({
        macAddress: wifiDevice?.address ?? "",
        ipAddress: active?.nmSettings?.[0]?.read()?.["ipv4"]?.["addresses"]?.[0]?.[0] ?? "",
        gateway: active?.nmSettings?.[0]?.read()?.["ipv4"]?.["gateway"] ?? "",
        dns: active?.nmSettings?.[0]?.read()?.["ipv4"]?.["dns"] ?? ""
    })

    readonly property var ethernetDeviceDetails: ({
        macAddress: wiredDevice?.address ?? "",
        ipAddress: "",
        gateway: "",
        dns: ""
    })

    readonly property list<var> ethernetDevices: (Networking.devices.values.filter(d => d.type === DeviceType.Wired) ?? []).map(d => ({
        iface: d.name,
        name: d.name,
        address: d.address,
        connected: d.connected,
        hasLink: d.hasLink,
        speed: d.linkSpeed,
        state: d.hasLink ? (d.connected ? "connected" : "disconnected") : "unavailable",
        connection: d.name,
        device: d
    }))

    readonly property var activeEthernet: ethernetDevices.find(d => d.connected) ?? null
    readonly property bool hasAvailableEthernet: ethernetDevices.some(d => d.state !== "unavailable")

    readonly property string ethernetSpeed: {
        const speed = wiredDevice?.linkSpeed ?? 0;
        if (speed <= 0) return "";
        return speed >= 1000 ? `${speed / 1000} Gbps` : `${speed} Mbps`;
    }
    property string ethernetDataUsage: ""
    property list<var> activeProcesses: []

    property var connectionCheckTimer: ({ stop: () => {}, start: () => {}, running: false })
    property var immediateCheckTimer: ({ stop: () => {}, start: () => {}, running: false, checkCount: 0 })

    function savedSecurityFor(ssid: string): string {
        if (!ssid)
            return "";
        return savedConnectionSecurity[ssid.toLowerCase().trim()] || "";
    }

    function findNetwork(ssid: string): var {
        if (!ssid)
            return null;
        return networks.find(n => n.name === ssid) ?? null;
    }

    function hasSavedProfile(ssid: string): bool {
        if (!ssid)
            return false;
        const ssidLower = ssid.toLowerCase().trim();
        return savedNetworks.some(n => n.name.toLowerCase().trim() === ssidLower);
    }
}
