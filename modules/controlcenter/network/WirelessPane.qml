pragma ComponentBehavior: Bound

import ".."
import "../components"
import qs.components
import qs.components.containers
import qs.config
import Quickshell.Widgets
import QtQuick

SplitPaneWithDetails {
    id: root

    required property Session session

    anchors.fill: parent

    activeItem: session.network.active
    paneIdGenerator: function(item) {
        return item ? (item.ssid || item.bssid || "") : "";
    }

    leftContent: Component {
        WirelessList {
            session: root.session
        }
    }

    rightDetailsComponent: Component {
        WirelessDetails {
            session: root.session
        }
    }

    rightSettingsComponent: Component {
        StyledFlickable {
            flickableDirection: Flickable.VerticalFlick
            contentHeight: settingsInner.height
            clip: true

            WirelessSettings {
                id: settingsInner

                anchors.left: parent.left
                anchors.right: parent.right
                session: root.session
            }
        }
    }

    overlayComponent: Component {
        WirelessPasswordDialog {
            anchors.fill: parent
            session: root.session
        }
    }
}
