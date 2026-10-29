pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import M3Shapes
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.images
import qs.services

StyledRect {
    id: root

    readonly property var progress: Steam.focusProgress?.appId === Steam.focusAppId ? Steam.focusProgress : null
    readonly property real percent: progress?.percent ?? 0
    readonly property var game: Steam.focusGame
    readonly property bool recent: Steam.recentGames.some(g => g.appId === Steam.focusAppId)

    implicitHeight: 196
    radius: Tokens.rounding.extraLarge
    color: Colours.tPalette.m3surfaceContainer

    ClipRect {
        anchors.fill: parent
        radius: root.radius

        FadeImage {
            id: art

            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: height * 460 / 215
            source: root.game?.headerUrl || Steam.headerUrl(Steam.focusAppId)

            layer.enabled: true
            layer.effect: Mask {
                maskSource: artMask
            }
        }

        Rectangle {
            id: artMask

            layer.enabled: true
            visible: false
            width: art.width
            height: art.height
            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop {
                    position: 0
                    color: Qt.alpha("black", 0)
                }
                GradientStop {
                    position: 0.4
                    color: Qt.alpha("black", 1)
                }
            }
        }
    }

    ColumnLayout {
        id: info

        anchors.left: parent.left
        anchors.right: shapeColumn.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Tokens.padding.extraLarge
        anchors.rightMargin: Tokens.spacing.extraLarge
        spacing: Tokens.spacing.small

        opacity: Steam.focusLoading ? 0.5 : 1

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        StyledRect {
            implicitWidth: chipRow.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: chipRow.implicitHeight + Tokens.padding.extraSmall * 2
            radius: Tokens.rounding.full
            color: {
                if (Steam.focusPlayingNow)
                    return Colours.palette.m3tertiaryContainer;
                if (Steam.focusNonSteam)
                    return Colours.palette.m3primaryContainer;
                return Colours.palette.m3secondaryContainer;
            }

            RowLayout {
                id: chipRow

                anchors.centerIn: parent
                spacing: Tokens.spacing.extraSmall

                MaterialIcon {
                    text: {
                        if (Steam.focusPlayingNow)
                            return "play_circle";
                        if (Steam.focusNonSteam)
                            return "videogame_asset";
                        if (root.recent)
                            return "history";
                        return (root.game?.lastPlayed ?? 0) > 0 ? "event" : "library_books";
                    }
                    fill: 1
                    fontStyle: Tokens.font.icon.small
                    color: {
                        if (Steam.focusPlayingNow)
                            return Colours.palette.m3onTertiaryContainer;
                        if (Steam.focusNonSteam)
                            return Colours.palette.m3onPrimaryContainer;
                        return Colours.palette.m3onSecondaryContainer;
                    }
                }

                StyledText {
                    text: {
                        if (Steam.focusPlayingNow)
                            return Tr.tr("Playing now");
                        if (Steam.focusNonSteam)
                            return Tr.tr("Non-Steam");
                        if (root.recent)
                            return Tr.tr("Played recently");
                        if ((root.game?.lastPlayed ?? 0) > 0)
                            return Tr.tr("Last played %1").arg(Tr.formatDateTime(new Date(root.game.lastPlayed * 1000), "MMM yyyy"));
                        return Tr.tr("From your library");
                    }
                    font: Tokens.font.label.builders.small.weight(Font.DemiBold).build()
                    color: {
                        if (Steam.focusPlayingNow)
                            return Colours.palette.m3onTertiaryContainer;
                        if (Steam.focusNonSteam)
                            return Colours.palette.m3onPrimaryContainer;
                        return Colours.palette.m3onSecondaryContainer;
                    }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: Steam.focusGameName || Tr.tr("No recently played games")
            font: Tokens.font.body.builders.large.size(23).weight(Font.DemiBold).build()
            color: Colours.palette.m3onSurface
            elide: Text.ElideRight
            animate: true

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.alpha(Colours.palette.m3surface, 0.35)
                shadowBlur: 1
                shadowVerticalOffset: 0
                shadowHorizontalOffset: 0
            }
        }

        RowLayout {
            spacing: Tokens.spacing.large
            visible: !!root.game

            Meta {
                icon: "schedule"
                text: Steam.formatPlaytime(root.game?.playtimeForever ?? 0)
            }

            Meta {
                visible: (root.game?.playtime2Weeks ?? 0) > 0
                icon: "trending_up"
                text: Tr.tr("%1 in 2 weeks").arg(Steam.formatPlaytime(root.game?.playtime2Weeks ?? 0))
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.small
            spacing: Tokens.spacing.small

            StyledProgressBar {
                Layout.fillWidth: true
                Layout.maximumWidth: 360
                visible: !!root.progress
                implicitHeight: Tokens.padding.small
                value: root.percent
                fgColour: Colours.palette.m3primary
                wavy: root.percent > 0 && root.percent < 1
            }

            StyledText {
                text: {
                    if (root.progress)
                        return Tr.tr("%1 of %2 achievements").arg(root.progress.unlocked).arg(root.progress.total);
                    if (Steam.focusLoading)
                        return Tr.tr("Loading…");
                    return Steam.focusError;
                }
                font: Tokens.font.label.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }

    ColumnLayout {
        id: shapeColumn

        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.extraSmall
        opacity: root.progress ? 1 : 0
        scale: root.progress ? 1 : 0.6

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

        StyledRect {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: captionText.implicitWidth + Tokens.padding.small * 2
            implicitHeight: captionText.implicitHeight + Tokens.padding.extraSmall
            radius: Tokens.rounding.full
            color: Qt.alpha(Colours.palette.m3surfaceContainer, 0.8)

            StyledText {
                id: captionText

                anchors.centerIn: parent
                text: root.percent >= 1 ? Tr.tr("Perfect!") : Tr.tr("Achievements")
                font: Tokens.font.label.builders.small.weight(Font.DemiBold).build()
                color: Colours.palette.m3onSurface
            }
        }

        MaterialShape {
            Layout.alignment: Qt.AlignHCenter
            implicitSize: Tokens.sizes.dashboard.perfUsageShapeSize
            color: root.percent >= 1 ? Colours.palette.m3tertiaryContainer : Colours.palette.m3primaryContainer
            shape: {
                if (root.percent >= 1)
                    return MaterialShape.SoftBurst;
                if (root.percent >= 0.66)
                    return MaterialShape.Sunny;
                if (root.percent >= 0.33)
                    return MaterialShape.Cookie9Sided;
                return MaterialShape.Cookie4Sided;
            }

            Behavior on color {
                CAnim {}
            }

            StyledText {
                anchors.centerIn: parent
                text: root.percent >= 1 ? "" : `${Math.round(animPercent.value * 100)}%`
                color: Colours.palette.m3onPrimaryContainer
                font: Tokens.font.headline.builders.small.width(50).weight(Font.DemiBold).build()
            }

            MaterialIcon {
                anchors.centerIn: parent
                visible: root.percent >= 1
                text: "trophy"
                fill: 1
                color: Colours.palette.m3onTertiaryContainer
                fontStyle: Tokens.font.icon.extraLarge
            }
        }
    }

    QtObject {
        id: animPercent

        property real value: root.percent

        Behavior on value {
            Anim {
                type: Anim.StandardExtraLarge
            }
        }
    }

    component Meta: RowLayout {
        property alias icon: metaIcon.text
        property alias text: metaText.text

        spacing: Tokens.spacing.extraSmall

        MaterialIcon {
            id: metaIcon

            color: Colours.palette.m3primary
            fontStyle: Tokens.font.icon.small
        }

        StyledText {
            id: metaText

            font: Tokens.font.body.small
            color: Colours.palette.m3onSurfaceVariant
        }
    }
}
