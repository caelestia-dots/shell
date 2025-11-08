pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.services
import qs.config
import qs.utils
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects

RowLayout {
    id: root

    anchors.fill: parent
    spacing: 0

    Item {
        Layout.preferredWidth: parent.width * 0.5
        Layout.minimumWidth: 420
        Layout.fillHeight: true

        ColumnLayout {
            id: outputColumn
            anchors.fill: parent
            anchors.margins: Appearance.padding.large + Appearance.padding.normal
            anchors.leftMargin: Appearance.padding.large
            anchors.rightMargin: Appearance.padding.large + Appearance.padding.normal / 2
            spacing: Appearance.spacing.large

            StyledText {
                text: qsTr("Output")
                font.pointSize: Appearance.font.size.large
                font.weight: 500
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small
                RowLayout {
                    anchors.left: outputColumn.left
                    anchors.right: outputColumn.right
                    spacing: Appearance.spacing.large
                    StyledText {
                        Layout.alignment: Qt.AlignVCenter
                        text: qsTr("Main Output")
                    }
                    StyledSelect {
                        Layout.fillWidth: true
                        items: Audio.sinks.map(e => e.description)
                        defIndex: Audio.sinks.indexOf(Audio.sink)

                        onOptionClicked: (index) => Audio.setAudioSink(Audio.sinks[index])
                    }
                }
                RowLayout {
                    anchors.left: outputColumn.left
                    anchors.right: outputColumn.right
                    spacing: Appearance.spacing.smaller
                    // mute button
                    IconButton {
                        Layout.preferredWidth: implicitWidth
                        Layout.preferredHeight: Appearance.padding.normal * 3

                        icon: Icons.getVolumeIcon(Audio.sink.audio.volume, Audio.sink.audio.muted)
                        checked: Audio.sink.audio.muted
                        radius: Appearance.rounding.normal
                        activeColour: Colours.palette.m3errorContainer 
                        inactiveColour: Colours.palette.m3primaryContainer
                        activeOnColour: Colours.palette.m3onErrorContainer
                        inactiveOnColour: Colours.palette.m3onPrimaryContainer
                        toggle: true
                        radiusAnim.duration: Appearance.anim.durations.expressiveFastSpatial
                        radiusAnim.easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                        onClicked: {
                            if (Audio.sink.ready && Audio.sink.audio) {
                                Audio.sink.audio.muted = !Audio.sink.audio.muted;
                            }
                        }
                        Behavior on Layout.preferredWidth {
                            Anim {
                                duration: Appearance.anim.durations.expressiveFastSpatial
                                easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                            }
                        }
                    }
                    // slider
                    CustomMouseArea {
                        Layout.fillWidth: true
                        implicitHeight: Appearance.padding.normal * 3

                        onWheel: event => {
                            if (event.angleDelta.y > 0)
                                Audio.incrementVolume();
                            else if (event.angleDelta.y < 0)
                                Audio.decrementVolume();
                        }

                        StyledSlider {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            implicitHeight: parent.implicitHeight

                            type: Audio.sink.audio.muted ? StyledSlider.SliderType.Error : StyledSlider.SliderType.Default

                            value: Audio.volume
                            onMoved: Audio.setVolume(value)

                            Behavior on value {
                                Anim {}
                            }
                        }
                    }
                    // volume
                    StyledText {
                        id: volumeLevel
                        property string displayText: `${Math.round(Audio.sink.audio.volume * 100)}%`
                        color: Audio.sink.audio.muted ? Colours.palette.m3error : Colours.palette.m3primary
                        opacity: Audio.sink.audio.muted ? 0.6 : 1
                        font.pointSize: Appearance.font.size.normal
                        text: displayText

                        // Set the width of the text to the max width it can get,
                        // so that when values change slider dont change it's when volume text changes size
                        FontMetrics {
                            id: fm
                            font: volumeLevel.font
                        }
                        Component.onCompleted: {
                            const maxWidth = Math.ceil(fm.advanceWidth("100%"));
                            volumeLevel.Layout.minimumWidth = maxWidth
                        }
                        Behavior on opacity {
                            Anim {
                                duration: Appearance.anim.durations.normal
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                spacing: Appearance.spacing.larger

                StyledText {
                    text: qsTr("Programs")
                    font.pointSize: Appearance.font.size.large
                    font.weight: 300
                }
                StyledListView {
                    id: outputList
                    visible: Audio.sinkStreams.length > 0
                    model: Audio.sinkStreams
                    anchors.topMargin: Appearance.spacing.normal
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.larger
                    clip: true

                    StyledScrollBar.vertical: StyledScrollBar {
                        flickable: outputList
                    }

                    delegate: ColumnLayout {
                        required property PwNode modelData
                        anchors.left: outputList.contentItem.left
                        anchors.right: outputList.contentItem.right
                        spacing: Appearance.spacing.smaller / 2

                        // Text
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.smaller
                            IconImage {
                                width: Appearance.padding.smaller * 4
                                height: Appearance.padding.smaller * 4

                                source: Icons.getAppIcon(modelData.name, "image-missing")
                            }
                            StyledText {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                font.pointSize: Appearance.font.size.small
                                text: {
                                    // Copied from https://git.outfoxxed.me/quickshell/quickshell-examples/src/branch/master/mixer
                                    // application.name -> description -> name
                                    const app = modelData.properties["application.name"] ?? (modelData.description != "" ? modelData.description : modelData.name);
                                    let media = modelData.properties["media.name"];
                                    return media != undefined ? `${app}: ${media}` : app;
                                }
                            }
                        }
                        RowLayout {
                            spacing: Appearance.spacing.smaller
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
                            // Slider
                            CustomMouseArea {
                                Layout.fillWidth: true
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

                                    opacity: modelData.audio.muted ? 0.6 : 1
                                    value: modelData.audio.volume
                                    type: modelData.audio.muted ? StyledSlider.SliderType.Error : StyledSlider.SliderType.Default
                                    onMoved: parent.setVolume(value)

                                    Behavior on value {
                                        Anim {}
                                    }
                                    Behavior on opacity {
                                        Anim {
                                            duration: Appearance.anim.durations.normal
                                        }
                                    }
                                }
                            }
                            // Volume Text
                            StyledText {
                                id: volumeLevel
                                property string displayText: `${Math.round(modelData.audio.volume * 100)}%`
                                color: modelData.audio.muted ? Colours.palette.m3error : Colours.palette.m3primary
                                opacity: modelData.audio.muted ? 0.6 : 1
                                font.pointSize: Appearance.font.size.normal
                                text: displayText

                                // Set the width of the text to the max width it can get,
                                // so that when values change slider dont change it's when volume text changes size
                                FontMetrics {
                                    id: fm
                                    font: volumeLevel.font
                                }
                                Component.onCompleted: {
                                    const maxWidth = Math.ceil(fm.advanceWidth("100%"));
                                    volumeLevel.Layout.minimumWidth = maxWidth
                                }
                                Behavior on opacity {
                                    Anim {
                                        duration: Appearance.anim.durations.normal
                                    }
                                }
                            }
                        }
                    }
                }
                StyledText {
                    visible: Audio.sinkStreams.length === 0
                    anchors.topMargin: Appearance.spacing.normal
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    color: Colours.palette.m3outline
                    text: qsTr("No output sources available")
                }
            }
        }

        InnerBorder {
            leftThickness: 0
            rightThickness: Appearance.padding.normal / 2
        }
    }
    Item {
        Layout.preferredWidth: parent.width * 0.5
        Layout.minimumWidth: 420
        Layout.fillHeight: true

        ColumnLayout {
            id: inputColumn
            anchors.fill: parent
            anchors.margins: Appearance.padding.large + Appearance.padding.normal
            anchors.leftMargin: Appearance.padding.large
            anchors.rightMargin: Appearance.padding.large + Appearance.padding.normal / 2
            spacing: Appearance.spacing.large

            StyledText {
                text: qsTr("Input")
                font.pointSize: Appearance.font.size.large
                font.weight: 500
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small
                RowLayout {
                    anchors.left: inputColumn.left
                    anchors.right: inputColumn.right
                    spacing: Appearance.spacing.large
                    StyledText {
                        Layout.alignment: Qt.AlignVCenter
                        text: qsTr("Main Input")
                    }
                    StyledSelect {
                        Layout.fillWidth: true
                        items: Audio.sources.map(e => e.description)
                        defIndex: Audio.sources.indexOf(Audio.source)

                        onOptionClicked: (index) => Audio.setAudioSource(Audio.sources[index])
                    }
                }
                RowLayout {
                    anchors.left: inputColumn.left
                    anchors.right: inputColumn.right
                    spacing: Appearance.spacing.smaller
                    // mute button
                    IconButton {
                        Layout.preferredWidth: implicitWidth
                        Layout.preferredHeight: Appearance.padding.normal * 3

                        icon: Icons.getMicVolumeIcon(Audio.source.audio.volume, Audio.source.audio.muted)
                        checked: Audio.source.audio.muted
                        radius: Appearance.rounding.normal
                        activeColour: Colours.palette.m3errorContainer 
                        inactiveColour: Colours.palette.m3primaryContainer
                        activeOnColour: Colours.palette.m3onErrorContainer
                        inactiveOnColour: Colours.palette.m3onPrimaryContainer
                        toggle: true
                        radiusAnim.duration: Appearance.anim.durations.expressiveFastSpatial
                        radiusAnim.easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                        onClicked: {
                            if (Audio.source.ready && Audio.source.audio) {
                                Audio.source.audio.muted = !Audio.source.audio.muted;
                            }
                        }
                        Behavior on Layout.preferredWidth {
                            Anim {
                                duration: Appearance.anim.durations.expressiveFastSpatial
                                easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                            }
                        }
                    }
                    // slider
                    CustomMouseArea {
                        Layout.fillWidth: true
                        implicitHeight: Appearance.padding.normal * 3

                        onWheel: event => {
                            if (event.angleDelta.y > 0)
                                Audio.incrementSourceVolume();
                            else if (event.angleDelta.y < 0)
                                Audio.decrementSourceVolume();
                        }

                        StyledSlider {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            implicitHeight: parent.implicitHeight

                            type: Audio.source.audio.muted ? StyledSlider.SliderType.Error : StyledSlider.SliderType.Default

                            value: Audio.sourceVolume
                            onMoved: Audio.setSourceVolume(value)

                            Behavior on value {
                                Anim {}
                            }
                        }
                    }
                    // volume
                    StyledText {
                        id: inputVolumeLevel
                        property string displayText: `${Math.round(Audio.source.audio.volume * 100)}%`
                        color: Audio.source.audio.muted ? Colours.palette.m3error : Colours.palette.m3primary
                        opacity: Audio.source.audio.muted ? 0.6 : 1
                        font.pointSize: Appearance.font.size.normal
                        text: displayText

                        // Set the width of the text to the max width it can get,
                        // so that when values change slider dont change it's when volume text changes size
                        FontMetrics {
                            id: inputfm
                            font: inputVolumeLevel.font
                        }
                        Component.onCompleted: {
                            const maxWidth = Math.ceil(inputfm.advanceWidth("100%"));
                            inputVolumeLevel.Layout.minimumWidth = maxWidth
                        }
                        Behavior on opacity {
                            Anim {
                                duration: Appearance.anim.durations.normal
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                spacing: Appearance.spacing.larger

                StyledText {
                    text: qsTr("Programs")
                    font.pointSize: Appearance.font.size.large
                    font.weight: 300
                }
                StyledListView {
                    id: inputList
                    visible: Audio.sourceStreams.length > 0
                    model: Audio.sourceStreams
                    anchors.topMargin: Appearance.spacing.normal
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.larger
                    clip: true

                    StyledScrollBar.vertical: StyledScrollBar {
                        flickable: inputList
                    }

                    delegate: ColumnLayout {
                        required property PwNode modelData
                        anchors.left: inputList.contentItem.left
                        anchors.right: inputList.contentItem.right
                        spacing: Appearance.spacing.smaller / 2

                        // Text
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.smaller
                            IconImage {
                                width: Appearance.padding.smaller * 4
                                height: Appearance.padding.smaller * 4

                                source: Icons.getAppIcon(modelData.name, "image-missing")
                            }
                            StyledText {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                font.pointSize: Appearance.font.size.small
                                text: {
                                    // Copied from https://git.outfoxxed.me/quickshell/quickshell-examples/src/branch/master/mixer
                                    // application.name -> description -> name
                                    const app = modelData.properties["application.name"] ?? (modelData.description != "" ? modelData.description : modelData.name);
                                    let media = modelData.properties["media.name"];
                                    return media != undefined ? `${app}: ${media}` : app;
                                }
                            }
                        }
                        RowLayout {
                            spacing: Appearance.spacing.smaller
                            // mute button
                            IconButton {
                                Layout.preferredWidth: implicitWidth
                                Layout.preferredHeight: Appearance.padding.normal * 3

                                icon: Icons.getMicVolumeIcon(modelData.audio.volume, modelData.audio.muted)
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
                            // Slider
                            CustomMouseArea {
                                Layout.fillWidth: true
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

                                    opacity: modelData.audio.muted ? 0.6 : 1
                                    value: modelData.audio.volume
                                    type: modelData.audio.muted ? StyledSlider.SliderType.Error : StyledSlider.SliderType.Default
                                    onMoved: parent.setVolume(value)

                                    Behavior on value {
                                        Anim {}
                                    }
                                    Behavior on opacity {
                                        Anim {
                                            duration: Appearance.anim.durations.normal
                                        }
                                    }
                                }
                            }
                            // Volume Text
                            StyledText {
                                id: volumeLevel
                                property string displayText: `${Math.round(modelData.audio.volume * 100)}%`
                                color: modelData.audio.muted ? Colours.palette.m3error : Colours.palette.m3primary
                                opacity: modelData.audio.muted ? 0.6 : 1
                                font.pointSize: Appearance.font.size.normal
                                text: displayText

                                // Set the width of the text to the max width it can get,
                                // so that when values change slider dont change it's when volume text changes size
                                FontMetrics {
                                    id: fm
                                    font: volumeLevel.font
                                }
                                Component.onCompleted: {
                                    const maxWidth = Math.ceil(fm.advanceWidth("100%"));
                                    volumeLevel.Layout.minimumWidth = maxWidth
                                }
                                Behavior on opacity {
                                    Anim {
                                        duration: Appearance.anim.durations.normal
                                    }
                                }
                            }
                        }
                    }
                }
                StyledText {
                    visible: Audio.sourceStreams.length === 0
                    anchors.topMargin: Appearance.spacing.normal
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    color: Colours.palette.m3outline
                    text: qsTr("No input sources available")
                }
            }
        }

        InnerBorder {
            id: rightBorder
            leftThickness: Appearance.padding.normal / 2
        }
    }
}
