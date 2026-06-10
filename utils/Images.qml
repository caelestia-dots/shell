pragma Singleton

import Quickshell

Singleton {
    readonly property list<string> validImageTypes: ["jpeg", "png", "webp", "tiff", "svg"]
    readonly property list<string> validImageExtensions: ["jpg", "jpeg", "png", "webp", "tif", "tiff", "svg"]
    readonly property list<string> validProfileImageTypes: validImageTypes.concat(["gif"])
    readonly property list<string> validProfileImageExtensions: validImageExtensions.concat(["gif"])

    function isValidImageByName(name: string): bool {
        const lowerName = name.toLowerCase();
        return validImageExtensions.some(t => lowerName.endsWith(`.${t}`));
    }

    function isValidProfileImageByName(name: string): bool {
        const lowerName = name.toLowerCase();
        return validProfileImageExtensions.some(t => lowerName.endsWith(`.${t}`));
    }
}
