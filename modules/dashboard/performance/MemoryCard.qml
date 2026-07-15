import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    readonly property color accent: Colours.palette.m3tertiary

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.medium

    implicitWidth: layout.implicitWidth + Tokens.padding.extraLargeIncreased * 2
    implicitHeight: layout.implicitHeight + Tokens.padding.large * 2

    ServiceRef {
        service: Memory
    }

    ColumnLayout {
        id: layout

        anchors.centerIn: parent
        spacing: Tokens.spacing.extraSmall

        RowLayout {
            Layout.leftMargin: -Tokens.padding.extraSmall
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "memory_alt"
                fill: 1
                color: root.accent
                fontStyle: Tokens.font.icon.builders.medium.weight(Font.DemiBold).build() // DemiBold to fix fill issues
            }

            StyledText {
                text: qsTr("Memory")
                font: Tokens.font.title.medium
            }
        }

        CircularProgress {
            Layout.topMargin: Tokens.spacing.large
            Layout.alignment: Qt.AlignHCenter
            implicitSize: usageColumn.implicitHeight + thickness + Tokens.padding.largeIncreased * 2
            startAngle: -225
            sweepAngle: 270

            fgColour: root.accent
            value: Memory.percentage

            Behavior on clampedVal {
                Anim {}
            }

            ColumnLayout {
                id: usageColumn

                anchors.centerIn: parent
                anchors.verticalCenterOffset: Tokens.padding.extraSmall
                spacing: 0

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Math.round(Memory.percentage * 100) + "%"
                    font: Tokens.font.title.builders.large.width(90).build()
                    color: root.accent
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Used")
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: {
                const fmt = UsageFmt.formatKib(Memory.used, Memory.total);
                return `${+fmt.value.toFixed(1)} / ${+fmt.total.toFixed(1)} ${fmt.unit}`;
            }
            font: Tokens.font.body.medium
        }
    }
}
