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


    // Helper to get formatted filename
    function getLrcFilename() {
        if (!player || !player.metadata) return ""
            let artist = player.metadata["xesam:artist"]
            let title = player.metadata["xesam:title"]
            //console.log(player.metadata["xesam:asText"])
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

        // If FileView doesn't load a local file, try external
        Qt.callLater(() => {
            if (lyricsModel.count === 0) fetchLRCLIB()
                else loading = false
        })
    }

    function fetchLRCLIB() {
        let artist = player.metadata["xesam:artist"]
        let title  = player.metadata["xesam:title"]
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
                    }
                }
                loading = false
            }
        }
        xhr.send()
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
        function onMetadataChanged() { loadLyrics() }
    }
}
