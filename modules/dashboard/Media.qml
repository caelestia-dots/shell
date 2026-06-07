import "media"
import QtQuick
import QtQuick.Layouts
import M3Shapes
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property DrawerVisibilities visibilities

    implicitWidth: Tokens.sizes.dashboard.mediaTabWidth
    implicitHeight: Tokens.sizes.dashboard.mediaTabHeight

    BackgroundShapes {
        anchors.fill: parent
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.extraLarge

        CoverVisualiser {
            Layout.fillHeight: true
            implicitWidth: Tokens.sizes.dashboard.mediaSectionWidth
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            state: Players.active ? "" : "noMedia"

            states: State {
                name: "noMedia"

                PropertyChanges {
                    noMedia.opacity: 1
                    content.opacity: 0
                }
            }

            transitions: [
                Transition {
                    from: ""

                    SequentialAnimation {
                        Anim {
                            target: content
                            property: "opacity"
                            type: Anim.DefaultEffects
                        }
                        Anim {
                            target: noMedia
                            property: "opacity"
                            type: Anim.SlowEffects
                        }
                    }
                },
                Transition {
                    to: ""

                    SequentialAnimation {
                        Anim {
                            target: noMedia
                            property: "opacity"
                            type: Anim.DefaultEffects
                        }
                        Anim {
                            target: content
                            property: "opacity"
                            type: Anim.SlowEffects
                        }
                    }
                }
            ]

            Loader {
                id: noMedia

                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -Tokens.padding.extraLarge * 2
                asynchronous: true
                active: opacity > 0
                opacity: 0

                sourceComponent: ColumnLayout {
                    spacing: Tokens.spacing.small

                    MaterialShape {
                        Layout.topMargin: (pathBounds().height - implicitSize) / 2
                        Layout.bottomMargin: (pathBounds().height - implicitSize) / 2 + Tokens.spacing.small
                        Layout.alignment: Qt.AlignHCenter
                        color: Colours.palette.m3primaryContainer
                        implicitSize: icon.implicitHeight + Tokens.padding.extraLarge * 2
                        shape: MaterialShape.ClamShell

                        Behavior on color {
                            CAnim {}
                        }

                        MaterialIcon {
                            id: icon

                            anchors.centerIn: parent
                            text: "queue_music"
                            fontStyle: Tokens.font.icon.builders.large.scale(2).build()
                            color: Colours.palette.m3onPrimaryContainer
                        }
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Nothing playing")
                        font: Tokens.font.headline.medium
                    }

                    StyledText {
                        text: qsTr("Play something for it to show up here!")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.large
                    }
                }
            }

            Loader {
                id: content

                anchors.fill: parent
                asynchronous: true
                active: opacity > 0

                sourceComponent: RowLayout {
                    spacing: Tokens.spacing.extraLarge

                    Details {
                        Layout.fillWidth: true
                    }

                    LyricsAndSelector {
                        Layout.fillHeight: true
                        implicitWidth: Tokens.sizes.dashboard.mediaSectionWidth
                    }
                }
            }
        }
    }
}
