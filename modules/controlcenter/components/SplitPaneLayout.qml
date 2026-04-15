pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.effects

RowLayout {
    id: root

    property Component leftContent: null
    property Component rightContent: null
    property real leftWidthRatio: 0.4
    property int leftMinimumWidth: 420
    property var leftLoaderProperties: ({})
    property var rightLoaderProperties: ({})
    property alias leftLoader: leftLoader
    property alias rightLoader: rightLoader

    spacing: 0

    Item {
        id: leftPane

        Layout.preferredWidth: Math.floor(parent.width * root.leftWidthRatio)
        Layout.minimumWidth: root.leftMinimumWidth
        Layout.fillHeight: true

        ClippingRectangle {
            id: leftClippingRect

            anchors.fill: parent
            anchors.margins: Tokens.padding.normal
            anchors.leftMargin: 0
            anchors.rightMargin: Tokens.padding.normal / 2

            radius: leftBorder.innerRadius
            color: "transparent"

            Loader {
                id: leftLoader

                anchors.fill: parent
                anchors.margins: Tokens.padding.large + Tokens.padding.normal
                anchors.leftMargin: Tokens.padding.large
                anchors.rightMargin: Tokens.padding.large + Tokens.padding.normal / 2

                asynchronous: true
                sourceComponent: root.leftContent

                Component.onCompleted: {
                    for (const key in root.leftLoaderProperties) {
                        leftLoader[key] = root.leftLoaderProperties[key];
                    }
                }
            }
        }

        InnerBorder {
            id: leftBorder

            leftThickness: 0
            rightThickness: Tokens.padding.normal / 2
        }
    }

    Item {
        id: rightPane

        Layout.fillWidth: true
        Layout.fillHeight: true

        ClippingRectangle {
            id: rightClippingRect

            anchors.fill: parent
            anchors.margins: Tokens.padding.normal
            anchors.leftMargin: 0
            anchors.rightMargin: Tokens.padding.normal / 2

            radius: rightBorder.innerRadius
            color: "transparent"

            Loader {
                id: rightLoader

                anchors.fill: parent
                anchors.margins: Tokens.padding.large * 2

                asynchronous: true
                sourceComponent: root.rightContent

                Component.onCompleted: {
                    for (const key in root.rightLoaderProperties) {
                        rightLoader[key] = root.rightLoaderProperties[key];
                    }
                }
            }
        }

        InnerBorder {
            id: rightBorder

            leftThickness: Tokens.padding.normal / 2
        }
    }
}
