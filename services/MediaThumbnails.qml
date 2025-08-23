pragma Singleton

import qs.components.misc
import qs.services
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    
    // Signal to notify when thumbnails are updated
    signal thumbnailUpdated()

    // Debug logging
    function debugLog(msg) {
        console.log("[MediaThumbnails]", msg)
    }
    
    // Connect to YouTubeThumbnailProvider's signal
    Connections {
        target: YouTubeThumbnailProvider
        function onThumbnailReady(url) {
            debugLog(`YouTube thumbnail ready: ${url}`)
            root.thumbnailUpdated()
        }
    }
    
    // Timer to frequently check browser window title for faster detection
    Timer {
        interval: 1000  // Check browser title every second
        running: true
        repeat: true
        onTriggered: {
            if (Players.active && isYouTubeContent(Players.active)) {
                getCurrentBrowserTitleForMonitoring()
            }
        }
    }
    
    function getCurrentBrowserTitleForMonitoring() {
        const proc = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["bash", "-c", "xdotool getactivewindow getwindowname 2>/dev/null || echo ''"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        const newTitle = text.trim()
                        if (newTitle && newTitle !== root.lastBrowserTitle && newTitle.includes('YouTube')) {
                            root.lastBrowserTitle = newTitle
                            root.debugLog(\`Browser title changed to: "\${newTitle}"\`)
                            // Trigger thumbnail update for active player
                            if (Players.active) {
                                root.thumbnailUpdated()
                            }
                        }
                    }
                }
            }
        `, root)
    }

    function getThumbnailUrl(player) {
        if (!player) return ""
        
        const identity = player.identity || ""
        const title = player.trackTitle || ""
        const artist = player.trackArtist || ""
        
        debugLog(`Player: ${identity}, Title: "${title}", Artist: "${artist}"`)
        
        // Try MPRIS trackArtUrl first, but check if it's stale
        const mprisThumbnail = player.trackArtUrl
        if (mprisThumbnail && mprisThumbnail.length > 0) {
            // Check if MPRIS data seems outdated (hasn't changed in a while)
            if (!isMprisDataStale(player)) {
                debugLog(`Using MPRIS thumbnail: ${mprisThumbnail}`)
                return mprisThumbnail
            } else {
                debugLog(`MPRIS data appears stale, trying fallback`)
            }
        }

        // For YouTube content, use the dedicated provider
        if (isYouTubeContent(player)) {
            const ytThumbnail = YouTubeThumbnailProvider.getThumbnailForTitle(title)
            if (ytThumbnail) {
                debugLog(`Using YouTube thumbnail: ${ytThumbnail}`)
                return ytThumbnail
            }
            // Provider will start search automatically
            return ""
        }

        debugLog("No thumbnail found")
        return ""
    }

    property var lastMprisUpdate: ({})
    property string lastBrowserTitle: ""
    
    function isMprisDataStale(player) {
        if (!player) return true
        
        const playerKey = `${player.identity}_${player.trackTitle}`
        const now = Date.now()
        
        if (!lastMprisUpdate[playerKey]) {
            lastMprisUpdate[playerKey] = now
            return false
        }
        
        // Consider data stale if it hasn't changed in 10 seconds
        const staleThreshold = 10000
        return (now - lastMprisUpdate[playerKey]) > staleThreshold
    }

    function isYouTubeContent(player) {
        if (!player) return false
        
        const title = player.trackTitle || ""
        const identity = player.identity || ""
        
        return (identity.toLowerCase().includes("mozilla") ||
                identity.toLowerCase().includes("firefox") ||
                identity.toLowerCase().includes("zen") ||
                identity.toLowerCase().includes("chrome")) &&
               title.toLowerCase().includes("youtube")
    }
}