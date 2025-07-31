import qs.widgets
import qs.services
import qs.config

import QtQuick.Layouts
import QtQuick
import QtQuick.Controls

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
            bottomPadding: Appearance.spacing.small
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
            bottomPadding: Appearance.spacing.small
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
}
