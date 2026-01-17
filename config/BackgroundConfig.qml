import Quickshell.Io

JsonObject {
    property bool enabled: true
    property DesktopClock desktopClock: DesktopClock {}
    property Visualiser visualiser: Visualiser {}

    component DesktopClock: JsonObject {
        property bool enabled: false
        property real scale: 1.0
        property string position: "bottom-right"

        property JsonObject shadow: JsonObject {
            property bool enabled: true
            property real opacity: 0.6
            property real blur: 0.4
        }
    }

    component Visualiser: JsonObject {
        property bool enabled: false
        property bool autoHide: true
        property bool blur: false
        property real rounding: 1
        property real spacing: 1
    }
}
