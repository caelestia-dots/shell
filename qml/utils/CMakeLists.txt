qs_qml_module(caelestia-qml-utils
    URI Caelestia.Qml.Utils
    QML_FILES
        Searcher.qml
        scripts/fzf.js
        scripts/fuzzysort.js
    QML_SINGLETONS
        Icons.qml
        Images.qml
        NetworkConnection.qml
        Paths.qml
        Strings.qml
        SysInfo.qml
    DEPENDENCIES
        QtQuick
        Quickshell
        Quickshell.Io
)
