.pragma library

function compareInList(filterList, string) {
    const regexChecker = /^\^.*\$$/;
    for (const filter of filterList) {
        // If filter is a regex
        if (regexChecker.test(filter)) {
            if ((new RegExp(filter)).test(string))
                return true;
        } else {
            if (filter === string)
                return true;
        }
    }
    return false;
}
