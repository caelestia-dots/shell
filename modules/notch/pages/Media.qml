pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.hallownest
import qs.services
import qs.modules.notch

NotchPage {
    id: root

    readonly property MprisPlayer player: NotchMedia.player
    readonly property real artSize: 82
    readonly property bool playing: player?.isPlaying ?? false
    readonly property bool multiPlayer: Players.list.length > 1
    readonly property string artistLine: {
        if (!player)
            return "";
        const artist = player.trackArtist || Tr.tr("Unknown artist");
        const album = player.trackAlbum || "";
        return album && album !== player.trackTitle ? `${artist} · ${album}` : artist;
    }

    function nextPlayer(): void {
        if (Players.list.length < 2)
            return;
        const i = Players.list.indexOf(player);
        Players.manualActive = Players.list[(i + 1) % Players.list.length];
    }

    implicitWidth: player ? 460 : 360
    implicitHeight: player ? playerCard.implicitHeight : emptyCard.implicitHeight

    Component.onCompleted: NotchMedia.positionUsers++
    Component.onDestruction: NotchMedia.positionUsers--

    HkCard {
        id: emptyCard

        anchors.left: parent.left
        anchors.right: parent.right
        visible: !root.player
        implicitHeight: empty.implicitHeight + Tokens.padding.extraLarge * 2
        ornate: true

        ColumnLayout {
            id: empty

            anchors.centerIn: parent
            spacing: Tokens.spacing.small

            Mask {
                Layout.alignment: Qt.AlignHCenter
                size: 42
                filled: false
                colour: Hallownest.steel
                opacity: 0.45
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Tr.tr("Nothing playing")
                color: Hallownest.subtext
                font.family: Hallownest.serif
                font.pointSize: 11.5
            }
        }
    }

    HkCard {
        id: playerCard

        anchors.left: parent.left
        anchors.right: parent.right
        visible: !!root.player
        implicitHeight: content.implicitHeight + Tokens.padding.large * 2
        ornate: true
        clip: true

        // Subtle blurred album-art atmospheric wash inside the obsidian card
        Item {
            anchors.fill: parent
            visible: art.status === Image.Ready && root.visible
            opacity: root.playing ? 0.16 : 0.09
            layer.enabled: visible
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1
                blurMax: 48
            }

            Behavior on opacity {
                Anim {
                    type: Anim.SlowEffects
                }
            }

            Image {
                anchors.fill: parent
                source: art.source
                sourceSize.width: 96
                sourceSize.height: 96
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        // Fade the wash smoothly into the card surface so text & controls stay crisp
        Rectangle {
            anchors.fill: parent
            radius: playerCard.radius
            visible: art.status === Image.Ready
            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop {
                    position: 0
                    color: Qt.alpha(Hallownest.card, 0.35)
                }
                GradientStop {
                    position: 0.55
                    color: Qt.alpha(Hallownest.card, 0.78)
                }
                GradientStop {
                    position: 1
                    color: Qt.alpha(Hallownest.card, 0.94)
                }
            }
        }

        ColumnLayout {
            id: content

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.small + 2

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium + 2

                Item {
                    implicitWidth: root.artSize
                    implicitHeight: root.artSize

                    // Breathing ambient halo behind the cover art while playing
                    Item {
                        id: artHalo

                        property real breath

                        anchors.centerIn: parent
                        width: root.artSize + 24
                        height: root.artSize + 24
                        opacity: root.playing ? (0.26 + breath * 0.14) : 0.1
                        visible: root.visible
                        layer.enabled: visible
                        layer.effect: MultiEffect {
                            blurEnabled: true
                            blur: 1
                            blurMax: 28
                        }

                        SequentialAnimation on breath {
                            running: root.playing && root.visible
                            loops: Animation.Infinite

                            NumberAnimation {
                                to: 1
                                duration: 2400
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                to: 0
                                duration: 2400
                                easing.type: Easing.InOutSine
                            }
                        }

                        Behavior on opacity {
                            Anim {
                                type: Anim.SlowEffects
                            }
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: root.artSize
                            height: root.artSize
                            radius: 12
                            color: Hallownest.soul
                            visible: art.status !== Image.Ready
                        }

                        Image {
                            anchors.centerIn: parent
                            width: root.artSize
                            height: root.artSize
                            source: art.source
                            sourceSize.width: 64
                            sourceSize.height: 64
                            fillMode: Image.PreserveAspectCrop
                            visible: art.status === Image.Ready
                            asynchronous: true
                        }
                    }

                    ClippingRectangle {
                        anchors.fill: parent
                        radius: 11
                        color: Hallownest.void_
                        border.width: 1
                        border.color: Qt.alpha(Hallownest.soul, 0.18)

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "music_note"
                            color: Hallownest.steel
                            fontStyle: Tokens.font.icon.large
                            visible: art.status !== Image.Ready
                        }

                        Image {
                            id: art

                            anchors.fill: parent
                            source: Players.getArtUrl(root.player)
                            sourceSize.width: root.artSize * 2
                            sourceSize.height: root.artSize * 2
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 3

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small

                        Rectangle {
                            implicitWidth: sourceRow.implicitWidth + (root.multiPlayer ? 14 : 0)
                            implicitHeight: 20
                            radius: 10
                            color: root.multiPlayer && sourceArea.containsMouse ? Hallownest.raise(Hallownest.card, 1.55) : "transparent"

                            Behavior on color {
                                CAnim {}
                            }

                            Row {
                                id: sourceRow

                                anchors.centerIn: parent
                                spacing: 5

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 4
                                    height: 4
                                    rotation: 45
                                    color: root.playing ? Hallownest.lifeblood : Hallownest.faint
                                }

                                StyledText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Players.getIdentity(root.player) || Tr.tr("Media")
                                    color: root.multiPlayer && sourceArea.containsMouse ? Hallownest.soul : Hallownest.subtext
                                    font.pointSize: 7.5
                                    font.weight: Font.DemiBold
                                    font.capitalization: Font.AllUppercase
                                    font.letterSpacing: 0.8
                                }

                                MaterialIcon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: root.multiPlayer
                                    text: "swap_horiz"
                                    color: sourceArea.containsMouse ? Hallownest.soul : Hallownest.faint
                                    fontStyle: Tokens.font.icon.small
                                }
                            }

                            MouseArea {
                                id: sourceArea

                                anchors.fill: parent
                                enabled: root.multiPlayer
                                hoverEnabled: true
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: root.nextPlayer()
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        MiniEqualizer {
                            visible: root.playing
                            running: root.playing && root.visible
                            colour: Hallownest.soul
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: root.player?.trackTitle || Tr.tr("Unknown title")
                        color: Hallownest.soul
                        font.pointSize: 12.5
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                        animate: true
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: root.artistLine
                        color: Hallownest.subtext
                        font.pointSize: 9.5
                        elide: Text.ElideRight
                        animate: true
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 2
                spacing: Tokens.spacing.small + 2

                StyledText {
                    text: NotchMedia.lengthStr(seek.dragging ? seek.dragValue * (root.player?.length ?? 0) : root.player?.position ?? -1)
                    color: Hallownest.subtext
                    font.family: Hallownest.mono
                    font.pointSize: 8
                }

                HkSlider {
                    id: seek

                    Layout.fillWidth: true
                    Layout.rightMargin: 6
                    colour: Hallownest.soul
                    enabled: (root.player?.canSeek ?? false) && !NotchMedia.hasUnknownLength
                    value: root.player ? root.player.position / (root.player.length || 1) : 0

                    onMoved: value => {
                        if (root.player?.canSeek)
                            root.player.position = value * root.player.length;
                    }
                }

                StyledText {
                    text: NotchMedia.hasUnknownLength ? "--:--" : `-${NotchMedia.lengthStr(Math.max(0, (root.player?.length ?? 0) - (root.player?.position ?? 0)))}`
                    color: Hallownest.subtext
                    font.family: Hallownest.mono
                    font.pointSize: 8
                }
            }

            HkDivider {
                Layout.fillWidth: true
                opacity: 0.5
            }

            Item {
                Layout.fillWidth: true
                implicitHeight: controls.implicitHeight

                // Left: Ghost lyrics toggle
                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: lyricsRow.implicitWidth + 18
                    implicitHeight: 28
                    radius: 14
                    color: NotchSettings.lyrics ? Qt.alpha(Hallownest.soul, lyricsArea.containsMouse ? 0.16 : 0.1) : lyricsArea.containsMouse ? Hallownest.raise(Hallownest.card, 1.55) : "transparent"

                    Behavior on color {
                        CAnim {}
                    }

                    Row {
                        id: lyricsRow

                        anchors.centerIn: parent
                        spacing: 5

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "lyrics"
                            color: NotchSettings.lyrics || lyricsArea.containsMouse ? Hallownest.soul : Hallownest.steel
                            fontStyle: Tokens.font.icon.small
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Tr.tr("Lyrics")
                            color: NotchSettings.lyrics || lyricsArea.containsMouse ? Hallownest.soul : Hallownest.subtext
                            font.pointSize: 8.5
                            font.weight: Font.Medium
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: NotchSettings.lyrics
                            width: 4
                            height: 4
                            rotation: 45
                            color: Hallownest.soul
                        }
                    }

                    MouseArea {
                        id: lyricsArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotchSettings.set("lyrics", !NotchSettings.lyrics)
                    }
                }

                // Center: Tactile transport controls
                Row {
                    id: controls

                    anchors.centerIn: parent
                    spacing: Tokens.spacing.medium

                    ControlButton {
                        icon: "skip_previous"
                        enabled: root.player?.canGoPrevious ?? false
                        onClicked: root.player?.previous()
                    }

                    ControlButton {
                        icon: root.playing ? "pause" : "play_arrow"
                        primary: true
                        enabled: root.player?.canTogglePlaying ?? false
                        onClicked: root.player?.togglePlaying()
                    }

                    ControlButton {
                        icon: "skip_next"
                        enabled: root.player?.canGoNext ?? false
                        onClicked: root.player?.next()
                    }
                }

                // Right: Inline volume slider expanding smoothly on hover
                Item {
                    id: volume

                    readonly property bool open: volumeHover.hovered || volumeSlider.dragging

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 28 + (open ? 82 + Tokens.spacing.small : 0)
                    implicitHeight: 28
                    clip: true

                    Behavior on implicitWidth {
                        Anim {
                            type: Anim.FastSpatial
                        }
                    }

                    HoverHandler {
                        id: volumeHover
                    }

                    HkSlider {
                        id: volumeSlider

                        anchors.right: volumeBtn.left
                        anchors.rightMargin: Tokens.spacing.small + 4
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 74
                        colour: Audio.muted ? Hallownest.steel : Hallownest.lifeblood
                        opacity: volume.open ? 1 : 0
                        value: Audio.volume

                        onMoved: value => Audio.setVolume(value)

                        Behavior on opacity {
                            Anim {
                                type: Anim.FastEffects
                            }
                        }
                    }

                    Rectangle {
                        id: volumeBtn

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 28
                        radius: 14
                        color: volArea.containsMouse ? Hallownest.raise(Hallownest.card, 1.55) : "transparent"

                        Behavior on color {
                            CAnim {}
                        }

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: Audio.muted ? "volume_off" : Audio.volume > 0.5 ? "volume_up" : "volume_down"
                            color: Audio.muted ? Hallownest.grimm : volArea.containsMouse ? Hallownest.soul : Hallownest.steel
                            fontStyle: Tokens.font.icon.small
                        }

                        MouseArea {
                            id: volArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (Audio.sink?.audio)
                                    Audio.sink.audio.muted = !Audio.muted;
                            }
                        }
                    }
                }
            }
        }
    }

    component ControlButton: Rectangle {
        id: button

        required property string icon
        property bool primary

        signal clicked

        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: primary ? 40 : 32
        implicitHeight: implicitWidth
        radius: implicitWidth / 2
        color: primary ? Hallownest.soul : buttonArea.containsMouse ? Hallownest.raise(Hallownest.card, 1.65) : "transparent"
        opacity: enabled ? 1 : 0.32
        scale: buttonArea.pressed ? 0.9 : 1
        layer.enabled: primary && root.playing
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Hallownest.soul
            shadowOpacity: 0.35
            shadowBlur: 0.7
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
            blurMax: 16
        }

        Behavior on scale {
            Anim {
                type: Anim.FastSpatial
            }
        }

        Behavior on color {
            CAnim {}
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: button.icon
            color: button.primary ? Hallownest.void_ : buttonArea.containsMouse ? Hallownest.soul : Hallownest.steel
            fontStyle: button.primary ? Tokens.font.icon.large : Tokens.font.icon.medium
            fill: 1
            animate: true
        }

        MouseArea {
            id: buttonArea

            anchors.fill: parent
            enabled: button.enabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }
}
