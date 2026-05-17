pragma Singleton

import QtQuick
import Quickshell.Services.UPower

QtObject {
    id: root

    readonly property int count: getCategories().length

    readonly property var settingDefinitions: [
        // Appearance
        {
            label: "Theme Mode",
            category: "appearance",
            tab: "Wallpaper & Scheme",
            keywords: ["theme", "dark", "light", "auto", "mode"]
        },
        {
            label: "Color Scheme",
            category: "appearance",
            tab: "Wallpaper & Scheme",
            keywords: ["color", "scheme", "catppuccin", "everforest", "nord", "gruvbox"]
        },
        {
            label: "Wallpaper",
            category: "appearance",
            tab: "Wallpaper & Scheme",
            keywords: ["wallpaper", "background", "desktop", "image"]
        },
        {
            label: "UI Font",
            category: "appearance",
            tab: "Typography & Motion",
            keywords: ["font", "typography", "text", "roboto"]
        },
        {
            label: "Animation Speed",
            category: "appearance",
            tab: "Typography & Motion",
            keywords: ["animation", "speed", "motion"]
        },
        {
            label: "Window Shadows",
            category: "appearance",
            tab: "Effects",
            keywords: ["shadow", "window", "effect"]
        },
        {
            label: "Corner Rounding",
            category: "appearance",
            tab: "Effects",
            keywords: ["corner", "rounding", "radius"]
        },

        // Taskbar
        {
            label: "Taskbar Auto-hide",
            category: "taskbar",
            tab: "General",
            keywords: ["taskbar", "auto", "hide", "autohide"]
        },
        {
            label: "Workspace Indicator",
            category: "taskbar",
            tab: "Workspaces",
            keywords: ["workspace", "indicator", "taskbar"]
        },
        {
            label: "Status Icons",
            category: "taskbar",
            tab: "Systray & Status",
            keywords: ["status", "icons", "tray", "system"]
        },

        // Launcher
        {
            label: "Launcher Enabled",
            category: "launcher",
            tab: "General",
            keywords: ["launcher", "enabled", "toggle"]
        },
        {
            label: "Launcher Apps",
            category: "launcher",
            tab: "General",
            keywords: ["launcher", "apps", "applications"]
        },
        {
            label: "Favorite Apps",
            category: "launcher",
            tab: "Applications",
            keywords: ["favorite", "apps", "pin", "starred"]
        },
        {
            label: "Actions",
            category: "launcher",
            tab: "Actions",
            keywords: ["actions", "special", "commands", "calculator"]
        },

        // Dashboard
        {
            label: "Widget Management",
            category: "dashboard",
            tab: "Dashboard",
            keywords: ["widget", "manage", "dashboard"]
        },
        {
            label: "Media Widget",
            category: "dashboard",
            tab: "Media",
            keywords: ["media", "player", "music", "album"]
        },
        {
            label: "System Monitor",
            category: "dashboard",
            tab: "Performance",
            keywords: ["system", "monitor", "cpu", "ram"]
        },
        {
            label: "Weather Widget",
            category: "dashboard",
            tab: "Weather",
            keywords: ["weather", "temperature", "forecast"]
        },

        // Display
        {
            label: "Display Resolution",
            category: "display",
            tab: "General",
            keywords: ["display", "monitor", "resolution", "refresh"]
        },
        {
            label: "Night Light",
            category: "display",
            tab: "Night Light",
            keywords: ["night", "light", "blue", "eye", "temperature"]
        },

        // Network
        {
            label: "Wi-Fi Settings",
            category: "network",
            tab: "Wireless",
            keywords: ["wifi", "wireless", "network", "connect"]
        },
        {
            label: "Ethernet Settings",
            category: "network",
            tab: "Ethernet",
            keywords: ["ethernet", "wired", "lan"]
        },
        {
            label: "VPN Connections",
            category: "network",
            tab: "VPN",
            keywords: ["vpn", "wireguard", "tunnel", "privacy"]
        },

        // Audio
        {
            label: "Audio Output",
            category: "audio",
            tab: "Output & Input",
            keywords: ["audio", "output", "speaker", "headphone", "volume"]
        },
        {
            label: "Microphone",
            category: "audio",
            tab: "Output & Input",
            keywords: ["audio", "input", "microphone", "mic"]
        },
        {
            label: "Per-App Volume",
            category: "audio",
            tab: "Applications",
            keywords: ["application", "volume", "per", "app", "mixer"]
        },

        // Bluetooth
        {
            label: "Bluetooth Devices",
            category: "bluetooth",
            tab: "Devices",
            keywords: ["bluetooth", "device", "pair", "connect"]
        },
        {
            label: "Bluetooth Settings",
            category: "bluetooth",
            tab: "Settings",
            keywords: ["bluetooth", "discoverable", "codec"]
        },

        // Power
        {
            label: "Power Mode",
            category: "power",
            tab: "Inhibit and idle",
            keywords: ["inhibit", "idle", "timeout", "sleep", "suspend", "lock"]
        },
        {
            label: "Battery Behavior",
            category: "power",
            tab: "Battery Behavior",
            keywords: ["battery", "charge", "health", "cycle"]
        },

        // Notifications
        {
            label: "Notification Settings",
            category: "notifications",
            tab: "General",
            keywords: ["notification", "alert", "badge", "sound"]
        },
        {
            label: "Per-App Notifications",
            category: "notifications",
            tab: "Applications",
            keywords: ["notification", "application", "per", "app"]
        },
        {
            label: "Do Not Disturb",
            category: "notifications",
            tab: "On-Screen-Display",
            keywords: ["do", "not", "disturb", "dnd", "quiet"]
        },

        // Plugins
        {
            label: "Plugin Management",
            category: "plugins",
            tab: "General",
            keywords: ["plugin", "extension", "addon", "manage"]
        },
        {
            label: "Launcher Plugins",
            category: "plugins",
            tab: "Launcher",
            keywords: ["launcher", "plugin", "extension"]
        },
        {
            label: "Taskbar Plugins",
            category: "plugins",
            tab: "Taskbar",
            keywords: ["taskbar", "plugin", "extension"]
        }
    ]

    function getCategories() {
        return [
            {
                id: "appearance",
                label: "Appearance",
                icon: "palette",
                isDirect: true,
                tabs: ["Wallpaper & Scheme", "Typography & Motion", "Effects"],
                title: "Appearance",
                description: "Customize the look and feel of your desktop",
                children: []
            },
            {
                id: "shell",
                label: "Shell",
                icon: "desktop_windows",
                isDirect: false,
                tabs: [],
                title: "",
                description: "",
                children: [
                    {
                        id: "taskbar",
                        label: "Taskbar",
                        icon: "dock_to_bottom",
                        tabs: ["General", "Workspaces", "Systray & Status"],
                        title: "Taskbar",
                        description: "Configure your taskbar appearance and behavior"
                    },
                    {
                        id: "launcher",
                        label: "Launcher",
                        icon: "apps",
                        tabs: ["General", "Applications", "Actions"],
                        title: "Launcher",
                        description: "Customize application launcher settings"
                    },
                    {
                        id: "dashboard",
                        label: "Dashboard",
                        icon: "dashboard",
                        tabs: ["Dashboard", "Media", "Performance", "Weather"],
                        title: "Dashboard",
                        description: "Configure dashboard widgets and layout"
                    },
                    {
                        id: "sidebar",
                        label: "Sidebar",
                        icon: "side_navigation",
                        tabs: [],
                        title: "Sidebar",
                        description: "Sidebar panel settings"
                    },
                    {
                        id: "utilities",
                        label: "Utilities",
                        icon: "handyman",
                        tabs: [],
                        title: "Utilities",
                        description: "Quick access utilities and tools"
                    },
                    {
                        id: "notifications",
                        label: "Notifications",
                        icon: "notifications",
                        tabs: ["General", "Applications", "On-Screen-Display"],
                        title: "Notifications",
                        description: "Manage notification settings and behavior"
                    },
                    {
                        id: "session",
                        label: "Session",
                        icon: "account_circle",
                        tabs: [],
                        title: "Session Menus",
                        description: "User session and power menu settings"
                    },
                    {
                        id: "lockscreen",
                        label: "Lockscreen",
                        icon: "lock",
                        tabs: [],
                        title: "Lockscreen",
                        description: "Lock screen appearance and security"
                    }
                ]
            },
            {
                id: "display",
                label: "Display",
                icon: "monitor",
                isDirect: true,
                tabs: ["General", "Night Light"],
                title: "Display",
                description: "Monitor configuration and display settings",
                children: []
            },
            {
                id: "services",
                label: "Services",
                icon: "settings_applications",
                isDirect: false,
                tabs: [],
                title: "",
                description: "",
                children: [
                    {
                        id: "network",
                        label: "Network",
                        icon: "wifi",
                        tabs: ["Wireless", "Ethernet", "VPN"],
                        title: "Network",
                        description: "Network connections and settings"
                    },
                    {
                        id: "audio",
                        label: "Audio",
                        icon: "volume_up",
                        tabs: ["Output & Input", "Applications"],
                        title: "Audio",
                        description: "Sound devices and volume control"
                    },
                    {
                        id: "bluetooth",
                        label: "Bluetooth",
                        icon: "bluetooth",
                        tabs: ["Devices", "Settings"],
                        title: "Bluetooth",
                        description: "Bluetooth device management"
                    },
                    {
                        id: "location",
                        label: "Location",
                        icon: "location_on",
                        tabs: [],
                        title: "Location Services",
                        description: "Location access and privacy"
                    },
                    {
                        id: "screenrecorder",
                        label: "Screen Recorder",
                        icon: "screen_record",
                        tabs: [],
                        title: "Screen Recorder",
                        description: "Screen recording settings"
                    }
                ]
            },
            {
                id: "power",
                label: "Power",
                icon: "power_settings_new",
                isDirect: true,
                tabs: ["Inhibit and idle", "Battery Behavior"],
                title: "Power",
                description: "Power management and battery settings",
                children: []
            },
            {
                id: "advanced",
                label: "Advanced",
                icon: "tune",
                isDirect: false,
                tabs: [],
                title: "",
                description: "",
                children: [
                    {
                        id: "plugins",
                        label: "Plugins",
                        icon: "extension",
                        tabs: ["General", "Launcher", "Taskbar", "Dashboard"],
                        title: "Plugins",
                        description: "Manage and configure plugins"
                    },
                    {
                        id: "hooks",
                        label: "Hooks",
                        icon: "link",
                        tabs: [],
                        title: "Hooks",
                        description: "System hooks and automation"
                    }
                ]
            }
        ];
    }

    function getBottomItems() {
        return [
            {
                id: "about",
                label: "About",
                icon: "info",
                isDirect: true,
                tabs: [],
                title: "About Caelestia",
                description: "System information and credits",
                children: []
            },
            {
                id: "updates",
                label: "Updates",
                icon: "update",
                isDirect: true,
                tabs: [],
                title: "Updates",
                description: "System updates and changelog",
                children: []
            }
        ];
    }

    function getByIndex(index) {
        const cats = getCategories();
        if (index >= 0 && index < cats.length)
            return cats[index];
        return null;
    }

    function getById(id) {
        const cats = getCategories();
        for (let i = 0; i < cats.length; i++) {
            if (cats[i].id === id)
                return cats[i];
            const children = cats[i].children;
            for (let j = 0; j < children.length; j++) {
                if (children[j].id === id)
                    return children[j];
            }
        }
        const bottom = getBottomItems();
        for (let i = 0; i < bottom.length; i++) {
            if (bottom[i].id === id)
                return bottom[i];
        }
        return null;
    }

    function getCategoryTabs(id) {
        const tabs = getById(id)?.tabs ?? [];
        if (id === "power" && !(UPower.displayDevice?.isLaptopBattery ?? false))
            return tabs.filter(t => t !== "Battery Behavior");
        return tabs;
    }

    function isChildActive(parentId, activeId) {
        const parent = getById(parentId);
        if (!parent || parent.isDirect)
            return false;
        for (let i = 0; i < parent.children.length; i++) {
            if (parent.children[i].id === activeId)
                return true;
        }
        return false;
    }

    function buildSearchIndex() {
        return root.settingDefinitions.map(setting => {
            const cat = getById(setting.category);
            const categoryLabel = cat?.label ?? setting.category;
            const tab = setting.tab || (cat?.tabs?.[0] ?? "");
            const icon = cat?.icon ?? "settings";
            return {
                label: setting.label,
                categoryId: setting.category,
                tab: tab,
                categoryLabel: categoryLabel,
                icon: icon,
                keywords: setting.keywords,
                description: setting.description || ""
            };
        });
    }

    function calculateScore(item, query, terms) {
        let score = 0;
        const labelLower = item.label.toLowerCase();
        const catLower = item.categoryLabel.toLowerCase();

        // Exact label match gets highest score
        if (labelLower === query)
            score += 15;
        else if (labelLower.includes(query))
            score += 10;

        for (const term of terms) {
            if (labelLower.includes(term))
                score += 5;
            if (catLower.includes(term))
                score += 2;

            for (const kw of item.keywords) {
                if (kw === term)
                    score += 4;
                else if (kw.startsWith(term))
                    score += 3;
                else if (kw.includes(term))
                    score += 1;
            }
        }

        return score;
    }

    function searchSettings(query, maxResults) {
        if (!query || !query.trim())
            return [];
        maxResults = maxResults || 8;

        const lower = query.toLowerCase().trim();
        const terms = lower.split(/\s+/);
        const index = root.buildSearchIndex();

        return index.map(item => Object.assign({}, item, {
                score: root.calculateScore(item, lower, terms)
            })).filter(item => item.score > 0).sort((a, b) => b.score - a.score).slice(0, maxResults);
    }
}
