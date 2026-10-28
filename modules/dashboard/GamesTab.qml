pragma ComponentBehavior: Bound

import "games"
import QtQuick
import QtQuick.Layouts
import M3Shapes
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.images
import qs.services

Item {
    id: root

    readonly property bool hasProfile: !!Steam.profile
    readonly property real achPercent: Steam.libraryAchievements?.percent ?? 0
    property bool steamShowsSessions

    implicitWidth: 840
    implicitHeight: layout.implicitHeight

    Component.onCompleted: {
        if (Steam.enabled && Steam.configured && !Steam.profile && !Steam.loading)
            Steam.reload();
    }

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Tokens.spacing.medium

        Loader {
            Layout.fillWidth: true
            active: !Steam.configured || (Steam.error.length > 0 && !root.hasProfile)
            visible: active
            sourceComponent: PlaceholderCard {
                icon: !Steam.configured ? "key" : "error"
                title: !Steam.configured ? Tr.tr("Configure Steam") : Tr.tr("Could not load Steam data")
                body: !Steam.configured ? Tr.tr("Add your API key and Steam ID in Nexus → Complements.") : Steam.error
            }
        }

        Loader {
            Layout.fillWidth: true
            Layout.preferredHeight: 320
            active: Steam.configured && !root.hasProfile && Steam.error.length === 0
            visible: active
            sourceComponent: Item {
                LoadingIndicator {
                    anchors.centerIn: parent
                }
            }
        }

        ProfileHeader {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.large
            Layout.rightMargin: Tokens.padding.small
            visible: root.hasProfile
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.hasProfile
            spacing: Tokens.spacing.medium

            StatCard {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                revealDelay: 0
                icon: "sports_esports"
                label: Tr.tr("Games")
                caption: Tr.tr("in your library")
                value: Steam.gameCount > 0 ? Steam.gameCount : -1
                shape: MaterialShape.Cookie9Sided
                accent: Colours.palette.m3primary
                shapeColour: Colours.palette.m3primaryContainer
                onShapeColour: Colours.palette.m3onPrimaryContainer

                RowLayout {
                    anchors.fill: parent
                    spacing: Tokens.spacing.extraSmall

                    Repeater {
                        model: Steam.topGamesByPlaytime.slice(0, 4)

                        ClipRect {
                            id: capsule

                            required property var modelData

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: Tokens.rounding.small
                            color: Colours.palette.m3surfaceContainerHighest

                            FadeImage {
                                anchors.fill: parent
                                source: capsule.modelData.capsuleUrl
                            }
                        }
                    }
                }
            }

            StatCard {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                revealDelay: 60
                icon: "schedule"
                label: Tr.tr("Hours")
                caption: Steam.recentPlaytimeMinutes > 0 ? Tr.tr("+%1 h in 2 weeks").arg(Steam.formatHoursCompact(Steam.recentPlaytimeMinutes)) : Tr.tr("played in total")
                value: Steam.totalPlaytimeMinutes > 0 ? Steam.totalPlaytimeMinutes / 60 : -1
                formatter: v => String(Math.round(v)).replace(/\B(?=(\d{3})+(?!\d))/g, Tr.locale.groupSeparator)
                shape: MaterialShape.Clover4Leaf
                accent: Colours.palette.m3secondary
                shapeColour: Colours.palette.m3secondaryContainer
                onShapeColour: Colours.palette.m3onSecondaryContainer

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Tokens.spacing.extraSmall

                    PlaytimeShareBar {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Steam.topGamesByPlaytime.length > 0 ? Tr.tr("Top: %1").arg(Steam.topGamesByPlaytime[0].name) : ""
                        font: Tokens.font.label.small
                        color: Colours.palette.m3onSurfaceVariant
                        elide: Text.ElideRight
                    }
                }
            }

            StatCard {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                revealDelay: 120
                icon: "emoji_events"
                label: Tr.tr("Achievements")
                caption: Steam.libraryAchievements ? Tr.tr("%1 / %2 unlocked").arg(Steam.libraryAchievements.unlocked).arg(Steam.libraryAchievements.total) : (Steam.libraryAchievementsLoading ? Tr.tr("Loading…") : "")
                value: Steam.libraryAchievements ? root.achPercent * 100 : -1
                formatter: v => `${Math.round(v)}%`
                shape: {
                    if (root.achPercent >= 0.66)
                        return MaterialShape.SoftBurst;
                    if (root.achPercent >= 0.33)
                        return MaterialShape.Sunny;
                    return MaterialShape.Cookie4Sided;
                }
                accent: Colours.palette.m3tertiary
                shapeColour: Colours.palette.m3tertiaryContainer
                onShapeColour: Colours.palette.m3onTertiaryContainer

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Tokens.spacing.extraSmall

                    StyledProgressBar {
                        Layout.fillWidth: true
                        implicitHeight: Tokens.padding.small
                        value: root.achPercent
                        fgColour: Colours.palette.m3tertiary
                        bgColour: Colours.palette.m3tertiaryContainer
                        indeterminate: Steam.libraryAchievementsLoading && !Steam.libraryAchievements
                    }

                    RowLayout {
                        spacing: 2

                        MaterialIcon {
                            text: "workspace_premium"
                            fill: 1
                            color: Colours.palette.m3tertiary
                            fontStyle: Tokens.font.icon.small
                        }

                        StyledText {
                            text: Tr.tr("%1 perfect games").arg(Steam.libraryAchievements?.perfect ?? 0)
                            font: Tokens.font.label.small
                            color: Colours.palette.m3onSurfaceVariant
                        }
                    }
                }
            }

            StatCard {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                revealDelay: 180
                icon: "group"
                label: Tr.tr("Friends")
                caption: Steam.friendsOnline >= 0 ? Tr.tr("online · %1 in game").arg(Math.max(0, Steam.friendsInGame)) : Tr.tr("Private")
                value: Steam.friendsOnline
                shape: MaterialShape.Pentagon
                accent: Colours.palette.m3primary
                shapeColour: Colours.palette.m3primaryContainer
                onShapeColour: Colours.palette.m3onPrimaryContainer

                FriendAvatars {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        FocusHero {
            Layout.fillWidth: true
            visible: root.hasProfile
        }

        RecentGamesRow {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.extraSmall
            visible: root.hasProfile && Steam.pickerGames.length > 1
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.hasProfile
            spacing: Tokens.spacing.medium

            SessionList {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                visible: Steam.focusNonSteam || root.steamShowsSessions
                sessions: Steam.focusNonSteam ? (Steam.focusGame?.sessions ?? []) : Steam.focusSessions
                tracked: !Steam.focusNonSteam || !!Steam.focusGame?.tracked
                switchIcon: Steam.focusNonSteam ? "" : "trophy"
                onSwitchRequested: root.steamShowsSessions = false
            }

            AchievementList {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                visible: !Steam.focusNonSteam && !root.steamShowsSessions
                emptyText: Steam.focusLoading ? Tr.tr("Loading…") : Steam.focusError || Tr.tr("No achievements unlocked yet")
                model: Steam.focusAchievements
                switchIcon: "history"
                onSwitchRequested: root.steamShowsSessions = true
            }

            ActivityCard {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                gameKey: Steam.focusAppId
                sessions: Steam.focusNonSteam ? (Steam.focusGame?.sessions ?? []) : Steam.focusSessions
                dailyMinutes: Steam.focusNonSteam ? ({}) : (Steam.dailyPlaytime[Steam.focusAppId] ?? {})
                markerTimes: Steam.focusNonSteam ? [] : Steam.focusUnlockTimes
            }
        }
    }

    component PlaytimeShareBar: Item {
        id: bar

        readonly property var games: Steam.topGamesByPlaytime.slice(0, 4)
        readonly property real total: Math.max(1, Steam.totalPlaytimeMinutes)
        readonly property real topSum: games.reduce((acc, g) => acc + g.playtimeForever, 0)
        readonly property real gap: 3
        readonly property real usable: Math.max(0, width - gap * games.length)

        implicitHeight: Tokens.padding.small
        clip: true

        Row {
            anchors.fill: parent
            spacing: bar.gap

            Repeater {
                model: bar.games

                StyledRect {
                    required property var modelData
                    required property int index

                    implicitHeight: bar.height
                    implicitWidth: Math.max(bar.height, bar.usable * modelData.playtimeForever / bar.total)
                    radius: Tokens.rounding.full
                    color: Qt.alpha(Colours.palette.m3secondary, 1 - index * 0.2)

                    Behavior on implicitWidth {
                        Anim {
                            type: Anim.StandardLarge
                        }
                    }
                }
            }

            StyledRect {
                implicitHeight: bar.height
                visible: implicitWidth > bar.height
                implicitWidth: bar.usable * (bar.total - bar.topSum) / bar.total
                radius: Tokens.rounding.full
                color: Colours.palette.m3secondaryContainer
            }
        }
    }

    component FriendAvatars: Row {
        spacing: -8

        Repeater {
            model: Steam.friendsPreview.slice(0, 6)

            StyledRect {
                id: avatar

                required property var modelData

                implicitWidth: 30
                implicitHeight: 30
                radius: Tokens.rounding.full
                color: modelData.inGame ? Colours.palette.m3tertiary : Colours.palette.m3surfaceContainer

                ClipRect {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3surfaceContainerHighest

                    FadeImage {
                        anchors.fill: parent
                        source: avatar.modelData.avatarUrl
                    }
                }
            }
        }

        StyledRect {
            visible: Steam.friendsOnline > 6
            implicitWidth: 30
            implicitHeight: 30
            radius: Tokens.rounding.full
            color: Colours.palette.m3primaryContainer

            StyledText {
                anchors.centerIn: parent
                text: `+${Steam.friendsOnline - 6}`
                font: Tokens.font.label.builders.small.weight(Font.DemiBold).build()
                color: Colours.palette.m3onPrimaryContainer
            }
        }

        MaterialIcon {
            visible: Steam.friendsOnline < 0
            text: "lock"
            color: Colours.palette.m3outline
            fontStyle: Tokens.font.icon.medium
        }
    }
}
