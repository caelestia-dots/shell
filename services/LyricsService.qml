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
    readonly property string lyricsDir: Paths.absolutePath(Config.paths.lyricsDir)

    // The data source for the UI
    readonly property alias model: lyricsModel
    ListModel { id: lyricsModel }


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
                    console.log("Not found on LrcLib")
                    fetchNetEase(title, artist)
                }
                loading = false
            }
        }
        xhr.send()
    }

    function fetchNetEase(title, artist) {
        loading = true;
        const searchQuery = encodeURIComponent(title + " " + artist);
        const searchUrl = `https://music.163.com/api/search/get/web?type=1&s=${searchQuery}&limit=1`;

        const headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Referer": "https://music.163.com/"
        };
        // NetEase works very differently from LrcLib
        // Search for Song ID
        let xhrSearch = new XMLHttpRequest();
        xhrSearch.open("GET", searchUrl);
        Object.keys(headers).forEach(key => xhrSearch.setRequestHeader(key, headers[key]));

        xhrSearch.onreadystatechange = () => {
            if (xhrSearch.readyState === XMLHttpRequest.DONE) {
                if (xhrSearch.status === 200) {
                    try {
                        let searchRes = JSON.parse(xhrSearch.responseText);
                        let songId = searchRes.result?.songs?.[0]?.id;

                        if (songId) {
                            // Get Lyrics for that ID
                            let xhrLrc = new XMLHttpRequest();
                            xhrLrc.open("GET", `https://music.163.com/api/song/media?id=${songId}`);
                            Object.keys(headers).forEach(key => xhrLrc.setRequestHeader(key, headers[key]));

                            xhrLrc.onreadystatechange = () => {
                                if (xhrLrc.readyState === XMLHttpRequest.DONE && xhrLrc.status === 200) {
                                    try {
                                        let lrcRes = JSON.parse(xhrLrc.responseText);
                                        if (lrcRes.lyric) {
                                            let parsed = Lrc.parseLrc(lrcRes.lyric);
                                            lyricsModel.clear();
                                            for (let line of parsed) {
                                                lyricsModel.append({ time: line.time, text: line.text });
                                            }
                                            root.updatePosition();
                                        }
                                    } catch (e) { console.log("NetEase Parse Error:", e) }
                                    loading = false;
                                }
                            };
                            xhrLrc.send();
                        } else { loading = false; }
                    } catch (e) { loading = false; }
                } else { loading = false; console.log(xhrSearch.status)}
            }
        };
        xhrSearch.send();
    }

    // Update currentIndex based on player position
    function updatePosition() {
        if (!player || !lyricsModel.count) return
            let arr = []
            for (let i = 0; i < lyricsModel.count; i++) arr.push(lyricsModel.get(i))
                root.currentIndex = Lrc.getCurrentLine(arr, player.position)
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
