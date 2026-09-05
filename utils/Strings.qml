pragma Singleton

import Quickshell

Singleton {
    property var _regexCache: ({})

    // Notification bodies may contain the small HTML subset from the
    // freedesktop spec (b, i, u, a, img). That is fine wherever the text is
    // rendered in full, but where it gets elided or truncated the markup is cut
    // in half and Qt shows it verbatim - e.g. the <a href> Chrome puts in the
    // body of web notifications. Those places need the text only.
    function hasMarkup(text: string): bool {
        return /<[a-z!\/][^>]*>/i.test(text);
    }

    function stripMarkup(text: string): string {
        if (!hasMarkup(text))
            return text;
        return text.replace(/<br\s*\/?>/gi, " ").replace(/<[^>]+>/g, "").replace(/&(?:nbsp|#160);/gi, " ").replace(/&(?:quot|#34);/gi, '"').replace(/&(?:apos|#39);/gi, "'").replace(/&(?:lt|#60);/gi, "<").replace(/&(?:gt|#62);/gi, ">").replace(/&(?:amp|#38);/gi, "&").replace(/[ \t]+/g, " ").trim();
    }

    function testRegexList(filterList: list<string>, target: string): bool {
        const regexChecker = /^\^.*\$$/;
        for (const filter of filterList) {
            if (regexChecker.test(filter)) {
                let re = _regexCache[filter];
                if (!re) {
                    re = new RegExp(filter);
                    _regexCache[filter] = re;
                }
                if (re.test(target))
                    return true;
            } else {
                if (filter === target)
                    return true;
            }
        }
        return false;
    }
}
