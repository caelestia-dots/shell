qs_qml_module(caelestia-qml-modules-dashboard
    URI Caelestia.Qml.Modules.Dashboard
    QML_FILES
        Content.qml
        Dash.qml
        Media.qml
        Performance.qml
        Tabs.qml
        WeatherTab.qml
        Wrapper.qml
    DEPENDENCIES
        QtQuick
        QtQuick.Layouts
        QtQuick.Templates
        Quickshell
        Quickshell.Services.UPower
        Quickshell.Widgets
)

add_subdirectory(dash)
add_subdirectory(media)
add_subdirectory(performance)
