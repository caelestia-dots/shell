import "."
import qs.services
import Quickshell
import QtQuick

Item {
    id: root

    readonly property var windows: Quickshell.screens.map(screen => windowComponent.createObject(root, { screen: screen }))

    Component {
        id: windowComponent

        ConfigEditorWindow {}
    }

    Connections {
        target: ConfigEditor

        function onOpen(): void {
            for (const window of windows) {
                window.visible = true;
            }
        }

        function onClose(): void {
            for (const window of windows) {
                window.visible = false;
            }
        }
    }
}
