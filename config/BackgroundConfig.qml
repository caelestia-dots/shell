import Quickshell.Io

JsonObject {
    property bool enabled: true
    property DesktopClock desktopClock: DesktopClock {}
    property Visualiser visualiser: Visualiser {}
    property Wallpaper wallpaper: Wallpaper {}

    component DesktopClock: JsonObject {
        property bool enabled: false
    }

    component Visualiser: JsonObject {
        property bool enabled: false
        property bool autoHide: true
        property bool blur: false
        property real rounding: 1
        property real spacing: 1
    }

    component Wallpaper: JsonObject {
        property bool muteAudio: true
        property real volume: 1.0
    }
}
