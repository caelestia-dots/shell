pragma Singleton

import qs.config
import qs.utils
import Caelestia.Models
import Quickshell
import Quickshell.Io
import QtQuick

Searcher {
    id: root

    readonly property string currentNamePath: `${Paths.state}/wallpaper/path.txt`
    readonly property list<string> smartArg: Config.services.smartScheme ? [] : ["--no-smart"]

    property bool showPreview: false
    readonly property string current: showPreview ? previewPath : actualCurrent
    property string previewPath
    property string actualCurrent
    property bool previewColourLock

    // Folder selection support
    property int currentFolderIndex: 0
    property int debouncedFolderIndex: 0
    
    readonly property var folders: {
        const folderList = folderModel.entries.map(e => e.name);
        folderList.sort((a, b) => a.localeCompare(b, undefined, {numeric: true, sensitivity: 'base'}));
        return ["All", ...folderList];
    }
    readonly property string currentFolder: Config.launcher.folderSelection ? (folders[currentFolderIndex] ?? "All") : "All"
    readonly property string debouncedCurrentFolder: Config.launcher.folderSelection ? (folders[debouncedFolderIndex] ?? "All") : "All"

    Timer {
        interval: 350
        running: root.currentFolderIndex !== root.debouncedFolderIndex
        repeat: false
        onTriggered: root.debouncedFolderIndex = root.currentFolderIndex
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

    // Filter wallpapers by folder
    function queryWithFolder(search: string, folder: string): list<var> {
        const results = query(search);
        if (folder === "All" || folder === "")
            return results;
        return results.filter(w => w.relativePath.startsWith(folder + "/"));
    }

    list: wallpapers.entries
    key: "relativePath"
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

    FileSystemModel {
        id: folderModel

        path: Paths.wallsdir
        filter: FileSystemModel.Dirs
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
