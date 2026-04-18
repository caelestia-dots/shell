pragma ComponentBehavior: Bound

import ".."
import "../components"
import "."
import QtQuick
import Quickshell.Bluetooth
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls

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
