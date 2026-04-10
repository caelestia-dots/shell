qs_qml_module(caelestia-qml-modules-utilities
    URI Caelestia.Qml.Modules.Utilities
    QML_FILES
        Background.qml
        Content.qml
        RecordingDeleteModal.qml
        Wrapper.qml
    DEPENDENCIES
        QtQuick
        QtQuick.Layouts
        Quickshell
)

add_subdirectory(cards)
add_subdirectory(toasts)
