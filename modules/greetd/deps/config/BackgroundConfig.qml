import Quickshell.Io

JsonObject {
    property bool enabled: true
    property DesktopClock desktopClock: DesktopClock {}

    component DesktopClock: JsonObject {
        property bool enabled: false
    }
}
