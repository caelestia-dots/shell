pragma Singleton

import Quickshell
import Caelestia.I18n
import Caelestia.State

Singleton {
    // Order matches the tab order in the picker. Icons are Material Symbols (not symbols)
    readonly property var source: PickerSource {
        name: "symbols"
        mode: "symbol"
        recent: PersistentState.recentSymbols ?? []
        groups: [
            {
                id: "recent",
                icon: "history",
                name: Tr.trCtx("Recent", "symbol category")
            },
            {
                id: "arrows",
                icon: "arrow_right_alt",
                name: Tr.trCtx("Arrows", "symbol category")
            },
            {
                id: "math",
                icon: "calculate",
                name: Tr.trCtx("Math", "symbol category")
            },
            {
                id: "greek",
                icon: "functions",
                name: Tr.trCtx("Greek", "symbol category")
            },
            {
                id: "currency",
                icon: "payments",
                name: Tr.trCtx("Currency", "symbol category")
            },
            {
                id: "text",
                icon: "format_quote",
                name: Tr.trCtx("Punctuation & Marks", "symbol category")
            },
            {
                id: "letters",
                icon: "text_fields",
                name: Tr.trCtx("Latin Letters", "symbol category")
            },
            {
                id: "shapes",
                icon: "category",
                name: Tr.trCtx("Shapes", "symbol category")
            },
            {
                id: "box",
                icon: "border_all",
                name: Tr.trCtx("Box & Blocks", "symbol category")
            },
            {
                id: "misc",
                icon: "emoji_symbols",
                name: Tr.trCtx("Miscellaneous", "symbol category")
            }
        ]

        onRecentRequested: list => PersistentState.recentSymbols = list
    }
}
