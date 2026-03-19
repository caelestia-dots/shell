pragma Singleton

import qs.config
import qs.utils
import Caelestia
import QtQuick
import Quickshell
import Quickshell.Io
import "../utils/scripts/lrcparser.js" as Lrc

Singleton {
    id: root

    property var player: Players.active
    property int currentIndex: -1
    property bool loading: false
    property bool isManualSeeking: false
    property bool lyricsVisible: Config.services.showLyrics
    property string backend: "Local"
    property real currentSongId: 0

    property real offset

    readonly property string lyricsDir: Paths.absolutePath(Config.paths.lyricsDir)
    readonly property string lyricsMapFile: Paths.absolutePath(Config.paths.lyricsDir) + "/lyrics_map.json"

    property int currentRequestId: 0

    // The data source for the UI
    readonly property alias model: lyricsModel
    readonly property alias candidatesModel: fetchedCandidatesModel

    property var lyricsMap: ({})

    ListModel {
        id: lyricsModel
    }
    ListModel {
        id: fetchedCandidatesModel
    }

    Timer {
        id: seekTimer
        interval: 500
        onTriggered: root.isManualSeeking = false
    }

    // If no local lyrics were loaded within the interval, fall back to NetEase
    Timer {
        id: fallbackTimer
        interval: 200
        onTriggered: {
            if (lyricsModel.count === 0) {
                root.backend = "NetEase";
                fallbackToOnline();
            }
        }
    }

    Timer {
        id: loadDebounce
        interval: 50
        onTriggered: root._doLoadLyrics()
    }

    FileView {
        id: lyricsMapFileView
        path: root.lyricsMapFile
        printErrors: false
        onLoaded: {
            try {
                root.lyricsMap = JSON.parse(text());
            } catch (e) {
                root.lyricsMap = {};
            }
        }
    }

    FileView {
        id: lrcFile
        printErrors: false
        onLoaded: {
            fallbackTimer.stop();
            let parsed = Lrc.parseLrc(text());
            if (parsed.length > 0) {
                root.backend = "Local";
                updateModel(parsed);
                loading = false;
            } else {
                root.backend = "NetEase";
                fallbackToOnline();
            }
        }
    }

    Connections {
        target: Players
        function onActiveChanged() {
            root.player = Players.active;
            loadLyrics();
        }
    }

    Connections {
        target: root.player
        ignoreUnknownSignals: true
        function onMetadataChanged() {
            loadLyrics();
        }
    }

    Process {
        id: saveLyricsMap
        command: ["sh", "-c", `mkdir -p "${root.lyricsDir}" && echo '${JSON.stringify(root.lyricsMap)}' > "${root.lyricsMapFile}"`]
    }

    function getMetadata() {
        if (!player || !player.metadata)
            return null;
        let artist = player.metadata["xesam:artist"];
        const title = player.metadata["xesam:title"];
        if (Array.isArray(artist))
            artist = artist.join(", ");
        return {
            artist: artist || "Unknown",
            title: title || "Unknown"
        };
    }

    function _metaKey(meta) {
        return `${meta.artist} - ${meta.title}`;
    }

    function savePrefs() {
        let meta = getMetadata();
        if (!meta)
            return;
        let key = _metaKey(meta);
        let existing = root.lyricsMap[key] ?? {};
        root.lyricsMap[key] = {
            offset: root.offset,
            backend: root.backend,
            neteaseId: existing.neteaseId ?? null
        };
        // reassign to notify QML bindings of the map change
        root.lyricsMap = root.lyricsMap;
        saveLyricsMap.command = ["sh", "-c", `mkdir -p "${root.lyricsDir}" && echo '${JSON.stringify(root.lyricsMap).replace(/'/g, "'\\''")}' > "${root.lyricsMapFile}"`];
        saveLyricsMap.running = true;
    }

    function toggleVisibility() {
        Config.services.showLyrics = !Config.services.showLyrics;
        Config.save();
    }

    function loadLyrics() {
        loadDebounce.restart();
    }

    function _doLoadLyrics() {
        const meta = getMetadata();
        if (!meta)
            return;

        loading = true;
        lyricsModel.clear();
        currentIndex = -1;
        root.currentSongId = 0;
        root.backend = "Local";

        root.currentRequestId++;
        let requestId = root.currentRequestId;

        let key = _metaKey(meta);
        let saved = root.lyricsMap[key];
        root.offset = saved?.offset ?? 0.0;

        if (saved?.neteaseId && saved?.backend === "NetEase") {
            root.backend = "NetEase";
            root.currentSongId = saved.neteaseId;
            fetchNetEaseLyrics(saved.neteaseId, requestId);
            fetchNetEaseCandidates(meta.title, meta.artist, requestId);
            return;
        }

        if (saved?.backend === "NetEase") {
            fallbackTimer.restart();
            return;
        }

        let cleanDir = lyricsDir.replace(/\/$/, "");
        let fullPath = `${cleanDir}/${meta.artist} - ${meta.title}.lrc`;

        lrcFile.path = "";
        lrcFile.path = fullPath;
        fetchNetEaseCandidates(meta.title, meta.artist, requestId); //to populate the list regardless

        // if the file is missing, FileView will not fire onLoaded, so we arm the fallback timer here as a safety net. It is cancelled in onLoaded if the file loads successfully.
        if (saved?.backend !== "Local")
            fallbackTimer.restart();
    }

    function updateModel(parsedArray) {
        root.currentIndex = -1;
        lyricsModel.clear();
        for (let line of parsedArray) {
            lyricsModel.append({
                time: line.time,
                lyricLine: line.text
            });
        }
    }

    function fallbackToOnline() {
        let meta = getMetadata();
        if (!meta)
            return;
        fetchNetEase(meta.title, meta.artist, root.currentRequestId);
    }

    // NetEase

    // shared headers for all NetEase requests
    readonly property var _netEaseHeaders: ({
            "User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:120.0) Gecko/20100101 Firefox/120.0",
            "Referer": "https://music.163.com/"
        })

    // searches NetEase and populates the candidates model. returns the result array via the onResults callback
    function _searchNetEase(title, artist, reqId, onResults) {
        Requests.resetCookies();
        const query = encodeURIComponent(`${title} ${artist}`);
        const url = `https://music.163.com/api/search/get?s=${query}&type=1&limit=5`;

        Requests.get(url, text => {
            if (reqId !== root.currentRequestId)
                return;
            const res = JSON.parse(text);
            const songs = res.result?.songs || [];

            fetchedCandidatesModel.clear();
            for (let s of songs) {
                fetchedCandidatesModel.append({
                    id: s.id,
                    title: s.name || "Unknown Title",
                    artist: s.artists?.map(a => a.name).join(", ") || "Unknown Artist"
                });
            }

            onResults(songs);
        }, err => {}, root._netEaseHeaders);
    }

    // populates the candidates model only. used when a saved NetEase ID already exists and we just want to refresh the picker list.
    function fetchNetEaseCandidates(title, artist, reqId) {
        _searchNetEase(title, artist, reqId, _songs => {});
    }

    // searches NetEase, populates candidates, then auto-selects the best match and fetches its lyrics.
    function fetchNetEase(title, artist, reqId) {
        _searchNetEase(title, artist, reqId, songs => {
            const bestMatch = songs.find(s => {
                const inputArtist = String(artist || "").toLowerCase();
                const sArtist = String(s.artists?.[0]?.name || "").toLowerCase();
                return inputArtist.includes(sArtist) || sArtist.includes(inputArtist);
            });

            if (!bestMatch) {
                return; // No reliable lyrics found
            }

            let key = `${artist} - ${title}`;
            root.lyricsMap[key] = {
                offset: root.lyricsMap[key]?.offset ?? 0.0,
                backend: "NetEase",
                neteaseId: bestMatch.id
            };
            root.currentSongId = bestMatch.id;
            savePrefs();
            fetchNetEaseLyrics(bestMatch.id, reqId);
        });
    }

    function fetchNetEaseLyrics(id, reqId) {
        const url = `https://music.163.com/api/song/lyric?id=${id}&lv=1&kv=1&tv=-1`;
        Requests.get(url, text => {
            if (reqId !== root.currentRequestId)
                return;
            const res = JSON.parse(text);
            if (res.lrc?.lyric) {
                updateModel(Lrc.parseLrc(res.lrc.lyric));
                loading = false;
            }
        });
    }

    function selectCandidate(songId) {
        let meta = getMetadata();
        if (!meta)
            return;
        root.backend = "NetEase";
        root.currentSongId = songId;
        let key = _metaKey(meta);
        root.lyricsMap[key] = {
            offset: root.lyricsMap[key]?.offset ?? 0.0,
            neteaseId: songId
        };
        savePrefs();
        fetchNetEaseLyrics(songId, currentRequestId);
    }

    function updatePosition() {
        if (isManualSeeking || loading || !player || lyricsModel.count === 0)
            return;

        let pos = player.position - root.offset;
        let newIdx = -1;
        for (let i = lyricsModel.count - 1; i >= 0; i--) {
            if (pos >= lyricsModel.get(i).time - 0.1) { // 100ms fudge factor
                newIdx = i;
                break;
            }
        }

        if (newIdx !== currentIndex) {
            root.currentIndex = newIdx;
        }
    }

    function jumpTo(index, time) {
        root.isManualSeeking = true;
        root.currentIndex = index;

        if (player) {
            player.position = time + root.offset + 0.01; // compensate for rounding
        }

        seekTimer.restart();
    }
}
