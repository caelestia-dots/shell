import Quickshell.Io

JsonObject {
    property int maxShown: 8
    property int maxWallpapers: 9 // Warning: even numbers look bad
    property string actionPrefix: ">"
    property bool enableDangerousActions: false // Allow actions that can cause losing data, like shutdown, reboot and logout
    property int dragThreshold: 50

    property JsonObject sizes: JsonObject {
        property int itemWidth: 600
        property int itemHeight: 57
        property int wallpaperWidth: 280
        property int wallpaperHeight: 200
    }
}
