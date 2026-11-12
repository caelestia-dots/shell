pragma Singleton

import Quickshell
import Caelestia.I18n

Singleton {
    // Pages are cycled with arrows/wheel/dots; tools only open from Home or by id
    readonly property var pages: [
        {
            id: "home",
            icon: "home",
            label: Tr.tr("Home")
        },
        {
            id: "media",
            icon: "music_note",
            label: Tr.tr("Media")
        },
        {
            id: "calendar",
            icon: "calendar_month",
            label: Tr.tr("Calendar")
        },
        {
            id: "weather",
            icon: "partly_cloudy_day",
            label: Tr.tr("Weather")
        },
        {
            id: "focus",
            icon: "timer",
            label: Tr.tr("Focus")
        }
    ]
    readonly property var tools: [
        {
            id: "clipboard",
            icon: "content_paste",
            label: Tr.tr("Clipboard")
        },
        {
            id: "shelf",
            icon: "inventory_2",
            label: Tr.tr("Shelf")
        },
        {
            id: "ai",
            icon: "smart_toy",
            label: Tr.tr("AI")
        },
        {
            id: "performance",
            icon: "speed",
            label: Tr.tr("Performance")
        }
    ]
    // ScreenState.notchPage indexes this list
    readonly property var all: pages.concat(tools)

    function find(id: string): int {
        return all.findIndex(p => p.id === id);
    }
}
