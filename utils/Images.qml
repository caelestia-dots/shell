pragma Singleton

import Quickshell

Singleton {
    readonly property list<string> validImageTypes: ["jpeg", "png", "webp", "tiff", "svg", "gif"]
    readonly property list<string> validImageExtensions: ["jpg", "jpeg", "png", "webp", "tif", "tiff", "svg", "gif"]

    function isValidImageByName(name: string): bool {
        const lowerName = name.toLowerCase();
        return validImageExtensions.some(t => lowerName.endsWith(`.${t}`));
    }
}
