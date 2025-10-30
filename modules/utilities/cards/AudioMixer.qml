pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config
import qs.utils
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    required property var props

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + layout.anchors.margins * 2

    radius: Appearance.rounding.normal
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Appearance.padding.large
        spacing: Audio.streams.length > 0 ? Appearance.spacing.normal : 0

        WrapperMouseArea {
            Layout.fillWidth: true

            cursorShape: Qt.PointingHandCursor
            onClicked: root.props.audioMixerExpanded = !root.props.audioMixerExpanded
            RowLayout {
                spacing: Appearance.spacing.normal
                z: 1

                StyledRect {
                    implicitWidth: implicitHeight
                    implicitHeight: {
                        const h = icon.implicitHeight + Appearance.padding.smaller * 2;
                        return h - (h % 2);
                    }

                    radius: Appearance.rounding.full
                    color: Colours.palette.m3secondaryContainer

                    MaterialIcon {
                        id: icon

                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: -0.5
                        anchors.verticalCenterOffset: 1.5
                        text: "speaker"
                        color: Colours.palette.m3onSecondaryContainer
                        font.pointSize: Appearance.font.size.large
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Audio Mixer")
                    font.pointSize: Appearance.font.size.normal
                    elide: Text.ElideRight
                }

                IconButton {
                    icon: root.props.audioMixerExpanded ? "unfold_less" : "unfold_more"
                    type: IconButton.Text
                    label.animate: true
                    onClicked: root.props.audioMixerExpanded = !root.props.audioMixerExpanded
                }
            }
        }

        Loader {
            id: mixer

            anchors.bottomMargin:Appearance.padding.large
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            sourceComponent: mixerDetails
        }
    }

    Component {
        id: mixerDetails

        ColumnLayout {
            Layout.maximumWidth: parent.implicitWidth
            implicitHeight: (Appearance.font.size.larger + Appearance.padding.small) * (root.props.audioMixerExpanded ? 10 : 0)
            opacity: root.props.audioMixerExpanded ? 1 : 0
            spacing: 0

            StyledListView  {
                id: list

                Layout.fillWidth: true
                implicitWidth: parent.maximumWidth
                implicitHeight: model.length > 0 ? parent.implicitHeight : 0
                spacing: Appearance.spacing.smaller

                model: Audio.streams
                clip: true

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: list
                }

                delegate: ColumnLayout {
                    required property PwNode modelData

                    width: list.width
                    Layout.fillWidth: true

                    spacing: Appearance.spacing.small / 2
                    visible: true

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
                                const app = modelData.properties["application.name"] ?? (modelData.description != "" ? modelData.description : modelData.name);
                                const media = modelData.properties["media.name"];
                                return media != undefined ? `${app} - ${media}` : app;
                            }
                        }
                        // The volume is seperated from title to make sure it is not elided away
                        StyledText {
                            // if right margin is not given the half of the handle gets clipped off
                            Layout.rightMargin: Appearance.spacing.normal
                            font.pointSize: Appearance.font.size.small
                            font.weight: 100
                            text: qsTr("(%1)").arg(modelData.audio.muted ? qsTr("Muted") : `${Math.round(modelData.audio.volume * 100)}%`)
                        }
                    }
                    RowLayout {
                        // mute button
                        IconButton {
                            Layout.preferredWidth: implicitWidth
                            Layout.preferredHeight: Appearance.padding.normal * 3

                            icon: Icons.getVolumeIcon(modelData.audio.volume, modelData.audio.muted)
                            checked: modelData.audio.muted
                            radius: Appearance.rounding.normal
                            activeColour: Colours.palette.m3errorContainer
                            inactiveColour: Colours.palette.m3primaryContainer
                            activeOnColour: Colours.palette.m3onErrorContainer
                            inactiveOnColour: Colours.palette.m3onPrimaryContainer
                            toggle: true
                            radiusAnim.duration: Appearance.anim.durations.expressiveFastSpatial
                            radiusAnim.easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                            onClicked: {
                                if (modelData.ready && modelData.audio) {
                                    modelData.audio.muted = !modelData.audio.muted;
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
                            // if right margin is not given the half of the handle gets clipped off
                            Layout.rightMargin: Appearance.spacing.normal
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

                                value: modelData.audio.muted ? 0 : modelData.audio.volume
                                onMoved: parent.setVolume(value)

                                Behavior on value {
                                    Anim {}
                                }
                            }
                        }
                    }
                }
            }
            StyledText {
                visible: Audio.streams.length === 0
                height: parent.implicitHeight
                Layout.alignment: Qt.AlignHCenter
                color: Colours.palette.m3outline
                text: qsTr("No sinks available")
            }
        
            Behavior on implicitHeight {
                Anim {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }
            Behavior on opacity {
                Anim {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }
        }
    }
}
