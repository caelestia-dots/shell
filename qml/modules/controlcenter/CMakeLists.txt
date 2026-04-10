qs_qml_module(caelestia-qml-modules-controlcenter
    URI Caelestia.Qml.Modules.Controlcenter
    QML_FILES
        ControlCenter.qml
        NavRail.qml
        Panes.qml
        Session.qml
        WindowTitle.qml
    QML_SINGLETONS
        PaneRegistry.qml
        WindowFactory.qml
    DEPENDENCIES
        QtQuick
        QtQuick.Layouts
        Quickshell
        Quickshell.Widgets
)

add_subdirectory(appearance)
add_subdirectory(audio)
add_subdirectory(bluetooth)
add_subdirectory(components)
add_subdirectory(dashboard)
add_subdirectory(launcher)
add_subdirectory(network)
add_subdirectory(notifications)
add_subdirectory(state)
add_subdirectory(taskbar)
