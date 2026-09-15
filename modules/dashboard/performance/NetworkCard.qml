import QtQuick
import QtQuick.Layouts
import Caelestia.Components
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Services
import qs.components
import qs.services

StyledRect {
    id: root

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.extraLarge

    implicitWidth: Tokens.sizes.dashboard.perfNetworkCardWidth
    implicitHeight: Tokens.sizes.dashboard.perfNetworkCardHeight

    ServiceRef {
        service: NetworkUsage
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        anchors.bottomMargin: Tokens.padding.medium
        spacing: 0

        RowLayout {
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "swap_vert"
                color: Colours.palette.m3primary
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                text: Tr.tr("Network")
                font: Tokens.font.title.medium
            }
        }

        // Sparkline graph
        Item {
            Layout.topMargin: Tokens.spacing.medium
            Layout.bottomMargin: Tokens.spacing.small
            Layout.fillWidth: true
            Layout.fillHeight: true

            SparklineItem {
                id: sparkline

                property real targetMax: 1024
                property real smoothMax: targetMax

                anchors.fill: parent
                line1: NetworkUsage.uploadBuffer // qmllint disable missing-type
                line1Color: Colours.palette.m3secondary
                line1FillAlpha: 0.15
                line2: NetworkUsage.downloadBuffer // qmllint disable missing-type
                line2Color: Colours.palette.m3tertiary
                line2FillAlpha: 0.2
                maxValue: smoothMax
                historyLength: NetworkUsage.historyLength

                Connections {
                    function onValuesChanged(): void {
                        sparkline.targetMax = Math.max(NetworkUsage.downloadBuffer.maximum, NetworkUsage.uploadBuffer.maximum, 1024);
                        slideAnim.restart();
                    }

                    target: NetworkUsage.downloadBuffer
                }

                NumberAnimation {
                    id: slideAnim

                    target: sparkline
                    property: "slideProgress"
                    from: 0
                    to: 1
                    easing.type: Easing.Linear
                    duration: GlobalConfig.dashboard.resourceUpdateInterval
                }

                Behavior on smoothMax {
                    Anim {}
                }
            }

            // "Collecting data" placeholder
            StyledText {
                anchors.centerIn: parent
                text: Tr.tr("Collecting data...")
                font: Tokens.font.body.small
                color: Colours.palette.m3outline
                visible: NetworkUsage.downloadBuffer.count < 2
            }
        }

        // Download row
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "download"
                color: Colours.palette.m3tertiary
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                text: Tr.trCtx("Download", "network throughput")
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                text: Units.formatBytes(NetworkUsage.downloadSpeed ?? 0, true)
                font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
                color: Colours.palette.m3tertiary
            }
        }

        // Upload row
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "upload"
                color: Colours.palette.m3secondary
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                text: Tr.trCtx("Upload", "network throughput")
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                text: Units.formatBytes(NetworkUsage.uploadSpeed ?? 0, true)
                font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
                color: Colours.palette.m3secondary
            }
        }

        // Session totals
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "history"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                text: Tr.trCtx("Total", "total network data transferred")
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                text: {
                    const downText = Units.formatBytes(NetworkUsage.downloadTotal ?? 0);
                    const upText = Units.formatBytes(NetworkUsage.uploadTotal ?? 0);
                    // TRANSLATORS: %1 = downloaded total, %2 = uploaded total
                    return Tr.tr("↓%1 ↑%2").arg(downText).arg(upText);
                }
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }
}
