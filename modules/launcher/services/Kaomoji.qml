pragma Singleton

import Quickshell
import Caelestia.I18n
import Caelestia.State

Singleton {
    readonly property var source: PickerSource {
        name: "kaomoji"
        mode: "kaomoji"
        columns: 3
        wide: true
        recent: PersistentState.recentKaomoji ?? []
        groups: [
            {
                id: "recent",
                icon: "history",
                name: Tr.trCtx("Recent", "kaomoji category")
            },
            {
                id: "happy",
                icon: "mood",
                name: Tr.trCtx("Happy", "kaomoji category")
            },
            {
                id: "love",
                icon: "favorite",
                name: Tr.trCtx("Love", "kaomoji category")
            },
            {
                id: "sad",
                icon: "sentiment_dissatisfied",
                name: Tr.trCtx("Sad", "kaomoji category")
            },
            {
                id: "angry",
                icon: "local_fire_department",
                name: Tr.trCtx("Angry", "kaomoji category")
            },
            {
                id: "shy",
                icon: "sentiment_neutral",
                name: Tr.trCtx("Shy & Surprised", "kaomoji category")
            },
            {
                id: "actions",
                icon: "directions_run",
                name: Tr.trCtx("Actions", "kaomoji category")
            },
            {
                id: "animals",
                icon: "pets",
                name: Tr.trCtx("Animals", "kaomoji category")
            },
            {
                id: "misc",
                icon: "star",
                name: Tr.trCtx("Misc", "kaomoji category")
            }
        ]

        onRecentRequested: list => PersistentState.recentKaomoji = list
    }
}
