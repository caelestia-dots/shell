pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Services

// Saved connection profiles, split out of Nmcli along their own boundary.
//
// State comes from NetworkManager's Settings interface over dbus. This replaces
// parsing `nmcli connection show` and then spawning a further nmcli per wifi
// profile just to read its SSID, one at a time through a queue. Actions stay on
// the CLI: adding, deleting and toggling autoconnect have nothing to parse and
// nothing to gain from dbus.
Singleton {
    id: root

    readonly property bool ready: NetworkProfiles.ready

    readonly property list<var> list: {
        const found = [];
        for (const profile of NetworkProfiles.profiles)
            found.push(profile);
        return found;
    }

    readonly property list<var> wireless: root.list.filter(p => p.type === "802-11-wireless")

    // SSIDs with a saved profile, deduplicated case-insensitively the way the
    // parsed version was.
    readonly property list<string> ssids: {
        const seen = new Map();
        for (const profile of root.wireless)
            if (profile.ssid && !seen.has(profile.ssid.toLowerCase()))
                seen.set(profile.ssid.toLowerCase(), profile.ssid);
        return Array.from(seen.values());
    }

    // Key management per saved SSID, lowercased key, e.g. "wpa-psk".
    readonly property var securityBySsid: {
        const security = {};
        for (const profile of root.wireless)
            if (profile.ssid)
                security[profile.ssid.toLowerCase()] = profile.keyMgmt;
        return security;
    }

    function find(ssid: string): var {
        if (!ssid)
            return null;

        const wanted = ssid.toLowerCase().trim();
        return root.wireless.find(p => p.ssid && p.ssid.toLowerCase().trim() === wanted) ?? null;
    }

    function has(ssid: string): bool {
        return root.find(ssid) !== null;
    }

    function keyMgmtFor(ssid: string): string {
        return root.find(ssid)?.keyMgmt ?? "";
    }

    // Turns NetworkManager's key management into the label the UI shows.
    function securityLabel(keyMgmt: string): string {
        switch ((keyMgmt || "").trim().toLowerCase()) {
        case "":
        case "none":
            return qsTr("Open");
        case "sae":
            return "WPA3";
        case "wpa-psk":
            return "WPA2";
        case "wpa-eap":
        case "wpa-eap-suite-b-192":
            return qsTr("Enterprise");
        case "owe":
            return qsTr("Enhanced Open");
        case "ieee8021x":
            return "802.1X";
        default:
            return keyMgmt.trim();
        }
    }

    function securityFor(ssid: string): string {
        const profile = root.find(ssid);
        return profile ? root.securityLabel(profile.keyMgmt) : "";
    }

    // One-shot nmcli call; only the exit code matters, so there's nothing to
    // parse and no shared state to race.
    function run(args: list<string>, callback: var): void {
        const proc = actionProc.createObject(root, {
            command: ["nmcli", ...args],
            callback: callback ?? null
        });
        proc.running = true;
    }

    function forget(name: string, callback: var): void {
        if (!name) {
            if (callback)
                callback(false);
            return;
        }
        run(["connection", "delete", name], callback);
    }

    function setAutoconnect(name: string, autoconnect: bool, callback: var): void {
        if (!name) {
            if (callback)
                callback(false);
            return;
        }
        // No refetch afterwards: the profile reports its own edits over dbus.
        run(["connection", "modify", name, "connection.autoconnect", autoconnect ? "yes" : "no"], callback);
    }

    Component {
        id: actionProc

        Process {
            id: proc

            property var callback: null

            environment: ({
                    LANG: "C.UTF-8",
                    LC_ALL: "C.UTF-8"
                })

            onExited: code => { // qmllint disable signal-handler-parameters
                const callback = proc.callback;
                proc.destroy();
                callback?.(code === 0);
            }
        }
    }
}
