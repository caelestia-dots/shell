import QtQuick 2.15
import Qt.labs.folderlistmodel 2.1
import caelestia.shell 1.0

Wallpaper {
    id: wallpaper
    anchors.fill: parent

    // Path to your wallpaper folder
    property string wallpaperFolder: "~/Pictures/Wallpapers"

    // Scan the folder for images
    FolderListModel {
        id: folderModel
        folder: wallpaperFolder
        nameFilters: ["*.jpg", "*.png", "*.jpeg"]
    }

    // Pick a random wallpaper on startup
    Component.onCompleted: {
        if (folderModel.count > 0) {
            var randomIndex = Math.floor(Math.random() * folderModel.count)
            wallpaper.source = folderModel.get(randomIndex).filePath
        }
    }

    // Optional: rotate every X minutes
    Timer {
        interval: 600000  // 10 minutes (600,000 ms)
        running: true
        repeat: true
        onTriggered: {
            if (folderModel.count > 0) {
                var randomIndex = Math.floor(Math.random() * folderModel.count)
                wallpaper.source = folderModel.get(randomIndex).filePath
            }
        }
    }
}

