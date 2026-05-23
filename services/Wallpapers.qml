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
    readonly property string screenWallpapersPath: `${Paths.state}/wallpaper/screens.json`
    readonly property list<string> smartArg: GlobalConfig.services.smartScheme ? [] : ["--no-smart"]

    readonly property string primaryScreen: "eDP-1"

    property string selectedScreen: primaryScreen
    readonly property var screenNames: Screens.screens.map(s => s.name)

    property bool showPreview: false
    readonly property string current: showPreview ? previewPath : actualCurrent
    property string previewPath
    property string actualCurrent
    property bool previewColourLock

    property var screenWallpapers: ({})

    signal screenWallpaperUpdated(string screenName, string path)

    function wallpaperForScreen(screenName: string): string {
        if (screenName && screenWallpapers[screenName])
            return screenWallpapers[screenName];
        return actualCurrent;
    }

    // Cycle to the next screen in the list
    function cycleSelectedScreen(): void {
        const names = screenNames;
        if (names.length <= 1) return;
        const idx = names.indexOf(selectedScreen);
        selectedScreen = names[(idx + 1) % names.length];
    }

    function setWallpaper(path: string, screenName: string): void {
        const target = (screenName && screenName !== "undefined") ? screenName : selectedScreen;
        const resolved = (target && target !== "undefined") ? target : primaryScreen;

        if (resolved !== primaryScreen) {
            const updated = Object.assign({}, screenWallpapers);
            updated[resolved] = path;
            screenWallpapers = updated;
            saveScreensProc.running = true;
            screenWallpaperUpdated(resolved, path);
            previewColourLock = false;
            stopPreview();
        } else {
            actualCurrent = path;
            const updated = Object.assign({}, screenWallpapers);
            updated[resolved] = path;
            screenWallpapers = updated;
            saveScreensProc.running = true;
            screenWallpaperUpdated(resolved, path);
            Quickshell.execDetached(["caelestia", "wallpaper", "-f", path, ...smartArg]);
        }
    }

    function preview(path: string): void {
        if (selectedScreen !== primaryScreen) {
            // For non-primary screens: show wallpaper preview without changing colours
            previewPath = path;
            showPreview = true;
        } else {
            // Primary screen: full preview including colour scheme
            previewPath = path;
            showPreview = true;
            if (Colours.scheme === "dynamic")
                getPreviewColoursProc.running = true;
        }
    }

    function stopPreview(): void {
        showPreview = false;
        if (!previewColourLock)
            Colours.showPreview = false;
    }

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
            root.setWallpaper(path, root.primaryScreen);
        }

        function list(): string {
            return root.list.map(w => w.path).join("\n");
        }

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

    FileView {
        id: screensFileView

        path: root.screenWallpapersPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const parsed = JSON.parse(text().trim());
                root.screenWallpapers = parsed;
                for (const [screen, path] of Object.entries(parsed))
                    root.screenWallpaperUpdated(screen, path);
            } catch (e) {
                root.screenWallpapers = ({});
            }
        }
    }

    Component.onCompleted: {
        Qt.callLater(() => {
            for (const [screen, path] of Object.entries(root.screenWallpapers))
                root.screenWallpaperUpdated(screen, path);
        });
    }

    Process {
        id: saveScreensProc

        command: [
            "sh", "-c",
            `mkdir -p "$(dirname '${root.screenWallpapersPath}')" && printf '%s' '${JSON.stringify(root.screenWallpapers)}' > '${root.screenWallpapersPath}'`
        ]
    }

    FileSystemModel {
        id: wallpapers

        recursive: true
        path: Paths.wallsdir
        filter: FileSystemModel.Images
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
