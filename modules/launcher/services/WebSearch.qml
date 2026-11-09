pragma Singleton

import Quickshell
import Caelestia.I18n

Singleton {
    id: root

    readonly property var providers: ({
            "google": {
                name: "Google",
                icon: "search",
                url: "https://www.google.com/search?q=%s"
            },
            "youtube": {
                name: "YouTube",
                icon: "play_circle",
                url: "https://www.youtube.com/results?search_query=%s"
            },
            "wiki": {
                name: "Wikipedia",
                icon: "menu_book",
                url: "https://fr.wikipedia.org/wiki/Special:Search?search=%s"
            },
            "gh": {
                name: "GitHub",
                icon: "code",
                url: "https://github.com/search?q=%s"
            },
            "github": {
                name: "GitHub",
                icon: "code",
                url: "https://github.com/search?q=%s"
            },
            "reddit": {
                name: "Reddit",
                icon: "forum",
                url: "https://www.reddit.com/search/?q=%s"
            },
            "maps": {
                name: "Google Maps",
                icon: "map",
                url: "https://www.google.com/maps/search/%s"
            }
        })

    function normalise(text: string): string {
        return text.trim().replace(/\s+/g, " ");
    }

    function result(query: string, provider: var): var {
        const url = provider.url.replace("%s", encodeURIComponent(query));

        return {
            name: Tr.tr("Search for \"%1\"").arg(query),
            desc: provider.name,
            icon: provider.icon,
            url,
            onClicked: function (list) {
                list.screenState.launcher = false;
                Quickshell.execDetached(["xdg-open", url]);
            }
        };
    }

    function parse(text: string): var {
        const normalized = normalise(text);

        if (!normalized)
            return null;

        const separator = normalized.indexOf(" ");
        if (separator < 0)
            return null;

        const providerKey = normalized.slice(0, separator).toLowerCase();
        if (!Object.keys(providers).includes(providerKey))
            return null;

        const query = normalized.slice(separator + 1);
        return result(query, providers[providerKey]);
    }

    function fallback(text: string): var {
        const query = normalise(text);

        if (!query)
            return null;

        return result(query, providers.google);
    }
}
