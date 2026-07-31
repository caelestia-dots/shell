pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Audio")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Output
        SliderRow {
            first: true
            icon: Icons.getVolumeIcon(Audio.volume, Audio.muted)
            label: qsTr("Output")
            valueLabel: Math.round(value * 100) + "%"
            value: Audio.volume
            enabled: !Audio.muted
            onMoved: v => Audio.setVolume(v)
        }

        ToggleRow {
            text: qsTr("Muted")
            checked: Audio.muted
            onToggled: Audio.setStreamMuted(Audio.sink, checked)
        }

        AudioDeviceList {
            nodes: Audio.sinks
            currentId: Audio.sink?.id ?? -1
            iconName: "speaker"
            placeholderIcon: "speaker"
            placeholderText: qsTr("No output devices")
            onSelected: node => Audio.setAudioSink(node)
        }

        // Input
        SliderRow {
            Layout.topMargin: Tokens.spacing.large - parent.spacing
            first: true
            icon: Icons.getMicVolumeIcon(Audio.sourceVolume, Audio.sourceMuted)
            label: qsTr("Input")
            valueLabel: Math.round(value * 100) + "%"
            value: Audio.sourceVolume
            enabled: !Audio.sourceMuted
            onMoved: v => Audio.setSourceVolume(v)
        }

        ToggleRow {
            text: qsTr("Muted")
            checked: Audio.sourceMuted
            onToggled: Audio.setStreamMuted(Audio.source, checked)
        }

        AudioDeviceList {
            nodes: Audio.sources
            currentId: Audio.source?.id ?? -1
            iconName: "mic"
            placeholderIcon: "mic_off"
            placeholderText: qsTr("No input devices")
            onSelected: node => Audio.setAudioSource(node)
        }

        // Per-app volumes
        NavRow {
            Layout.topMargin: Tokens.spacing.large - parent.spacing
            first: true
            last: true

            icon: "tune"
            text: qsTr("App volumes")
            subtext: Audio.streams.length === 0 ? qsTr("No apps playing audio") : Audio.streams.length === 1 ? qsTr("1 app playing audio") : qsTr("%1 apps playing audio").arg(Audio.streams.length)
            onClicked: root.nState.openSubPage(1)
        }
    }
}
