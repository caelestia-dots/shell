pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.images
import qs.services

StyledRect {
    id: root

    required property var model
    property string emptyText
    property real rareThreshold: 15
    property real contentHeight: 4 * 44 + 3 * Tokens.spacing.small
    property string switchIcon

    signal switchRequested

    function isRare(pct: real): bool {
        return pct >= 0 && pct <= root.rareThreshold;
    }

    function tierColours(pct: real): var {
        if (pct <= 5)
            return [Colours.palette.m3tertiaryContainer, Colours.palette.m3onTertiaryContainer];
        return [Colours.palette.m3primaryContainer, Colours.palette.m3onPrimaryContainer];
    }

    function formatPercent(pct: real): string {
        return Tr.tr("%1%").arg(pct < 10 ? pct.toFixed(1) : Math.round(pct));
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
            Layout.fillWidth: true
            Layout.bottomMargin: Tokens.spacing.extraSmall
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "trophy"
                color: Colours.palette.m3primary
                fill: 1
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("Achievements")
                font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
                color: Colours.palette.m3onSurface
            }

            StyledRect {
                visible: !!Steam.focusProgress && Steam.focusProgress.total > 0
                implicitWidth: countText.implicitWidth + Tokens.padding.small * 2
                implicitHeight: 24
                radius: Tokens.rounding.full
                color: Colours.palette.m3secondaryContainer

                StyledText {
                    id: countText

                    anchors.centerIn: parent
                    text: Tr.tr("%1 / %2").arg(Steam.focusProgress?.unlocked ?? 0).arg(Steam.focusProgress?.total ?? 0)
                    font: Tokens.font.label.builders.small.weight(Font.DemiBold).build()
                    color: Colours.palette.m3onSecondaryContainer
                }
            }

            IconButton {
                visible: root.switchIcon.length > 0
                Layout.topMargin: -Tokens.padding.extraSmall
                Layout.bottomMargin: -Tokens.padding.extraSmall
                type: IconButton.Text
                icon: root.switchIcon
                onClicked: root.switchRequested()
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.contentHeight
            visible: root.model.length === 0

            Column {
                anchors.centerIn: parent
                spacing: Tokens.spacing.small

                MaterialIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Steam.focusLoading ? "hourglass_empty" : "trophy"
                    color: Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.large
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.emptyText
                    font: Tokens.font.body.small
                    color: Colours.palette.m3outline
                }
            }
        }

        VerticalFadeListView {
            id: list

            Layout.fillWidth: true
            Layout.preferredHeight: root.contentHeight
            Layout.rightMargin: -Tokens.spacing.small
            visible: root.model.length > 0
            clip: true
            spacing: Tokens.spacing.small
            fadeAmount: 0.08
            model: root.model

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: list
            }

            delegate: Item {
                id: row

                required property var modelData
                required property int index

                readonly property real pct: modelData.globalPercent ?? -1
                readonly property bool locked: !modelData.unlocked
                readonly property bool special: root.isRare(pct)
                readonly property bool rare: !locked && special
                readonly property real baseHeight: rare ? 44 : 32
                readonly property bool firstLocked: locked && (index === 0 || !!root.model[index - 1]?.unlocked)
                readonly property real headerHeight: firstLocked ? 28 + (index > 0 ? Tokens.spacing.small : 0) : 0

                width: list.width - Tokens.spacing.small
                implicitHeight: headerHeight + Math.max(baseHeight, textCol.implicitHeight)

                opacity: 0
                Component.onCompleted: opacity = 1

                Behavior on opacity {
                    SequentialAnimation {
                        PauseAnimation {
                            duration: Math.min(row.index, 8) * 40
                        }
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }

                RowLayout {
                    visible: row.firstLocked
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: content.top
                    anchors.bottomMargin: Tokens.spacing.small
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        text: "lock"
                        color: Colours.palette.m3outline
                        fontStyle: Tokens.font.icon.small
                    }

                    StyledText {
                        text: Tr.tr("Locked · %1").arg((Steam.focusProgress?.total ?? 0) - (Steam.focusProgress?.unlocked ?? 0))
                        font: Tokens.font.label.builders.medium.weight(Font.DemiBold).build()
                        color: Colours.palette.m3outline
                    }

                    StyledRect {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Colours.palette.m3outlineVariant
                    }
                }

                RowLayout {
                    id: content

                    anchors.fill: parent
                    anchors.topMargin: row.headerHeight
                    spacing: Tokens.spacing.medium

                    Item {
                        Layout.alignment: Qt.AlignTop
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: row.baseHeight

                        ClipRect {
                            anchors.centerIn: parent
                            implicitWidth: row.rare ? 44 : 30
                            implicitHeight: implicitWidth
                            radius: row.rare ? Tokens.rounding.medium : Tokens.rounding.small
                            color: Colours.palette.m3surfaceContainerHighest
                            opacity: row.rare ? 1 : row.locked ? 0.5 : 0.75

                            FadeImage {
                                anchors.fill: parent
                                source: row.modelData.icon || ""
                            }
                        }
                    }

                    ColumnLayout {
                        id: textCol

                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: row.modelData.name
                            font: row.rare ? Tokens.font.body.builders.small.weight(Font.DemiBold).build() : Tokens.font.body.small
                            color: row.rare ? Colours.palette.m3onSurface : row.locked ? Colours.palette.m3outline : Colours.palette.m3onSurfaceVariant
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            visible: text.length > 0
                            text: row.modelData.description ?? ""
                            font: Tokens.font.label.small
                            color: row.rare ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3outline
                            opacity: row.locked ? 0.8 : 1
                            wrapMode: Text.WordWrap
                        }
                    }

                    StyledRect {
                        Layout.alignment: Qt.AlignTop
                        Layout.topMargin: (row.baseHeight - implicitHeight) / 2
                        visible: row.special
                        opacity: row.locked ? 0.55 : 1
                        implicitWidth: badgeRow.implicitWidth + Tokens.padding.small * 2
                        implicitHeight: 24
                        radius: Tokens.rounding.full
                        color: root.tierColours(row.pct)[0]

                        RowLayout {
                            id: badgeRow

                            anchors.centerIn: parent
                            spacing: 2

                            MaterialIcon {
                                text: row.pct <= 5 ? "diamond" : "auto_awesome"
                                fill: 1
                                color: root.tierColours(row.pct)[1]
                                fontStyle: Tokens.font.icon.small
                            }

                            StyledText {
                                text: root.formatPercent(row.pct)
                                font: Tokens.font.label.builders.small.weight(Font.DemiBold).build()
                                color: root.tierColours(row.pct)[1]
                            }
                        }
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignTop
                        Layout.topMargin: (row.baseHeight - implicitHeight) / 2
                        Layout.rightMargin: Tokens.padding.small
                        visible: !row.special && (row.pct >= 0 || row.locked)
                        spacing: 2

                        MaterialIcon {
                            text: row.pct < 0 ? "lock" : "groups"
                            color: Colours.palette.m3outline
                            fontStyle: Tokens.font.icon.small
                        }

                        StyledText {
                            visible: row.pct >= 0
                            text: root.formatPercent(row.pct)
                            font: Tokens.font.label.small
                            color: Colours.palette.m3outline
                        }
                    }
                }
            }
        }
    }
}
