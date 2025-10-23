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

    function setWallpaper(path: string): void {
        actualCurrent = path;
        
        const isGif = path.toLowerCase().endsWith(".gif");
        
        if (isGif) {
            // Bypass CLI and write directly to path.txt for GIFs
            writeGifPathProc.command = ["sh", "-c", `echo '${path}' > '${currentNamePath}'`];
            writeGifPathProc.running = true;
            
            if (Colours.scheme === "dynamic") {
                setGifColoursProc.command = ["caelestia", "wallpaper", "-p", path, ...smartArg];
                setGifColoursProc.running = true;
            }
        } else {
            Quickshell.execDetached(["caelestia", "wallpaper", "-f", path, ...smartArg]);
        }
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

    Process {
        id: writeGifPathProc
        // Command is set dynamically in setWallpaper()
        // Writes GIF path directly to path.txt since CLI doesn't support GIFs
    }

    Process {
        id: setGifColoursProc
        stdout: StdioCollector {
            onStreamFinished: {
                const scheme = JSON.parse(text);
                
                Colours.load(text, false);
                
                // Persist the scheme JSON directly to file
                const schemePath = `${Paths.state}/scheme.json`;
                saveGifSchemeProc.command = ["sh", "-c", `echo '${text}' > '${schemePath}'`];
                saveGifSchemeProc.schemeData = scheme;
                saveGifSchemeProc.running = true;
            }
        }
    }

    Process {
        id: saveGifSchemeProc
        property var schemeData: null
        
        // Saves the GIF color scheme to the persistent scheme.json file
        onExited: {
            if (schemeData) {
                Quickshell.execDetached([
                    "caelestia", "scheme", "set",
                    "-m", schemeData.mode,
                    "-v", schemeData.variant
                ]);
            }
        }
    }
}
