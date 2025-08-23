pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    
    property string currentThumbnail: ""
    property string currentVideoTitle: ""
    
    signal thumbnailReady(string url)
    
    Process {
        id: ytDlpProcess
        
        running: false
        
        stdout: StdioCollector {
            onTextChanged: {
                // Process output as it comes in, looking for thumbnail URLs
                const lines = text.split('\n')
                for (const line of lines) {
                    const trimmedLine = line.trim()
                    if (trimmedLine.startsWith("https://i.ytimg.com/") || 
                        trimmedLine.startsWith("https://img.youtube.com/")) {
                        // Convert WebP URLs to JPEG for better compatibility
                        let thumbnailUrl = trimmedLine
                        if (thumbnailUrl.includes("vi_webp/")) {
                            thumbnailUrl = thumbnailUrl.replace("vi_webp/", "vi/").replace(".webp", ".jpg")
                        }
                        root.currentThumbnail = thumbnailUrl
                        root.thumbnailReady(thumbnailUrl)
                        console.log(`[YouTubeThumbnailProvider] Thumbnail found: ${thumbnailUrl}`)
                        // Stop the process once we have the URL - we don't need the download
                        ytDlpProcess.running = false
                        return
                    }
                }
            }
            
            onStreamFinished: {
                // Fallback in case onTextChanged didn't catch it
                let thumbnailUrl = text.trim()
                if (thumbnailUrl && (thumbnailUrl.startsWith("https://i.ytimg.com/") || 
                                   thumbnailUrl.startsWith("https://img.youtube.com/"))) {
                    if (!root.currentThumbnail) {
                        // Convert WebP URLs to JPEG for better compatibility
                        if (thumbnailUrl.includes("vi_webp/")) {
                            thumbnailUrl = thumbnailUrl.replace("vi_webp/", "vi/").replace(".webp", ".jpg")
                        }
                        root.currentThumbnail = thumbnailUrl
                        root.thumbnailReady(thumbnailUrl)
                        console.log(`[YouTubeThumbnailProvider] Thumbnail found: ${thumbnailUrl}`)
                    }
                } else {
                    console.log(`[YouTubeThumbnailProvider] No valid thumbnail: "${thumbnailUrl}"`)
                }
            }
        }
        
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim()) {
                    // Ignore the download errors - we only need the thumbnail URL
                    const lines = text.trim().split('\n')
                    const warningLines = lines.filter(line => line.includes('WARNING'))
                    if (warningLines.length > 0) {
                        console.log(`[YouTubeThumbnailProvider] ${warningLines[0]}`)
                    }
                }
            }
        }
    }
    
    function searchForThumbnail(title) {
        const cleanTitle = title.replace(/^\(\d+\)\s*/, "").replace(/\s*-\s*YouTube$/, "").trim()
        
        if (cleanTitle === currentVideoTitle) {
            // Already have result for this title
            return
        }
        
        // Stop any running search to start a new one immediately
        if (ytDlpProcess.running) {
            ytDlpProcess.running = false
        }
        
        if (!cleanTitle) return
        
        currentVideoTitle = cleanTitle
        currentThumbnail = ""
        
        const searchQuery = `ytsearch:"${cleanTitle}"`
        ytDlpProcess.command = [
            "yt-dlp", 
            "--get-thumbnail",
            "--no-playlist",
            "--quiet",
            searchQuery
        ]
        ytDlpProcess.running = true
        
        console.log(`[YouTubeThumbnailProvider] Searching for: ${cleanTitle}`)
    }
    
    function getThumbnailForTitle(title) {
        const cleanTitle = title.replace(/^\(\d+\)\s*/, "").replace(/\s*-\s*YouTube$/, "").trim()
        
        if (cleanTitle !== currentVideoTitle) {
            searchForThumbnail(title)
            return ""
        }
        
        return currentThumbnail
    }
}