pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.services
import qs.utils

Searcher {
    id: root

    readonly property string currentNamePath: `${Paths.state}/wallpaper/path.txt`
    readonly property list<string> smartArg: GlobalConfig.services.smartScheme ? [] : ["--no-smart"]
    readonly property list<string> videoExtensions: ["mp4", "webm", "mov", "avi", "mkv"]
    readonly property list<string> gifExtensions: ["gif"]
    readonly property string videoFramePath: `${Paths.cache}/wallpaper-video-frame.jpg`
    readonly property string fallback: Quickshell.shellPath("assets/wallpaper.webp")

    // Picker thumbnails live in their own dir so the QML picker can use plain
    // `file://` URLs directly, avoiding the C++ imagecacher entirely. Mirrors
    // wallsdir layout: <wallsdir>/foo/bar.mp4 -> <thumbsDir>/foo/bar.mp4.jpg
    readonly property string thumbsDir: `${Paths.cache}/wallpaper-thumbs`
    readonly property string _thumbgenScript: Quickshell.shellPath("scripts/thumbgen.py")

    property bool showPreview: false
    readonly property string current: showPreview ? previewPath : actualCurrent
    property string previewPath
    property string previewColoursPath
    property string actualCurrent
    property bool previewColourLock
    property bool pendingPreviewClear

    property var subfolderFilters: []
    property var _allSubdirs: []
    // Bumped whenever the thumbnail cache is regenerated; picker items pin
    // the version in their URL so the file system isn't hit on every redraw.
    property int thumbnailVersion: 0


    function isVideo(path: string): bool {
        const idx = path.lastIndexOf(".");
        return idx !== -1 && videoExtensions.includes(path.slice(idx + 1).toLowerCase());
    }

    function getFileType(path: string): string {
        const idx = path.lastIndexOf(".");
        const ext = idx !== -1 ? path.slice(idx + 1).toLowerCase() : "";
        if (videoExtensions.includes(ext))
            return "video";
        if (ext === "gif")
            return "gif";
        return "image";
    }

    function getCategoryFor(path: string): string {
        const baseDir = Paths.wallsdir.endsWith("/") ? Paths.wallsdir : Paths.wallsdir + "/";
        if (!path.startsWith(baseDir))
            return "";
        let category = path.slice(baseDir.length);
        if (category.includes("/"))
            category = category.slice(0, category.indexOf("/"));
        return category;
    }

    function getThumbnailPath(filePath: string): string {
        const baseDir = Paths.wallsdir.endsWith("/") ? Paths.wallsdir : Paths.wallsdir + "/";
        if (!filePath.startsWith(baseDir))
            return "";
        return thumbsDir + "/" + filePath.slice(baseDir.length) + ".jpg";
    }

    function _triggerThumbnails(): void {
        if (!Paths.wallsdir) return;
        if (delayedThumbnailGen.running) delayedThumbnailGen.restart();
        else delayedThumbnailGen.start();
    }

    function setRandom(): void {
        const walls = internalEntries;
        if (walls.length === 0) return;
        const idx = Math.floor(Math.random() * walls.length);
        setWallpaper(walls[idx].path);
    }

    function setWallpaper(path: string): void {
        actualCurrent = path;

        // For videos we still extract a representative frame so the colour
        // scheme generator (which only handles stills) has something to chew
        // on, then write the video path itself into path.txt.
        if (!isVideo(path)) {
            Quickshell.execDetached(["caelestia", "wallpaper", "-f", path, ...smartArg]);
            return;
        }

        const smart = smartArg.join(" ");
        Quickshell.execDetached([
            "bash",
            "-c",
            `if command -v ffmpeg >/dev/null 2>&1; then ffmpeg -y -loglevel error -i "$1" -frames:v 1 "$2" && caelestia wallpaper -f "$2" ${smart}; fi; printf %s "$1" > "$3"`,
            "bash",
            path,
            videoFramePath,
            currentNamePath
        ]);
    }

    function preview(path: string): void {
        previewPath = path;
        showPreview = true;

        if (Colours.scheme !== "dynamic")
            return;

        if (isVideo(path)) {
            previewFrameProc.running = true;
        } else {
            previewColoursPath = path;
            getPreviewColoursProc.running = true;
        }
    }

    function stopPreview(): void {
        showPreview = false;
        if (previewColourLock)
            pendingPreviewClear = true;
        else
            Colours.showPreview = false;
    }

    onPreviewColourLockChanged: {
        if (!previewColourLock && pendingPreviewClear)
            Colours.showPreview = false;
    }

    // ── Wallpaper entries as QtObjects for Searcher ────────────────────

    property var internalEntries: []

    list: internalEntries

    Component {
        id: wallpaperEntryFactory

        QtObject {
            property string path
            property string name
            property string parentDir
            property string relativePath
        }
    }

    function _buildList(filePaths: var): void {
        const arr = [];
        const baseDir = Paths.wallsdir.endsWith("/") ? Paths.wallsdir : Paths.wallsdir + "/";

        for (const f of filePaths) {
            const entry = wallpaperEntryFactory.createObject(root);
            entry.path = f;
            entry.name = f.split("/").pop();
            entry.parentDir = f.substring(0, f.lastIndexOf("/"));
            entry.relativePath = f.startsWith(baseDir) ? f.slice(baseDir.length) : f;
            arr.push(entry);
        }

        for (const e of internalEntries.slice())
            e.destroy();

        internalEntries = arr;
        root._triggerThumbnails();
    }

    // ── IPC ────────────────────────────────────────────────────────────

    IpcHandler {
        function get(): string {
            return root.actualCurrent;
        }

        function set(path: string): void {
            root.setWallpaper(path);
        }

        function list(): string {
            return root.internalEntries.map(w => w.path).join("\n");
        }

        target: "wallpaper"
    }

    // ── Current wallpaper persistence ──────────────────────────────────

    FileView {
        id: currentFileView

        path: root.currentNamePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const wall = text().trim();
            if (!wall) {
                root.actualCurrent = root.fallback;
                Quickshell.execDetached(["caelestia", "wallpaper", "-f", root.fallback, ...root.smartArg]);
            } else {
                root.actualCurrent = wall;
            }
            root.previewColourLock = false;
            root._triggerScan();
        }
        onLoadFailed: {
            root.actualCurrent = root.fallback;
            root.previewColourLock = false;
            Quickshell.execDetached(["caelestia", "wallpaper", "-f", root.fallback, ...root.smartArg]);
            root._triggerScan();
        }
    }

    // ── Wallpaper directory scanning via find ──────────────────────────

    function _triggerScan(): void {
        if (!Paths.wallsdir) return;
        scanProc.running = true;
        scanSubfoldersProc.running = true;
    }

    Component.onCompleted: initialScanTimer.start()

    Timer {
        id: initialScanTimer

        interval: 500
        repeat: false
        onTriggered: root._triggerScan()
    }

    Process {
        id: scanProc

        running: false

        command: {
            const d = Paths.wallsdir;
            if (!d) return [];
            return ["find", d, "-name", ".*", "-prune", "-o", "-type", "f",
                "(", "-name", "*.jpg", "-o", "-name", "*.jpeg", "-o", "-name", "*.png",
                "-o", "-name", "*.webp", "-o", "-name", "*.tif", "-o", "-name", "*.tiff",
                "-o", "-name", "*.bmp", "-o", "-name", "*.svg",
                "-o", "-name", "*.gif", "-o", "-name", "*.mp4", "-o", "-name", "*.webm",
                "-o", "-name", "*.mov", "-o", "-name", "*.avi", "-o", "-name", "*.mkv", ")", "-print"];
        }

        stdout: StdioCollector {
            onStreamFinished: {
                const files = text.trim().split("\n").filter(f => f.length > 0);
                if (files.length === 0) {
                    console.log("No wallpapers found in", Paths.wallsdir, "— using fallback");
                    scanFallback.running = true;
                } else {
                    const sorted = files.sort();
                    const prevSorted = root.internalEntries.map(e => e.path).sort();
                    const changed = JSON.stringify(sorted) !== JSON.stringify(prevSorted);

                    if (changed) {
                        console.log("Wallpaper scan found", sorted.length, "files");
                        root._buildList(sorted);
                    }
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0)
                    console.warn("Wallpaper scan stderr:", text);
            }
        }
    }

    Process {
        id: scanFallback

        running: false
        command: {
            const d = Quickshell.shellPath("assets");
            if (!d) return [];
            return ["find", d, "-name", ".*", "-prune", "-o", "-type", "f",
                "(", "-name", "*.jpg", "-o", "-name", "*.jpeg", "-o", "-name", "*.png",
                "-o", "-name", "*.webp", "-o", "-name", "*.tif", "-o", "-name", "*.tiff",
                "-o", "-name", "*.bmp", "-o", "-name", "*.svg",
                "-o", "-name", "*.gif", "-o", "-name", "*.mp4", "-o", "-name", "*.webm",
                "-o", "-name", "*.mov", "-o", "-name", "*.avi", "-o", "-name", "*.mkv", ")", "-print"];
        }

        stdout: StdioCollector {
            onStreamFinished: {
                const files = text.trim().split("\n").filter(f => f.length > 0);
                console.log("Fallback scan found", files.length, "wallpapers");
                root._buildList(files.sort());
            }
        }
    }

    Process {
        id: scanSubfoldersProc

        running: false
        command: {
            const d = Paths.wallsdir;
            if (!d) return [];
            return ["find", d, "-mindepth", "1", "-name", ".*", "-prune", "-o", "-type", "d", "-print"];
        }

        stdout: StdioCollector {
            onStreamFinished: {
                const raw = text.trim().split("\n").filter(f => f.length > 0);
                root._allSubdirs = raw;

                const base = Paths.wallsdir.endsWith("/") ? Paths.wallsdir : Paths.wallsdir + "/";
                const topLevel = raw
                    .map(p => {
                        const rel = p.replace(base, "");
                        return rel.indexOf("/") === -1 ? p.split("/").pop() : null;
                    })
                    .filter(n => n !== null && !n.startsWith("."))
                    .sort();
                root.subfolderFilters = topLevel;
            }
        }
    }

    // ── Directory watchers ─────────────────────────────────────────────

    FileView {
        id: dirWatcher

        path: Paths.wallsdir
        watchChanges: true
        printErrors: false
        onFileChanged: {
            if (!Paths.wallsdir) return;
            root._triggerScan();
        }
    }

    Instantiator {
        model: root._allSubdirs
        delegate: FileView {
            path: modelData
            watchChanges: true
            printErrors: false
            onFileChanged: {
                console.log("Subdirectory changed:", path);
                root._triggerScan();
            }
        }
    }

    // ── Preview colour extraction ──────────────────────────────────────

    Process {
        id: previewFrameProc

        command: ["ffmpeg", "-y", "-loglevel", "error", "-i", root.previewPath, "-frames:v", "1", root.videoFramePath]
        onExited: code => { // qmllint disable signal-handler-parameters
            if (code === 0) {
                root.previewColoursPath = root.videoFramePath;
                getPreviewColoursProc.running = true;
            }
        }
    }

    Process {
        id: getPreviewColoursProc

        command: ["caelestia", "wallpaper", "-p", root.previewColoursPath, ...root.smartArg]
        stdout: StdioCollector {
            onStreamFinished: {
                Colours.load(text, true);
                Colours.showPreview = true;
            }
        }
    }

    // ── Thumbnail generation ───────────────────────────────────────────
    //
    // The thumbnail script (scripts/thumbgen.py) writes 280x158-crop JPGs
    // mirroring wallsdir into <cache>/wallpaper-thumbs/. The picker items
    // bind directly to those file:// URLs so videos and gifs get thumbs
    // without depending on the C++ imagecacher having ffmpeg support.
    //
    // Runs 2s after the most recent _buildList so a flurry of FS events
    // collapses into a single generation pass.

    Timer {
        id: delayedThumbnailGen

        interval: 2000
        repeat: false
        onTriggered: {
            const fallbackDir = Paths.wallsdir;
            thumbgenProc.command = [
                "python3", root._thumbgenScript,
                Paths.wallsdir,
                Paths.cache,
                fallbackDir
            ];
            thumbgenProc.running = true;
        }
    }

    Process {
        id: thumbgenProc

        running: false
        command: []

        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) console.log("thumbgen:", text);
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) console.warn("thumbgen err:", text);
            }
        }
        onExited: exitCode => { // qmllint disable signal-handler-parameters
            if (exitCode === 0) {
                root.thumbnailVersion++;
            } else {
                console.warn("thumbgen failed with code:", exitCode);
            }
        }
    }
}
