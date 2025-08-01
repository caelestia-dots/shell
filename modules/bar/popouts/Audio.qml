import qs.widgets
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Pipewire

ColumnLayout {
    id: root

    required property var wrapper

    property var devices: Pipewire.nodes.values.reduce((acc, node) => {
        if (!node.isStream) {
            if (node.isSink) {
                acc.output.push(node)
            } else if (node.audio) {
                acc.input.push(node)
            }
        }
        return acc
    }, { input: [], output: [] })

    property list<PwNode> inputDevices: devices.input
    property list<PwNode> outputDevices: devices.output

    ColumnLayout {
        spacing: -Appearance.spacing.small

        Label {
            text: qsTr("Output")
            font.weight: 500
            Layout.bottomMargin: Appearance.spacing.small
        }

        Repeater {
            model: root.outputDevices

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

        Label {
            text: qsTr("Input")
            font.weight: 500
            Layout.bottomMargin: Appearance.spacing.small
        }

        Repeater {
            model: root.inputDevices

            StyledRadioButton {
                text: modelData.description
                checked: Audio.source?.id === modelData.id
                font.pointSize: Appearance.font.size.small
                onClicked: Audio.setAudioSource(modelData)
            }
        }
    }

    StyledText {
        text: qsTr("Settings")
        font.weight: 500
        Layout.topMargin: Appearance.spacing.small
    }

    RowLayout {
        StyledSlider {
            id: volumeSlider

            isHorizontal: true
            icon: {
                if (Audio.muted)
                    return "no_sound";
                if (value >= 0.5)
                    return "volume_up";
                if (value > 0)
                    return "volume_down";
                return "volume_mute";
            }

            value: Audio.volume
            onMoved: Audio.setVolume(value)

            implicitWidth: Config.osd.sizes.sliderHeight
            implicitHeight: Config.osd.sizes.sliderWidth
        }

        StyledRect {
            id: pavuButton

            implicitWidth: implicitHeight
            implicitHeight: Config.osd.sizes.sliderWidth

            radius: Appearance.rounding.normal
            color: Colours.palette.m3surfaceContainer

            StateLayer {
                function onClicked(): void {
                    root.wrapper.hasCurrent = false;
                    Quickshell.execDetached(["app2unit", "--", ...Config.bar.externalAudioProgram]);
                }
            }

            MaterialIcon {
                id: icon

                anchors.centerIn: parent
                text: "settings"
            }
        }
    }
}
