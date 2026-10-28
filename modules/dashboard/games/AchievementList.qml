import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.images
import qs.services

StyledRect {
    id: root

    required property string title
    required property string icon
    required property string emptyText
    required property var model
    property color accent: Colours.palette.m3primary
    property bool showRarity
    property int maxItems: 4

    function tierColours(pct: real): var {
        if (pct < 0)
            return [Colours.palette.m3surfaceContainerHighest, Colours.palette.m3onSurfaceVariant];
        if (pct <= 5)
            return [Colours.palette.m3tertiaryContainer, Colours.palette.m3onTertiaryContainer];
        if (pct <= 15)
            return [Colours.palette.m3primaryContainer, Colours.palette.m3onPrimaryContainer];
        if (pct <= 40)
            return [Colours.palette.m3secondaryContainer, Colours.palette.m3onSecondaryContainer];
        return [Colours.palette.m3surfaceContainerHighest, Colours.palette.m3onSurfaceVariant];
    }

    function tierIcon(pct: real): string {
        if (pct <= 5)
            return "diamond";
        if (pct <= 15)
            return "auto_awesome";
        if (pct <= 40)
            return "star";
        return "groups";
    }

    implicitHeight: col.implicitHeight + Tokens.padding.large * 2
    radius: Tokens.rounding.extraLarge
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: col

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.small

        RowLayout {
            Layout.bottomMargin: Tokens.spacing.extraSmall
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: root.icon
                color: root.accent
                fill: 1
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                text: root.title
                font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
                color: Colours.palette.m3onSurface
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 4 * 44 + 3 * Tokens.spacing.small
            visible: root.model.length === 0
            spacing: Tokens.spacing.small

            Item {
                Layout.fillHeight: true
            }

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: Steam.focusLoading ? "hourglass_empty" : "trophy"
                color: Colours.palette.m3outline
                fontStyle: Tokens.font.icon.large
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.emptyText
                font: Tokens.font.body.small
                color: Colours.palette.m3outline
            }

            Item {
                Layout.fillHeight: true
            }
        }

        Repeater {
            model: root.model.slice(0, root.maxItems)

            RowLayout {
                id: row

                required property var modelData
                required property int index

                readonly property var tier: root.tierColours(modelData.globalPercent ?? -1)

                Layout.fillWidth: true
                implicitHeight: 44
                spacing: Tokens.spacing.medium

                opacity: 0
                Component.onCompleted: opacity = 1

                Behavior on opacity {
                    SequentialAnimation {
                        PauseAnimation {
                            duration: row.index * 50
                        }
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }

                ClipRect {
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 44
                    radius: Tokens.rounding.medium
                    color: Colours.palette.m3surfaceContainerHighest

                    FadeImage {
                        anchors.fill: parent
                        source: row.modelData.icon || ""
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: row.modelData.name
                        font: Tokens.font.body.builders.small.weight(Font.DemiBold).build()
                        color: Colours.palette.m3onSurface
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: text.length > 0
                        text: row.modelData.description
                        font: Tokens.font.label.small
                        color: Colours.palette.m3onSurfaceVariant
                        elide: Text.ElideRight
                    }
                }

                StyledRect {
                    visible: root.showRarity && row.modelData.globalPercent >= 0
                    implicitWidth: badgeRow.implicitWidth + Tokens.padding.small * 2
                    implicitHeight: 24
                    radius: Tokens.rounding.full
                    color: row.tier[0]

                    RowLayout {
                        id: badgeRow

                        anchors.centerIn: parent
                        spacing: 2

                        MaterialIcon {
                            text: root.tierIcon(row.modelData.globalPercent)
                            fill: 1
                            color: row.tier[1]
                            fontStyle: Tokens.font.icon.small
                        }

                        StyledText {
                            text: Tr.tr("%1%").arg(row.modelData.globalPercent < 10 ? row.modelData.globalPercent.toFixed(1) : Math.round(row.modelData.globalPercent))
                            font: Tokens.font.label.builders.small.weight(Font.DemiBold).build()
                            color: row.tier[1]
                        }
                    }
                }

                StyledText {
                    visible: !root.showRarity
                    text: Steam.formatUnlockAge(row.modelData.unlockTime)
                    font: Tokens.font.label.small
                    color: Colours.palette.m3outline
                }
            }
        }
    }
}
