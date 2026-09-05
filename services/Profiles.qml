pragma Singleton

import QtQuick
import Quickshell
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

    // Profile names, i.e. what nmcli takes as a connection argument.
    readonly property list<string> names: root.list.map(p => p.id)

    // SSIDs with a saved profile, deduplicated case-insensitively the way the
    // parsed version was.
    readonly property list<string> ssids: {
        const seen = new Map();
        for (const profile of root.wireless)
            if (profile.ssid && !seen.has(profile.ssid.toLowerCase()))
                seen.set(profile.ssid.toLowerCase(), profile.ssid);
        return Array.from(seen.values());
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

    // The profile name for an SSID. Falls back to the SSID itself, which is
    // what NetworkManager names a profile by default.
    function nameFor(ssid: string): string {
        if (!ssid)
            return "";

        const wanted = ssid.toLowerCase().trim();
        return root.find(ssid)?.id ?? root.names.find(n => n && n.toLowerCase().trim() === wanted) ?? ssid;
    }

    // Whether anything saved matches this SSID, by profile SSID or by name.
    function hasName(ssid: string): bool {
        if (!ssid)
            return false;

        const wanted = ssid.toLowerCase().trim();
        return root.has(ssid) || root.names.some(n => n && n.toLowerCase().trim() === wanted);
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

    // Looks a profile up by SSID first, then by name, since callers pass
    // whichever they have.
    function profileFor(nameOrSsid: string): var {
        if (!nameOrSsid)
            return null;

        const wanted = nameOrSsid.toLowerCase().trim();
        return root.find(nameOrSsid) ?? root.list.find(p => p.id && p.id.toLowerCase().trim() === wanted) ?? null;
    }

    // The saved IPv4 configuration, in the shape the parsed nmcli output had.
    function ipv4ConfigFor(nameOrSsid: string): var {
        const profile = root.profileFor(nameOrSsid);
        if (!profile)
            return null;

        // "auto-dns" isn't a NetworkManager method; it's how the UI
        // distinguishes DHCP with custom DNS from plain DHCP.
        const method = profile.ipv4Method || "auto";

        return {
            method: method === "auto" && profile.ipv4IgnoreAutoDns ? "auto-dns" : method,
            address: profile.ipv4Address,
            gateway: profile.ipv4Gateway,
            dns: profile.ipv4Dns.join(", "),
            ignoreAutoDns: profile.ipv4IgnoreAutoDns,
            autoconnect: profile.autoconnect
        };
    }

    function forget(name: string, callback: var): void {
        if (!name) {
            if (callback)
                callback(false);
            return;
        }
        NmAction.run(["connection", "delete", name], callback);
    }

    // Turning autoconnect off also makes NetworkManager ask for the password on
    // the next manual connect rather than silently reusing the stored one
    // (psk-flags 2 = "not saved, always ask"); turning it back on restores
    // psk-flags 0 so the next password is saved.
    function setAutoconnect(name: string, autoconnect: bool, callback: var): void {
        if (!name) {
            if (callback)
                callback(false);
            return;
        }

        const base = ["connection", "modify", name, "connection.autoconnect", autoconnect ? "yes" : "no"];
        const cmd = autoconnect ? [...base, "802-11-wireless-security.psk-flags", "0"] : [...base, "802-11-wireless-security.psk-flags", "2", "802-11-wireless-security.psk", ""];

        // No refetch afterwards: the profile reports its own edits over dbus.
        NmAction.run(cmd, (success, error) => {
            // Open networks have no security settings, so nmcli rejects those
            // fields. Retry with just the autoconnect change.
            if (!success && (error.includes("802-11-wireless-security") || error.includes("is not a valid property") || error.includes("Error: invalid"))) {
                NmAction.run(base, callback);
                return;
            }

            if (callback)
                callback(success);
        });
    }
}
