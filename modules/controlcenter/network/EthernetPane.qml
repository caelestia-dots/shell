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

    activeItem: session.ethernet.active
    paneIdGenerator: function(item) {
        return item ? (item.interface || "") : "";
    }

    leftContent: Component {
        EthernetList {
            session: root.session
        }
    }

    rightDetailsComponent: Component {
        EthernetDetails {
            session: root.session
        }
    }

    rightSettingsComponent: Component {
        StyledFlickable {
            flickableDirection: Flickable.VerticalFlick
            contentHeight: settingsInner.height
            clip: true

            EthernetSettings {
                id: settingsInner

                anchors.left: parent.left
                anchors.right: parent.right
                session: root.session
            }
        }
    }
}
