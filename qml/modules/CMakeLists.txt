qs_qml_module(caelestia-qml-modules
    URI Caelestia.Qml.Modules
    QML_FILES
        BatteryMonitor.qml
        IdleMonitors.qml
        Shortcuts.qml
    DEPENDENCIES
        QtQuick
        Quickshell
)

add_subdirectory(areapicker)
add_subdirectory(background)
add_subdirectory(bar)
add_subdirectory(controlcenter)
add_subdirectory(dashboard)
add_subdirectory(drawers)
add_subdirectory(launcher)
add_subdirectory(lock)
add_subdirectory(notifications)
add_subdirectory(osd)
add_subdirectory(session)
add_subdirectory(sidebar)
add_subdirectory(utilities)
add_subdirectory(windowinfo)
