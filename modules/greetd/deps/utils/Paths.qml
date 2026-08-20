pragma Singleton

import Quickshell

Singleton {
    id: root

    // System paths for greetd - no user-specific paths
    readonly property url home: "file:///tmp/greetd"
    readonly property url pictures: "file:///usr/share/backgrounds"
    
    // Use system paths for greetd data
    readonly property url data: "file:///var/lib/caelestia-greetd"
    readonly property url state: "file:///var/lib/caelestia-greetd/state"
    readonly property url cache: "file:///var/cache/caelestia-greetd"
    readonly property url config: "file:///etc/caelestia/greetd"
    
    readonly property url imagecache: `${cache}/imagecache`

    function stringify(path: url): string {
        return path.toString().replace(/%20/g, " ");
    }

    function expandTilde(path: string): string {
        // No tilde expansion in greetd environment
        return path;
    }

    function shortenHome(path: string): string {
        // No home shortening in greetd environment
        return path;
    }

    function strip(path: url): string {
        return stringify(path).replace("file://", "");
    }

    function mkdir(path: url): void {
        // Simplified for greetd - directories should be pre-created
        console.log("mkdir not available in greetd environment:", path);
    }

    function copy(from: url, to: url): void {
        // Simplified for greetd - no file operations
        console.log("copy not available in greetd environment:", from, "to", to);
    }
}