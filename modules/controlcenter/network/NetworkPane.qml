pragma ComponentBehavior: Bound

import qs.components.effects
import qs.components.containers
import qs.config
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    anchors.fill: parent
    spacing: 0

    // Left panel - Network List
    Item {
        Layout.preferredWidth: Math.floor(parent.width * 0.4)
        Layout.minimumWidth: 420
        Layout.fillHeight: true

        StyledFlickable {
            anchors.fill: parent
            anchors.margins: Appearance.padding.large + Appearance.padding.normal
            anchors.leftMargin: Appearance.padding.large
            anchors.rightMargin: Appearance.padding.large + Appearance.padding.normal / 2

            flickableDirection: Flickable.VerticalFlick
            contentHeight: networkList.height

            NetworkList {
                id: networkList

                anchors.left: parent.left
                anchors.right: parent.right
            }
        }

        InnerBorder {
            leftThickness: 0
            rightThickness: Appearance.padding.normal / 2
        }
    }

    // Right panel - Settings
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        ClippingRectangle {
            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            anchors.leftMargin: 0
            anchors.rightMargin: Appearance.padding.normal / 2

            radius: rightBorder.innerRadius
            color: "transparent"

            StyledFlickable {
                anchors.fill: parent
                anchors.margins: Appearance.padding.large * 2

                flickableDirection: Flickable.VerticalFlick
                contentHeight: settings.height

                NetworkSettings {
                    id: settings

                    anchors.left: parent.left
                    anchors.right: parent.right
                }
            }
        }

        InnerBorder {
            id: rightBorder

            leftThickness: Appearance.padding.normal / 2
        }
    }
}
