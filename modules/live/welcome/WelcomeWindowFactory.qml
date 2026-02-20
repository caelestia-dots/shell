pragma Singleton

import QtQuick
import Quickshell
import qs.components

Singleton {
    id: root

    function create(parent: Item, props: var): void {
        welcomeWindowWrapper.createObject(parent ?? dummy, props);
    }

    QtObject {
        id: dummy
    }

    Component {
        id: welcomeWindowWrapper

        FloatingWindow {
            id: win

            implicitWidth: 1000
            implicitHeight: 600

            minimumSize: Qt.size(900, 250)

            color: "transparent"

            title: qsTr("Welcome to Caelestia")

            WelcomeWindow {
                id: welcomeWindow

                anchors.fill: parent

                function close(): void {
                    win.destroy();
                }
            }

            Behavior on color {
                CAnim {}
            }
        }
    }
}