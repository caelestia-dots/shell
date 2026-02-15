pragma Singleton

import Quickshell

Singleton {
    function testRegexList(filterList: list<string>, target: string): bool {
        const regexChecker = /^\^.*\$$/;
        for (const filter of filterList) {
            // If filter is a regex
            if (regexChecker.test(filter)) {
                if ((new RegExp(filter)).test(target))
                    return true;
            } else {
                if (filter === target)
                    return true;
            }
        }
        return false;
    }
}
