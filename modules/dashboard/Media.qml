pragma ComponentBehavior: Bound

import qs.widgets
import qs.services
import qs.utils
import qs.config
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Shapes

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

    implicitWidth: cover.implicitWidth + Config.dashboard.sizes.mediaVisualiserSize * 2 + details.implicitWidth + details.anchors.leftMargin + bongocat.implicitWidth + bongocat.anchors.leftMargin * 2 + Appearance.padding.large * 2
    implicitHeight: Math.max(cover.implicitHeight + Config.dashboard.sizes.mediaVisualiserSize * 2, details.implicitHeight, bongocat.implicitHeight) + Appearance.padding.large * 2

    Behavior on playerProgress {
        NumberAnimation {
            duration: Appearance.anim.durations.large
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standard
        }
    }

    Timer {
        running: Players.active?.isPlaying ?? false
        interval: Config.dashboard.mediaUpdateInterval
        triggeredOnStart: true
        repeat: true
        onTriggered: Players.active?.positionChanged()
    }

    Ref {
        service: Cava
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

        preferredRendererType: Shape.CurveRenderer
        data: visualiserBars.instances
    }

    Variants {
        id: visualiserBars

        model: Array.from({
            length: Config.dashboard.visualiserBars
        }, (_, i) => i)

        ShapePath {
            id: visualiserBar

            required property int modelData
            readonly property int value: Math.max(1, Math.min(100, Cava.values[modelData]))

            readonly property real angle: modelData * 2 * Math.PI / Config.dashboard.visualiserBars
            readonly property real magnitude: value / 100 * Config.dashboard.sizes.mediaVisualiserSize
            readonly property real cos: Math.cos(angle)
            readonly property real sin: Math.sin(angle)

            capStyle: ShapePath.RoundCap
            strokeWidth: 360 / Config.dashboard.visualiserBars - Appearance.spacing.small / 4
            strokeColor: Colours.palette.m3primary

            startX: visualiser.centerX + (visualiser.innerX + strokeWidth / 2) * cos
            startY: visualiser.centerY + (visualiser.innerY + strokeWidth / 2) * sin

            PathLine {
                x: visualiser.centerX + (visualiser.innerX + visualiserBar.strokeWidth / 2 + visualiserBar.magnitude) * visualiserBar.cos
                y: visualiser.centerY + (visualiser.innerY + visualiserBar.strokeWidth / 2 + visualiserBar.magnitude) * visualiserBar.sin
            }

            Behavior on strokeColor {
                ColorAnimation {
                    duration: Appearance.anim.durations.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.standard
                }
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

        color: Colours.palette.m3surfaceContainerHigh
        radius: Appearance.rounding.full

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

        ElideText {
            id: title

            label: (Players.active?.trackTitle ?? qsTr("No media")) || qsTr("Unknown title")
            color: Colours.palette.m3primary
            font.pointSize: Appearance.font.size.normal
        }

        ElideText {
            id: album

            label: (Players.active?.trackAlbum ?? qsTr("No media")) || qsTr("Unknown album")
            color: Colours.palette.m3outline
            font.pointSize: Appearance.font.size.small
        }

        ElideText {
            id: artist

            label: (Players.active?.trackArtist ?? qsTr("No media")) || qsTr("Unknown artist")
            color: Colours.palette.m3secondary
        }

        RowLayout {
            id: controls

            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Appearance.spacing.small
            Layout.bottomMargin: Appearance.spacing.smaller

            spacing: Appearance.spacing.small

            Control {
                icon: "skip_previous"
                canUse: Players.active?.canGoPrevious ?? false

                function onClicked(): void {
                    Players.active?.previous();
                }
            }

            Control {
                icon: Players.active?.isPlaying ? "pause" : "play_arrow"
                canUse: Players.active?.canTogglePlaying ?? false
                primary: true

                function onClicked(): void {
                    Players.active?.togglePlaying();
                }
            }

            Control {
                icon: "skip_next"
                canUse: Players.active?.canGoNext ?? false

                function onClicked(): void {
                    Players.active?.next();
                }
            }
        }

        Slider {
            id: slider

            implicitWidth: controls.implicitWidth * 1.5
            implicitHeight: Appearance.padding.normal * 3

            value: root.playerProgress
            onMoved: {
                const active = Players.active;
                if (active?.canSeek && active?.positionSupported)
                    active.position = value * active.length;
            }

            background: Item {
                StyledRect {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.topMargin: slider.implicitHeight / 3
                    anchors.bottomMargin: slider.implicitHeight / 3

                    implicitWidth: slider.handle.x - slider.implicitHeight / 6

                    color: Colours.palette.m3primary
                    radius: Appearance.rounding.full
                    topRightRadius: slider.implicitHeight / 15
                    bottomRightRadius: slider.implicitHeight / 15
                }

                StyledRect {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.topMargin: slider.implicitHeight / 3
                    anchors.bottomMargin: slider.implicitHeight / 3

                    implicitWidth: parent.width - slider.handle.x - slider.handle.implicitWidth - slider.implicitHeight / 6

                    color: Colours.palette.m3surfaceContainer
                    radius: Appearance.rounding.full
                    topLeftRadius: slider.implicitHeight / 15
                    bottomLeftRadius: slider.implicitHeight / 15
                }
            }

            handle: StyledRect {
                id: rect

                x: slider.visualPosition * slider.availableWidth

                implicitWidth: slider.implicitHeight / 4.5
                implicitHeight: slider.implicitHeight

                color: Colours.palette.m3primary
                radius: Appearance.rounding.full

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPressed: event => event.accepted = false
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

            Control {
                icon: "flip_to_front"
                canUse: Players.active?.canRaise ?? false
                fontSize: Appearance.font.size.larger
                padding: Appearance.padding.small
                fill: false
                color: Colours.palette.m3surfaceContainer

                function onClicked(): void {
                    Players.active?.raise();
                    root.visibilities.dashboard = false;
                }
            }

            MouseArea {
                id: playerSelector

                property bool expanded

                Layout.alignment: Qt.AlignVCenter

                implicitWidth: slider.implicitWidth / 2
                implicitHeight: currentPlayer.implicitHeight + Appearance.padding.small * 2

                cursorShape: Qt.PointingHandCursor
                onClicked: expanded = !expanded

                RectangularShadow {
                    anchors.fill: playerSelectorBg

                    opacity: playerSelector.expanded ? 1 : 0
                    radius: playerSelectorBg.radius
                    color: Colours.palette.m3shadow
                    blur: 5
                    spread: 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Appearance.anim.durations.normal
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.anim.curves.standard
                        }
                    }
                }

                StyledRect {
                    id: playerSelectorBg

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom

                    implicitHeight: playersWrapper.implicitHeight + Appearance.padding.small * 2

                    color: Colours.palette.m3secondaryContainer
                    radius: Appearance.rounding.normal

                    Item {
                        id: playersWrapper

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: Appearance.padding.small

                        clip: true
                        implicitHeight: playerSelector.expanded && Players.list.length > 1 ? players.implicitHeight : currentPlayer.implicitHeight

                        Column {
                            id: players

                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom

                            spacing: Appearance.spacing.small

                            Repeater {
                                model: Players.list.filter(p => p !== Players.active)

                                Row {
                                    id: player

                                    required property MprisPlayer modelData

                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: Appearance.spacing.small

                                    IconImage {
                                        id: playerIcon

                                        source: Icons.getAppIcon(player.modelData.identity, "image-missing")
                                        implicitSize: Math.round(identity.implicitHeight * 0.9)
                                    }

                                    StyledText {
                                        id: identity

                                        text: identityMetrics.elidedText
                                        color: Colours.palette.m3onSecondaryContainer

                                        TextMetrics {
                                            id: identityMetrics

                                            text: player.modelData.identity
                                            font.family: identity.font.family
                                            font.pointSize: identity.font.pointSize
                                            elide: Text.ElideRight
                                            elideWidth: playerSelector.implicitWidth - playerIcon.implicitWidth - player.spacing - Appearance.padding.smaller * 2
                                        }

                                        MouseArea {

                                            anchors.fill: parent

                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                Players.manualActive = player.modelData;
                                                playerSelector.expanded = false;
                                            }
                                        }
                                    }
                                }
                            }

                            Item {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                implicitHeight: 1

                                StyledRect {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.margins: -Appearance.padding.normal
                                    color: Colours.palette.m3secondary
                                    implicitHeight: 1
                                }
                            }

                            Row {
                                id: currentPlayer

                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: Appearance.spacing.small

                                IconImage {
                                    id: currentIcon

                                    source: Icons.getAppIcon(Players.active?.identity ?? "", "multimedia-player")
                                    implicitSize: Math.round(currentIdentity.implicitHeight * 0.9)
                                }

                                StyledText {
                                    id: currentIdentity

                                    animate: true
                                    text: currentIdentityMetrics.elidedText
                                    color: Colours.palette.m3onSecondaryContainer

                                    TextMetrics {
                                        id: currentIdentityMetrics

                                        text: Players.active?.identity ?? "No players"
                                        font.family: currentIdentity.font.family
                                        font.pointSize: currentIdentity.font.pointSize
                                        elide: Text.ElideRight
                                        elideWidth: playerSelector.implicitWidth - currentIcon.implicitWidth - currentPlayer.spacing - Appearance.padding.smaller * 2
                                    }
                                }
                            }
                        }

                        Behavior on implicitHeight {
                            NumberAnimation {
                                duration: Appearance.anim.durations.normal
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Appearance.anim.curves.emphasized
                            }
                        }
                    }
                }
            }

            Control {
                icon: "delete"
                canUse: Players.active?.canQuit ?? false
                fontSize: Appearance.font.size.larger
                padding: Appearance.padding.small
                fill: false
                color: Colours.palette.m3surfaceContainer

                function onClicked(): void {
                    Players.active?.quit();
                }
            }
        }
    }

    Item {
        id: bongocat

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: details.right
        anchors.leftMargin: Appearance.spacing.normal

        implicitWidth: visualiser.width
        implicitHeight: visualiser.height

        AnimatedImage {
            anchors.centerIn: parent

            width: visualiser.width * 0.75
            height: visualiser.height * 0.75

            playing: Players.active?.isPlaying ?? false
            speed: BeatDetector.bpm / 300
            source: Paths.expandTilde(Config.paths.mediaGif)
            asynchronous: true
            fillMode: AnimatedImage.PreserveAspectFit
        }
    }

    component ElideText: StyledText {
        id: elideText

        property alias label: metrics.text

        Layout.fillWidth: true

        animate: true
        horizontalAlignment: Text.AlignHCenter
        text: metrics.elidedText

        TextMetrics {
            id: metrics

            font.family: elideText.font.family
            font.pointSize: elideText.font.pointSize
            elide: Text.ElideRight
            elideWidth: elideText.width
        }
    }

    component Control: StyledRect {
        id: control

        required property string icon
        required property bool canUse
        property int fontSize: Appearance.font.size.extraLarge
        property int padding
        property bool fill: true
        property bool primary
        function onClicked(): void {
        }

        implicitWidth: Math.max(icon.implicitWidth, icon.implicitHeight) + padding * 2
        implicitHeight: implicitWidth

        radius: Appearance.rounding.full
        color: primary && canUse ? Colours.palette.m3primary : "transparent"

        StateLayer {
            disabled: !control.canUse
            radius: parent.radius
            color: control.primary ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface

            function onClicked(): void {
                control.onClicked();
            }
        }

        MaterialIcon {
            id: icon

            anchors.centerIn: parent
            anchors.horizontalCenterOffset: -font.pointSize * 0.02
            anchors.verticalCenterOffset: font.pointSize * 0.02

            animate: true
            fill: control.fill ? 1 : 0
            text: control.icon
            color: control.canUse ? control.primary ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface : Colours.palette.m3outline
            font.pointSize: control.fontSize
        }
    }
}
