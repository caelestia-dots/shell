pragma ComponentBehavior: Bound

import qs.components
import qs.components.effects
import qs.components.controls
import qs.components.containers
import qs.services
import qs.utils
import qs.config
import Caelestia.Services
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Controls
import QtQuick.Effects

Item {
    id: root

    required property PersistentProperties visibilities

    property real playerProgress: {
        const active = Players.active;
        return active?.length ? active.position / active.length : 0;
    }

    function lengthStr(length: int): string {
        if (length < 0)
            return "-1:-1";

        const hours = Math.floor(length / 3600);
        const mins = Math.floor((length % 3600) / 60);
        const secs = Math.floor(length % 60).toString().padStart(2, "0");

        if (hours > 0)
            return `${hours}:${mins.toString().padStart(2, "0")}:${secs}`;
        return `${mins}:${secs}`;
    }

    implicitWidth: cover.implicitWidth + Config.dashboard.sizes.mediaVisualiserSize * 2 + details.implicitWidth + details.anchors.leftMargin + mediaGif.implicitWidth + mediaGif.anchors.leftMargin * 2 + Appearance.padding.large * 2
    implicitHeight: Math.max(cover.implicitHeight + Config.dashboard.sizes.mediaVisualiserSize * 2, details.implicitHeight, mediaGif.implicitHeight) + Appearance.padding.large * 2

    Behavior on playerProgress {
        Anim {
            duration: Appearance.anim.durations.large
        }
    }

    Timer {
        running: Players.active?.isPlaying ?? false
        interval: Config.dashboard.mediaUpdateInterval
        triggeredOnStart: true
        repeat: true
        onTriggered: Players.active?.positionChanged()
    }

    ServiceRef {
        service: Audio.cava
    }

    ServiceRef {
        service: Audio.beatTracker
    }

    Shape {
        id: visualiser

        readonly property real centerX: width / 2
        readonly property real centerY: height / 2
        readonly property real innerX: cover.implicitWidth / 2 + Appearance.spacing.small
        readonly property real innerY: cover.implicitHeight / 2 + Appearance.spacing.small
        property color colour: Colours.palette.m3primary

        anchors.fill: cover
        anchors.margins: -Config.dashboard.sizes.mediaVisualiserSize

        asynchronous: true
        preferredRendererType: Shape.CurveRenderer
        data: visualiserBars.instances
    }

    Variants {
        id: visualiserBars

        model: Array.from({
            length: Config.services.visualiserBars
        }, (_, i) => i)

        ShapePath {
            id: visualiserBar

            required property int modelData
            readonly property real value: Math.max(1e-3, Math.min(1, Audio.cava.values[modelData]))

            readonly property real angle: modelData * 2 * Math.PI / Config.services.visualiserBars
            readonly property real magnitude: value * Config.dashboard.sizes.mediaVisualiserSize
            readonly property real cos: Math.cos(angle)
            readonly property real sin: Math.sin(angle)

            capStyle: Appearance.rounding.scale === 0 ? ShapePath.SquareCap : ShapePath.RoundCap
            strokeWidth: 360 / Config.services.visualiserBars - Appearance.spacing.small / 4
            strokeColor: Colours.palette.m3primary

            startX: visualiser.centerX + (visualiser.innerX + strokeWidth / 2) * cos
            startY: visualiser.centerY + (visualiser.innerY + strokeWidth / 2) * sin

            PathLine {
                x: visualiser.centerX + (visualiser.innerX + visualiserBar.strokeWidth / 2 + visualiserBar.magnitude) * visualiserBar.cos
                y: visualiser.centerY + (visualiser.innerY + visualiserBar.strokeWidth / 2 + visualiserBar.magnitude) * visualiserBar.sin
            }

            Behavior on strokeColor {
                CAnim {}
            }
        }
    }

    StyledClippingRect {
        id: cover

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Appearance.padding.large + Config.dashboard.sizes.mediaVisualiserSize

        implicitWidth: Config.dashboard.sizes.mediaCoverArtSize
        implicitHeight: Config.dashboard.sizes.mediaCoverArtSize

        color: Colours.tPalette.m3surfaceContainerHigh
        radius: Infinity

        MaterialIcon {
            anchors.centerIn: parent

            grade: 200
            text: "art_track"
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: (parent.width * 0.4) || 1
        }

        Image {
            id: image

            anchors.fill: parent

            source: Players.active?.trackArtUrl ?? ""
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: width
            sourceSize.height: height
        }
    }

    ColumnLayout {
        id: details

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: visualiser.right
        anchors.leftMargin: Appearance.spacing.normal

        spacing: Appearance.spacing.small

        StyledText {
            id: title

            Layout.fillWidth: true
            Layout.maximumWidth: parent.implicitWidth

            animate: true
            horizontalAlignment: Text.AlignHCenter
            text: (Players.active?.trackTitle ?? qsTr("No media")) || qsTr("Unknown title")
            color: Players.active ? Colours.palette.m3primary : Colours.palette.m3onSurface
            font.pointSize: Appearance.font.size.normal
            elide: Text.ElideRight
        }

        StyledText {
            id: album

            Layout.fillWidth: true
            Layout.maximumWidth: parent.implicitWidth

            animate: true
            horizontalAlignment: Text.AlignHCenter
            visible: !!Players.active
            text: Players.active?.trackAlbum || qsTr("Unknown album")
            color: Colours.palette.m3outline
            font.pointSize: Appearance.font.size.small
            elide: Text.ElideRight
        }

        StyledText {
            id: artist

            Layout.fillWidth: true
            Layout.maximumWidth: parent.implicitWidth

            animate: true
            horizontalAlignment: Text.AlignHCenter
            text: (Players.active?.trackArtist ?? qsTr("Play some music for stuff to show up here!")) || qsTr("Unknown artist")
            color: Players.active ? Colours.palette.m3secondary : Colours.palette.m3outline
            elide: Text.ElideRight
            wrapMode: Players.active ? Text.NoWrap : Text.WordWrap
        }

        RowLayout {
            id: controls

            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Appearance.spacing.small
            Layout.bottomMargin: Appearance.spacing.smaller

            spacing: Appearance.spacing.small

            PlayerControl {
                type: IconButton.Text
                icon: "skip_previous"
                font.pointSize: Math.round(Appearance.font.size.large * 1.5)
                disabled: !Players.active?.canGoPrevious
                onClicked: Players.active?.previous()
            }

            PlayerControl {
                icon: Players.active?.isPlaying ? "pause" : "play_arrow"
                label.animate: true
                toggle: true
                padding: Appearance.padding.small / 2
                checked: Players.active?.isPlaying
                font.pointSize: Math.round(Appearance.font.size.large * 1.5)
                disabled: !Players.active?.canTogglePlaying
                onClicked: Players.active?.togglePlaying()
            }

            PlayerControl {
                type: IconButton.Text
                icon: "skip_next"
                font.pointSize: Math.round(Appearance.font.size.large * 1.5)
                disabled: !Players.active?.canGoNext
                onClicked: Players.active?.next()
            }
        }

        StyledSlider {
            id: slider

            enabled: !!Players.active
            implicitWidth: 280
            implicitHeight: Appearance.padding.normal * 3

            onMoved: {
                const active = Players.active;
                if (active?.canSeek && active?.positionSupported)
                    active.position = value * active.length;
            }

            Binding {
                target: slider
                property: "value"
                value: root.playerProgress
                when: !slider.pressed
            }

            CustomMouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton

                function onWheel(event: WheelEvent) {
                    const active = Players.active;
                    if (!active?.canSeek || !active?.positionSupported)
                        return;

                    event.accepted = true;
                    const delta = event.angleDelta.y > 0 ? 10 : -10;    // Time 10 seconds
                    Qt.callLater(() => {
                        active.position = Math.max(0, Math.min(active.length, active.position + delta));
                    });
                }
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: Math.max(position.implicitHeight, length.implicitHeight)

            StyledText {
                id: position

                anchors.left: parent.left

                text: root.lengthStr(Players.active?.position ?? -1)
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.small
            }

            StyledText {
                id: length

                anchors.right: parent.right

                text: root.lengthStr(Players.active?.length ?? -1)
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.small
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Appearance.spacing.small

            PlayerControl {
                type: IconButton.Text
                icon: "move_up"
                inactiveOnColour: Colours.palette.m3secondary
                padding: Appearance.padding.small
                font.pointSize: Appearance.font.size.large
                disabled: !Players.active?.canRaise
                onClicked: {
                    Players.active?.raise();
                    root.visibilities.dashboard = false;
                }
            }

            SplitButton {
                id: playerSelector

                disabled: !Players.list.length
                active: menuItems.find(m => m.modelData === Players.active) ?? menuItems[0]
                menu.onItemSelected: item => Players.manualActive = item.modelData

                menuItems: playerList.instances
                fallbackIcon: "music_off"
                fallbackText: qsTr("No players")

                label.Layout.maximumWidth: slider.implicitWidth * 0.28
                label.elide: Text.ElideRight

                stateLayer.disabled: true
                menuOnTop: true

                Variants {
                    id: playerList

                    model: Players.list

                    MenuItem {
                        required property MprisPlayer modelData

                        icon: modelData === Players.active ? "check" : ""
                        text: Players.getIdentity(modelData)
                        activeIcon: "animated_images"
                    }
                }
            }

            PlayerControl {
                type: IconButton.Text
                icon: "delete"
                inactiveOnColour: Colours.palette.m3error
                padding: Appearance.padding.small
                font.pointSize: Appearance.font.size.large
                disabled: !Players.active?.canQuit
                onClicked: Players.active?.quit()
            }
        }
    }

    Item {
        id: mediaGif

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: details.right
        anchors.leftMargin: Appearance.spacing.normal

        implicitWidth: visualiser.width
        implicitHeight: visualiser.height

        Loader {
            anchors.fill: parent
            sourceComponent: Config.dashboard.showAudioMixerOverMediaGif ? mixerCardComponent : mediaGifComponent
        }
    }

    component PlayerControl: IconButton {
        Layout.preferredWidth: implicitWidth + (stateLayer.pressed ? Appearance.padding.large : internalChecked ? Appearance.padding.smaller : 0)
        radius: stateLayer.pressed ? Appearance.rounding.small / 2 : internalChecked ? Appearance.rounding.small : implicitHeight / 2
        radiusAnim.duration: Appearance.anim.durations.expressiveFastSpatial
        radiusAnim.easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial

        Behavior on Layout.preferredWidth {
            Anim {
                duration: Appearance.anim.durations.expressiveFastSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
            }
        }
    }


    Component {
        id: mediaGifComponent
        AnimatedImage {
            id: mediaGif
            anchors.centerIn: parent

            width: visualiser.width * 0.75
            height: visualiser.height * 0.75

            playing: Players.active?.isPlaying ?? false
            speed: Audio.beatTracker.bpm / 300
            source: Paths.absolutePath(Config.paths.mediaGif)
            asynchronous: true
            fillMode: AnimatedImage.PreserveAspectFit
        }
    }

    Component {
        id: mixerCardComponent
        StyledRect {
            id: mixerCard
            radius: Appearance.rounding.small
            color: Colours.tPalette.m3surfaceContainer
            width: mediaGif.implicitWidth
            height: mediaGif.implicitHeight

            StyledRect {
                id: padding
                anchors.fill: parent
                anchors.margins: Appearance.padding.normal

                StyledText {
                    id: audioMixerTitle

                    Layout.minimumWidth: mixerCard.width - Appearance.spacing.normal * 2
                    horizontalAlignment: Text.AlignLeft
                    text: qsTr("Audio Mixer")
                    color: Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.larger
                    elide: Text.ElideRight
                }
                StyledListView {
                    id: list
                    model: Audio.streams
                    anchors.top: audioMixerTitle.bottom
                    anchors.topMargin: Appearance.spacing.normal
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    spacing: Appearance.spacing.small
                    clip: true

                    StyledScrollBar.vertical: StyledScrollBar {
                        flickable: list
                    }

                    delegate: RowLayout {
                        required property PwNode modelData
                        anchors.left: list.contentItem.left
                        anchors.right: list.contentItem.right
                        spacing: Appearance.spacing.normal

                        // Icon and mute button
                        Item {
                            Layout.alignment: Qt.AlignVCente

                            implicitWidth: Appearance.padding.smaller * 3
                            implicitHeight: Appearance.padding.smaller * 3

                            IconImage {
                                id: icon
                                anchors.fill: parent
                                source: Icons.getAppIcon(modelData.name, "image-missing")
                            }
                            MultiEffect {
                                anchors.fill: icon
                                source: icon
                                colorization: modelData.audio.muted && 1
                                // set to pure red instead of m3error so that the red color is more intense
                                colorizationColor: modelData.audio.muted && Qt.rgba(1.0, 0.0, 0.0, 1.0)
                            }
                            WrapperMouseArea {
                                id: ma
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: modelData.audio.muted = !modelData.audio.muted
                            }
                            ToolTip {
                                delay: Appearance.anim.durations.normal
                                visible: ma.containsMouse
                                opacity: opened ? 1 : 0

                                contentItem: StyledText {
                                    leftPadding: Appearance.spacing.small
                                    rightPadding: Appearance.spacing.small
                                    color: modelData.audio.muted ? Colours.palette.m3onErrorContainer : Colours.palette.m3onPrimaryContainer
                                    text: {
                                        // Copied from https://git.outfoxxed.me/quickshell/quickshell-examples/src/branch/master/mixer
                                        // application.name -> description -> name
                                        const app = modelData.properties["application.name"] ?? (modelData.description != "" ? modelData.description : modelData.name);
                                        let media = modelData.properties["media.name"];
                                        return media != undefined ? `${app} - ${media}` : app;
                                    }
                                }
                                background: StyledRect {
                                    color: modelData.audio.muted ? Colours.palette.m3errorContainer : Colours.palette.m3primaryContainer
                                    radius: Appearance.rounding.small
                                }
                                Behavior on opacity {
                                    Anim {
                                        duration: Appearance.anim.durations.normal
                                    }
                                }
                            }
                        }
                        // Slider
                        CustomMouseArea {
                            Layout.fillWidth: true
                            implicitHeight: Appearance.padding.smaller * 3

                            function setVolume(newVolume: real): void {
                                if (modelData.ready && modelData.audio) {
                                    modelData.audio.muted = false;
                                    modelData.audio.volume = Math.max(0, Math.min(1, newVolume));
                                }
                            }

                            onWheel: event => {
                                if (event.angleDelta.y > 0)
                                    setVolume(modelData.audio.volume + Config.services.audioIncrement);
                                else if (event.angleDelta.y < 0)
                                    setVolume(modelData.audio.volume - Config.services.audioIncrement);
                            }

                            StyledSlider {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                implicitHeight: parent.implicitHeight

                                opacity: modelData.audio.muted ? 0.6 : 1
                                value: modelData.audio.volume
                                type: modelData.audio.muted ? StyledSlider.SliderType.Error : StyledSlider.SliderType.Default
                                onMoved: parent.setVolume(value)

                                Behavior on value {
                                    Anim {}
                                }
                                Behavior on opacity {
                                    Anim {
                                        duration: Appearance.anim.durations.normal
                                    }
                                }
                            }
                        }
                        // Volume Text
                        StyledText {
                            id: volumeLevel
                            property string displayText: `${Math.round(modelData.audio.volume * 100)}%`
                            color: modelData.audio.muted ? Colours.palette.m3error : Colours.palette.m3primary
                            opacity: modelData.audio.muted ? 0.6 : 1
                            font.pointSize: Appearance.font.size.normal
                            text: displayText

                            // Set the width of the text to the max width it can get,
                            // so that when values change slider dont change it's when volume text changes size
                            FontMetrics {
                                id: fm
                                font: volumeLevel.font
                            }
                            Component.onCompleted: {
                                const maxWidth = Math.ceil(fm.advanceWidth("100%"));
                                volumeLevel.Layout.minimumWidth = maxWidth
                            }
                            Behavior on opacity {
                                Anim {
                                    duration: Appearance.anim.durations.normal
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
