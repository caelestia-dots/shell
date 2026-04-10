pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Bluetooth
import Quickshell.Widgets
import qs.components
import qs.components.containers
import qs.components.controls
import qs.config
import qs.modules.controlcenter
import qs.modules.controlcenter.bluetooth
import qs.modules.controlcenter.components

SplitPaneWithDetails {
    id: root

    required property Session session

    anchors.fill: parent

    activeItem: session.bt.active
    paneIdGenerator: function (item) {
        return item ? (item.address || "") : "";
    }

    leftContent: Component {
        StyledFlickable {
            id: leftFlickable

            flickableDirection: Flickable.VerticalFlick
            contentHeight: deviceList.height

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: leftFlickable
            }

            DeviceList {
                id: deviceList

                anchors.left: parent.left
                anchors.right: parent.right
                session: root.session
            }
        }
    }

    rightDetailsComponent: Component {
        Details {
            session: root.session
        }
    }

    rightSettingsComponent: Component {
        StyledFlickable {
            id: settingsFlickable

            flickableDirection: Flickable.VerticalFlick
            contentHeight: settingsInner.height

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: settingsFlickable
            }

            Settings {
                id: settingsInner

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                session: root.session
            }
        }
    }
}
