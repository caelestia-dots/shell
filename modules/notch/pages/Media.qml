pragma ComponentBehavior: Bound

import QtQuick
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
    readonly property real artSize: 56

    implicitWidth: player ? 400 : empty.implicitWidth
    implicitHeight: player ? content.implicitHeight : empty.implicitHeight

    Component.onCompleted: NotchMedia.positionUsers++
    Component.onDestruction: NotchMedia.positionUsers--

    ColumnLayout {
        id: empty

        anchors.centerIn: parent
        visible: !root.player
        spacing: Tokens.spacing.small

        Mask {
            Layout.alignment: Qt.AlignHCenter
            size: 52
            filled: false
            colour: Hallownest.steel
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Tr.tr("Nothing playing")
            color: Hallownest.subtext
            font.family: Hallownest.serif
            font.pointSize: 12
        }
    }

    ColumnLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        visible: !!root.player
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            ClippingRectangle {
                implicitWidth: root.artSize
                implicitHeight: root.artSize
                radius: 10
                color: Hallownest.card
                border.width: 1
                border.color: Hallownest.border

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

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    Layout.fillWidth: true
                    text: root.player?.trackTitle || Tr.tr("Unknown title")
                    color: Hallownest.soul
                    font.pointSize: 12
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                    animate: true
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.player?.trackArtist || Tr.tr("Unknown artist")
                    color: Hallownest.subtext
                    font.pointSize: 10
                    elide: Text.ElideRight
                    animate: true
                }
            }

            Item {
                id: volume

                readonly property bool open: volumeHover.hovered || volumeSlider.dragging

                Layout.alignment: Qt.AlignVCenter
                implicitWidth: volumeIcon.implicitWidth + (open ? 90 + Tokens.spacing.small : 0)
                implicitHeight: volumeIcon.implicitHeight
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

                    anchors.right: volumeIcon.left
                    anchors.rightMargin: Tokens.spacing.small + 6
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 80
                    colour: Hallownest.lifeblood
                    opacity: volume.open ? 1 : 0
                    value: Audio.volume

                    onMoved: value => Audio.setVolume(value)

                    Behavior on opacity {
                        Anim {
                            type: Anim.FastEffects
                        }
                    }
                }

                MaterialIcon {
                    id: volumeIcon

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: Audio.muted ? "volume_off" : Audio.volume > 0.5 ? "volume_up" : "volume_down"
                    color: Hallownest.text
                    fontStyle: Tokens.font.icon.medium

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (Audio.sink?.audio)
                                Audio.sink.audio.muted = !Audio.muted;
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

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

        Item {
            Layout.fillWidth: true
            implicitHeight: controls.implicitHeight

            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: lyricsRow.implicitWidth + Tokens.padding.large * 2
                implicitHeight: 26
                radius: 13
                color: NotchSettings.lyrics ? Qt.alpha(Hallownest.soul, 0.1) : Hallownest.button
                border.width: 1
                border.color: NotchSettings.lyrics ? Qt.alpha(Hallownest.soul, 0.4) : Hallownest.border

                Behavior on color {
                    CAnim {}
                }

                Row {
                    id: lyricsRow

                    anchors.centerIn: parent
                    spacing: Tokens.spacing.extraSmall

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "lyrics"
                        color: NotchSettings.lyrics ? Hallownest.soul : Hallownest.subtext
                        fontStyle: Tokens.font.icon.small
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Tr.tr("Lyrics")
                        color: NotchSettings.lyrics ? Hallownest.soul : Hallownest.subtext
                        font.pointSize: 9
                        font.weight: Font.DemiBold
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotchSettings.set("lyrics", !NotchSettings.lyrics)
                }
            }

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
                    icon: root.player?.isPlaying ? "pause" : "play_arrow"
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
        }
    }

    component ControlButton: Rectangle {
        id: button

        required property string icon
        property bool primary

        signal clicked

        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: primary ? 38 : 32
        implicitHeight: implicitWidth
        radius: implicitWidth / 2
        color: primary ? Hallownest.soul : buttonArea.containsMouse ? Hallownest.button : "transparent"
        opacity: enabled ? 1 : 0.35
        scale: buttonArea.pressed ? 0.9 : 1

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
            color: button.primary ? Hallownest.void_ : Hallownest.soul
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
