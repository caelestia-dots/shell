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

    // Launcher state
    property string launcherText // Kept in sync with the launcher's search text
    property string launcherPrefill // Text to fill in the launcher with, applied (and cleared) once it's open

    // Dashboard state
    property int dashboardTab
    property date dashboardDate: new Date()
}
