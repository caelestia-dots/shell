pragma Singleton

import "../utils/scripts/lrcparser.js" as Lrc
import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import qs.utils

Singleton {
    id: root

    property var player: Players.active
    property int currentIndex: -1
    property bool loading: false
    property bool isManualSeeking: false
    property bool lyricsVisible: GlobalConfig.services.showLyrics
    property string backend: "Local"
    property string preferredBackend: GlobalConfig.services.lyricsBackend
    property real currentSongId: 0
    property string loadedLocalFile: ""
    property real offset
    property int currentRequestId: 0
    property var lyricsMap: ({})

    readonly property string lyricsDir: Paths.absolutePath(GlobalConfig.paths.lyricsDir)
    readonly property string lyricsMapFile: lyricsDir + "/lyrics_map.json"
    readonly property alias model: lyricsModel
    readonly property alias candidatesModel: fetchedCandidatesModel
    readonly property var _netEaseHeaders: ({
            "User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:120.0) Gecko/20100101 Firefox/120.0",
            "Referer": "https://music.163.com/"
        })
    readonly property var _lrclibHeaders: ({
            "User-Agent": "caelestia-shell (https://github.com/caelestia-dots/shell)"
        })

    function getMetadata() {
        if (!player || !player.metadata)
            return null;
        let artist = player.metadata["xesam:artist"];
        const title = player.metadata["xesam:title"];
        if (Array.isArray(artist))
            artist = artist.join(", ");
        return {
            artist: artist || "Unknown",
            title: title || "Unknown",
            album: player.metadata["xesam:album"] || "",
            duration: player.length || 0
        };
    }

    function _metaKey(meta) {
        return `${meta.artist} - ${meta.title}`;
    }

    function _loadLyricsText(text) {
        const parsed = Lrc.parseLrc(text);
        if (parsed.length > 0) {
            updateModel(parsed);
            root.updatePosition();
            loading = false;
            return true;
        }

        const lines = String(text || "").split("\n").map(line => line.trim()).filter(line => line.length > 0);
        if (lines.length > 0) {
            updateModel(lines.map((line, index) => ({
                        time: index,
                        text: line
                    })));
            root.updatePosition();
            loading = false;
            return true;
        }

        return false;
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
            lrclibId: root.backend === "LRCLIB" ? root.currentSongId : (existing.lrclibId ?? null),
            neteaseId: root.backend === "NetEase" ? root.currentSongId : (existing.neteaseId ?? null)
        };
        // reassign to notify QML bindings of the map change
        root.lyricsMap = root.lyricsMap;
        saveLyricsMap.command = ["sh", "-c", `mkdir -p "${root.lyricsDir}" && echo '${JSON.stringify(root.lyricsMap).replace(/'/g, "'\\''")}' > "${root.lyricsMapFile}"`];
        saveLyricsMap.running = true;
    }

    function toggleVisibility() {
        GlobalConfig.services.showLyrics = !GlobalConfig.services.showLyrics;
    }

    function loadLyrics() {
        loadDebounce.restart();
    }

    function _doLoadLyrics() {
        const meta = getMetadata();
        if (!meta) {
            lyricsModel.clear();
            root.currentIndex = -1;
            return;
        }

        loading = true;
        lyricsModel.clear();
        fetchedCandidatesModel.clear();
        currentIndex = -1;
        root.currentSongId = 0;

        root.currentRequestId++;
        let requestId = root.currentRequestId;

        let key = _metaKey(meta);
        let saved = root.lyricsMap[key];
        root.offset = saved?.offset ?? 0.0;

        if (root.preferredBackend === "NetEase") {
            root.backend = "NetEase";
            fetchNetEase(meta.title, meta.artist, requestId);
            return;
        }

        if (root.preferredBackend === "LRCLIB") {
            root.backend = "LRCLIB";
            fetchLrcLibLyrics(meta.title, meta.artist, meta.album ?? "", meta.duration ?? 0, requestId);
            return;
        }

        if (root.preferredBackend === "Local") {
            root.backend = "Local";
            let cleanDir = lyricsDir.replace(/\/$/, "");
            let flatPath = `${cleanDir}/${meta.artist} - ${meta.title}.lrc`;

            // Search for files matching "Artist - Title.lrc" pattern
            const artistStr = Array.isArray(meta.artist) ? meta.artist.join(", ") : String(meta.artist || "");
            const titleStr = Array.isArray(meta.title) ? meta.title.join(", ") : String(meta.title || "");
            const escapedTitle = titleStr.replace(/'/g, "'\\''");
            const escapedArtist = artistStr.replace(/'/g, "'\\''");
            findLyricsInSubdirs.command = ["sh", "-c", `find "${cleanDir}" -type f -iname "*${escapedArtist}*${escapedTitle}*.lrc" | head -n 1`];
            findLyricsInSubdirs.requestId = requestId;
            findLyricsInSubdirs.running = true;

            lrcFile.path = "";
            lrcFile.path = flatPath;
            return;
        }

        // Auto mode: try local first
        root.backend = "Local";
        let cleanDir = lyricsDir.replace(/\/$/, "");
        let flatPath = `${cleanDir}/${meta.artist} - ${meta.title}.lrc`;

        const artistStr = Array.isArray(meta.artist) ? meta.artist.join(", ") : String(meta.artist || "");
        const titleStr = Array.isArray(meta.title) ? meta.title.join(", ") : String(meta.title || "");
        const escapedTitle = titleStr.replace(/'/g, "'\\''");
        const escapedArtist = artistStr.replace(/'/g, "'\\''");
        findLyricsInSubdirs.command = ["sh", "-c", `find "${cleanDir}" -type f -iname "*${escapedArtist}*${escapedTitle}*.lrc" | head -n 1`];
        findLyricsInSubdirs.requestId = requestId;
        findLyricsInSubdirs.running = true;

        lrcFile.path = "";
        lrcFile.path = flatPath;
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
        fetchLrcLibLyrics(meta.title, meta.artist, meta.album ?? "", meta.duration ?? 0, root.currentRequestId);
    }

    // LRCLIB

    function _parseLrcLibLyrics(payload) {
        const synced = String(payload?.syncedLyrics || "").trim();
        const plain = String(payload?.plainLyrics || "").trim();
        return synced || plain;
    }

    function _normaliseText(text) {
        return String(text || "").toLowerCase().replace(/\s+/g, " ").trim();
    }

    function _pickLrcLibCandidate(songs, title, artist) {
        const cleanTitle = _normaliseText(title);
        const cleanArtist = _normaliseText(artist);

        return songs.find(song => {
            const songTitle = _normaliseText(song.trackName);
            const songArtist = _normaliseText(song.artistName);
            const artistMatches = !cleanArtist || cleanArtist.includes(songArtist) || songArtist.includes(cleanArtist);
            return songTitle === cleanTitle && artistMatches && _parseLrcLibLyrics(song);
        }) || null;
    }

    function _appendLrcLibCandidate(song, index, fallbackTitle, fallbackArtist) {
        fetchedCandidatesModel.append({
            provider: "LRCLIB",
            id: index,
            trackId: song.id ?? index,
            title: song.trackName || fallbackTitle || "Unknown Title",
            artist: song.artistName || fallbackArtist || "Unknown Artist",
            album: song.albumName || "Unknown Album",
            duration: song.duration || 0,
            syncedLyrics: song.syncedLyrics || "",
            plainLyrics: song.plainLyrics || ""
        });
    }

    function _loadLrcLibResult(result, fallbackId) {
        const lyricsText = _parseLrcLibLyrics(result);
        if (!lyricsText)
            return false;

        root.backend = "LRCLIB";
        root.currentSongId = result.trackId ?? result.id ?? fallbackId ?? 0;
        if (_loadLyricsText(lyricsText)) {
            savePrefs();
            return true;
        }

        loading = false;
        return false;
    }

    function _normaliseDuration(duration) {
        const parsed = Number(duration || 0);
        if (!isFinite(parsed) || parsed <= 0)
            return 0;
        if (parsed > 100000)
            return Math.round(parsed / 1000000);
        if (parsed > 1000)
            return Math.round(parsed / 1000);
        return Math.round(parsed);
    }

    function fetchLrcLibCandidates(title, artist, reqId, autoSelect) {
        const params = [`track_name=${encodeURIComponent(title)}`];
        if (artist)
            params.push(`artist_name=${encodeURIComponent(artist)}`);

        const url = `https://lrclib.net/api/search?${params.join("&")}`;

        Requests.get(url, text => {
            if (reqId !== root.currentRequestId)
                return;

            const songs = JSON.parse(text) || [];
            fetchedCandidatesModel.clear();

            for (let i = 0; i < songs.length; i++) {
                const song = songs[i];
                _appendLrcLibCandidate(song, i, title, artist);
            }

            if (autoSelect) {
                const bestMatch = _pickLrcLibCandidate(songs, title, artist);
                if (bestMatch && _loadLrcLibResult(bestMatch, 0))
                    return;
            }

            loading = false;
        }, err => {}, root._lrclibHeaders);
    }

    function fetchLrcLibLyrics(title, artist, album, duration, reqId) {
        const roundedDuration = _normaliseDuration(duration);
        if (!title || !artist || !album || roundedDuration <= 0) {
            fetchLrcLibCandidates(title, artist, reqId, true);
            return;
        }

        const params = [`track_name=${encodeURIComponent(title)}`];
        params.push(`artist_name=${encodeURIComponent(artist)}`);
        params.push(`album_name=${encodeURIComponent(album)}`);
        params.push(`duration=${encodeURIComponent(roundedDuration)}`);

        const url = `https://lrclib.net/api/get?${params.join("&")}`;

        Requests.get(url, text => {
            if (reqId !== root.currentRequestId)
                return;

            const result = JSON.parse(text);
            if (!_parseLrcLibLyrics(result)) {
                fetchLrcLibCandidates(title, artist, reqId, true);
                return;
            }

            fetchedCandidatesModel.clear();
            _appendLrcLibCandidate(result, 0, title, artist);
            _loadLrcLibResult(result, 0);
        }, _err => {
            if (reqId !== root.currentRequestId)
                return;
            fetchLrcLibCandidates(title, artist, reqId, true);
        }, root._lrclibHeaders);
    }

    // NetEase

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
                    provider: "NetEase",
                    id: s.id,
                    trackId: s.id,
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
                if (!_loadLyricsText(res.lrc.lyric))
                    loading = false;
            }
        });
    }

    function selectCandidate(songId) {
        let meta = getMetadata();
        if (!meta)
            return;

        const candidate = songId >= 0 && songId < fetchedCandidatesModel.count ? fetchedCandidatesModel.get(songId) : null;
        const isLrcLibCandidate = candidate && candidate.provider === "LRCLIB";

        if (isLrcLibCandidate) {
            const lyricsText = _parseLrcLibLyrics(candidate);
            if (!lyricsText)
                return;

            root.backend = "LRCLIB";
            root.currentSongId = candidate.trackId ?? songId;
            _loadLrcLibResult(candidate, songId);
            return;
        }

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

    onPreferredBackendChanged: {
        if (GlobalConfig.services.lyricsBackend !== preferredBackend) {
            GlobalConfig.services.lyricsBackend = preferredBackend;
        }
    }

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

    // If no local lyrics were loaded within the interval, fall back to online lyrics
    Timer {
        id: fallbackTimer

        interval: 200
        onTriggered: {
            if (lyricsModel.count === 0) {
                root.backend = "LRCLIB";
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
                root.loadedLocalFile = path;
                updateModel(parsed);
                loading = false;
            } else if (root.preferredBackend === "Local") {
                // Local mode only - fail immediately
                root.backend = "LRCLIB";
                fallbackToOnline();
            }
            // In Auto mode, let the Process onExited handle fallback
        }
    }

    Connections {
        function onActiveChanged() {
            root.player = Players.active;
            loadLyrics();
        }

        target: Players
    }

    Connections {
        function onMetadataChanged() {
            loadLyrics();
        }

        target: root.player
        ignoreUnknownSignals: true
    }

    Process {
        id: saveLyricsMap

        command: ["sh", "-c", `mkdir -p "${root.lyricsDir}" && echo '${JSON.stringify(root.lyricsMap)}' > "${root.lyricsMapFile}"`]
    }

    Process {
        id: findLyricsInSubdirs

        property int requestId: -1
        property bool foundFile: false

        stdout: SplitParser {
            onRead: data => {
                if (findLyricsInSubdirs.requestId === root.currentRequestId) {
                    const foundPath = data.trim();
                    if (foundPath && foundPath.length > 0) {
                        findLyricsInSubdirs.foundFile = true;
                        fallbackTimer.stop();
                        root.loadedLocalFile = foundPath;
                        lrcFile.path = "";
                        lrcFile.path = foundPath;
                    }
                }
            }
        }

        onExited: (exitCode, exitStatus) => { // qmllint disable signal-handler-parameters
            if (requestId === root.currentRequestId && !foundFile && root.preferredBackend === "Auto") {
                if (lyricsModel.count === 0) {
                    fallbackTimer.restart();
                }
            }
            foundFile = false;
        }
    }
}
