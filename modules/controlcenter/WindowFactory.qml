pragma Singleton

import QtQuick
import Quickshell
import qs.components
import qs.services

Singleton {
    id: root

    function create(parent: Item, props: var): void {
        controlCenter.createObject(parent ?? dummy, props);
    }

    QtObject {
        id: dummy
    }

    Component {
        id: controlCenter

        FloatingWindow {
            id: win

            property alias active: cc.active
            property alias navExpanded: cc.navExpanded

            color: Colours.tPalette.m3surface

            onVisibleChanged: {
                if (!visible)
                    destroy();
            }

            implicitWidth: cc.implicitWidth
            implicitHeight: cc.implicitHeight

            minimumSize.width: implicitWidth
            minimumSize.height: implicitHeight
            maximumSize.width: implicitWidth
            maximumSize.height: implicitHeight

            title: qsTr("Caelestia Settings - %1").arg(cc.active.slice(0, 1).toUpperCase() + cc.active.slice(1))

            ControlCenter {
                id: cc

                anchors.fill: parent
                screen: win.screen
                onClose: win.destroy()
                floating: true
            }

            Behavior on color {
                CAnim {}
            }
        }
    }
}
