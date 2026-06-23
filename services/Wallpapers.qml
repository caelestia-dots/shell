pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.Models
import qs.services
import qs.utils

Searcher {
    id: root

    // qmllint disable missing-property signal-handler-parameters unqualified incompatible-type

    property bool _refreshing: false
    property string actualCurrent
    property string cacheBuster: ""
    readonly property string current: showPreview ? previewPath : actualCurrent
    readonly property string currentNamePath: `${Paths.state}/wallpaper/path.txt`
    property var itemBusters: ({})
    property bool previewColourLock
    property string previewPath
    property bool restoreWallpaperMode: false
    property bool showPreview: false
    readonly property list<string> smartArg: GlobalConfig.services.smartScheme ? [] : ["--no-smart"]
    readonly property list<string> validVideoExtensions: ["mp4", "webm", "mkv"]
    readonly property list<string> validWallpaperExtensions: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.tif", "*.tiff", "*.svg", "*.gif", "*.mp4", "*.webm", "*.mkv"]
    property string wallpaperMode: "static"

    function djb2_hash(s: string): string {
        let h = 5381;
        for (let i = 0; i < s.length; i++) {
            h = (h * 33 + s.charCodeAt(i)) >>> 0;
        }
        return h.toString(16);
    }
    function getCategoryFor(w: var): string {
        let category = w.parentDir.slice(Paths.wallsdir.length + 1);
        if (category.includes("/"))
            category = category.slice(0, category.indexOf("/"));
        return category;
    }

    // Removes duplicates
    function getDedupedEntries(entries: list<var>): list<var> {
        if (!entries)
            return [];
        let seen = {};
        let result = [];
        for (let i = 0; i < entries.length; i++) {
            let path = entries[i].path;
            if (!seen[path]) {
                seen[path] = true;
                result.push(entries[i]);
            }
        }
        return result;
    }
    function getWallpaperThumb(path: string, buster: string): string {
        let clean = String(path || "").split(/[?#]/)[0];
        if (clean.indexOf("file://") === 0)
            clean = clean.substring(7);
        let b = buster !== undefined ? buster : cacheBuster;
        return "file://" + Paths.cache + "/videothumbs/" + djb2_hash(clean) + ".jpg" + (b ? "?v=" + b : "");
    }
    function isVideo(path: string): bool {
        const clean = String(path || "").split(/[?#]/)[0].toLowerCase();
        const index = clean.lastIndexOf(".");
        const ext = index >= 0 ? clean.slice(index + 1) : "";
        return ["mp4", "webm", "mkv"].includes(ext);
    }
    function preview(path: string): void {
        let clean = String(path || "").split(/[?#]/)[0];
        if (clean.indexOf("file://") === 0)
            clean = clean.substring(7);
        previewPath = clean;
        showPreview = true;

        if (Colours.scheme === "dynamic")
            getPreviewColoursProc.running = true;
    }
    function refreshAnimatedThumbs(): void {
        if (_refreshing)
            return;
        itemBusters = {};
        _refreshing = true;
        extractThumbsProc.running = true;
    }
    function setRandom(): void {
        Quickshell.execDetached(["caelestia", "wallpaper", "-r", ...smartArg]);
    }
    function setWallpaper(path: string): void {
        let clean = String(path || "").split(/[?#]/)[0];
        if (clean.indexOf("file://") === 0)
            clean = clean.substring(7);
        actualCurrent = clean;
        if (isVideo(clean)) {
            previewColourLock = false;
            stopPreview();
        }
        Quickshell.execDetached(["caelestia", "wallpaper", "-f", clean, ...smartArg]);
    }
    function setWallpaperMode(mode: string): void {
        wallpaperMode = mode;
    }
    function stopPreview(): void {
        showPreview = false;
        if (!previewColourLock)
            Colours.showPreview = false;
    }
    function updateWallpapers(): void {
        staticWallpapers.update();
        animatedWallpapers.update();
    }

    extraOpts: useFuzzy ? ({}) : ({
            forward: false
        })
    key: "relativePath"
    list: getDedupedEntries(wallpaperMode === "animated" ? animatedWallpapers.entries : staticWallpapers.entries)
    useFuzzy: GlobalConfig.launcher.useFuzzy.wallpapers

    IpcHandler {
        function get(): string {
            return root.actualCurrent;
        }
        function list(): string {
            return root.list.map(w => w.path).join("\n");
        }
        function set(path: string): void {
            root.setWallpaper(path);
        }

        target: "wallpaper"
    }
    FileView {
        id: currentFile

        path: root.currentNamePath
        watchChanges: true

        onFileChanged: reload()
        onLoaded: {
            root.actualCurrent = text().trim();
            root.previewColourLock = false;
            if (root.isVideo(root.actualCurrent)) {
                root.wallpaperMode = "animated";
            }
        }
    }

    // Replaced single generic model with two isolated FileSystemModels to separate static images and animated videos in memory.
    FileSystemModel {
        id: staticWallpapers

        filter: FileSystemModel.Files
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.tif", "*.tiff", "*.svg", "*.gif"]
        path: Paths.wallsdir
        recursive: true
        watchChanges: true
    }
    FileSystemModel {
        id: animatedWallpapers

        filter: FileSystemModel.Files
        nameFilters: ["*.mp4", "*.webm", "*.mkv"]
        path: Paths.wallsdir + "/Animated"
        recursive: true
        watchChanges: true
    }
    Process {
        id: getPreviewColoursProc

        command: ["caelestia", "wallpaper", "-p", root.previewPath, ...root.smartArg]

        stdout: StdioCollector {
            onStreamFinished: {
                Colours.load(text, true);
                Colours.showPreview = true;
            }
        }
    }

    //  Watches for extracted thumbnails via a background text file
    FileView {
        path: "/tmp/caelestia_thumb_ready.txt"
        watchChanges: true

        onFileChanged: reload()
        onLoaded: {
            const lines = text().trim().split("\n");
            let newBusters = Object.assign({}, root.itemBusters);
            let changed = false;
            const now = Date.now().toString();
            for (let i = 0; i < lines.length; i++) {
                const line = lines[i].trim();
                if (line && !newBusters[line]) {
                    newBusters[line] = now;
                    changed = true;
                }
            }
            if (changed) {
                root.itemBusters = newBusters;
            }
        }
    }
    Process {
        id: extractThumbsProc

        command: ["caelestia", "wallpaper", "--extract-thumbs"]

        onExited: {
            root._refreshing = false;
            root.cacheBuster = Date.now().toString();
            root.restoreWallpaperMode = true;
            root.updateWallpapers();
        }
    }
}
