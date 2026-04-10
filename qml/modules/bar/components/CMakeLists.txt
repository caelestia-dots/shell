qs_qml_module(caelestia-qml-modules-bar-components
    URI Caelestia.Qml.Modules.Bar.Components
    QML_FILES
        ActiveWindow.qml
        Clock.qml
        OsIcon.qml
        Power.qml
        Settings.qml
        SettingsIcon.qml
        StatusIcons.qml
        Tray.qml
        TrayItem.qml
    DEPENDENCIES
        QtQuick
        QtQuick.Layouts
        Quickshell
)

add_subdirectory(workspaces)
