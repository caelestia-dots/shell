pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Caelestia.Config

Singleton {
    id: root

    // Our tinted icon theme, rebuilt in place on every style change. Qt caches theme icons by name, so
    // its icons are served as file URLs with a revision that changes whenever the theme is rebuilt
    readonly property string tintedTheme: `${Quickshell.env("HOME")}/.local/share/icons/YAMIS-Hallownest`
    property var tinted: ({})
    property int tintedRev
    property bool rescanQueued
    readonly property var weatherIcons: ({
            "0": "clear_day",
            "1": "clear_day",
            "2": "partly_cloudy_day",
            "3": "cloud",
            "45": "foggy",
            "48": "foggy",
            "51": "rainy",
            "53": "rainy",
            "55": "rainy",
            "56": "rainy",
            "57": "rainy",
            "61": "rainy",
            "63": "rainy",
            "65": "rainy",
            "66": "rainy",
            "67": "rainy",
            "71": "cloudy_snowing",
            "73": "cloudy_snowing",
            "75": "snowing_heavy",
            "77": "cloudy_snowing",
            "80": "rainy",
            "81": "rainy",
            "82": "rainy",
            "85": "cloudy_snowing",
            "86": "snowing_heavy",
            "95": "thunderstorm",
            "96": "thunderstorm",
            "99": "thunderstorm"
        })

    // qmlformat off
    readonly property list<string> networkIcons: [
        "signal_wifi_0_bar",
        "network_wifi_1_bar",
        "network_wifi_2_bar",
        "network_wifi_3_bar",
        "network_wifi"
    ]

    readonly property var bluetoothIconRules: [
        [["headset", "headphones"], "headphones"],
        [["audio"], "speaker"],
        [["phone"], "smartphone"],
        [["mouse"], "mouse"],
        [["keyboard"], "keyboard"]
    ]

    readonly property var notifIconRules: [
        [["reboot"], "restart_alt"],
        [["recording"], "screen_record"],
        [["battery"], "power"],
        [["screenshot"], "screenshot_monitor"],
        [["welcome"], "waving_hand"],
        [["time", "a break"], "schedule"],
        [["installed"], "download"],
        [["update"], "update"],
        [["unable to"], "deployed_code_alert"],
        [["profile"], "person"],
        [["file"], "folder_copy"]
    ]
    // qmlformat on

    /**
     * Checks if a name matches an icon rule. See the IconRule type in the config module.
     */

    // Drop-in for Quickshell.iconPath that sees the tinted theme change
    function iconPath(icon: var, fallback: var): string {
        const path = tinted[icon];
        if (path)
            return `file://${path}?v=${tintedRev}`;
        return fallback === undefined ? Quickshell.iconPath(icon) : Quickshell.iconPath(icon, fallback);
    }

    function reloadTinted(): void {
        if (scan.running)
            rescanQueued = true;
        else
            scan.running = true;
    }

    function getAppIcon(name: string, fallback: string): string {
        const icon = DesktopEntries.heuristicLookup(name)?.icon;
        if (fallback !== "undefined")
            return iconPath(icon, fallback);
        return iconPath(icon);
    }

    /**
     * Accepts a list of tables containing matching rules (strings) and their corresponding results.
     * If any of the strings are found in the text, returns the result associated with them. Otherwise returns the fallback.
     */
    function matchIcon(text: string, rules: var, fallback: string): string {
        for (const [needles, result] of rules)
            if (needles.some(n => text.includes(n)))
                return result;

        return fallback;
    }

    function getNetworkIcon(strength: int, isSecure = false): string {
        const level = Math.max(0, Math.min(4, Math.floor(strength / 20)));
        const icon = networkIcons[level];

        return isSecure && level > 0 ? `${icon}_locked` : icon;
    }

    function getBluetoothIcon(icon: string): string {
        return matchIcon(icon, bluetoothIconRules, "bluetooth");
    }

    function getWeatherIcon(code: string): string {
        return weatherIcons[code] ?? "air";
    }

    function getNotifIcon(summary: string, urgency: int): string {
        const fallback = urgency === NotificationUrgency.Critical ? "release_alert" : "chat";
        return matchIcon(summary.toLowerCase(), notifIconRules, fallback);
    }

    function getVolumeIcon(volume: real, isMuted: bool): string {
        if (isMuted)
            return "no_sound";
        if (volume >= 0.5)
            return "volume_up";
        if (volume > 0)
            return "volume_down";
        return "volume_mute";
    }

    function getMicVolumeIcon(volume: real, isMuted: bool): string {
        return !isMuted && volume > 0 ? "mic" : "mic_off";
    }

    function getTrayIcon(id: string, icon: string): string {
        for (const sub of GlobalConfig.bar.tray.iconSubs.values)
            if (sub.id === id)
                return sub.image ? Qt.resolvedUrl(sub.image) : Quickshell.iconPath(sub.icon);

        if (icon.includes("?path=")) {
            const [name, path] = icon.split("?path=");
            const file = name.slice(name.lastIndexOf("/") + 1);
            const themed = Quickshell.iconPath(file, true);
            icon = themed ? themed : Qt.resolvedUrl(`${path}/${file}`);
        }
        return icon;
    }

    Process {
        id: scan

        running: true
        command: ["find", root.tintedTheme, "-path", "*/scalable/*", "-name", "*.svg"]

        stdout: StdioCollector {
            onStreamFinished: {
                const map = {};
                for (const path of text.split("\n")) {
                    const name = path.slice(path.lastIndexOf("/") + 1, -4);
                    // apps/ wins over the other contexts when a name repeats
                    if (name && (!map[name] || path.includes("/apps/")))
                        map[name] = path;
                }
                root.tinted = map;
                root.tintedRev++;
            }
        }

        onExited: {
            if (root.rescanQueued) {
                root.rescanQueued = false;
                running = true;
            }
        }
    }
}
