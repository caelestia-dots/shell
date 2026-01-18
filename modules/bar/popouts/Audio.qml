pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../controlcenter/network"

Item {
    id: root

    required property var wrapper

    implicitWidth: layout.implicitWidth + Appearance.padding.normal * 2
    implicitHeight: layout.implicitHeight + Appearance.padding.normal * 2

    ButtonGroup {
        id: sinks
    }

    ButtonGroup {
        id: sources
    }

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacing.normal

        StyledText {
            text: qsTr("Output device")
            font.weight: 500
        }

        Repeater {
            model: Audio.sinks

            StyledRadioButton {
                id: control

                required property PwNode modelData

                ButtonGroup.group: sinks
                checked: Audio.sink?.id === modelData.id
                onClicked: Audio.setAudioSink(modelData)
                text: modelData.description
            }
        }

        StyledText {
            Layout.topMargin: Appearance.spacing.smaller
            text: qsTr("Input device")
            font.weight: 500
        }

        Repeater {
            model: Audio.sources

            StyledRadioButton {
                required property PwNode modelData

                ButtonGroup.group: sources
                checked: Audio.source?.id === modelData.id
                onClicked: Audio.setAudioSource(modelData)
                text: modelData.description
            }
        }

        StyledText {
            Layout.topMargin: Appearance.spacing.smaller
            Layout.bottomMargin: -Appearance.spacing.small / 2
            text: qsTr("Volume (%1)").arg(Audio.muted ? qsTr("Muted") : `${Math.round(Audio.volume * 100)}%`)
            font.weight: 500
        }

        CustomMouseArea {
            Layout.fillWidth: true
            implicitHeight: Appearance.padding.normal * 3

            onWheel: event => {
                if (event.angleDelta.y > 0)
                    Audio.incrementVolume();
                else if (event.angleDelta.y < 0)
                    Audio.decrementVolume();
            }

            StyledSlider {
                anchors.left: parent.left
                anchors.right: parent.right
                implicitHeight: parent.implicitHeight

                value: Audio.volume
                onMoved: Audio.setVolume(value)

                Behavior on value {
                    Anim {}
                }
            }
        }

        StyledText {
            Layout.topMargin: Appearance.spacing.normal
            Layout.bottomMargin: -Appearance.spacing.small / 2
            text: qsTr("Applications")
            font.weight: 500
            visible: Audio.streams.length > 0
        }

        Repeater {
            model: Audio.streams
            Layout.fillWidth: true
            visible: Audio.streams.length > 0

            delegate: ColumnLayout {
                required property var modelData

                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.smaller
                spacing: Appearance.spacing.smaller

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    MaterialIcon {
                        text: "apps"
                        font.pointSize: Appearance.font.size.small
                        fill: 0
                    }

                    StyledText {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        text: Audio.getStreamName(modelData)
                        font.pointSize: Appearance.font.size.small
                        font.weight: 500
                    }

                    StyledRect {
                        implicitWidth: implicitHeight
                        implicitHeight: streamMuteIcon.implicitHeight + Appearance.padding.small * 2

                        radius: Appearance.rounding.small
                        color: Audio.getStreamMuted(modelData) ? Colours.palette.m3secondary : Colours.palette.m3secondaryContainer

                        StateLayer {
                            function onClicked(): void {
                                Audio.setStreamMuted(modelData, !Audio.getStreamMuted(modelData));
                            }
                        }

                        MaterialIcon {
                            id: streamMuteIcon

                            anchors.centerIn: parent
                            text: Audio.getStreamMuted(modelData) ? "volume_off" : "volume_up"
                            color: Audio.getStreamMuted(modelData) ? Colours.palette.m3onSecondary : Colours.palette.m3onSecondaryContainer
                            font.pointSize: Appearance.font.size.small
                        }
                    }
                }

                StyledSlider {
                    Layout.fillWidth: true
                    implicitHeight: Appearance.padding.normal * 2

                    value: Audio.getStreamVolume(modelData)
                    enabled: !Audio.getStreamMuted(modelData)
                    opacity: enabled ? 1 : 0.5
                    onMoved: {
                        Audio.setStreamVolume(modelData, value);
                    }

                    Connections {
                        target: modelData
                        function onAudioChanged() {
                            if (modelData?.audio) {
                                value = modelData.audio.volume;
                            }
                        }
                    }

                    Behavior on value {
                        Anim {}
                    }
                }
            }
        }

        IconTextButton {
            Layout.fillWidth: true
            Layout.topMargin: Appearance.spacing.normal
            inactiveColour: Colours.palette.m3primaryContainer
            inactiveOnColour: Colours.palette.m3onPrimaryContainer
            verticalPadding: Appearance.padding.small
            text: qsTr("Open settings")
            icon: "settings"

            onClicked: root.wrapper.detach("audio")
        }
    }
}
