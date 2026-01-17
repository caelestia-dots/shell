import Quickshell.Io

JsonObject {
    property bool enabled: true
    property DesktopClock desktopClock: DesktopClock {}
    property Visualiser visualiser: Visualiser {}

    component DesktopClock: JsonObject {
        property bool enabled: false
        property real scale: 1.0
        property string position: "bottom-right"
        property bool invertColors: false
        property DesktopClockBackground background: DesktopClockBackground {}
        property DesktopClockShadow shadow: DesktopClockShadow {}
    }

    component DesktopClockBackground: JsonObject {
        property bool enabled: false
        property real opacity: 0.7
        property bool blur: true
    }

    component DesktopClockShadow: JsonObject {
        property bool enabled: true
        property real opacity: 0.7
        property real blur: 0.4
    }

    component Visualiser: JsonObject {
        property bool enabled: false
        property bool autoHide: true
        property bool blur: false
        property real rounding: 1
        property real spacing: 1
    }
}
