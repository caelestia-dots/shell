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
    readonly property string videoFramesPath: `${Paths.cache}/wallpapers/frames`
    readonly property list<string> smartArg: GlobalConfig.services.smartScheme ? [] : ["--no-smart"]

    // Extracts a representative frame from the video "$1" into "$2" unless it already exists.
    // Tries 1s in first (to skip fade-from-black intros), falls back to the first frame.
    readonly property string extractFrameScript: `mkdir -p "$(dirname "$2")"
if ! [ -f "$2" ]; then
    t="$2.$$.tmp"
    ffmpeg -y -loglevel error -ss 1 -i "$1" -frames:v 1 -c:v mjpeg -q:v 2 -f image2 "$t" 2> /dev/null
    [ -s "$t" ] || ffmpeg -y -loglevel error -i "$1" -frames:v 1 -c:v mjpeg -q:v 2 -f image2 "$t" || exit 1
    [ -s "$t" ] || exit 1
    mv -f "$t" "$2" || exit 1
fi`

    property bool showPreview: false
    readonly property string current: showPreview ? previewPath : actualCurrent
    readonly property string currentAnalysable: Images.isValidVideoByName(current) ? (videoFrames[current] ?? "") : current
    property string previewPath
    property string actualCurrent
    property bool previewColourLock
    property var videoFrames: ({})
    property var frameQueue: []

    function setWallpaper(path: string): void {
        actualCurrent = path;
        if (Images.isValidVideoByName(path)) {
            // The CLI can't handle videos: extract a frame for it to generate the colour
            // scheme/thumbnail from, then point the wallpaper state at the actual video.
            Quickshell.execDetached(["sh", "-c", `${extractFrameScript}
caelestia wallpaper -f "$2" ${smartArg.join(" ")} && printf %s "$1" > "$3"`, "sh", path, videoFramePath(path), currentNamePath]);
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

    function videoFramePath(path: string): string {
        return `${videoFramesPath}/${Qt.md5(path)}.jpg`;
    }

    function ensureVideoFrame(path: string): void {
        if (!Images.isValidVideoByName(path) || videoFrames[path] !== undefined || frameProc.activePath === path || frameQueue.includes(path))
            return;
        frameQueue.push(path);
        processFrameQueue();
    }

    function processFrameQueue(): void {
        if (frameProc.running || frameQueue.length === 0)
            return;
        frameProc.activePath = frameQueue.shift();
        frameProc.running = true;
    }

    function thumbnailFor(path: string): string {
        if (!Images.isValidVideoByName(path))
            return path;
        return videoFrames[path] ?? "";
    }

    function animationsActiveOn(screen: ShellScreen): bool {
        if (GameMode.enabled || Visibilities.sessionLocked)
            return false;

        const monitor = Hypr.monitorFor(screen);
        if (!monitor)
            return true;
        if (monitor.lastIpcObject.dpmsStatus === false)
            return false;

        // Mirrors the fullscreen detection in modules/drawers/ContentWindow.qml
        const specialName = monitor.lastIpcObject.specialWorkspace?.name;
        if (specialName) {
            const specialWs = Hypr.workspaces.values.find(ws => ws.name === specialName);
            return !(specialWs?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false);
        }
        return !(monitor.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false);
    }

    list: wallpapers.entries
    key: "relativePath"
    useFuzzy: GlobalConfig.launcher.useFuzzy.wallpapers
    extraOpts: useFuzzy ? ({}) : ({
            forward: false
        })

    onCurrentChanged: ensureVideoFrame(current)

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
        onFileChanged: reload()
        onLoaded: {
            const path = text().trim();

            // Intermediate write by the CLI while setting a video wallpaper (see setWallpaper)
            if (Images.isValidVideoByName(root.actualCurrent) && path === root.videoFramePath(root.actualCurrent))
                return;

            root.actualCurrent = path;
            root.previewColourLock = false;
        }
    }

    FileSystemModel {
        id: wallpapers

        recursive: true
        path: Paths.wallsdir
        filter: FileSystemModel.Images
        nameFilters: Images.validVideoExtensions.map(e => `*.${e}`)
    }

    Process {
        id: getPreviewColoursProc

        command: {
            if (Images.isValidVideoByName(root.previewPath))
                return ["sh", "-c", `${root.extractFrameScript}
exec caelestia wallpaper -p "$2" ${root.smartArg.join(" ")}`, "sh", root.previewPath, root.videoFramePath(root.previewPath)];
            return ["caelestia", "wallpaper", "-p", root.previewPath, ...root.smartArg];
        }
        stdout: StdioCollector {
            onStreamFinished: {
                Colours.load(text, true);
                Colours.showPreview = true;
            }
        }
    }

    Process {
        id: frameProc

        property string activePath

        command: ["sh", "-c", root.extractFrameScript, "sh", activePath, root.videoFramePath(activePath)]
        onExited: code => { // qmllint disable signal-handler-parameters
            const updated = Object.assign({}, root.videoFrames);
            updated[activePath] = code === 0 ? root.videoFramePath(activePath) : "";
            root.videoFrames = updated;
            activePath = "";
            root.processFrameQueue();
        }
    }
}
