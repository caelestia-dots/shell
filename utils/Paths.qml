pragma Singleton

import Quickshell
import Qt.labs.platform

Singleton {
    id: root

    readonly property url home: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
    readonly property url pictures: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]

    readonly property url data: `${StandardPaths.standardLocations(StandardPaths.GenericDataLocation)[0]}/caelestia`
    readonly property url state: `${StandardPaths.standardLocations(StandardPaths.GenericStateLocation)[0]}/caelestia`
    readonly property url cache: `${StandardPaths.standardLocations(StandardPaths.GenericCacheLocation)[0]}/caelestia`
    readonly property url config: `${StandardPaths.standardLocations(StandardPaths.GenericConfigLocation)[0]}/caelestia`

    readonly property url imagecache: `${cache}/imagecache`

    function stringify(path: url): string {
        let str = path.toString();
        if (str.startsWith("root:/"))
            str = `file://${Quickshell.shellDir}/${str.slice(6)}`;
        else if (str.startsWith("/"))
            str = `file://${str}`;
        return new URL(str).pathname;
    }

    function expandTilde(path: string): string {
        return strip(path.replace("~", stringify(root.home)));
    }

    function shortenHome(path: string): string {
        return path.replace(strip(root.home), "~");
    }

    function strip(path: url): string {
        return stringify(path).replace("file://", "");
    }

    function mkdir(path: url): void {
        Quickshell.execDetached(["mkdir", "-p", strip(path)]);
    }

    function copy(from: url, to: url): void {
        Quickshell.execDetached(["cp", strip(from), strip(to)]);
    }
}
