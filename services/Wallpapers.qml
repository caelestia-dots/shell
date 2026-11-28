pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.Models
import qs.services
import qs.utils

Searcher {
    id: root

    readonly property url previewSchemePath: Qt.resolvedUrl(`${Paths.state}/wallpaper/preview-scheme.json`)
    readonly property string currentNamePath: `${Paths.state}/wallpaper/path.txt`
    readonly property list<string> smartArg: GlobalConfig.services.smartScheme ? [] : ["--no-smart"]
    readonly property string fallback: Quickshell.shellPath("assets/wallpaper.webp")

    property bool showPreview: false
    readonly property string current: showPreview ? previewPath : actualCurrent
    property string previewPath
    property string actualCurrent
    property bool previewColourLock
    property bool pendingPreviewClear

    function getCategoryFor(w: FileSystemEntry): string {
        let category = w.parentDir.slice(Paths.wallsdir.length + 1);
        if (category.includes("/"))
            category = category.slice(0, category.indexOf("/"));
        return category;
    }

    function setRandom(): void {
        Quickshell.execDetached(["caelestia", "wallpaper", "-r", ...smartArg]);
    }

    function setWallpaper(path: string): void {
        actualCurrent = path;
        Quickshell.execDetached(["caelestia", "wallpaper", "-f", path, ...smartArg]);
    }

    function preview(path: string): void {
        previewPath = path;
        showPreview = true;

        if (Colours.scheme === "dynamic" && !getPreviewColoursProc.running) {
            getPreviewColoursProc.requestedPath = path;
            getPreviewColoursProc.running = true;
        }
    }

    function stopPreview(): void {
        showPreview = false;
        CUtils.deleteFile(previewSchemePath);
        if (previewColourLock)
            pendingPreviewClear = true;
        else
            Colours.showPreview = false;
    }

    onPreviewColourLockChanged: {
        if (!previewColourLock && pendingPreviewClear)
            Colours.showPreview = false;
    }

    Component.onCompleted: CUtils.deleteFile(previewSchemePath)
    Component.onDestruction: CUtils.deleteFile(previewSchemePath)

    list: wallpapers.entries
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
        path: root.currentNamePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            let wall = text().trim();
            if (!wall) {
                wall = root.fallback;
                Quickshell.execDetached(["caelestia", "wallpaper", "-f", root.fallback, ...root.smartArg]);
            }
            root.actualCurrent = wall;
            root.previewColourLock = false;
        }
        onLoadFailed: {
            root.actualCurrent = root.fallback;
            root.previewColourLock = false;
            Quickshell.execDetached(["caelestia", "wallpaper", "-f", root.fallback, ...root.smartArg]);
        }
    }

    FileSystemModel {
        id: wallpapers

        recursive: true
        path: Paths.wallsdir
        filter: FileSystemModel.Images | FileSystemModel.Videos
    }

    FileView {
        id: previewScheme

        path: root.previewSchemePath
        atomicWrites: true
        blockWrites: true
        printErrors: false
    }

    Process {
        id: getPreviewColoursProc

        property string requestedPath

        command: ["caelestia", "wallpaper", "-p", requestedPath, ...root.smartArg]
        onExited: {
            if (root.showPreview && requestedPath !== root.previewPath) {
                requestedPath = root.previewPath;
                running = true;
            }
        }
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.showPreview || getPreviewColoursProc.requestedPath !== root.previewPath)
                    return;
                try {
                    const scheme = JSON.parse(text);
                    if (!scheme.colours || typeof scheme.colours !== "object")
                        return;
                    Colours.load(text, true);
                    Colours.showPreview = true;
                    previewScheme.setText(text);
                } catch (e) {
                    console.warn("Could not load wallpaper preview colours:", e);
                }
            }
        }
    }
}
