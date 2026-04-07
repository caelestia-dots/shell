pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import qs.config

Singleton {
    id: root

    property var emojis: []
    property var categories: [
        {
            id: "all",
            name: "All Emojis",
            icon: "grid_view"
        },
        {
            id: "recent",
            name: "Recently Used",
            icon: "history"
        },
        {
            id: "people",
            name: "Smileys & People",
            icon: "sentiment_satisfied"
        },
        {
            id: "animals",
            name: "Animals & Nature",
            icon: "pets"
        },
        {
            id: "food",
            name: "Food & Drink",
            icon: "restaurant"
        },
        {
            id: "activity",
            name: "Activity",
            icon: "sports_soccer"
        },
        {
            id: "travel",
            name: "Travel & Places",
            icon: "flight"
        },
        {
            id: "objects",
            name: "Objects",
            icon: "lightbulb"
        },
        {
            id: "symbols",
            name: "Symbols",
            icon: "tag"
        },
        {
            id: "flags",
            name: "Flags",
            icon: "flag"
        }
    ]
    property var recentEmojis: []

    signal emojisLoaded

    function loadFrequentEmojis(): void {
        const frequent = Config.launcher.frequentEmojis || [];
        root.recentEmojis = frequent;
    }

    function saveFrequentEmojis(): void {
        Config.launcher.frequentEmojis = root.recentEmojis;
        Config.save();
    }

    function filterByCategory(category: string): var {
        if (category === "all") {
            return root.emojis;
        }
        if (category === "recent") {
            return root.recentEmojis.map(emoji => {
                return root.emojis.find(e => e.emoji === emoji);
            }).filter(e => e !== undefined);
        }
        return root.emojis.filter(e => e.category === category);
    }

    function search(query: string): var {
        if (!query)
            return root.emojis;

        const lowerQuery = query.toLowerCase();
        return root.emojis.filter(emoji => {
            if (emoji.emoji.includes(query))
                return true;
            if (emoji.name.toLowerCase().includes(lowerQuery))
                return true;
            if (emoji.keywords && emoji.keywords.some(k => k.toLowerCase().includes(lowerQuery)))
                return true;
            return false;
        });
    }

    function copyEmoji(emoji): void {
        Quickshell.execDetached(["sh", "-c", `echo -n '${emoji.emoji}' | wl-copy`]);

        // Add to recent emojis
        const index = root.recentEmojis.indexOf(emoji.emoji);
        if (index > -1) {
            root.recentEmojis.splice(index, 1);
        }
        root.recentEmojis.unshift(emoji.emoji);
        if (root.recentEmojis.length > 20) {
            root.recentEmojis = root.recentEmojis.slice(0, 20);
        }
        saveFrequentEmojis();

        Toaster.toast("Copied to clipboard", `${emoji.emoji} ${emoji.name}`, "sentiment_satisfied");
    }

    FileView {
        id: emojiFile

        path: `${Quickshell.shellDir}/assets/emoji.json`

        onLoaded: {
            try {
                root.emojis = JSON.parse(text());
                root.loadFrequentEmojis();
                root.emojisLoaded();
            } catch (e) {
                console.error("Failed to parse emoji.json:", e);
            }
        }
    }
}
