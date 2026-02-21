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

    // The only way i could get local lyrics working
    function getLrcFilename() {
        if (!player || !player.metadata) return ""
            let artist = player.metadata["xesam:artist"]
            let title = player.metadata["xesam:title"]
            if (Array.isArray(artist)) artist = artist.join(", ")
                return (artist && title) ? `${artist} - ${title}.lrc` : ""
    }

    FileView {
        id: lrcFile
        path: ""
        onLoaded: {
            let parsed = Lrc.parseLrc(text())
            lyricsModel.clear()
            for (let line of parsed) {
                lyricsModel.append({ time: line.time, text: line.text })
            }
        }
    }

    function loadLyrics() {
        let file = getLrcFilename()
        loading = true
        lyricsModel.clear()

        if (!file) {
            lrcFile.path = ""
            loading = false
            return
        }

        let fullPath = lyricsDir + "/" + file
        lrcFile.path = fullPath

        let artist = player.metadata["xesam:artist"]
        let title  = player.metadata["xesam:title"]

        // If no local lyrics, try online
        Qt.callLater(() => {
            if (lyricsModel.count === 0) {
                fetchLRCLIB(title, artist)
            } else {
                loading = false
            }
        })
    }

    //reusing my code from a different project

    function fetchLRCLIB(title, artist) {
        let url = `https://lrclib.net/api/get?artist_name=${encodeURIComponent(artist)}&track_name=${encodeURIComponent(title)}`

        let xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.onreadystatechange = () => {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    let response = JSON.parse(xhr.responseText)
                    if (response.syncedLyrics) {
                        let parsed = Lrc.parseLrc(response.syncedLyrics)
                        lyricsModel.clear()
                        for (let line of parsed) {
                            lyricsModel.append({ time: line.time, text: line.text })
                        }
                    } else {
                        console.log("Not found on LrcLib")
                        fetchNetEase(title, artist)
                    }
                } else {
                    console.log("Not found on LrcLib, Response: "+ xhr.status)
                    fetchNetEase(title, artist)
                }
                loading = false
            }
        }
        xhr.send()
    }

    function fetchNetEase(title, artist) {
        loading = true;
        console.log("Starting NetEase search for:", title, artist); // Debug log

        const searchQuery = encodeURIComponent(title + " " + artist);

        const searchUrl = `https://music.163.com/api/search/get?s=${searchQuery}&type=1&limit=1`;

        let xhrSearch = new XMLHttpRequest();
        xhrSearch.open("GET", searchUrl);

        xhrSearch.setRequestHeader("User-Agent", "Mozilla/5.0");

        xhrSearch.onreadystatechange = () => {
            if (xhrSearch.readyState === XMLHttpRequest.DONE) {
                console.log("NetEase Search Status:", xhrSearch.status);

                if (xhrSearch.status === 200) {
                    try {
                        let searchRes = JSON.parse(xhrSearch.responseText);
                        let songId = searchRes.result?.songs?.[0]?.id;

                        if (songId) {
                            console.log("Found NetEase Song ID:", songId);
                            fetchNetEaseLyrics(songId);
                        } else {
                            console.log("NetEase: No songs found in search results");
                            loading = false;
                        }
                    } catch (e) {
                        console.log("NetEase Search Parse Error:", e);
                        loading = false;
                    }
                } else {
                    loading = false;
                }
            }
        };

        xhrSearch.onerror = () => {
            console.log("NetEase Network Error occurred");
            loading = false;
        };

        xhrSearch.send();
    }

    function fetchNetEaseLyrics(songId) {
        let xhrLrc = new XMLHttpRequest();
        // This endpoint is generally more reliable for lyrics
        xhrLrc.open("GET", `https://music.163.com/api/song/lyric?id=${songId}&lv=1&kv=1&tv=-1`);

        xhrLrc.onreadystatechange = () => {
            if (xhrLrc.readyState === XMLHttpRequest.DONE && xhrLrc.status === 200) {
                try {
                    let lrcRes = JSON.parse(xhrLrc.responseText);

                    let lyricText = lrcRes.lrc?.lyric;

                    if (lyricText) {
                        let parsed = Lrc.parseLrc(lyricText);
                        lyricsModel.clear();
                        for (let line of parsed) {
                            lyricsModel.append({ time: line.time, text: line.text });
                        }
                        console.log("NetEase Lyrics Loaded successfully");
                        root.updatePosition();
                    } else {
                        console.log("NetEase: Song found but no lyrics available");
                    }
                } catch (e) {
                    console.log("NetEase Lyric Parse Error:", e);
                }
                loading = false;
            }
        };
        xhrLrc.send();
    }

    // Update currentIndex based on player position
    function updatePosition() {
        if (isManualSeeking || !player || !lyricsModel.count) return

        let arr = []
        for (let i = 0; i < lyricsModel.count; i++) arr.push(lyricsModel.get(i))
        root.currentIndex = Lrc.getCurrentLine(arr, player.position)
    }

    function jumpTo(index, time) {
        root.isManualSeeking = true;
        root.currentIndex = index;
        root.player.position = time + 0.1; //for the rounding

        seekTimer.restart(); // Start/Reset the lock timer
    }

    Connections {
        target: Players
        function onActiveChanged() { root.player = Players.active; loadLyrics() }
    }

    Connections {
        target: root.player
        function onMetadataChanged() {
            lyricsModel.clear()
            currentIndex=-1
            loadLyrics()

        }
    }
}
