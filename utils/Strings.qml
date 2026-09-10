pragma Singleton

import Quickshell
import Caelestia.I18n

Singleton {
    property var _regexCache: ({})

    function percent(value: int): string {
        // TRANSLATORS: %1 = a number
        return Tr.tr("%1%").arg(value);
    }

    function percentOne(value: real): string {
        return percent(Math.round(value * 100));
    }

    function withDataUnit(value: var, unit: string): string {
        const formats = {
            "B": Tr.tr("%1 B"),
            "KB": Tr.tr("%1 KB"),
            "MB": Tr.tr("%1 MB"),
            "GB": Tr.tr("%1 GB"),
            "TB": Tr.tr("%1 TB"),
            "B/s": Tr.tr("%1 B/s"),
            "KB/s": Tr.tr("%1 KB/s"),
            "MB/s": Tr.tr("%1 MB/s"),
            "GB/s": Tr.tr("%1 GB/s"),
            "KiB": Tr.tr("%1 KiB"),
            "MiB": Tr.tr("%1 MiB"),
            "GiB": Tr.tr("%1 GiB")
        };
        return (formats[unit] ?? ("%1 " + unit)).arg(value);
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
