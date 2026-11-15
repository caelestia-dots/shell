import Quickshell

PersistentProperties {
    required property ShellScreen modelData

    // Drawer visibilities
    property bool bar
    property bool osd
    property bool session
    property bool launcher
    property bool dashboard
    property bool utilities
    property bool sidebar

    // Launcher state: current search text, and text to fill in the next time it opens
    property string launcherText
    property string launcherPrefill

    // Dashboard state
    property int dashboardTab
    property date dashboardDate: new Date()
}
