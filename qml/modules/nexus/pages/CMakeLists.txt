qs_qml_module(caelestia-qml-modules-nexus-pages
    URI Caelestia.Qml.Modules.Nexus.Pages
    QML_FILES
        AboutPage.qml
        AppsPage.qml
        AudioPage.qml
        BluetoothPage.qml
        LanguageAndRegion.qml
        NetworkPage.qml
        PanelsPage.qml
        ServicesPage.qml
        WallpaperAndStyle.qml
    DEPENDENCIES
        QtQuick
        QtQuick.Layouts
        Quickshell
        Quickshell.Bluetooth
        Quickshell.Io
        Quickshell.Widgets
)

add_subdirectory(apps)
add_subdirectory(audio)
add_subdirectory(bluetooth)
add_subdirectory(network)
add_subdirectory(panels)
add_subdirectory(services)
add_subdirectory(wallandstyle)
