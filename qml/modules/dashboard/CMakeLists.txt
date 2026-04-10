qs_qml_module(caelestia-qml-modules-dashboard
    URI Caelestia.Qml.Modules.Dashboard
    QML_FILES
        Content.qml
        Dash.qml
        LyricMenu.qml
        LyricsView.qml
        Media.qml
        MediaWrapper.qml
        Performance.qml
        Tabs.qml
        WeatherTab.qml
        Wrapper.qml
    DEPENDENCIES
        QtQuick
        QtQuick.Layouts
        Quickshell
)

add_subdirectory(dash)
