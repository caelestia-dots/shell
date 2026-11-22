import Quickshell

PersistentProperties {
    required property ShellScreen modelData

    // Drawer visibilities
    property bool session
    property bool launcher
    property bool notch
    property bool sidebar
    property bool dockShown
    // Collapsed notch geometry, so the dock hand-off drops start and end on it
    property real notchWidth: 150
    property real notchHeight: 44
    property real notchRadius: 14

    property int notchPage
    property int mascotCalls
    // Animation for the next mascot call; empty = random
    property string mascotPick
    property date calendarDate: new Date()
}
