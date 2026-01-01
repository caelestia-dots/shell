pragma Singleton

import qs.config
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    readonly property var weatherIcons: ({
            "113": "clear_day",
            "116": "partly_cloudy_day",
            "119": "cloud",
            "122": "cloud",
            "143": "foggy",
            "176": "rainy",
            "179": "rainy",
            "182": "rainy",
            "185": "rainy",
            "200": "thunderstorm",
            "227": "cloudy_snowing",
            "230": "snowing_heavy",
            "248": "foggy",
            "260": "foggy",
            "263": "rainy",
            "266": "rainy",
            "281": "rainy",
            "284": "rainy",
            "293": "rainy",
            "296": "rainy",
            "299": "rainy",
            "302": "weather_hail",
            "305": "rainy",
            "308": "weather_hail",
            "311": "rainy",
            "314": "rainy",
            "317": "rainy",
            "320": "cloudy_snowing",
            "323": "cloudy_snowing",
            "326": "cloudy_snowing",
            "329": "snowing_heavy",
            "332": "snowing_heavy",
            "335": "snowing",
            "338": "snowing_heavy",
            "350": "rainy",
            "353": "rainy",
            "356": "rainy",
            "359": "weather_hail",
            "362": "rainy",
            "365": "rainy",
            "368": "cloudy_snowing",
            "371": "snowing",
            "374": "rainy",
            "377": "rainy",
            "386": "thunderstorm",
            "389": "thunderstorm",
            "392": "thunderstorm",
            "395": "snowing"
        })

    readonly property var categoryIcons: ({
            WebBrowser: "web",
            Printing: "print",
            Security: "security",
            Network: "chat",
            Archiving: "archive",
            Compression: "archive",
            Development: "code",
            IDE: "code",
            TextEditor: "edit_note",
            Audio: "music_note",
            Music: "music_note",
            Player: "music_note",
            Recorder: "mic",
            Game: "sports_esports",
            FileTools: "files",
            FileManager: "files",
            Filesystem: "files",
            FileTransfer: "files",
            Settings: "settings",
            DesktopSettings: "settings",
            HardwareSettings: "settings",
            TerminalEmulator: "terminal",
            ConsoleOnly: "terminal",
            Utility: "build",
            Monitor: "monitor_heart",
            Midi: "graphic_eq",
            Mixer: "graphic_eq",
            AudioVideoEditing: "video_settings",
            AudioVideo: "music_video",
            Video: "videocam",
            Building: "construction",
            Graphics: "photo_library",
            "2DGraphics": "photo_library",
            RasterGraphics: "photo_library",
            TV: "tv",
            System: "host",
            Office: "content_paste"
        })

    function getAppIcon(name: string, fallback: string): string {
        const icon = DesktopEntries.heuristicLookup(name)?.icon;
        if (fallback !== "undefined")
            return Quickshell.iconPath(icon, fallback);
        return Quickshell.iconPath(icon);
    }

    function getAppCategoryIcon(name: string, fallback: string): string {
        const categories = DesktopEntries.heuristicLookup(name)?.categories;

        if (categories)
            for (const [key, value] of Object.entries(categoryIcons))
                if (categories.includes(key))
                    return value;
        return fallback;
    }

    function getNetworkIcon(strength: int): string {
        if (strength >= 80)
            return "signal_wifi_4_bar";
        if (strength >= 60)
            return "network_wifi_3_bar";
        if (strength >= 40)
            return "network_wifi_2_bar";
        if (strength >= 20)
            return "network_wifi_1_bar";
        return "signal_wifi_0_bar";
    }

    function getBluetoothIcon(icon: string): string {
        if (icon.includes("headset") || icon.includes("headphones"))
            return "headphones";
        if (icon.includes("audio"))
            return "speaker";
        if (icon.includes("phone"))
            return "smartphone";
        if (icon.includes("mouse"))
            return "mouse";
        if (icon.includes("keyboard"))
            return "keyboard";
        return "bluetooth";
    }

    function getWeatherIcon(code: string): string {
        if (weatherIcons.hasOwnProperty(code))
            return weatherIcons[code];
        return "air";
    }

    function getNotifIcon(summary: string, urgency: int): string {
        summary = summary.toLowerCase();
        if (summary.includes("reboot"))
            return "restart_alt";
        if (summary.includes("recording"))
            return "screen_record";
        if (summary.includes("battery"))
            return "power";
        if (summary.includes("screenshot"))
            return "screenshot_monitor";
        if (summary.includes("welcome"))
            return "waving_hand";
        if (summary.includes("time") || summary.includes("a break"))
            return "schedule";
        if (summary.includes("installed"))
            return "download";
        if (summary.includes("update"))
            return "update";
        if (summary.includes("unable to"))
            return "deployed_code_alert";
        if (summary.includes("profile"))
            return "person";
        if (summary.includes("file"))
            return "folder_copy";
        if (urgency === NotificationUrgency.Critical)
            return "release_alert";
        return "chat";
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
        if (!isMuted && volume > 0)
            return "mic";
        return "mic_off";
    }

    function getSpecialWsIcon(name: string): string {
        name = name.toLowerCase().slice("special:".length);
        
        for (const iconConfig of Config.bar.workspaces.specialWorkspaceIcons) {
            if (iconConfig.name === name) {
                return iconConfig.icon;
            }
        }
        
        if (name === "special")
            return "star";
        if (name === "communication")
            return "forum";
        if (name === "music")
            return "music_cast";
        if (name === "todo")
            return "checklist";
        if (name === "sysmon")
            return "monitor_heart";
        return name[0].toUpperCase();
    }

    function getTrayIcon(id: string, icon: string): string {
        for (const sub of Config.bar.tray.iconSubs)
            if (sub.id === id)
                return sub.image ? Qt.resolvedUrl(sub.image) : Quickshell.iconPath(sub.icon);

        if (icon.includes("?path=")) {
            const [name, path] = icon.split("?path=");
            icon = Qt.resolvedUrl(`${path}/${name.slice(name.lastIndexOf("/") + 1)}`);
        }
        return icon;
    }
}
