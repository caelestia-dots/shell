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

    property bool showPreview: false
    readonly property string current: showPreview ? previewPath : actualCurrent
    property string previewPath
    property string actualCurrent
    property bool previewColourLock

    function isVideo(path: string): bool {
        return path.endsWith(".mp4") || path.endsWith(".mkv") ||
               path.endsWith(".webm") || path.endsWith(".avi") ||
               path.endsWith(".mov");
    }

    function setWallpaper(path: string): void {
        actualCurrent = path;
        Quickshell.execDetached(["caelestia", "wallpaper", "-f", path, ...smartArg]);
    }

    function preview(path: string): void {
        previewPath = path;
        showPreview = true;
        if (Colours.scheme === "dynamic")
            getPreviewColoursProc.running = true;
    }

    function stopPreview(): void {
        showPreview = false;
        if (!previewColourLock)
            Colours.showPreview = false;
    }

    list: wallpapers.entries
    key: "relativePath"
    useFuzzy: GlobalConfig.launcher.useFuzzy.wallpapers
    extraOpts: useFuzzy ? ({}) : ({ forward: false })

    IpcHandler {
        function get(): string { return root.actualCurrent; }
        function set(path: string): void { root.setWallpaper(path); }
        function list(): string { return root.list.map(w => w.path).join("\n"); }
        target: "wallpaper"
    }

    FileView {
        path: root.currentNamePath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            root.actualCurrent = text().trim();
            root.previewColourLock = false;
        }
    }

    FileSystemModel {
        id: wallpapers
        recursive: true
        path: Paths.wallsdir
        filter: FileSystemModel.Images
    }

    FileSystemModel {
        id: wallpapersVideos
        recursive: true
        path: Paths.wallsdir
        filter: FileSystemModel.Video
    }

    readonly property var listStatic: {
        const result = [];
        for (let i = 0; i < wallpapers.entries.length; i++)
            result.push(wallpapers.entries[i]);
        return result;
    }

    readonly property var listAnimated: {
        const result = [];
        for (let i = 0; i < wallpapersVideos.entries.length; i++)
            result.push(wallpapersVideos.entries[i]);
        return result;
    }

    readonly property var listAll: {
        const result = [];
        for (let i = 0; i < wallpapers.entries.length; i++)
            result.push(wallpapers.entries[i]);
        for (let i = 0; i < wallpapersVideos.entries.length; i++)
            result.push(wallpapersVideos.entries[i]);
        return result;
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
}