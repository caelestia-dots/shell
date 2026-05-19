pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils
import qs.services

QtObject {
    id: root

    property string source: ""
    property string activeSource: ""
    property string output: "ALL"
    property var monitorSourceMap: ({})
    property string fitMode: "Crop"
    property real playbackRate: 1.0
    property bool loop: true
    property int fadeDuration: 250
    property bool running: false
    property bool paused: false
    property bool visualActive: false
    property bool autoStart: false
    property string sortMode: "name"
    property string performanceMode: "Aggressive"

    property string pendingMode: ""
    property string pendingSource: ""
    property string pendingOutput: ""
    property var thumbnailCache: ({})
    property var thumbnailJobs: []
    property string activeThumbnailSource: ""
    property string activeThumbnailCachePath: ""
    property var metadataCache: ({})
    property var metadataJobs: []
    property string activeMetadataSource: ""
    property bool configLoaded: false
    property bool applyingConfig: false
    property bool mutatingState: false

    property string backendStatus: "Stopped"

    readonly property string configPath: `${Paths.config}/video-wallpaper.json`
    readonly property bool activeWallpaper: running && visualActive
    readonly property string thumbnailCacheDir: `${Paths.imagecache}/videowallpaper`
    readonly property string thumbnailCacheVersion: "v2"
    readonly property bool performanceLimited: GameMode.enabled
    readonly property bool effectivePaused: paused || (running && performanceLimited)
    readonly property string primaryMonitorName: {
        const names = Hypr.monitorNames();
        return names.length ? names[0] : "";
    }

    function monitorSourceKeys() {
        return Object.keys(monitorSourceMap || {});
    }

    function defaultConfigObject() {
        return {
            source: "",
            output: "ALL",
            monitorSources: [],
            fitMode: "Crop",
            playbackRate: 1.0,
            loop: true,
            fadeDuration: 250,
            autoStart: false,
            sortMode: "name",
            performanceMode: "Aggressive"
        };
    }

    function readConfigObject() {
        const raw = String(configFile.text() || "").trim();
        if (!raw)
            return defaultConfigObject();

        try {
            return Object.assign(defaultConfigObject(), JSON.parse(raw));
        } catch (error) {
            console.warn(`Failed to parse video wallpaper config: ${error}`);
            return defaultConfigObject();
        }
    }

    function writeConfigObject(value) {
        configFile.setText(JSON.stringify(Object.assign(defaultConfigObject(), value || {}), null, 4) + "\n");
    }

    function hasPerMonitorAssignments() {
        return monitorSourceKeys().length > 0;
    }

    function preferredAssignedSource() {
        const keys = monitorSourceKeys();
        if (!keys.length)
            return "";

        if (primaryMonitorName) {
            const primarySource = String(monitorSourceMap[primaryMonitorName] || "");
            if (primarySource)
                return primarySource;
        }

        return String(monitorSourceMap[keys[0]] || "");
    }

    function normalizedOutputForConfig() {
        if (!hasPerMonitorAssignments())
            return "ALL";

        const currentOutput = String(output || "");
        if (currentOutput && currentOutput !== "ALL" && String(monitorSourceMap[currentOutput] || ""))
            return currentOutput;

        if (primaryMonitorName && String(monitorSourceMap[primaryMonitorName] || ""))
            return primaryMonitorName;

        const keys = monitorSourceKeys();
        return keys.length ? keys[0] : "ALL";
    }

    function globalSource() {
        return hasPerMonitorAssignments() ? "" : String(source || "");
    }

    function assignedSourceForMonitor(monitorName) {
        const targetName = String(monitorName || "");
        if (!targetName)
            return "";
        return String(monitorSourceMap[targetName] || "");
    }

    function activeOutputNames() {
        const names = Hypr.monitorNames();
        if (!running || !visualActive)
            return [];

        if (hasPerMonitorAssignments()) {
            const assignedNames = [];
            for (let i = 0; i < names.length; i++) {
                if (String(monitorSourceMap[names[i]] || ""))
                    assignedNames.push(names[i]);
            }
            if (performanceMode === "Aggressive"
                && assignedNames.length > 1
                && primaryMonitorName
                && assignedNames.includes(primaryMonitorName))
                return [primaryMonitorName];
            return assignedNames;
        }

        if (!source)
            return [];

        const activeNames = [];
        for (let i = 0; i < names.length; i++) {
            activeNames.push(names[i]);
        }
        if (performanceMode === "Aggressive"
            && activeNames.length > 1
            && primaryMonitorName
            && activeNames.includes(primaryMonitorName))
            return [primaryMonitorName];
        return activeNames;
    }

    function usesPrimaryOnly() {
        const activeNames = activeOutputNames();
        return performanceMode === "Aggressive"
            && Hypr.monitorNames().length > 1
            && !!primaryMonitorName
            && activeNames.length === 1
            && activeNames[0] === primaryMonitorName;
    }

    function shouldDisplayOn(monitorName, screenName) {
        const targetName = String(monitorName || screenName || "");
        if (!targetName)
            return false;
        return activeOutputNames().includes(targetName);
    }

    function monitorSourcesToList() {
        const items = [];
        const keys = Object.keys(monitorSourceMap || {});
        for (let i = 0; i < keys.length; i++) {
            const monitor = keys[i];
            const assignedSource = String(monitorSourceMap[monitor] || "");
            if (!assignedSource)
                continue;
            items.push({
                monitor: monitor,
                source: assignedSource
            });
        }
        return items;
    }

    function monitorSourcesFromValue(value) {
        const result = {};
        if (!Array.isArray(value))
            return result;
        for (let i = 0; i < value.length; i++) {
            const entry = value[i];
            const monitor = String(entry?.monitor || "");
            const assignedSource = String(entry?.source || "");
            if (!monitor || !assignedSource)
                continue;
            result[monitor] = assignedSource;
        }
        return result;
    }

    function sourceForOutput(outputName) {
        const targetName = String(outputName || "");
        if (!targetName)
            return "";

        if (targetName === "ALL")
            return globalSource();

        if (hasPerMonitorAssignments())
            return assignedSourceForMonitor(targetName);

        return globalSource();
    }

    function sourceForMonitor(monitorName, screenName) {
        return sourceForOutput(String(monitorName || screenName || ""));
    }

    function activeOutputsForSource(path) {
        if (!path || !running || !visualActive)
            return [];
        const names = Hypr.monitorNames();
        const matches = [];
        for (let i = 0; i < names.length; i++) {
            if (sourceForOutput(names[i]) === path)
                matches.push(names[i]);
        }
        if (performanceMode === "Aggressive" && matches.length > 1 && primaryMonitorName)
            return matches.includes(primaryMonitorName) ? [primaryMonitorName] : [];
        return matches;
    }

    function activeOutputsTextForSource(path) {
        const names = activeOutputsForSource(path);
        if (!names.length)
            return "";
        const allNames = Hypr.monitorNames();
        if (names.length === allNames.length)
            return "ALL";
        return names.join(", ");
    }

    function isSourceActive(path) {
        return activeOutputsForSource(path).length > 0;
    }

    function setSourceForOutput(outputName, path) {
        const targetName = String(outputName || "");
        const assignedSource = String(path || "");
        if (!assignedSource)
            return;

        ensureThumbnail(assignedSource);
        ensureMetadata(assignedSource);

        if (targetName === "ALL" || !targetName) {
            source = assignedSource;
            output = "ALL";
            monitorSourceMap = ({});
        } else {
            const nextMap = Object.assign({}, monitorSourceMap);
            nextMap[targetName] = assignedSource;
            monitorSourceMap = nextMap;
            output = targetName;
            source = "";
        }

        activeSource = assignedSource;
        scheduleConfigSave();
        syncPlaybackBackend();
    }

    function applySelection(outputName, path) {
        const targetName = String(outputName || "");
        const assignedSource = String(path || "");
        if (!assignedSource)
            return;

        const currentAssignedSource = sourceForOutput(targetName);
        const shouldSwitch = running
            && visualActive
            && currentAssignedSource
            && currentAssignedSource !== assignedSource;

        mutatingState = true;
        if (shouldSwitch) {
            pendingMode = "switch";
            pendingSource = assignedSource;
            pendingOutput = targetName || "ALL";
            running = true;
            paused = false;
            backendStatus = qsTr("Running");
            visualActive = false;
            transitionTimer.restart();
        } else {
            setSourceForOutput(targetName, assignedSource);
            start(assignedSource);
            writeConfig();
        }
        mutatingState = false;
    }

    function finishTransition() {
        switch (pendingMode) {
        case "stop":
            activeSource = "";
            break;
        case "pause":
            break;
        case "resume":
            if (!activeSource)
                activeSource = preferredAssignedSource() || source;
            visualActive = true;
            break;
        case "start":
            if (pendingSource && !hasPerMonitorAssignments())
                source = pendingSource;
            if (!activeSource)
                activeSource = preferredAssignedSource() || source;
            visualActive = true;
            break;
        case "switch":
            if (pendingSource) {
                setSourceForOutput(pendingOutput || "ALL", pendingSource);
                activeSource = preferredAssignedSource() || source;
            }
            visualActive = true;
            break;
        default:
            break;
        }

        pendingMode = "";
        pendingSource = "";
        pendingOutput = "";
        syncPlaybackBackend();
        if (mutatingState)
            return;
        writeConfig();
    }

    function start(path) {
        const nextSource = String(path || preferredAssignedSource() || source || "");
        if (!nextSource)
            return;

        if (path)
            activeSource = nextSource;
        if (!source && !hasPerMonitorAssignments())
            source = nextSource;
        running = true;
        paused = false;
        if (!activeSource)
            activeSource = nextSource;
        visualActive = true;
        syncPlaybackBackend();
    }

    function stop() {
        if (!activeSource && !visualActive) {
            running = false;
            paused = false;
            backendStatus = qsTr("Stopped");
            return;
        }

        running = false;
        paused = false;
        backendStatus = qsTr("Stopped");
        pendingMode = "stop";
        visualActive = false;
        transitionTimer.restart();
    }

    function pause() {
        if (!running)
            return;
        paused = true;
        backendStatus = qsTr("Paused");
        syncPlaybackBackend();
    }

    function resume() {
        if (!running || (!source && !Object.keys(monitorSourceMap || {}).length))
            return;
        paused = false;
        if (!activeSource)
            activeSource = preferredAssignedSource() || source;
        syncPlaybackBackend();
    }

    function togglePause() {
        if (!running)
            return;
        if (paused)
            resume();
        else
            pause();
    }

    function selectSource(path) {
        if (!path)
            return;

        activeSource = path;
        if (running) {
            paused = false;
            visualActive = true;
            syncPlaybackBackend();
        }
    }

    function fileNameFor(path) {
        const text = String(path || "");
        const parts = text.split("/");
        return parts.length > 0 ? parts[parts.length - 1] : text;
    }

    function cacheKeyFor(path) {
        let h1 = 0xdeadbeef, h2 = 0x41c6ce57, ch;
        for (let i = 0; i < path.length; i++) {
            ch = path.charCodeAt(i);
            h1 = Math.imul(h1 ^ ch, 2654435761);
            h2 = Math.imul(h2 ^ ch, 1597334677);
        }
        h1 = Math.imul(h1 ^ (h1 >>> 16), 2246822507);
        h1 ^= Math.imul(h2 ^ (h2 >>> 13), 3266489909);
        h2 = Math.imul(h2 ^ (h2 >>> 16), 2246822507);
        h2 ^= Math.imul(h1 ^ (h1 >>> 13), 3266489909);
        return (h2 >>> 0).toString(16).padStart(8, "0") + (h1 >>> 0).toString(16).padStart(8, "0");
    }

    function cachePathFor(path) {
        return `${thumbnailCacheDir}/${cacheKeyFor(path)}-${thumbnailCacheVersion}.jpg`;
    }

    function thumbnailFor(path) {
        if (!path)
            return "";
        return thumbnailCache[path] || cachePathFor(path);
    }

    function ensureThumbnail(path) {
        if (!path || thumbnailCache[path] || activeThumbnailSource === path || thumbnailJobs.includes(path))
            return;
        queueThumbnailGeneration(path, cachePathFor(path));
    }

    function queueThumbnailGeneration(path, cachePath) {
        if (!path || thumbnailCache[path] || activeThumbnailSource === path || thumbnailJobs.includes(path))
            return;
        const nextJobs = thumbnailJobs.slice();
        nextJobs.push(path);
        thumbnailJobs = nextJobs;
        if (!activeThumbnailSource)
            startNextThumbnailJob(cachePath);
    }

    function startNextThumbnailJob(preferredCachePath) {
        if (activeThumbnailSource || !thumbnailJobs.length)
            return;

        const nextPath = thumbnailJobs[0];
        activeThumbnailSource = nextPath;
        activeThumbnailCachePath = preferredCachePath || cachePathFor(nextPath);
        thumbnailGen.command = [
            "/usr/bin/bash",
            "-lc",
            "mkdir -p \"$1\" && ffmpeg -y -loglevel error -i \"$2\" -vf \"select='eq(n\\,0)',scale=640:-1\" -frames:v 1 \"$3\"",
            "--",
            thumbnailCacheDir,
            nextPath,
            activeThumbnailCachePath
        ];
        thumbnailGen.running = true;
    }

    function finishThumbnailJob(success) {
        const path = activeThumbnailSource;
        const cachePath = activeThumbnailCachePath;

        if (path) {
            thumbnailJobs = thumbnailJobs.filter(function(item) { return item !== path; });
            if (success)
                thumbnailCache = Object.assign({}, thumbnailCache, { [path]: `${cachePath}?v=${Date.now()}` });
        }

        activeThumbnailSource = "";
        activeThumbnailCachePath = "";
        startNextThumbnailJob();
    }

    function metadataFor(path) {
        if (!path)
            return null;
        return metadataCache[path] || null;
    }

    function preloadMetadata(paths) {
        const items = paths || [];
        for (let i = 0; i < items.length; i++)
            ensureMetadata(items[i]);
    }

    function ensureMetadata(path) {
        if (!path || metadataCache[path] || activeMetadataSource === path || metadataJobs.includes(path))
            return;
        const nextJobs = metadataJobs.slice();
        nextJobs.push(path);
        metadataJobs = nextJobs;
        if (!activeMetadataSource)
            startNextMetadataJob();
    }

    function parseFrameRate(value) {
        const text = String(value || "");
        if (!text)
            return 0;
        if (text.indexOf("/") !== -1) {
            const parts = text.split("/");
            const numerator = Number(parts[0] || 0);
            const denominator = Number(parts[1] || 1);
            if (denominator === 0)
                return 0;
            return numerator / denominator;
        }
        return Number(text || 0);
    }

    function parseMetadataOutput(text, path) {
        const data = {
            path: path,
            duration: 0,
            size: 0,
            width: 0,
            height: 0,
            fps: 0,
            codec: ""
        };
        const lines = String(text || "").split("\n");
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            const tabIndex = line.indexOf("\t");
            if (tabIndex === -1)
                continue;
            const key = line.slice(0, tabIndex);
            const value = line.slice(tabIndex + 1).trim();
            switch (key) {
            case "duration":
                data.duration = Number(value || 0);
                break;
            case "size":
                data.size = Number(value || 0);
                break;
            case "width":
                data.width = Number(value || 0);
                break;
            case "height":
                data.height = Number(value || 0);
                break;
            case "fps":
                data.fps = parseFrameRate(value);
                break;
            case "codec":
                data.codec = value;
                break;
            default:
                break;
            }
        }
        data.resolutionPixels = data.width * data.height;
        return data;
    }

    function startNextMetadataJob() {
        if (activeMetadataSource || !metadataJobs.length)
            return;

        const nextPath = metadataJobs[0];
        activeMetadataSource = nextPath;
        metadataProbe.command = [
            "/usr/bin/bash",
            "-lc",
            "ffprobe -v error -select_streams v:0 -show_entries stream=width,height,avg_frame_rate,codec_name -show_entries format=duration,size -of default=noprint_wrappers=1:nokey=0 \"$1\" | sed -e 's/^avg_frame_rate=/fps\\t/' -e 's/^codec_name=/codec\\t/' -e 's/^width=/width\\t/' -e 's/^height=/height\\t/' -e 's/^duration=/duration\\t/' -e 's/^size=/size\\t/'",
            "--",
            nextPath
        ];
        metadataProbe.running = true;
    }

    function finishMetadataJob(success, text) {
        const path = activeMetadataSource;

        if (path) {
            metadataJobs = metadataJobs.filter(function(item) { return item !== path; });
            if (success) {
                metadataCache = Object.assign({}, metadataCache, { [path]: parseMetadataOutput(text, path) });
                if (path === activeSource || path === source)
                    syncPlaybackBackend();
            }
        }

        activeMetadataSource = "";
        startNextMetadataJob();
    }

    function performanceStatusText() {
        if (!running)
            return qsTr("Stopped");
        if (paused)
            return qsTr("Paused");
        if (performanceLimited)
            return qsTr("Paused for game mode");
        if (usesPrimaryOnly())
            return qsTr("Primary only");
        return qsTr("Running");
    }

    function syncPlaybackBackend() {
        if (!running || (!source && !Object.keys(monitorSourceMap || {}).length)) {
            visualActive = false;
            backendStatus = performanceStatusText();
            return;
        }

        if (effectivePaused) {
            visualActive = true;
            backendStatus = performanceStatusText();
            return;
        }

        const targetSource = activeSource || preferredAssignedSource() || source;
        if (!targetSource) {
            visualActive = false;
            backendStatus = performanceStatusText();
            return;
        }

        visualActive = true;
        backendStatus = performanceStatusText();
    }

    function scheduleConfigSave() {
        if (!configLoaded || applyingConfig || mutatingState)
            return;
        saveConfigTimer.restart();
    }

    function applyConfigState() {
        const cfg = readConfigObject();
        applyingConfig = true;

        const restoredMap = monitorSourcesFromValue(cfg.monitorSources || []);
        const restoredKeys = Object.keys(restoredMap);
        monitorSourceMap = restoredMap;
        source = restoredKeys.length ? "" : (cfg.source || "");
        if (restoredKeys.length) {
            output = String(cfg.output || "");
            output = normalizedOutputForConfig();
        } else {
            output = "ALL";
        }
        fitMode = cfg.fitMode || "Crop";
        playbackRate = Number(cfg.playbackRate || 1);
        loop = cfg.loop !== false;
        fadeDuration = Number(cfg.fadeDuration || 250);
        autoStart = !!cfg.autoStart;
        sortMode = cfg.sortMode || "name";
        performanceMode = cfg.performanceMode || "Aggressive";
        activeSource = restoredKeys.length ? preferredAssignedSource() : source;

        if (source) {
            ensureThumbnail(source);
            ensureMetadata(source);
        }

        const assignedSourceKeys = monitorSourceKeys();
        for (let i = 0; i < assignedSourceKeys.length; i++) {
            const assignedSource = String(monitorSourceMap[assignedSourceKeys[i]] || "");
            ensureThumbnail(assignedSource);
            ensureMetadata(assignedSource);
        }

        if (!configLoaded)
            configLoaded = true;

        if (source || assignedSourceKeys.length) {
            if (autoStart)
                start(assignedSourceKeys.length ? preferredAssignedSource() : source);
            else
                syncPlaybackBackend();
        } else {
            syncPlaybackBackend();
        }

        applyingConfig = false;
    }

    function writeConfig() {
        const configOutput = normalizedOutputForConfig();
        writeConfigObject({
            source: globalSource(),
            output: configOutput,
            monitorSources: monitorSourcesToList(),
            fitMode: fitMode,
            playbackRate: playbackRate,
            loop: loop,
            fadeDuration: fadeDuration,
            autoStart: autoStart,
            sortMode: sortMode,
            performanceMode: performanceMode
        });
        output = configOutput;
    }

    Component.onCompleted: {
        if (configFile.loaded)
            applyConfigState();
        else
            startupConfigTimer.restart();
    }

    onSourceChanged: {
        if (source) {
            ensureThumbnail(source);
            ensureMetadata(source);
        }
        syncPlaybackBackend();
        scheduleConfigSave();
    }
    onOutputChanged: { syncPlaybackBackend(); scheduleConfigSave(); }
    onFitModeChanged: scheduleConfigSave()
    onPlaybackRateChanged: scheduleConfigSave()
    onLoopChanged: scheduleConfigSave()
    onFadeDurationChanged: scheduleConfigSave()
    onAutoStartChanged: scheduleConfigSave()
    onSortModeChanged: scheduleConfigSave()
    onPerformanceModeChanged: { syncPlaybackBackend(); scheduleConfigSave(); }
    onPerformanceLimitedChanged: syncPlaybackBackend()
    onPrimaryMonitorNameChanged: syncPlaybackBackend()

    readonly property Timer transitionTimer: Timer {
        id: transitionTimer

        interval: Math.max(1, root.fadeDuration)
        onTriggered: root.finishTransition()
    }

    readonly property Timer saveConfigTimer: Timer {
        id: saveConfigTimer

        interval: 250
        onTriggered: root.writeConfig()
    }

    readonly property Timer startupConfigTimer: Timer {
        id: startupConfigTimer

        interval: 300
        repeat: false
        onTriggered: {
            if (root.configLoaded)
                return;
            if (configFile.loaded)
                root.applyConfigState();
            else
                restart();
        }
    }

    readonly property FileView configFile: FileView {
        id: configFile

        path: root.configPath
        watchChanges: true
        printErrors: false

        onLoaded: {
            if (!root.configLoaded)
                root.applyConfigState();
        }

        onLoadFailed: error => {
            if (!root.configLoaded) {
                root.configLoaded = true;
                root.applyingConfig = false;
                root.syncPlaybackBackend();
                if (error === FileViewError.FileNotFound)
                    Qt.callLater(() => root.writeConfigObject(root.defaultConfigObject()));
            }
        }

        onFileChanged: reload()
    }

    readonly property Process thumbnailGen: Process {
        id: thumbnailGen

        running: false
        onExited: exitCode => root.finishThumbnailJob(exitCode === 0)
    }

    readonly property Process metadataProbe: Process {
        id: metadataProbe

        running: false

        stdout: StdioCollector {
            id: metadataCollector
        }

        stderr: StdioCollector {}

        onExited: exitCode => root.finishMetadataJob(exitCode === 0, metadataCollector.text)
    }

}
