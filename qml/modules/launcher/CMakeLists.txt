qs_qml_module(caelestia-qml-modules-launcher
    URI Caelestia.Qml.Modules.Launcher
    QML_FILES
        AppList.qml
        Content.qml
        ContentList.qml
        WallpaperList.qml
        Wrapper.qml
    DEPENDENCIES
        QtQuick
        QtQuick.Layouts
        Quickshell
)

add_subdirectory(items)
add_subdirectory(services)
