qs_qml_module(caelestia-qml-modules-bar-components
    URI Caelestia.Qml.Modules.Bar.Components
    QML_FILES
        ActiveWindow.qml
        Clock.qml
        OsIcon.qml
        Power.qml
        StatusIcons.qml
        Tray.qml
        TrayItem.qml
    DEPENDENCIES
        QtQuick
        QtQuick.Layouts
        Quickshell
        Quickshell.Bluetooth
        Quickshell.Services.SystemTray
        Quickshell.Services.UPower
)

add_subdirectory(workspaces)
