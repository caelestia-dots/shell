pragma Singleton

import qs.config
import qs.utils
import Caelestia
import Quickshell
import QtQuick
import Quickshell.Io
import Quickshell.Services.Mpris
import "../utils/scripts/lrcparser.js" as Lrc

Singleton {
    id: root

    property var player: Players.active
    property int currentIndex: -1
    property bool loading: false
    property bool isManualSeeking: false
    readonly property string lyricsDir: Paths.absolutePath(Config.paths.lyricsDir)

    // The data source for the UI
    readonly property alias model: lyricsModel
    ListModel { id: lyricsModel }

    Timer {
        id: seekTimer
        interval: 500
        onTriggered: root.isManualSeeking = false
    }

    function getMetadata() {
        if (!player || !player.metadata) return null;
        let artist = player.metadata["xesam:artist"];
        let title = player.metadata["xesam:title"];
        if (Array.isArray(artist)) artist = artist.join(", ");
        return { artist: artist || "Unknown", title: title || "Unknown" };
    }

    function loadLyrics() {
        let meta = getMetadata();
        if (!meta) return;

        loading = true;
        lyricsModel.clear();
        currentIndex = -1;

        let filename = `${meta.artist} - ${meta.title}.lrc`;
        let fullPath = lyricsDir + "/" + filename;

        lrcFile.path = "";
        lrcFile.path = fullPath;

        // Fallback safety: If FileView doesn't trigger onLoaded (file missing),
        fallbackTimer.restart();
    }

    Timer {
        id: fallbackTimer
        interval: 200
        onTriggered: {
            if (lyricsModel.count === 0) fallbackToOnline();
        }
    }

    FileView {
        id: lrcFile
        onLoaded: {
            fallbackTimer.stop();
            let parsed = Lrc.parseLrc(text());
            if (parsed.length > 0) {
                updateModel(parsed);
                loading = false;
            } else {
                fallbackToOnline();
            }
        }
    }

    function fallbackToOnline() {
        let meta = getMetadata();
        if (!meta) return;
        fetchLRCLIB(meta.title, meta.artist);
    }

    function updateModel(parsedArray) {
        lyricsModel.clear();
        for (let line of parsedArray) {
            lyricsModel.append({ time: line.time, text: line.text });
        }
    }

    function fetchLRCLIB(title, artist) {
        let url = `https://lrclib.net/api/get?artist_name=${encodeURIComponent(artist)}&track_name=${encodeURIComponent(title)}`;
        let xhr = new XMLHttpRequest();
        xhr.open("GET", url);
        xhr.onreadystatechange = () => {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    let res = JSON.parse(xhr.responseText);
                    if (res.syncedLyrics) {
                        updateModel(Lrc.parseLrc(res.syncedLyrics));
                        loading = false;
                        return;
                    }
                }
                fetchNetEase(title, artist);
            }
        };
        xhr.send();
    }

    function fetchNetEase(title, artist) {
        const query = encodeURIComponent(title + " " + artist);
        const url = `https://music.163.com/api/search/get?s=${query}&type=1&limit=5`; // Get 5 results to verify

        let xhr = new XMLHttpRequest();
        xhr.open("GET", url);
        xhr.setRequestHeader("User-Agent", "Mozilla/5.0");
        xhr.onreadystatechange = () => {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                let res = JSON.parse(xhr.responseText);
                let songs = res.result?.songs || [];

                // Find a song where the artist matches
                let bestMatch = songs.find(s => {
                    let inputArtist = String(artist || "").toLowerCase();
                    let sArtist = String(s.artists?.[0]?.name || "").toLowerCase();

                    return inputArtist.includes(sArtist) || sArtist.includes(inputArtist);
                });

                if (bestMatch) {
                    fetchNetEaseLyrics(bestMatch.id);
                } else {
                    loading = false;
                    console.log("NetEase: No reliable match found.");
                }
            } else if (xhr.readyState === XMLHttpRequest.DONE) {
                loading = false;
            }
        };
        xhr.send();
    }

    function fetchNetEaseLyrics(id) {
        let xhr = new XMLHttpRequest();
        xhr.open("GET", `https://music.163.com/api/song/lyric?id=${id}&lv=1&kv=1&tv=-1`);
        xhr.onreadystatechange = () => {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                let res = JSON.parse(xhr.responseText);
                if (res.lrc?.lyric) {
                    updateModel(Lrc.parseLrc(res.lrc.lyric));
                }
                loading = false;
            }
        };
        xhr.send();
    }

    function updatePosition() {
        if (isManualSeeking || !player || lyricsModel.count === 0) return;

        let pos = player.position;
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
            player.position = time + 0.01; // for the rounding
        }

        seekTimer.restart();
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
        function onMetadataChanged() { loadLyrics(); }
    }
}
