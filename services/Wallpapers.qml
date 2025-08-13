pragma Singleton

import qs.config
import qs.utils
import Quickshell
import Quickshell.Io
import QtQuick

Searcher {
    id: root

    readonly property string currentNamePath: Paths.strip(`${Paths.state}/wallpaper/path.txt`)

    property bool showPreview: false
    readonly property string current: showPreview ? previewPath : actualCurrent
    property string previewPath
    property string actualCurrent
    property bool previewColourLock

    function setWallpaper(path: string): void {
        actualCurrent = path;
        Quickshell.execDetached(["caelestia", "wallpaper", "-f", path]);
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

    reloadableId: "wallpapers"

    list: wallpapers.instances
    useFuzzy: Config.launcher.useFuzzy.wallpapers
    extraOpts: useFuzzy ? ({}) : ({
            forward: false
        })

    IpcHandler {
        target: "wallpaper"

        function get(): string {
            return root.actualCurrent;
        }

        function set(path: string): void {
            root.setWallpaper(path);
        }

        function list(): string {
            return root.list.map(w => w.path).join("\n");
        }
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

    Process {
        id: getPreviewColoursProc

        command: ["caelestia", "wallpaper", "-p", root.previewPath]
        stdout: StdioCollector {
            onStreamFinished: {
                Colours.load(text, true);
                Colours.showPreview = true;
            }
        }
    }

    Process {
        id: getWallsProc

        running: true
        command: ["find", "-L", Paths.expandTilde(Config.paths.wallpaperDir), "-type", "d", "-path", '*/.*', "-prune", "-o", "-not", "-name", '.*', "-type", "f", "-print"]
        stdout: StdioCollector {
            onStreamFinished: wallpapers.model = text.trim().split("\n").filter(w => Images.isValidImageByName(w)).sort()
        }
    }

    Process {
        id: watchWallsProc

        running: true
        command: ["inotifywait", "-r", "-e", "close_write,moved_to,create", "-m", Paths.expandTilde(Config.paths.wallpaperDir)]
        stdout: SplitParser {
            onRead: data => {
                if (Images.isValidImageByName(data))
                    getWallsProc.running = true;
            }
        }
    }

    Connections {
        target: Config.paths

        function onWallpaperDirChanged(): void {
            getWallsProc.running = true;
            watchWallsProc.running = false;
            watchWallsProc.running = true;
        }
    }

    Variants {
        id: wallpapers

        Wallpaper {}
    }

    component Wallpaper: QtObject {
        required property string modelData
        readonly property string path: modelData
        readonly property string name: path.slice(Paths.expandTilde(Config.paths.wallpaperDir).length + 1, path.lastIndexOf("."))
    }
}
