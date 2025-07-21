import Quickshell.Io
import QtQuick

JsonObject {
    property bool enabled: true
    readonly property DesktopClock desktopClock: DesktopClock {}

    component DesktopClock: QtObject {
        readonly property bool enabled: true
    }
}
