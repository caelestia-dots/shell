pragma Singleton

import Quickshell
import Caelestia.I18n
import Caelestia.State

Singleton {
    // Order matches the tab order in the picker. Icons are Material Symbols (not emojis)
    readonly property var source: PickerSource {
        name: "emojis"
        mode: "emoji"
        checkRenderable: true
        recent: PersistentState.recentEmojis ?? []
        groups: [
            {
                id: "recent",
                icon: "history",
                name: Tr.trCtx("Recent", "emoji category")
            },
            {
                id: "people",
                icon: "mood",
                name: Tr.trCtx("Smileys & People", "emoji category")
            },
            {
                id: "nature",
                icon: "pets",
                name: Tr.trCtx("Animals & Nature", "emoji category")
            },
            {
                id: "food",
                icon: "restaurant",
                name: Tr.trCtx("Food & Drink", "emoji category")
            },
            {
                id: "activities",
                icon: "sports_soccer",
                name: Tr.trCtx("Activities", "emoji category")
            },
            {
                id: "travel",
                icon: "directions_car",
                name: Tr.trCtx("Travel & Places", "emoji category")
            },
            {
                id: "objects",
                icon: "lightbulb",
                name: Tr.trCtx("Objects", "emoji category")
            },
            {
                id: "symbols",
                icon: "emoji_symbols",
                name: Tr.trCtx("Symbols", "emoji category")
            },
            {
                id: "flags",
                icon: "flag",
                name: Tr.trCtx("Flags", "emoji category")
            }
        ]

        onRecentRequested: list => PersistentState.recentEmojis = list
    }
}
