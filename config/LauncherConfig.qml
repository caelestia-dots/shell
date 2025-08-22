import Quickshell.Io

JsonObject {
    property bool enabled: true
    property int maxShown: 8
    property int maxWallpapers: 9 // Warning: even numbers look bad
    property string actionPrefix: ">"
    property bool enableDangerousActions: false // Allow actions that can cause losing data, like shutdown, reboot and logout
    property int dragThreshold: 50
    property bool vimKeybinds: false
    property UseFuzzy useFuzzy: UseFuzzy {}
    property Sizes sizes: Sizes {}
    property AppQueryWeights appQueryWeights: AppQueryWeights {}

    component UseFuzzy: JsonObject {
        property bool apps: true
        property bool actions: false
        property bool schemes: false
        property bool variants: false
        property bool wallpapers: false
    }

    component Sizes: JsonObject {
        property int itemWidth: 600
        property int itemHeight: 57
        property int wallpaperWidth: 280
        property int wallpaperHeight: 200
    }

    component AppQueryWeights: JsonObject {
        property real name: 2
        property real comment: 1
        property real genericName: 0 // Zero or less = desconsidered query
        property real categories: 0
        property real keywords: 0

    }
}
