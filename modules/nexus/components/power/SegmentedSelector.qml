pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    property string value: ""
    property var options: []

    signal selectionChanged(string newValue)

    implicitHeight: row.implicitHeight
    implicitWidth: row.implicitWidth

    Row {
        id: row

        anchors.fill: parent
        spacing: Math.floor(Tokens.spacing.small / 2)

        Repeater {
            model: root.options

            delegate: StyledRect {
                id: seg

                required property var modelData

                readonly property bool selected: root.value === modelData.value

                height: Tokens.font.size.normal + Tokens.padding.small * 2
                width: Math.max(label.implicitWidth + Tokens.padding.normal * 2, Tokens.font.size.large * 3)
                radius: Tokens.rounding.full
                color: seg.selected ? Colours.palette.m3primary : Colours.layer(Colours.palette.m3surfaceContainerHigh, 1)

                Behavior on color {
                    CAnim {}
                }

                StateLayer {
                    function onClicked(): void {
                        root.selectionChanged(seg.modelData.value);
                    }

                    radius: Tokens.rounding.full
                    color: seg.selected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                }

                StyledText {
                    id: label

                    anchors.centerIn: parent
                    text: seg.modelData.label
                    color: seg.selected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                    font.pointSize: Tokens.font.size.small
                    font.weight: seg.selected ? Font.Medium : Font.Normal

                    Behavior on color {
                        CAnim {}
                    }
                }
            }
        }
    }
}
