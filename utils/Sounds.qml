pragma Singleton

import Quickshell

Singleton {
    readonly property list<string> validSoundExtensions: ["mp3", "wav", "flac", "ogg", "oga", "acc", "m4a", "wav"]

    function isValidSoundByName(name: string): bool {
        return validSoundExtensions.some(t => name.endsWith(`.${t}`));
    }
}