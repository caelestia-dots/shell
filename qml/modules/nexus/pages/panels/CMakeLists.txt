qs_qml_module(caelestia-qml-modules-nexus-pages-panels
    URI Caelestia.Qml.Modules.Nexus.Pages.Panels
    QML_FILES
        DashboardPanel.qml
        LauncherPanel.qml
        SidebarPanel.qml
        TaskbarPanel.qml
        UtilitiesPanel.qml
    DEPENDENCIES
        QtQuick
        QtQuick.Layouts
)

add_subdirectory(taskbar)
