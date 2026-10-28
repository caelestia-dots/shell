import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.images
import qs.services

RowLayout {
    id: root

    property int maxGames: 5

    spacing: Tokens.spacing.small

    Repeater {
        model: {
            const games = Steam.recentGames.slice(0, root.maxGames);
            for (const g of Steam.topGamesByPlaytime) {
                if (games.length >= root.maxGames)
                    break;
                if (!games.some(r => r.appId === g.appId))
                    games.push(g);
            }
            return games;
        }

        Item {
            id: card

            required property var modelData
            required property int index

            readonly property bool selected: modelData.appId === Steam.focusAppId
            readonly property bool playing: modelData.appId === (Steam.profile?.gameId ?? "")

            Layout.fillWidth: true
            Layout.preferredWidth: 1
            implicitHeight: 84

            scale: selected ? 1 : hover.pressed ? 0.95 : 0.97
            opacity: 0

            Component.onCompleted: opacity = Qt.binding(() => selected || hover.containsMouse ? 1 : 0.8)

            Behavior on scale {
                Anim {
                    type: Anim.FastSpatial
                }
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            StyledRect {
                anchors.fill: parent
                radius: Tokens.rounding.large
                color: card.selected ? Colours.palette.m3primary : "transparent"
            }

            ClipRect {
                property real inset: card.selected ? 3 : 0

                anchors.fill: parent
                anchors.margins: inset
                radius: Tokens.rounding.large - inset

                Behavior on inset {
                    Anim {
                        type: Anim.FastSpatial
                    }
                }
                color: Colours.palette.m3surfaceContainerHighest

                FadeImage {
                    anchors.fill: parent
                    source: Steam.headerUrl(card.modelData.appId)
                }
            }

            StyledRect {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: Tokens.padding.small
                visible: card.playing
                implicitWidth: 22
                implicitHeight: 22
                radius: Tokens.rounding.full
                color: Colours.palette.m3tertiaryContainer

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "play_arrow"
                    fill: 1
                    fontStyle: Tokens.font.icon.small
                    color: Colours.palette.m3onTertiaryContainer
                }
            }

            StateLayer {
                id: hover

                radius: Tokens.rounding.large
                color: "white"
                onClicked: Steam.setFocusApp(card.modelData.appId, card.modelData.name)
            }
        }
    }
}
