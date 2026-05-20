pragma Singleton

import Quickshell

Singleton {
    readonly property list<string> validImageTypes: ["jpeg", "png", "webp", "tiff", "svg", "gif"]
    readonly property list<string> validImageExtensions: ["jpg", "jpeg", "png", "webp", "tif", "tiff", "svg", "gif"]

    readonly property list<string> validVideoTypes: ["mp4", "webm", "mkv", "avi", "mov", "wmv", "flv"]
    readonly property list<string> validVideoExtensions: ["mp4", "webm", "mkv", "avi", "mov", "wmv", "flv"]

    function isValidImageByName(name: string): bool {
        return validImageExtensions.some(t => name.endsWith(`.${t}`));
    }

    function isValidVideoByName(name: string): bool {
        return validVideoExtensions.some(t => name.endsWith(`.${t}`));
    }

    function isVideo(name: string): bool {
        return isValidVideoByName(name);
    }
}
