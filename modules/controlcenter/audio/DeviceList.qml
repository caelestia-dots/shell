pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    spacing: Appearance.spacing.large

    // Output Devices Section
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        StyledText {
            text: qsTr("Output Devices")
            font.pointSize: Appearance.font.size.large
            font.weight: 700
        }

        Repeater {
            model: Audio.sinks

            DeviceCard {
                required property PwNode modelData
                required property int index

                Layout.fillWidth: true
                deviceName: modelData.description || modelData.name || qsTr("Unknown Device")
                deviceType: "output"
                isActive: Audio.sink?.id === modelData.id
                
                onClicked: Audio.setAudioSink(modelData)
            }
        }
    }

    // Separator
    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: Appearance.spacing.normal
        Layout.bottomMargin: Appearance.spacing.normal
        Layout.preferredHeight: 1
        color: Colours.palette.m3outlineVariant
        opacity: 0.3
    }

    // Input Devices Section
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        StyledText {
            text: qsTr("Input Devices")
            font.pointSize: Appearance.font.size.large
            font.weight: 700
        }

        Repeater {
            model: Audio.sources

            DeviceCard {
                required property PwNode modelData
                required property int index

                Layout.fillWidth: true
                deviceName: modelData.description || modelData.name || qsTr("Unknown Device")
                deviceType: "input"
                isActive: Audio.source?.id === modelData.id
                
                onClicked: Audio.setAudioSource(modelData)
            }
        }
    }

    component DeviceCard: StyledRect {
        id: card

        required property string deviceName
        required property string deviceType
        required property bool isActive

        signal clicked()

        implicitHeight: cardContent.implicitHeight + Appearance.padding.large * 2
        radius: Appearance.rounding.normal
        color: isActive ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainer

        StateLayer {
            color: isActive ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface

            function onClicked(): void {
                card.clicked();
            }
        }

        RowLayout {
            id: cardContent

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Appearance.padding.large

            spacing: Appearance.spacing.normal

            MaterialIcon {
                text: deviceType === "output" ? 
                      (isActive ? "volume_up" : "speaker") : 
                      (isActive ? "mic" : "mic_none")
                font.pointSize: Appearance.font.size.extraLarge
                color: isActive ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
            }

            StyledText {
                Layout.fillWidth: true
                text: deviceName
                font.weight: isActive ? 600 : 400
                color: isActive ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                elide: Text.ElideRight
            }

            MaterialIcon {
                text: "check_circle"
                font.pointSize: Appearance.font.size.large
                color: Colours.palette.m3primary
                visible: isActive
            }
        }
    }
}
