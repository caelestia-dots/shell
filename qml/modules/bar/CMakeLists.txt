qs_qml_module(caelestia-qml-modules-bar
    URI Caelestia.Qml.Modules.Bar
    QML_FILES
        Bar.qml
        BarWrapper.qml
    DEPENDENCIES
        QtQuick
        QtQuick.Layouts
        Quickshell
)

add_subdirectory(components)
add_subdirectory(popouts)
