import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

RowLayout {
    id: root

    required property bool isLarge

    spacing: Appearance.spacing.large * (isLarge ? 2 : 1.5)
    width: isLarge ? Config.lock.sizes.mediaWidth : Config.lock.sizes.mediaWidthSmall

    property real playerProgress: {
        const active = Players.active;
        return active?.length ? active.position / active.length : 0;
    }

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

    Item {
        Layout.alignment: Qt.AlignVCenter
        Layout.topMargin: root.isLarge ? 0 : Config.lock.sizes.border / 2
        Layout.bottomMargin: root.isLarge ? Config.lock.sizes.border / 2 : 0
        Layout.leftMargin: root.isLarge ? 0 : Config.lock.sizes.border / 2

        implicitWidth: root.isLarge ? Config.lock.sizes.mediaCoverSize : Config.lock.sizes.mediaCoverSizeSmall
        implicitHeight: root.isLarge ? Config.lock.sizes.mediaCoverSize : Config.lock.sizes.mediaCoverSizeSmall

        ClippingWrapperRectangle {
            anchors.fill: parent

            color: Colours.palette.m3surfaceContainerHigh
            radius: Appearance.rounding.small
            rotation: 9

            Image {
                anchors.fill: parent

                source: Players.active?.trackArtUrl ?? ""
                asynchronous: true
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: width
                sourceSize.height: height
            }

            Behavior on color {
                ColorAnimation {
                    duration: Appearance.anim.durations.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.standard
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: -1
            border.width: Config.lock.sizes.mediaCoverBorder
            border.color: Colours.palette.m3primary
            color: "transparent"
            radius: Appearance.rounding.small
            rotation: 9

            Behavior on border.color {
                ColorAnimation {
                    duration: Appearance.anim.durations.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.standard
                }
            }
        }

        StyledClippingRect {
            anchors.fill: parent

            color: Colours.palette.m3surfaceContainerHigh
            radius: Appearance.rounding.small

            border.width: Config.lock.sizes.mediaCoverBorder
            border.color: Colours.palette.m3primary

            MaterialIcon {
                anchors.centerIn: parent

                grade: 200
                text: "art_track"
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: (root.isLarge ? Config.lock.sizes.mediaCoverSize : Config.lock.sizes.mediaCoverSizeSmall) * 0.4
            }

            Image {
                anchors.fill: parent

                source: Players.active?.trackArtUrl ?? ""
                asynchronous: true
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: width
                sourceSize.height: height
            }
        }
    }

    ColumnLayout {
        Layout.alignment: Qt.AlignVCenter
        Layout.topMargin: root.isLarge ? 0 : Config.lock.sizes.border / 2
        Layout.bottomMargin: root.isLarge ? Config.lock.sizes.border / 2 : 0
        Layout.rightMargin: root.isLarge ? Config.lock.sizes.border / 2 : 0
        Layout.fillWidth: true

        spacing: root.isLarge ? Appearance.spacing.small : Appearance.spacing.small / 2

        StyledText {
            Layout.fillWidth: true

            animate: true
            text: (Players.active?.trackTitle ?? qsTr("No media")) || qsTr("Unknown title")
            color: Colours.palette.m3primary
            font.pointSize: root.isLarge ? Appearance.font.size.large : Appearance.font.size.larger
            elide: Text.ElideRight
        }

        StyledText {
            Layout.fillWidth: true

            animate: true
            text: (Players.active?.trackAlbum ?? qsTr("No media")) || qsTr("Unknown album")
            color: Colours.palette.m3outline
            font.pointSize: root.isLarge ? Appearance.font.size.larger : Appearance.font.size.normal
            elide: Text.ElideRight
        }

        StyledText {
            Layout.fillWidth: true

            animate: true
            text: (Players.active?.trackArtist ?? qsTr("No media")) || qsTr("Unknown artist")
            color: Colours.palette.m3secondary
            font.pointSize: root.isLarge ? Appearance.font.size.larger : Appearance.font.size.normal
            elide: Text.ElideRight
        }

        RowLayout {
            id: controls

            Layout.fillWidth: true

            spacing: Appearance.spacing.small

            StyledSlider {
                id: slider

                Layout.rightMargin: root.isLarge ? Appearance.spacing.small : 0
                Layout.fillWidth: true
                implicitHeight: Appearance.padding.normal * 3

                value: root.playerProgress
                onMoved: {
                    const active = Players.active;
                    if (active?.canSeek && active?.positionSupported)
                        active.position = value * active.length;
                }
            }

            Control {
                icon: "skip_previous"
                canUse: Players.active?.canGoPrevious ?? false
                fontSize: root.isLarge ? Appearance.font.size.extraLarge : Appearance.font.size.large * 1.2

                function onClicked(): void {
                    Players.active?.previous();
                }
            }

            Control {
                icon: Players.active?.isPlaying ? "pause" : "play_arrow"
                canUse: Players.active?.canTogglePlaying ?? false
                fontSize: root.isLarge ? Appearance.font.size.extraLarge : Appearance.font.size.large * 1.2
                primary: true

                function onClicked(): void {
                    Players.active?.togglePlaying();
                }
            }

            Control {
                icon: "skip_next"
                canUse: Players.active?.canGoNext ?? false
                fontSize: root.isLarge ? Appearance.font.size.extraLarge : Appearance.font.size.large * 1.2

                function onClicked(): void {
                    Players.active?.next();
                }
            }
        }
    }

    component Control: StyledRect {
        id: control

        required property string icon
        required property bool canUse
        required property int fontSize
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
