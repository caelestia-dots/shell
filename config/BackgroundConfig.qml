import Quickshell.Io

JsonObject {
    property bool enabled: false
    property DesktopClock desktopClock: DesktopClock {}

    component DesktopClock: JsonObject {
        property bool enabled: false
    }
}
