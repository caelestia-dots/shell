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

    readonly property string currentNamePath: `${Paths.state}/wallpaper/path.txt`
    readonly property list<string> smartArg: GlobalConfig.services.smartScheme ? [] : ["--no-smart"]
    readonly property list<string> validVideoExtensions: ["mp4", "webm", "mkv"]
    readonly property list<string> validWallpaperExtensions: [
        "*.jpg", "*.jpeg", "*.png", "*.webp", "*.tif", "*.tiff", "*.svg", "*.gif",
        "*.mp4", "*.webm", "*.mkv"
    ]

    property bool showPreview: false
    readonly property string current: showPreview ? previewPath : actualCurrent
    property string previewPath
    property string actualCurrent
    property bool previewColourLock
    property string wallpaperMode: "static"
    property string cacheBuster: ""

    function djb2_hash(s) {
        let h = 5381;
        for (let i = 0; i < s.length; i++) {
            h = (h * 33 + s.charCodeAt(i)) >>> 0;
        }
        return h.toString(16);
    }

    function getWallpaperThumb(path, buster) {
        let clean = String(path || "").split(/[?#]/)[0];
        if (clean.indexOf("file://") === 0) clean = clean.substring(7);
        let b = buster !== undefined ? buster : cacheBuster;
        return "file://" + Paths.cache + "/videothumbs/" + djb2_hash(clean) + ".jpg" + (b ? "?v=" + b : "");
    }

    function setWallpaperMode(mode) {
        wallpaperMode = mode;
    }

    function isVideo(path: string): bool {
        const clean = String(path || "").split(/[?#]/)[0].toLowerCase();
        const index = clean.lastIndexOf(".");
        const ext = index >= 0 ? clean.slice(index + 1) : "";
        return ["mp4", "webm", "mkv"].includes(ext);
    }

    function setWallpaper(path: string): void {
        let clean = String(path || "").split(/[?#]/)[0];
        if (clean.indexOf("file://") === 0) clean = clean.substring(7);
        actualCurrent = clean;
        if (isVideo(clean)) {
            previewColourLock = false;
            stopPreview();
        }
        Quickshell.execDetached(["caelestia", "wallpaper", "-f", clean, ...smartArg]);
    }

    function preview(path: string): void {
        let clean = String(path || "").split(/[?#]/)[0];
        if (clean.indexOf("file://") === 0) clean = clean.substring(7);
        previewPath = clean;
        showPreview = true;

        if (Colours.scheme === "dynamic")
            getPreviewColoursProc.running = true;
    }

    function stopPreview(): void {
        showPreview = false;
        if (!previewColourLock)
            Colours.showPreview = false;
    }

    // Removes duplicates
    function getDedupedEntries(entries) {
        if (!entries) return [];
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

    list: getDedupedEntries(wallpaperMode === "animated" ? animatedWallpapers.entries : staticWallpapers.entries)
    key: "relativePath"
    useFuzzy: GlobalConfig.launcher.useFuzzy.wallpapers
    extraOpts: useFuzzy ? ({}) : ({
            forward: false
        })

    IpcHandler {
        function get(): string {
            return root.actualCurrent;
        }

        function set(path: string): void {
            root.setWallpaper(path);
        }

        function list(): string {
            return root.list.map(w => w.path).join("\n");
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

        watchChanges: true
        recursive: true
        path: Paths.wallsdir
        filter: FileSystemModel.Files
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.tif", "*.tiff", "*.svg", "*.gif"]
    }

    FileSystemModel {
        id: animatedWallpapers

        watchChanges: true
        recursive: true
        path: Paths.wallsdir + "/Animated"
        filter: FileSystemModel.Files
        nameFilters: ["*.mp4", "*.webm", "*.mkv"]
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

    property bool _refreshing: false
    property bool restoreWallpaperMode: false
    property var itemBusters: ({})

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

    function updateWallpapers() {
        staticWallpapers.update();
        animatedWallpapers.update();
    }

    function refreshAnimatedThumbs() {
        if (_refreshing) return;
        itemBusters = {};
        _refreshing = true;
        _extractThumbsProc.running = true;
    }

    Process {
        id: _extractThumbsProc

        command: ["caelestia", "wallpaper", "--extract-thumbs"]
        onExited: (exitCode, exitStatus) => {
            root._refreshing = false;
            root.cacheBuster = Date.now().toString();
            root.restoreWallpaperMode = true;
            root.updateWallpapers();
        }
    }
}
