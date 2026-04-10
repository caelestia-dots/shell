qs_qml_module(caelestia-qml-modules-bar-popouts
    URI Caelestia.Qml.Modules.Bar.Popouts
    QML_FILES
        ActiveWindow.qml
        Audio.qml
        Battery.qml
        Bluetooth.qml
        ClipWrapper.qml
        Content.qml
        LockStatus.qml
        Network.qml
        PopoutState.qml
        TrayMenu.qml
        WirelessPassword.qml
        Wrapper.qml
    DEPENDENCIES
        QtQuick
        QtQuick.Layouts
        Quickshell
        Quickshell.Services.SystemTray
)

add_subdirectory(kblayout)
