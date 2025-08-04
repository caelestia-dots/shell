import qs.widgets
import qs.widgets.sliders
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Qt.labs.platform

ColumnLayout {
    id: root

    required property var wrapper

    ColumnLayout {
        spacing: -Appearance.spacing.small

        StyledText {
            text: qsTr("Output")
            font.weight: 500
            Layout.bottomMargin: Appearance.spacing.small
        }

        Repeater {
            model: Audio.sinks

            StyledRadioButton {
                id: control

                text: modelData.description
                checked: Audio.sink?.id === modelData.id
                font.pointSize: Appearance.font.size.small
                onClicked: Audio.setAudioSink(modelData)
            }
        }
    }

    ColumnLayout {
        spacing: -Appearance.spacing.small

        StyledText {
            text: qsTr("Input")
            font.weight: 500
            Layout.bottomMargin: Appearance.spacing.small
        }

        Repeater {
            model: Audio.sources

            StyledRadioButton {
                text: modelData.description
                checked: Audio.source?.id === modelData.id
                font.pointSize: Appearance.font.size.small
                onClicked: Audio.setAudioSource(modelData)
            }
        }
    }

    StyledText {
        text: qsTr("Volume")
        font.weight: 500
        Layout.topMargin: Appearance.spacing.small
    }

    LineSlider {
        implicitWidth: root.implicitWidth
        implicitHeight: Appearance.padding.normal * 3
        value: Audio.volume
        onMoved: Audio.setVolume(value);
    }

    StyledRect {
        visible: Config.bar.externalAudioProgram.length > 0
        Layout.topMargin: Appearance.spacing.small
        implicitWidth: expandBtn.implicitWidth + Appearance.padding.normal * 2
        implicitHeight: expandBtn.implicitHeight + Appearance.padding.small

        radius: Appearance.rounding.normal
        color: Colours.palette.m3primaryContainer

        StateLayer {
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
