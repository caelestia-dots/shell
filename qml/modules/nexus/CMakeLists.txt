qs_qml_module(caelestia-qml-modules-nexus
    URI Caelestia.Qml.Modules.Nexus
    QML_FILES
        NavPane.qml
        Nexus.qml
        NexusState.qml
        Pages.qml
    QML_SINGLETONS
        PageCompRegistry.qml
        PageRegistry.qml
        WindowFactory.qml
    DEPENDENCIES
        QtQuick
        QtQuick.Layouts
        Quickshell
        Quickshell.Bluetooth
)

add_subdirectory(common)
add_subdirectory(navpane)
add_subdirectory(pages)
