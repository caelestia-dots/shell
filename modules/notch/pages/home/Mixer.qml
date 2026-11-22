pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import Caelestia.I18n
import qs.components
import qs.components.hallownest
import qs.services
import qs.utils

// Per-app volume: one row per playback stream (recording streams like Cava are left out)
ColumnLayout {
    id: root

    readonly property var streams: Audio.streams.filter(s => s.type === PwNodeType.AudioOutStream)

    spacing: 8

    HkCard {
        Layout.fillWidth: true
        visible: root.streams.length === 0
        implicitHeight: 96

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 6

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "music_off"
                color: Hallownest.faint
                font.pointSize: 20
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Tr.tr("No apps playing audio")
                color: Hallownest.subtext
                font.family: Hallownest.serif
                font.pointSize: 10
            }
        }
    }

    Repeater {
        model: ScriptModel {
            values: root.streams
        }

        HkCard {
            id: row

            required property PwNode modelData
            readonly property bool muted: Audio.getStreamMuted(modelData)
            readonly property real volume: Audio.getStreamVolume(modelData)
            readonly property string title: modelData.properties["media.name"] ?? ""

            Layout.fillWidth: true
            implicitHeight: 56

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 10

                IconImage {
                    implicitSize: 28
                    source: Icons.iconPath(row.modelData.properties["application.icon-name"] || row.modelData.properties["application.process.binary"] || "", "audio-x-generic")
                }

                ColumnLayout {
                    Layout.preferredWidth: 150
                    Layout.maximumWidth: 150
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: Audio.getStreamName(row.modelData)
                        color: Hallownest.soul
                        font.pointSize: 10
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: !!row.title && row.title !== Audio.getStreamName(row.modelData)
                        text: row.title
                        color: Hallownest.subtext
                        font.pointSize: 8
                        elide: Text.ElideRight
                    }
                }

                HkButton {
                    icon: row.muted ? "volume_off" : "volume_up"
                    accent: row.muted ? Hallownest.grimm : Hallownest.soul
                    tinted: row.muted
                    onClicked: Audio.setStreamMuted(row.modelData, !row.muted)
                }

                MouseArea {
                    Layout.fillWidth: true
                    implicitHeight: 24
                    acceptedButtons: Qt.NoButton
                    onWheel: e => Audio.setStreamVolume(row.modelData, row.volume + (e.angleDelta.y > 0 ? 0.05 : -0.05))

                    HkSlider {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        value: row.volume
                        colour: row.muted ? Hallownest.faint : Hallownest.lifeblood
                        onMoved: v => Audio.setStreamVolume(row.modelData, v)
                    }
                }

                StyledText {
                    Layout.preferredWidth: 34
                    horizontalAlignment: Text.AlignRight
                    text: row.muted ? Tr.tr("Off") : `${Math.round(row.volume * 100)}%`
                    color: row.muted ? Hallownest.grimm : Hallownest.subtext
                    font.family: Hallownest.mono
                    font.pointSize: 9
                }
            }
        }
    }
}
