pragma Singleton

import Quickshell

Singleton {
    readonly property list<string> validImageTypes: ["jpeg", "png", "webp", "tiff", "svg"]
    readonly property list<string> validImageExtensions: ["jpg", "jpeg", "png", "webp", "tif", "tiff", "svg"]
    readonly property list<string> validVideoExtensions: ["mp4", "webm", "mkv", "avi", "mov"]

    function isValidImageByName(name: string): bool {
        return validImageExtensions.some(t => name.endsWith(`.${t}`));
    }

    function isValidVideoByName(name: string): bool {
        return validVideoExtensions.some(t => name.endsWith(`.${t}`));
    }

    function isVideoFile(path: string): bool {
        return isValidVideoByName(path.split('/').pop());
    }
}
