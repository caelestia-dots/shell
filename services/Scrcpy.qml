pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Services
import Caelestia.I18n

Singleton {
    id: root

    // adb and scrcpy are optional dependencies
    property bool available

    // Keyed by KDE Connect device id: { serial, wireless }
    property var links: ({})
    // Keyed by KDE Connect device id: true while its mirroring window is open
    property var sessions: ({})
    // Keyed by KDE Connect device id: true while connecting or starting
    property var busy: ({})
    // Whether a USB device is waiting for the "Allow USB debugging" prompt
    property bool unauthorizedUsb

    // IPv4 addresses of adb devices by serial, so the phone is only asked once
    property var serialAddresses: ({})
    property bool refreshing
    property var sessionProcesses: ({})
    // Action to run once a device that was just connected appears in links
    property var pendingConnect: null

    // Connect action waiting for the phone's service to be discovered
    property var pendingService: null
    property int watchers

    // The pairing in progress: { deviceId, status, error }. status is "waiting" for
    // the pairing screen, "pairing", "connecting" or "failed".
    property var pairing: null
    // The phone's pairing service, once its pairing screen is open
    readonly property var pairingService: pairing ? findService(pairing.deviceId, "pairing") : null

    signal failed(string device, string error)
    // The phone has never been paired with this computer over wireless debugging
    signal pairingRequired(string device)
    signal paired(string device)

    function fail(deviceId: string, error: string): void {
        console.warn(lc, `Screen mirroring for ${deviceId} failed: ${error}`);
        failed(deviceId, error);
    }

    function ipv4Addresses(deviceId: string): list<string> {
        const device = KdeConnect.devices.find(d => d.id === deviceId);
        return (device?.addresses ?? []).filter(a => /^\d{1,3}(\.\d{1,3}){3}$/.test(a));
    }

    function hasLink(deviceId: string): bool {
        return links[deviceId] !== undefined;
    }

    function isRunning(deviceId: string): bool {
        return sessions[deviceId] !== undefined;
    }

    function isBusy(deviceId: string): bool {
        return busy[deviceId] === true;
    }

    function setBusy(deviceId: string, value: bool): void {
        const next = Object.assign({}, busy);
        if (value)
            next[deviceId] = true;
        else
            delete next[deviceId];
        busy = next;
    }

    function run(command: list<string>, callback: var): void {
        const proc = commandComp.createObject(root, {
            command,
            callback
        });
        proc.running = true;
    }

    // Maps adb devices to KDE Connect devices through their network addresses.
    // Wireless serials carry the address, other devices are asked for theirs.
    function refresh(): void {
        if (!available || refreshing)
            return;

        refreshing = true;
        run(["adb", "devices"], result => {
            const ready = [];
            let unauthorized = false;

            for (const line of result.output.split("\n").slice(1)) {
                const [serial, state] = line.trim().split(/\s+/);
                if (!serial)
                    continue;
                if (state === "device")
                    ready.push(serial);
                else if (state === "unauthorized" && !isWireless(serial))
                    unauthorized = true;
            }

            unauthorizedUsb = unauthorized;
            resolveAddresses(ready, 0);
        });
    }

    function isWireless(serial: string): bool {
        return /^\d{1,3}(\.\d{1,3}){3}:\d+$/.test(serial) || serial.includes("._adb-tls-connect._tcp");
    }

    function resolveAddresses(serials: list<string>, index: int): void {
        if (index >= serials.length) {
            updateLinks(serials);
            return;
        }

        const serial = serials[index];
        const direct = serial.match(/^(\d{1,3}(?:\.\d{1,3}){3}):\d+$/);

        if (direct || serialAddresses[serial]) {
            if (direct)
                cacheAddresses(serial, [direct[1]]);
            resolveAddresses(serials, index + 1);
            return;
        }

        run(["adb", "-s", serial, "shell", "ip", "-4", "-o", "addr"], result => {
            const addresses = [...result.output.matchAll(/inet (\d{1,3}(?:\.\d{1,3}){3})\//g)].map(m => m[1]).filter(a => !a.startsWith("127."));
            cacheAddresses(serial, addresses);
            resolveAddresses(serials, index + 1);
        });
    }

    function cacheAddresses(serial: string, addresses: list<string>): void {
        const next = Object.assign({}, serialAddresses);
        next[serial] = addresses;
        serialAddresses = next;
    }

    function updateLinks(serials: list<string>): void {
        const next = {};

        for (const device of KdeConnect.devices) {
            const addresses = ipv4Addresses(device.id);
            const matches = serials.filter(s => (serialAddresses[s] ?? []).some(a => addresses.includes(a)));
            // A cable is faster and more reliable than Wi-Fi when both are there
            const serial = matches.find(s => !isWireless(s)) ?? matches[0];

            if (serial)
                next[device.id] = {
                    serial,
                    wireless: isWireless(serial)
                };
        }

        // Forget serials which are gone, so a reused serial is looked up again
        const cache = {};
        for (const serial of serials)
            if (serialAddresses[serial])
                cache[serial] = serialAddresses[serial];

        serialAddresses = cache;
        links = next;
        refreshing = false;
    }

    function findService(deviceId: string, kind: string): var {
        const addresses = ipv4Addresses(deviceId);
        return discovery.services.find(s => s.kind === kind && addresses.includes(s.address)) ?? null;
    }

    // Connects to the phone's wireless debugging service
    function connect(deviceId: string, onConnected: var): void {
        if (ipv4Addresses(deviceId).length === 0) {
            fail(deviceId, Tr.tr("The phone is not on the same network"));
            return;
        }

        setBusy(deviceId, true);

        const service = findService(deviceId, "connect");
        if (service) {
            connectTo(deviceId, service, onConnected);
            return;
        }

        // Discovery may have only just started, so give the phone a moment to answer
        pendingService = {
            deviceId,
            onConnected
        };
        discovery.query();
        serviceWait.restart();
    }

    function connectTo(deviceId: string, service: var, onConnected: var): void {
        run(["adb", "connect", `${service.address}:${service.port}`], result => {
            // adb exits with 0 even when connecting fails, so read its output
            const output = result.output.trim();
            if (!/^(already )?connected to /.test(output)) {
                setBusy(deviceId, false);
                // The phone answered on the network, so this is almost always a phone
                // which has not been paired with this computer yet
                console.info(lc, `Connecting to ${deviceId} failed, pairing needed: ${output || result.error.trim()}`);
                pairingRequired(deviceId);
                return;
            }

            pendingConnect = {
                deviceId,
                onConnected
            };
            // Look up the new device even if a refresh is already running
            refreshing = false;
            refresh();
        });
    }

    function start(deviceId: string): void {
        if (!available || isRunning(deviceId) || isBusy(deviceId))
            return;

        if (!hasLink(deviceId)) {
            connect(deviceId, () => start(deviceId));
            return;
        }

        const device = KdeConnect.devices.find(d => d.id === deviceId);
        const args = ["scrcpy", "--serial", links[deviceId].serial, "--window-title", device?.name ?? "scrcpy", "--keep-active"];

        const proc = sessionComp.createObject(root, {
            deviceId,
            command: args
        });

        const nextProcesses = Object.assign({}, sessionProcesses);
        nextProcesses[deviceId] = proc;
        sessionProcesses = nextProcesses;

        const nextSessions = Object.assign({}, sessions);
        nextSessions[deviceId] = true;
        sessions = nextSessions;

        proc.running = true;
    }

    function setPairing(changes: var): void {
        pairing = pairing ? Object.assign({}, pairing, changes) : null;
    }

    // Waits for the phone's "Pair device with pairing code" screen, whose service
    // provides the port the code is entered for
    function startPairing(deviceId: string): void {
        if (!available)
            return;

        pairing = {
            deviceId,
            status: "waiting",
            error: ""
        };
        discovery.query();
    }

    function submitPairingCode(code: string): void {
        const current = pairing;
        const service = pairingService;
        if (!current || !service || !/^\d{6}$/.test(code) || current.status === "pairing" || current.status === "connecting")
            return;

        setPairing({
            status: "pairing",
            error: ""
        });

        run(["adb", "pair", `${service.address}:${service.port}`, code], result => {
            if (pairing?.deviceId !== current.deviceId)
                return;

            // Like connect, adb pair exits with 0 on failure
            if (!result.output.includes("Successfully paired to")) {
                setPairing({
                    status: "failed",
                    error: (result.output.trim() || result.error.trim()).replace(/^Failed: /, "") || Tr.tr("Pairing failed")
                });
                return;
            }

            setPairing({
                status: "connecting"
            });
            paired(current.deviceId);

            connect(current.deviceId, () => {
                if (pairing?.deviceId === current.deviceId)
                    pairing = null;
            });
        });
    }

    function cancelPairing(): void {
        pairing = null;
    }

    // Keeps discovery running while something shows mirroring controls
    function watch(): void {
        watchers++;
    }

    function unwatch(): void {
        watchers = Math.max(0, watchers - 1);
    }

    function stop(deviceId: string): void {
        const proc = sessionProcesses[deviceId];
        if (!proc)
            return;

        proc.stopped = true;
        proc.running = false;
    }

    function endSession(deviceId: string): void {
        const nextProcesses = Object.assign({}, sessionProcesses);
        delete nextProcesses[deviceId];
        sessionProcesses = nextProcesses;

        const nextSessions = Object.assign({}, sessions);
        delete nextSessions[deviceId];
        sessions = nextSessions;
    }

    Component.onCompleted: run(["sh", "-c", "command -v adb && command -v scrcpy"], result => {
        available = result.exitCode === 0;
        refresh();
    })

    onFailed: (device, error) => {
        // Connecting after pairing failed, so the pairing view shows why
        if (pairing?.deviceId === device && pairing.status === "connecting")
            setPairing({
                status: "failed",
                error
            });
    }
    onPairingRequired: device => {
        if (pairing?.deviceId === device && pairing.status === "connecting")
            setPairing({
                status: "failed",
                error: Tr.tr("Paired, but the phone refused the connection")
            });
    }
    onLinksChanged: {
        const pending = pendingConnect;
        if (!pending)
            return;

        pendingConnect = null;
        setBusy(pending.deviceId, false);

        if (hasLink(pending.deviceId))
            pending.onConnected?.();
        else
            fail(pending.deviceId, Tr.tr("Connected, but could not match the phone"));
    }

    Connections {
        function onDevicesChanged(): void {
            root.refresh();
        }

        target: KdeConnect
    }

    AdbDiscovery {
        id: discovery

        active: root.available && (root.watchers > 0 || root.pairing !== null || Object.keys(root.busy).length > 0)

        onServicesChanged: {
            const pending = root.pendingService;
            const service = pending ? root.findService(pending.deviceId, "connect") : null;
            if (!service)
                return;

            serviceWait.stop();
            root.pendingService = null;
            root.connectTo(pending.deviceId, service, pending.onConnected);
        }
    }

    Timer {
        id: serviceWait

        interval: 4000
        onTriggered: {
            const pending = root.pendingService;
            if (!pending)
                return;

            root.pendingService = null;
            root.setBusy(pending.deviceId, false);
            root.fail(pending.deviceId, Tr.tr("Wireless debugging is not enabled on the phone"));
        }
    }

    Component {
        id: commandComp

        Process {
            id: proc

            property var callback

            environment: ({
                    LC_ALL: "C"
                })

            stdout: StdioCollector {
                id: output
            }

            stderr: StdioCollector {
                id: error
            }

            onExited: code => { // qmllint disable signal-handler-parameters
                Qt.callLater(() => {
                    proc.callback?.({
                        exitCode: code,
                        output: output.text ?? "",
                        error: error.text ?? ""
                    });
                    proc.destroy();
                });
            }
        }
    }

    Component {
        id: sessionComp

        Process {
            id: session

            property string deviceId
            // Set when stopped from the shell, which ends scrcpy with a signal
            property bool stopped

            stderr: StdioCollector {
                id: sessionError
            }

            onExited: code => { // qmllint disable signal-handler-parameters
                Qt.callLater(() => {
                    root.endSession(session.deviceId);

                    // Closing the window exits cleanly. Otherwise show scrcpy's own error.
                    if (code !== 0 && !session.stopped) {
                        const errors = (sessionError.text ?? "").split("\n").filter(l => l.startsWith("ERROR: "));
                        const message = errors.length > 0 ? errors[errors.length - 1].slice(7) : Tr.tr("Screen mirroring stopped unexpectedly");
                        root.fail(session.deviceId, message);
                    }

                    session.destroy();
                });
            }
        }
    }

    LoggingCategory {
        id: lc

        name: "caelestia.qml.services.scrcpy"
        defaultLogLevel: LoggingCategory.Info
    }
}
