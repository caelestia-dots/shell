pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// Mirrors WallItem.qml's structure (square preview + label + StateLayer
// click ripple) so the Colours grid matches the existing Wallpapers grid's
// look and animations -- just a 3-way primary/secondary/tertiary colour
// swatch instead of an Image.
Item {
    id: root

    required property string name
    required property string flavour
    required property var colours
    property bool current: false

    signal clicked

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.small

        StyledClippingRect {
            id: swatch

            Layout.fillWidth: true
            implicitHeight: width
            radius: Tokens.rounding.largeIncreased
            color: `#${root.colours.surface}`
            border.width: root.current ? 3 : 0
            border.color: Colours.palette.m3primary

            Row {
                anchors.fill: parent

                Rectangle {
                    width: parent.width / 3
                    height: parent.height
                    color: `#${root.colours.primary}`
                }

                Rectangle {
                    width: parent.width / 3
                    height: parent.height
                    color: `#${root.colours.secondary}`
                }

                Rectangle {
                    width: parent.width / 3
                    height: parent.height
                    color: `#${root.colours.tertiary}`
                }
            }
        }

        Row {
            Layout.bottomMargin: Tokens.padding.small
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing.extraSmall

            StyledText {
                text: root.flavour === "default" ? root.name : `${root.name} ${root.flavour}`
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.builders.small.weight(Font.Medium).build()
                elide: Text.ElideRight
            }

            Loader {
                active: root.current
                asynchronous: true
                anchors.verticalCenter: parent.verticalCenter

                sourceComponent: MaterialIcon {
                    text: "check"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.large
                }
            }
        }
    }

    StateLayer {
        onClicked: root.clicked()
    }
}
