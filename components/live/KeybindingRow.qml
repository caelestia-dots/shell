import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.effects
import qs.services
import qs.config

StyledRect {
    id: root

    required property string label
    required property var keys
    property string desc

    Layout.fillWidth: true
    implicitHeight: row.implicitHeight + Appearance.padding.large * 2
    radius: Appearance.rounding.normal
    color: Colours.palette.m3surfaceContainerLow

    Behavior on implicitHeight {
        Anim {}
    }

    RowLayout {
        id: row

        anchors.fill: parent
        anchors.margins: Appearance.padding.large
        spacing: Appearance.spacing.normal

        RowLayout {
            spacing: Appearance.spacing.small

            Repeater {
                model: root.keys

                delegate: RowLayout {
                    spacing: Appearance.spacing.small

                    KeyChip {
                        keyText: modelData
                    }

                    StyledText {
                        visible: index < root.keys.length - 1
                        text: "+"
                        font.pointSize: Appearance.font.size.small
                        color: Colours.palette.m3onSurfaceVariant
                        opacity: 0.5
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 2

            StyledText {
                Layout.alignment: Qt.AlignRight
                text: root.label
                font.pointSize: Appearance.font.size.normal
                color: Colours.palette.m3onSurface
            }

            StyledText {
                Layout.alignment: Qt.AlignRight
                text: root.desc
                visible: root.desc
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3onSurfaceVariant
                opacity: 0.7
            }
        }
    }
}
