pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import M3Shapes
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    required property string icon
    required property string label
    property string caption
    property color accent: Colours.palette.m3primary
    property color shapeColour: Colours.palette.m3primaryContainer
    property color onShapeColour: Colours.palette.m3onPrimaryContainer
    property int shape: MaterialShape.Cookie9Sided

    property real value: -1
    property var formatter: v => String(Math.round(v))
    property real displayValue: Math.max(0, value)
    property int revealDelay

    default property alias stripData: strip.data

    readonly property real shapeSize: 72

    implicitHeight: layout.implicitHeight + Tokens.padding.large * 2
    radius: Tokens.rounding.extraLarge
    color: Colours.tPalette.m3surfaceContainer

    opacity: 0
    scale: 0.94
    Component.onCompleted: revealTimer.start()

    Timer {
        id: revealTimer

        interval: root.revealDelay
        onTriggered: {
            root.opacity = 1;
            root.scale = 1;
        }
    }

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    Behavior on scale {
        Anim {
            type: Anim.DefaultSpatial
        }
    }

    Behavior on displayValue {
        Anim {
            type: Anim.StandardExtraLarge
        }
    }

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.padding.large
        anchors.topMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        spacing: Tokens.spacing.small

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: Tokens.spacing.small

                StyledRect {
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: Tokens.rounding.full
                    color: Qt.alpha(root.accent, 0.14)

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: root.icon
                        color: root.accent
                        fontStyle: Tokens.font.icon.small
                        fill: 1
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.label
                    font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
                    color: Colours.palette.m3onSurface
                    elide: Text.ElideRight
                }
            }

            MaterialShape {
                implicitSize: root.shapeSize
                shape: root.shape
                color: root.shapeColour

                Behavior on color {
                    CAnim {}
                }

                StyledText {
                    anchors.centerIn: parent
                    width: parent.width - Tokens.padding.medium * 2
                    horizontalAlignment: Text.AlignHCenter
                    text: root.value < 0 ? "–" : root.formatter(root.displayValue)
                    color: root.onShapeColour
                    font: Tokens.font.headline.builders.small.width(50).weight(Font.DemiBold).build()
                    fontSizeMode: Text.HorizontalFit
                    minimumPointSize: 10
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.rightMargin: Tokens.padding.extraSmall
            text: root.caption || " "
            font: Tokens.font.label.small
            color: Colours.palette.m3onSurfaceVariant
            elide: Text.ElideRight
        }

        Item {
            id: strip

            Layout.fillWidth: true
            Layout.rightMargin: Tokens.padding.extraSmall
            implicitHeight: 30
        }
    }
}
