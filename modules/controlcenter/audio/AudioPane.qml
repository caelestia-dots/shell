pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.services
import qs.config
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    required property Session session

    anchors.fill: parent

    spacing: 0

    Item {
        id: leftAudioItem
        Layout.preferredWidth: Math.floor(parent.width * 0.4)
        Layout.minimumWidth: 420
        Layout.fillHeight: true

        ClippingRectangle {
            id: leftAudioClippingRect
            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            anchors.leftMargin: 0
            anchors.rightMargin: Appearance.padding.normal / 2

            radius: leftAudioBorder.innerRadius
            color: "transparent"

            Loader {
                id: leftAudioLoader

                anchors.fill: parent
                anchors.margins: Appearance.padding.large + Appearance.padding.normal
                anchors.leftMargin: Appearance.padding.large
                anchors.rightMargin: Appearance.padding.large + Appearance.padding.normal / 2

                asynchronous: true
                sourceComponent: audioLeftContentComponent
            }
        }

        InnerBorder {
            id: leftAudioBorder
            leftThickness: 0
            rightThickness: Appearance.padding.normal / 2
        }

        Component {
            id: audioLeftContentComponent

            StyledFlickable {
                id: leftAudioFlickable
                flickableDirection: Flickable.VerticalFlick
                contentHeight: leftContent.height

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: leftAudioFlickable
                }

                ColumnLayout {
                    id: leftContent

                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: Appearance.spacing.normal

                // Settings header above the collapsible sections
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.smaller

                    StyledText {
                        text: qsTr("Settings")
                        font.pointSize: Appearance.font.size.large
                        font.weight: 500
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }

                CollapsibleSection {
                    id: outputDevicesSection

                    Layout.fillWidth: true
                    title: qsTr("Output devices")
                    expanded: true

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.small

                            StyledText {
                                text: qsTr("Devices (%1)").arg(Audio.sinks.length)
                                font.pointSize: Appearance.font.size.normal
                                font.weight: 500
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("All available output devices")
                            color: Colours.palette.m3outline
                        }

                        Repeater {
                            Layout.fillWidth: true
                            model: Audio.sinks

                            delegate: StyledRect {
                                required property var modelData

                                Layout.fillWidth: true

                                color: Audio.sink?.id === modelData.id ? Colours.layer(Colours.palette.m3surfaceContainer, 2) : "transparent"
                                radius: Appearance.rounding.normal

                                StateLayer {
                                    function onClicked(): void {
                                        Audio.setAudioSink(modelData);
                                    }
                                }

                                RowLayout {
                                    id: outputRowLayout

                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.margins: Appearance.padding.normal

                                    spacing: Appearance.spacing.normal

                                    MaterialIcon {
                                        text: Audio.sink?.id === modelData.id ? "speaker" : "speaker_group"
                                        font.pointSize: Appearance.font.size.large
                                        fill: Audio.sink?.id === modelData.id ? 1 : 0
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        maximumLineCount: 1

                                        text: modelData.description || qsTr("Unknown")
                                        font.weight: Audio.sink?.id === modelData.id ? 500 : 400
                                    }
                                }

                                implicitHeight: outputRowLayout.implicitHeight + Appearance.padding.normal * 2
                            }
                        }
                    }
                }

                CollapsibleSection {
                    id: inputDevicesSection

                    Layout.fillWidth: true
                    title: qsTr("Input devices")
                    expanded: true

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.small

                            StyledText {
                                text: qsTr("Devices (%1)").arg(Audio.sources.length)
                                font.pointSize: Appearance.font.size.normal
                                font.weight: 500
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("All available input devices")
                            color: Colours.palette.m3outline
                        }

                        Repeater {
                            Layout.fillWidth: true
                            model: Audio.sources

                            delegate: StyledRect {
                                required property var modelData

                                Layout.fillWidth: true

                                color: Audio.source?.id === modelData.id ? Colours.layer(Colours.palette.m3surfaceContainer, 2) : "transparent"
                                radius: Appearance.rounding.normal

                                StateLayer {
                                    function onClicked(): void {
                                        Audio.setAudioSource(modelData);
                                    }
                                }

                                RowLayout {
                                    id: inputRowLayout

                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.margins: Appearance.padding.normal

                                    spacing: Appearance.spacing.normal

                                    MaterialIcon {
                                        text: "mic"
                                        font.pointSize: Appearance.font.size.large
                                        fill: Audio.source?.id === modelData.id ? 1 : 0
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        maximumLineCount: 1

                                        text: modelData.description || qsTr("Unknown")
                                        font.weight: Audio.source?.id === modelData.id ? 500 : 400
                                    }
                                }

                                implicitHeight: inputRowLayout.implicitHeight + Appearance.padding.normal * 2
                            }
                        }
                    }
                }
            }
            }
        }
    }

    Item {
        id: rightAudioItem
        Layout.fillWidth: true
        Layout.fillHeight: true

        ClippingRectangle {
            id: rightAudioClippingRect
            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            anchors.leftMargin: 0
            anchors.rightMargin: Appearance.padding.normal / 2

            radius: rightAudioBorder.innerRadius
            color: "transparent"

            Loader {
                id: rightAudioLoader

                anchors.fill: parent
                anchors.topMargin: Appearance.padding.large * 2
                anchors.bottomMargin: Appearance.padding.large * 2
                anchors.leftMargin: 0
                anchors.rightMargin: 0

                asynchronous: true
                sourceComponent: audioRightContentComponent
            }
        }

        InnerBorder {
            id: rightAudioBorder
            leftThickness: Appearance.padding.normal / 2
        }

        Component {
            id: audioRightContentComponent

            StyledFlickable {
                id: rightAudioFlickable
                flickableDirection: Flickable.VerticalFlick
                contentHeight: contentLayout.height

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: rightAudioFlickable
                }

                ColumnLayout {
                    id: contentLayout

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: Appearance.padding.large * 2
                    anchors.rightMargin: Appearance.padding.large * 2
                    spacing: Appearance.spacing.normal

                ConnectionHeader {
                    icon: "volume_up"
                    title: qsTr("Audio Settings")
                }

                SectionHeader {
                    title: qsTr("Output volume")
                    description: qsTr("Control the volume of your output device")
                }

                SectionContainer {
                    contentSpacing: Appearance.spacing.normal

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.normal

                            StyledText {
                                text: qsTr("Volume")
                                font.pointSize: Appearance.font.size.normal
                                font.weight: 500
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            StyledRect {
                                Layout.preferredWidth: 70
                                implicitHeight: outputVolumeInput.implicitHeight + Appearance.padding.small * 2
                                color: outputVolumeInputHover.containsMouse || outputVolumeInput.activeFocus 
                                       ? Colours.layer(Colours.palette.m3surfaceContainer, 3)
                                       : Colours.layer(Colours.palette.m3surfaceContainer, 2)
                                radius: Appearance.rounding.small
                                border.width: 1
                                border.color: outputVolumeInput.activeFocus 
                                              ? Colours.palette.m3primary
                                              : Qt.alpha(Colours.palette.m3outline, 0.3)
                                enabled: !Audio.muted
                                opacity: enabled ? 1 : 0.5

                                Behavior on color { CAnim {} }
                                Behavior on border.color { CAnim {} }

                                MouseArea {
                                    id: outputVolumeInputHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.IBeamCursor
                                    acceptedButtons: Qt.NoButton
                                }

                                StyledTextField {
                                    id: outputVolumeInput
                                    anchors.centerIn: parent
                                    width: parent.width - Appearance.padding.normal
                                    horizontalAlignment: TextInput.AlignHCenter
                                    validator: IntValidator { bottom: 0; top: 100 }
                                    enabled: !Audio.muted
                                    
                                    Component.onCompleted: {
                                        text = Math.round(Audio.volume * 100).toString();
                                    }
                                    
                                    Connections {
                                        target: Audio
                                        function onVolumeChanged() {
                                            if (!outputVolumeInput.activeFocus) {
                                                outputVolumeInput.text = Math.round(Audio.volume * 100).toString();
                                            }
                                        }
                                    }
                                    
                                    onTextChanged: {
                                        if (activeFocus) {
                                            const val = parseInt(text);
                                            if (!isNaN(val) && val >= 0 && val <= 100) {
                                                Audio.setVolume(val / 100);
                                            }
                                        }
                                    }
                                    onEditingFinished: {
                                        const val = parseInt(text);
                                        if (isNaN(val) || val < 0 || val > 100) {
                                            text = Math.round(Audio.volume * 100).toString();
                                        }
                                    }
                                }
                            }

                            StyledText {
                                text: "%"
                                color: Colours.palette.m3outline
                                font.pointSize: Appearance.font.size.normal
                                opacity: Audio.muted ? 0.5 : 1
                            }

                            StyledRect {
                                implicitWidth: implicitHeight
                                implicitHeight: muteIcon.implicitHeight + Appearance.padding.normal * 2

                                radius: Appearance.rounding.normal
                                color: Audio.muted ? Colours.palette.m3secondary : Colours.palette.m3secondaryContainer

                                StateLayer {
                                    function onClicked(): void {
                                        if (Audio.sink?.audio) {
                                            Audio.sink.audio.muted = !Audio.sink.audio.muted;
                                        }
                                    }
                                }

                                MaterialIcon {
                                    id: muteIcon

                                    anchors.centerIn: parent
                                    text: Audio.muted ? "volume_off" : "volume_up"
                                    color: Audio.muted ? Colours.palette.m3onSecondary : Colours.palette.m3onSecondaryContainer
                                }
                            }
                        }

                        StyledSlider {
                            id: outputVolumeSlider
                            Layout.fillWidth: true
                            implicitHeight: Appearance.padding.normal * 3

                            value: Audio.volume
                            enabled: !Audio.muted
                            opacity: enabled ? 1 : 0.5
                            onMoved: {
                                Audio.setVolume(value);
                                if (!outputVolumeInput.activeFocus) {
                                    outputVolumeInput.text = Math.round(value * 100).toString();
                                }
                            }
                        }
                    }
                }

                SectionHeader {
                    title: qsTr("Input volume")
                    description: qsTr("Control the volume of your input device")
                }

                SectionContainer {
                    contentSpacing: Appearance.spacing.normal

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.normal

                            StyledText {
                                text: qsTr("Volume")
                                font.pointSize: Appearance.font.size.normal
                                font.weight: 500
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            StyledRect {
                                Layout.preferredWidth: 70
                                implicitHeight: inputVolumeInput.implicitHeight + Appearance.padding.small * 2
                                color: inputVolumeInputHover.containsMouse || inputVolumeInput.activeFocus 
                                       ? Colours.layer(Colours.palette.m3surfaceContainer, 3)
                                       : Colours.layer(Colours.palette.m3surfaceContainer, 2)
                                radius: Appearance.rounding.small
                                border.width: 1
                                border.color: inputVolumeInput.activeFocus 
                                              ? Colours.palette.m3primary
                                              : Qt.alpha(Colours.palette.m3outline, 0.3)
                                enabled: !Audio.sourceMuted
                                opacity: enabled ? 1 : 0.5

                                Behavior on color { CAnim {} }
                                Behavior on border.color { CAnim {} }

                                MouseArea {
                                    id: inputVolumeInputHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.IBeamCursor
                                    acceptedButtons: Qt.NoButton
                                }

                                StyledTextField {
                                    id: inputVolumeInput
                                    anchors.centerIn: parent
                                    width: parent.width - Appearance.padding.normal
                                    horizontalAlignment: TextInput.AlignHCenter
                                    validator: IntValidator { bottom: 0; top: 100 }
                                    enabled: !Audio.sourceMuted
                                    
                                    Component.onCompleted: {
                                        text = Math.round(Audio.sourceVolume * 100).toString();
                                    }
                                    
                                    Connections {
                                        target: Audio
                                        function onSourceVolumeChanged() {
                                            if (!inputVolumeInput.activeFocus) {
                                                inputVolumeInput.text = Math.round(Audio.sourceVolume * 100).toString();
                                            }
                                        }
                                    }
                                    
                                    onTextChanged: {
                                        if (activeFocus) {
                                            const val = parseInt(text);
                                            if (!isNaN(val) && val >= 0 && val <= 100) {
                                                Audio.setSourceVolume(val / 100);
                                            }
                                        }
                                    }
                                    onEditingFinished: {
                                        const val = parseInt(text);
                                        if (isNaN(val) || val < 0 || val > 100) {
                                            text = Math.round(Audio.sourceVolume * 100).toString();
                                        }
                                    }
                                }
                            }

                            StyledText {
                                text: "%"
                                color: Colours.palette.m3outline
                                font.pointSize: Appearance.font.size.normal
                                opacity: Audio.sourceMuted ? 0.5 : 1
                            }

                            StyledRect {
                                implicitWidth: implicitHeight
                                implicitHeight: muteInputIcon.implicitHeight + Appearance.padding.normal * 2

                                radius: Appearance.rounding.normal
                                color: Audio.sourceMuted ? Colours.palette.m3secondary : Colours.palette.m3secondaryContainer

                                StateLayer {
                                    function onClicked(): void {
                                        if (Audio.source?.audio) {
                                            Audio.source.audio.muted = !Audio.source.audio.muted;
                                        }
                                    }
                                }

                                MaterialIcon {
                                    id: muteInputIcon

                                    anchors.centerIn: parent
                                    text: "mic_off"
                                    color: Audio.sourceMuted ? Colours.palette.m3onSecondary : Colours.palette.m3onSecondaryContainer
                                }
                            }
                        }

                        StyledSlider {
                            id: inputVolumeSlider
                            Layout.fillWidth: true
                            implicitHeight: Appearance.padding.normal * 3

                            value: Audio.sourceVolume
                            enabled: !Audio.sourceMuted
                            opacity: enabled ? 1 : 0.5
                            onMoved: {
                                Audio.setSourceVolume(value);
                                if (!inputVolumeInput.activeFocus) {
                                    inputVolumeInput.text = Math.round(value * 100).toString();
                                }
                            }
                        }
                    }
                }
            }
            }
        }
    }
}