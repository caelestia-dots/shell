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

        ColumnLayout {
            // get a list of nodes that output to the default sink
            PwNodeLinkTracker {
              id: linkTracker
              node: Pipewire.defaultAudioSink
            }
            PwObjectTracker {
                objects: [linkTracker.linkGroups]
            }

            property bool activeSourceExists: linkTracker.linkGroups.some(e => !Config.bar.popouts.audio.onlyShowActive || e.state == PwLinkState.Active)
            property bool enabled: Config.bar.popouts.audio.showPrograms && activeSourceExists
            // The master volume slider above takes a bit too much space compared to radio buttons, so I used half the margin on top of this
            Layout.topMargin: enabled ? Appearance.spacing.small / 2 : 0
            // Stop programs with long names to stretch the popup
            Layout.maximumWidth: parent.implicitWidth
            visible: enabled

            StyledText {
                text: qsTr("Programs")
                font.weight: 500
            }
            Repeater {
                model: linkTracker.linkGroups.filter(e => e.source.isStream)

                ColumnLayout {
                    required property PwLinkGroup modelData
                    PwObjectTracker {
                        objects: [modelData]
                    }
                    PwObjectTracker {
                        objects: [modelData.source]
                    }
                    Layout.topMargin: Appearance.spacing.small

                    spacing: Appearance.spacing.small / 2
                    visible: !Config.bar.popouts.audio.onlyShowActive || modelData.state === PwLinkState.Active

                    // description
                    RowLayout {
                        StyledText {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap

                            font.pointSize: Appearance.font.size.small
                            font.weight: 100
                            text: {
                              // Copied from https://git.outfoxxed.me/quickshell/quickshell-examples/src/branch/master/mixer
                              // application.name -> description -> name
                              const app = modelData.source.properties["application.name"] ?? (modelData.source.description != "" ? modelData.source.description : modelData.source.name);
                              const media = modelData.source.properties["media.name"];
                              return media != undefined ? `${app} - ${media}` : app;
                            }
                        }
                        // The volume is seperated from title to make sure it is not elided away
                        StyledText {
                            font.pointSize: Appearance.font.size.small
                            font.weight: 100
                            text: qsTr("(%1)").arg(modelData.source.audio.muted ? qsTr("Muted") : `${Math.round(modelData.source.audio.volume * 100)}%`)
                        }
                    }
                    RowLayout {
                        // mute button
                        IconButton {
                            Layout.preferredWidth: implicitWidth
                            Layout.preferredHeight: Appearance.padding.normal * 3

                            icon: {
                                if (modelData.source.audio.muted)
                                    return "no_sound";
                                if (modelData.source.audio.volume >= 0.5)
                                    return "volume_up";
                                if (modelData.source.audio.volume > 0)
                                    return "volume_down";
                                return "volume_mute";
                            }
                            checked: modelData.source.audio.muted
                            radius: Appearance.rounding.normal
                            activeColour: Colours.palette.m3errorContainer
                            inactiveColour: Colours.palette.m3primaryContainer
                            activeOnColour: Colours.palette.m3onErrorContainer
                            inactiveOnColour: Colours.palette.m3onPrimaryContainer
                            toggle: true
                            radiusAnim.duration: Appearance.anim.durations.expressiveFastSpatial
                            radiusAnim.easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                            onClicked: {
                                if (modelData.source.ready && modelData.source.audio) {
                                    modelData.source.audio.muted = !modelData.source.audio.muted;
                                }
                            }
                            Behavior on Layout.preferredWidth {
                                Anim {
                                    duration: Appearance.anim.durations.expressiveFastSpatial
                                    easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                                }
                            }
                        }
                        // volume slider
                        CustomMouseArea {
                            Layout.fillWidth: true

                            implicitHeight: Appearance.padding.smaller * 3

                            function setVolume(newVolume: real): void {
                                if (modelData.source.ready && modelData.source.audio) {
                                    modelData.source.audio.muted = false;
                                    modelData.source.audio.volume = Math.max(0, Math.min(1, newVolume));
                                }
                            }

                            onWheel: event => {
                                if (event.angleDelta.y > 0)
                                    setVolume(modelData.source.audio.volume + Config.services.audioIncrement);
                                else if (event.angleDelta.y < 0)
                                    setVolume(modelData.source.audio.volume - Config.services.audioIncrement);
                            }

                            StyledSlider {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                implicitHeight: parent.implicitHeight

                                value: modelData.source.audio.muted ? 0 : modelData.source.audio.volume
                                onMoved: parent.setVolume(value)

                                Behavior on value {
                                    Anim {}
                                }
                            }
                        }
                    }
                }
            }
        }

        StyledRect {
            Layout.topMargin: Appearance.spacing.normal
            visible: Config.general.apps.audio.length > 0

            implicitWidth: expandBtn.implicitWidth + Appearance.padding.normal * 2
            implicitHeight: expandBtn.implicitHeight + Appearance.padding.small

            radius: Appearance.rounding.normal
            color: Colours.palette.m3primaryContainer

            StateLayer {
                color: Colours.palette.m3onPrimaryContainer

                function onClicked(): void {
                    root.wrapper.hasCurrent = false;
                    Quickshell.execDetached(["app2unit", "--", ...Config.general.apps.audio]);
                }
            }

            RowLayout {
                id: expandBtn

                anchors.centerIn: parent
                spacing: Appearance.spacing.small

                StyledText {
                    Layout.leftMargin: Appearance.padding.smaller
                    text: qsTr("Open settings")
                    color: Colours.palette.m3onPrimaryContainer
                }

                MaterialIcon {
                    text: "chevron_right"
                    color: Colours.palette.m3onPrimaryContainer
                    font.pointSize: Appearance.font.size.large
                }
            }
        }
    }
}
