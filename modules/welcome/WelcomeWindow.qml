pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    function create(parent: Item, props: var): void {
        welcomeWrapper.createObject(parent ?? dummy, props);
    }

    QtObject {
        id: dummy
    }

    Component {
        id: welcomeWrapper

        FloatingWindow {
            id: win

            implicitWidth: 1000
            implicitHeight: 600

            color: "transparent"

            title: qsTr("Welcome to Caelestia")

            Welcome {
                id: welcome

                anchors.fill: parent

                function close(): void {
                    win.destroy();
                }
            }
        }
    }
}