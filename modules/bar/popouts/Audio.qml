import qs.widgets
import qs.widgets.sliders
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
            if (node.isSink) acc.output.push(node)
            else if (node.audio) acc.input.push(node)
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
