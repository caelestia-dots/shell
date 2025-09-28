pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import qs.utils
import Quickshell
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    required property var props
    required property var visibilities

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + layout.anchors.margins * 2

    radius: Appearance.rounding.normal
    color: Colours.tPalette.m3surfaceContainer

    // 0 = Screenshots, 1 = Recordings
    property int tabIndex: props.utilitiesMediaTab

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Appearance.padding.large
        spacing: Appearance.spacing.normal

        // Header
        RowLayout {
            spacing: Appearance.spacing.normal
            z: 1

            // Leading icon chip
            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: {
                    const h = icon.implicitHeight + Appearance.padding.smaller * 2;
                    return h - (h % 2);
                }

                radius: Appearance.rounding.full
                color: tabIndex === 1
                       ? (Recorder.running ? Colours.palette.m3secondary : Colours.palette.m3secondaryContainer)
                       : Colours.palette.m3secondaryContainer

                MaterialIcon {
                    id: icon

                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: -0.5
                    anchors.verticalCenterOffset: 1.5
                    text: tabIndex === 0 ? "screenshot_monitor" : "screen_record"
                    color: tabIndex === 1
                           ? (Recorder.running ? Colours.palette.m3onSecondary : Colours.palette.m3onSecondaryContainer)
                           : Colours.palette.m3onSecondaryContainer
                    font.pointSize: Appearance.font.size.large
                }
            }

            // Titles
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: tabIndex === 0 ? qsTr("Screenshots") : qsTr("Screen Recorder")
                    font.pointSize: Appearance.font.size.normal
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: tabIndex === 0
                          ? qsTr("Capture an area or the screen and edit in Swappy")
                          : (Recorder.paused ? qsTr("Recording paused") : Recorder.running ? qsTr("Recording running") : qsTr("Recording off"))
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.small
                    elide: Text.ElideRight
                }
            }

            // Tab selector + contextual action on the right
            RowLayout {
                spacing: Appearance.spacing.small

                // Mini tab selector
                RowLayout {
                    spacing: Appearance.spacing.smaller

                    IconButton {
                        id: tabShots
                        icon: "photo"
                        type: IconButton.Text
                        toggle: true
                        checked: root.tabIndex === 0
                        onClicked: { root.tabIndex = 0; root.props.utilitiesMediaTab = 0 }
                        label.text: qsTr("Shots")
                    }

                    IconButton {
                        id: tabRecs
                        icon: "screen_record"
                        type: IconButton.Text
                        toggle: true
                        checked: root.tabIndex === 1
                        onClicked: { root.tabIndex = 1; root.props.utilitiesMediaTab = 1 }
                        label.text: qsTr("Recs")
                    }
                }

                // Contextual action area
                Loader {
                    Layout.leftMargin: Appearance.spacing.normal
                    sourceComponent: root.tabIndex === 0 ? screenshotActions : recordingActions
                }
            }
        }

        // Body switches between lists/controls
        Loader {
            id: bodyLoader

            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            sourceComponent: root.tabIndex === 0 ? screenshotList : (Recorder.running ? recordingControls : recordingList)

            Behavior on Layout.preferredHeight {
                Anim {}
            }
        }
    }

    // --- Screenshots actions ---
    Component {
        id: screenshotActions

        SplitButton {
            id: screenshotSplit
            z: 2
            disabled: false
            active: menuItems.find(m => root.props.screenshotMode === m.icon + m.text) ?? menuItems[0]
            menu.onItemSelected: item => root.props.screenshotMode = item.icon + item.text
            stateLayer.disabled: false

            menuItems: [
                MenuItem {
                    icon: "screenshot"
                    text: qsTr("Area (edit)")
                    activeText: qsTr("Area")
                    onClicked: {
                        root.visibilities.utilities = false;
                        root.visibilities.sidebar = false;
                        pendingCommand = ["caelestia", "shell", "picker", "openFreeze"];
                        delayTimer.restart();
                    }
                },
                MenuItem {
                    icon: "screenshot_region"
                    text: qsTr("Active window (edit)")
                    activeText: qsTr("Window")
                    onClicked: {
                        root.visibilities.utilities = false;
                        root.visibilities.sidebar = false;
                        pendingCommand = ["caelestia", "shell", "picker", "open"];
                        delayTimer.restart();
                    }
                }
            ]
        }
    }

    // --- Recording actions (when not running) ---
    Component {
        id: recordingActions

        SplitButton {
            disabled: Recorder.running
            active: menuItems.find(m => root.props.recordingMode === m.icon + m.text) ?? menuItems[0]
            menu.onItemSelected: item => root.props.recordingMode = item.icon + item.text

            menuItems: [
                MenuItem { icon: "fullscreen"; text: qsTr("Record fullscreen"); activeText: qsTr("Fullscreen"); onClicked: Recorder.start() },
                MenuItem { icon: "screenshot_region"; text: qsTr("Record region"); activeText: qsTr("Region"); onClicked: Recorder.start(["-r"]) },
                MenuItem { icon: "select_to_speak"; text: qsTr("Record fullscreen with sound"); activeText: qsTr("Fullscreen"); onClicked: Recorder.start(["-s"]) },
                MenuItem { icon: "volume_up"; text: qsTr("Record region with sound"); activeText: qsTr("Region"); onClicked: Recorder.start(["-sr"]) }
            ]
        }
    }

    // --- Bodies ---
    Component {
        id: screenshotList

        ScreenshotList {
            props: root.props
            visibilities: root.visibilities
        }
    }

    Component {
        id: recordingList

        RecordingList {
            props: root.props
            visibilities: root.visibilities
        }
    }

    Component {
        id: recordingControls

        RowLayout {
            spacing: Appearance.spacing.normal

            StyledRect {
                radius: Appearance.rounding.full
                color: Recorder.paused ? Colours.palette.m3tertiary : Colours.palette.m3error

                implicitWidth: recText.implicitWidth + Appearance.padding.normal * 2
                implicitHeight: recText.implicitHeight + Appearance.padding.smaller * 2

                StyledText {
                    id: recText

                    anchors.centerIn: parent
                    animate: true
                    text: Recorder.paused ? "PAUSED" : "REC"
                    color: Recorder.paused ? Colours.palette.m3onTertiary : Colours.palette.m3onError
                    font.family: Appearance.font.family.mono
                }

                Behavior on implicitWidth { Anim {} }

                SequentialAnimation on opacity {
                    running: !Recorder.paused
                    alwaysRunToEnd: true
                    loops: Animation.Infinite

                    Anim { from: 1; to: 0 }
                    Anim { from: 0; to: 1 }
                }
            }

            StyledText {
                text: {
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
                font.pointSize: Appearance.font.size.normal
            }

            Item { Layout.fillWidth: true }

            IconButton {
                label.animate: true
                icon: Recorder.paused ? "play_arrow" : "pause"
                toggle: true
                checked: Recorder.paused
                type: IconButton.Tonal
                font.pointSize: Appearance.font.size.large
                onClicked: {
                    Recorder.togglePause();
                    internalChecked = Recorder.paused;
                }
            }

            IconButton {
                icon: "stop"
                inactiveColour: Colours.palette.m3error
                inactiveOnColour: Colours.palette.m3onError
                font.pointSize: Appearance.font.size.large
                onClicked: Recorder.stop()
            }
        }
    }

    // Delayed launch for screenshot tools
    property var pendingCommand: []

    Timer {
        id: delayTimer
        interval: 300
        running: false
        repeat: false
        onTriggered: {
            if (root.pendingCommand.length > 0) {
                Quickshell.execDetached(root.pendingCommand);
                root.pendingCommand = [];
            }
        }
    }
}
