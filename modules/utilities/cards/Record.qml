pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    required property var props
    required property ScreenState screenState
    readonly property real nonAnimHeight: btnLayout.implicitHeight + listOrControls.implicitHeight + layout.spacing + layout.anchors.margins * 2

    readonly property bool recordingBusy: Recorder.running || Recorder.starting
    property string lastError: ""
    readonly property string currentVideoMode: GlobalConfig.utilities?.recording?.videoMode ?? "fullscreen"

    // Parallel to the split button's menu items
    readonly property list<string> videoModes: ["fullscreen", "region", "window"]

    // gpu-screen-recorder takes one audio argument, so the two switches collapse
    // into a single mode
    readonly property string currentAudioMode: {
        const recordSystem = GlobalConfig.utilities?.recording?.recordSystem ?? true;
        const recordMic = GlobalConfig.utilities?.recording?.recordMicrophone ?? false;
        if (recordSystem && recordMic)
            return "combined";
        if (recordSystem)
            return "system";
        if (recordMic)
            return "mic";
        return "none";
    }

    function setVideoMode(mode: string): void {
        if (GlobalConfig.utilities?.recording) {
            GlobalConfig.utilities.recording.videoMode = mode;
            GlobalConfig.save();
        }
    }

    function startRecording(mode: string): void {
        root.setVideoMode(mode);
        Recorder.start(mode, root.currentAudioMode);
    }

    function startingText(mode: string): string {
        return qsTr("Starting %1...").arg(root.videoModeLabel(mode));
    }

    function videoModeLabel(mode: string): string {
        if (mode === "fullscreen")
            return qsTr("fullscreen");
        if (mode === "region")
            return qsTr("region");
        if (mode === "window")
            return qsTr("window");
        return mode;
    }

    function audioModeLabel(mode: string): string {
        if (mode === "combined")
            return qsTr("system + mic");
        if (mode === "system")
            return qsTr("system audio");
        if (mode === "mic")
            return qsTr("microphone");
        return qsTr("no audio");
    }

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + layout.anchors.margins * 2

    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer

    Connections {
        function onErrorOccurred(errorMsg: string): void {
            root.lastError = errorMsg;
        }

        function onRecordingStarted(): void {
            root.lastError = "";
        }

        target: Recorder
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        RowLayout {
            id: btnLayout

            spacing: Tokens.spacing.medium

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: {
                    const h = icon.implicitHeight + Tokens.padding.small * 2;
                    return h - (h % 2);
                }

                radius: Tokens.rounding.full
                color: root.recordingBusy ? Colours.palette.m3secondary : Colours.palette.m3secondaryContainer

                MaterialIcon {
                    id: icon

                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 1
                    text: "screen_record"
                    color: Recorder.running ? Colours.palette.m3onSecondary : Colours.palette.m3onSecondaryContainer
                    fontStyle: Tokens.font.icon.large
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Screen Recorder")
                    font: Tokens.font.body.medium
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: {
                        if (root.lastError !== "")
                            return qsTr("Error: %1").arg(root.lastError);
                        if (Recorder.starting)
                            return root.startingText(Recorder.videoMode || root.currentVideoMode);
                        if (Recorder.paused)
                            return qsTr("Recording paused");
                        if (Recorder.running) {
                            const videoText = root.videoModeLabel(Recorder.videoMode || root.currentVideoMode);
                            const audioText = root.audioModeLabel(Recorder.audioMode || root.currentAudioMode);
                            return qsTr("Recording %1 with %2").arg(videoText).arg(audioText);
                        }
                        return qsTr("Recording off");
                    }
                    color: root.lastError !== "" ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                    animate: true
                }
            }

            SplitButton {
                disabled: root.recordingBusy
                active: menuItems[root.videoModes.indexOf(root.currentVideoMode)] ?? menuItems[0]
                menu.onItemSelected: item => {
                    const idx = menuItems.indexOf(item);
                    if (idx >= 0)
                        root.setVideoMode(root.videoModes[idx]);
                }

                menuItems: [
                    MenuItem {
                        icon: "fullscreen"
                        text: qsTr("Record fullscreen")
                        activeText: qsTr("Fullscreen")
                        onClicked: root.startRecording("fullscreen")
                    },
                    MenuItem {
                        icon: "screenshot_region"
                        text: qsTr("Record region")
                        activeText: qsTr("Region")
                        onClicked: root.startRecording("region")
                    },
                    MenuItem {
                        icon: "web_asset"
                        text: qsTr("Record window")
                        activeText: qsTr("Window")
                        onClicked: root.startRecording("window")
                    }
                ]
            }
        }

        StyledRect {
            Layout.fillWidth: true

            visible: root.lastError !== ""
            implicitHeight: visible ? errorText.implicitHeight + Tokens.padding.medium * 2 : 0
            radius: Tokens.rounding.small
            color: Colours.palette.m3errorContainer

            StyledText {
                id: errorText

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                text: root.lastError
                color: Colours.palette.m3onErrorContainer
                wrapMode: Text.Wrap
                font: Tokens.font.body.small
            }

            Behavior on implicitHeight {
                Anim {
                    duration: Tokens.anim.durations.small
                }
            }
        }

        // Audio Sources Section
        ColumnLayout {
            Layout.fillWidth: true
            visible: !root.recordingBusy
            spacing: Tokens.spacing.small

            RowLayout {
                spacing: Tokens.spacing.small

                StyledText {
                    text: qsTr("Audio Sources")
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }

                Item {
                    Layout.fillWidth: true
                }

                IconButton {
                    icon: root.props.recordingAudioExpanded ? "unfold_less" : "unfold_more"
                    type: IconButton.Text
                    label.animate: true
                    onClicked: {
                        root.props.recordingAudioExpanded = !root.props.recordingAudioExpanded;
                    }
                }
            }

            Item {
                id: audioSourcesContainer

                Layout.fillWidth: true
                Layout.preferredHeight: root.props.recordingAudioExpanded ? audioSourcesLayout.implicitHeight : 0
                clip: true
                enabled: root.props.recordingAudioExpanded
                opacity: root.props.recordingAudioExpanded ? 1 : 0
                visible: root.props.recordingAudioExpanded || height > 0

                ColumnLayout {
                    id: audioSourcesLayout

                    width: parent.width
                    y: root.props.recordingAudioExpanded ? 0 : -Tokens.spacing.small
                    spacing: Tokens.spacing.extraSmall

                    // System Audio (Default Sink)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.medium

                        StyledSwitch {
                            checked: GlobalConfig.utilities?.recording?.recordSystem ?? true
                            onToggled: {
                                if (GlobalConfig.utilities?.recording) {
                                    GlobalConfig.utilities.recording.recordSystem = checked;
                                    GlobalConfig.save();
                                }
                            }
                        }

                        StyledText {
                            Layout.preferredWidth: 85
                            text: qsTr("System")
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }

                        StyledSlider {
                            Layout.fillWidth: true

                            implicitHeight: 24
                            opacity: (GlobalConfig.utilities?.recording?.recordSystem ?? true) ? 1.0 : 0.5
                            from: 0
                            to: 1
                            value: Audio.volume
                            onMoved: Audio.setVolume(value)
                        }

                        StyledText {
                            text: Math.round(Audio.volume * 100) + "%"
                            font: Tokens.font.body.small
                            color: Colours.palette.m3onSurfaceVariant
                            Layout.preferredWidth: 40
                        }

                        IconButton {
                            icon: Audio.muted ? "volume_off" : "volume_up"
                            type: Audio.muted ? IconButton.Filled : IconButton.Tonal
                            font: Tokens.font.icon.small
                            onClicked: {
                                if (Audio.sink?.audio)
                                    Audio.sink.audio.muted = !Audio.sink.audio.muted;
                            }
                        }
                    }

                    // Microphone (Default Source)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.medium

                        StyledSwitch {
                            checked: GlobalConfig.utilities?.recording?.recordMicrophone ?? false
                            onToggled: {
                                if (GlobalConfig.utilities?.recording) {
                                    GlobalConfig.utilities.recording.recordMicrophone = checked;
                                    GlobalConfig.save();
                                }
                            }
                        }

                        StyledText {
                            Layout.preferredWidth: 85
                            text: qsTr("Microphone")
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }

                        StyledSlider {
                            Layout.fillWidth: true

                            implicitHeight: 24
                            opacity: (GlobalConfig.utilities?.recording?.recordMicrophone ?? false) ? 1.0 : 0.5
                            from: 0
                            to: 1
                            value: Audio.sourceVolume
                            onMoved: Audio.setSourceVolume(value)
                        }

                        StyledText {
                            text: Math.round(Audio.sourceVolume * 100) + "%"
                            font: Tokens.font.body.small
                            color: Colours.palette.m3onSurfaceVariant
                            Layout.preferredWidth: 40
                        }

                        IconButton {
                            icon: Audio.sourceMuted ? "mic_off" : "mic"
                            type: Audio.sourceMuted ? IconButton.Filled : IconButton.Tonal
                            font: Tokens.font.icon.small
                            onClicked: {
                                if (Audio.source?.audio)
                                    Audio.source.audio.muted = !Audio.source.audio.muted;
                            }
                        }
                    }

                    Behavior on y {
                        Anim {
                            duration: Tokens.anim.durations.small
                        }
                    }
                }

                Behavior on Layout.preferredHeight {
                    Anim {
                        type: Anim.DefaultSpatial
                    }
                }

                Behavior on opacity {
                    Anim {
                        duration: Tokens.anim.durations.small
                    }
                }
            }
        }

        Loader {
            id: listOrControls

            property bool running: root.recordingBusy

            asynchronous: true
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            sourceComponent: running ? recordingControls : recordingList
            clip: Layout.preferredHeight < implicitHeight

            Behavior on Layout.preferredHeight {
                id: locHeightAnim

                enabled: false

                Anim {}
            }

            Behavior on running {
                SequentialAnimation {
                    Anim {
                        target: listOrControls
                        property: "opacity"
                        to: 0
                        type: Anim.DefaultEffects
                    }
                    PropertyAction {
                        target: locHeightAnim
                        property: "enabled"
                        value: true
                    }
                    PropertyAction {}
                    ParallelAnimation {
                        SequentialAnimation {
                            PauseAnimation {
                                duration: 100
                            }
                            PropertyAction {
                                target: locHeightAnim
                                property: "enabled"
                                value: false
                            }
                        }
                        Anim {
                            target: listOrControls
                            property: "opacity"
                            to: 1
                            type: Anim.SlowEffects
                        }
                    }
                }
            }
        }
    }

    Component {
        id: recordingList

        RecordingList {
            props: root.props
            screenState: root.screenState
        }
    }

    Component {
        id: recordingControls

        RowLayout {
            spacing: Tokens.spacing.medium

            StyledRect {
                radius: Tokens.rounding.full
                color: Recorder.starting ? Colours.palette.m3secondary : Recorder.paused ? Colours.palette.m3tertiary : Colours.palette.m3error

                implicitWidth: recText.implicitWidth + Tokens.padding.medium * 2
                implicitHeight: recText.implicitHeight + Tokens.padding.large

                StyledText {
                    id: recText

                    anchors.centerIn: parent
                    animate: true
                    text: Recorder.paused ? "PAUSED" : "REC"
                    color: Recorder.paused ? Colours.palette.m3onTertiary : Colours.palette.m3onError
                    font: Tokens.font.mono.small
                }

                Behavior on implicitWidth {
                    Anim {}
                }

                SequentialAnimation on opacity {
                    running: !Recorder.starting && !Recorder.paused && Recorder.running
                    alwaysRunToEnd: true
                    loops: Animation.Infinite

                    Anim {
                        from: 1
                        to: 0
                        duration: Tokens.anim.durations.large
                        easing: Tokens.anim.emphasizedAccel
                    }
                    Anim {
                        from: 0
                        to: 1
                        duration: Tokens.anim.durations.extraLarge
                        easing: Tokens.anim.emphasizedDecel
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: {
                    if (Recorder.starting)
                        return root.startingText(Recorder.videoMode || root.currentVideoMode);
                    const elapsed = Recorder.elapsed;
                    const hours = Math.floor(elapsed / 3600);
                    const mins = Math.floor((elapsed % 3600) / 60);
                    const secs = Math.floor(elapsed % 60).toString().padStart(2, "0");
                    let time;
                    if (hours > 0)
                        time = `${hours}:${mins.toString().padStart(2, "0")}:${secs}`;
                    else
                        time = `${mins}:${secs}`;
                    return qsTr("Recording for %1").arg(time);
                }
                font: Tokens.font.body.medium
                elide: Text.ElideMiddle
            }

            ButtonRow {
                spacing: Tokens.spacing.extraSmall

                IconButton {
                    icon: Recorder.paused ? "play_arrow" : "pause"
                    isToggle: true
                    checked: Recorder.paused
                    type: IconButton.Tonal
                    font: Tokens.font.icon.large
                    onClicked: {
                        Recorder.togglePause();
                        internalChecked = Recorder.paused;
                    }
                }

                IconButton {
                    icon: "stop"
                    inactiveColour: Colours.palette.m3error
                    inactiveOnColour: Colours.palette.m3onError
                    font: Tokens.font.icon.large
                    onClicked: Recorder.stop()
                }
            }
        }
    }
}
