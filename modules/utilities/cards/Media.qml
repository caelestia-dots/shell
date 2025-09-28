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
    onTabIndexChanged: tabSwitch.restart()

    property var screenshotMenuItems
    property var recordingMenuItems

    Component.onCompleted: {
        // Helper to create screenshot items that hold a stable reference to this card
        const mkShot = (icon, text, activeText, cmdArray) => {
            const qml = 'import qs.components.controls; MenuItem { property var mediaRoot; icon: "' + icon + '"; text: qsTr("' + text + '"); activeText: qsTr("' + activeText + '"); onClicked: { if (mediaRoot && mediaRoot.triggerShot) mediaRoot.triggerShot(' + JSON.stringify(cmdArray) + ') } }';
            const item = Qt.createQmlObject(qml, root);
            item.mediaRoot = root;
            return item;
        }
        screenshotMenuItems = [
            mkShot("crop_free", "Area (edit)", "Area", ["caelestia", "shell", "picker", "openFreeze"]),
            mkShot("web_asset", "Active window (edit)", "Window", ["caelestia", "shell", "picker", "open"])
        ]

        // Helper to create recording items that call Recorder directly
        const mkRec = (icon, text, activeText, args) => {
            const call = args ? 'Recorder.start(' + JSON.stringify(args) + ')' : 'Recorder.start()';
            const qml = 'import qs.components.controls; import qs.services; MenuItem { icon: "' + icon + '"; text: qsTr("' + text + '"); activeText: qsTr("' + activeText + '"); onClicked: { ' + call + ' } }';
            return Qt.createQmlObject(qml, root);
        }
        recordingMenuItems = [
            mkRec("fullscreen", "Record fullscreen", "Fullscreen", null),
            mkRec("screenshot_region", "Record region", "Region", ["-r"]),
            mkRec("select_to_speak", "Record fullscreen with sound", "Fullscreen", ["-s"]),
            mkRec("volume_up", "Record region with sound", "Region", ["-sr"])
        ]
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Appearance.padding.large
        spacing: Appearance.spacing.normal

        // Header: two icon chips (tabs) + contextual actions on the right
        RowLayout {
            spacing: Appearance.spacing.normal
            z: 1

            // Screenshot chip (acts as tab toggle)
            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: {
                    const h = shotIcon.implicitHeight + Appearance.padding.smaller * 2;
                    return h - (h % 2);
                }
                radius: Appearance.rounding.full
                color: root.tabIndex === 0 ? Colours.palette.m3secondaryContainer : Colours.layer(Colours.palette.m3surfaceContainerHigh, 1)

                MaterialIcon {
                    id: shotIcon
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: -0.5
                    anchors.verticalCenterOffset: 1.5
                    text: "screenshot_monitor"
                    color: root.tabIndex === 0 ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.large
                }

                CustomMouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { root.tabIndex = 0; root.props.utilitiesMediaTab = 0 }
                }
            }

            // Recording chip (acts as tab toggle)
            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: {
                    const h = recIcon.implicitHeight + Appearance.padding.smaller * 2;
                    return h - (h % 2);
                }
                radius: Appearance.rounding.full
                color: root.tabIndex === 1
                       ? (Recorder.running ? Colours.palette.m3secondary : Colours.palette.m3secondaryContainer)
                       : Colours.layer(Colours.palette.m3surfaceContainerHigh, 1)

                MaterialIcon {
                    id: recIcon
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: -0.5
                    anchors.verticalCenterOffset: 1.5
                    text: "screen_record"
                    color: root.tabIndex === 1
                           ? (Recorder.running ? Colours.palette.m3onSecondary : Colours.palette.m3onSecondaryContainer)
                           : Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.large
                }

                CustomMouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { root.tabIndex = 1; root.props.utilitiesMediaTab = 1 }
                }
            }

            Item { Layout.fillWidth: true }

            // Contextual action area (SplitButton)
            SplitButton {
                Layout.leftMargin: Appearance.spacing.normal
                z: 2
                disabled: root.tabIndex === 1 && Recorder.running
                active: root.tabIndex === 0 ? (screenshotMenuItems.find(m => root.props.screenshotMode === m.icon + m.text) ?? screenshotMenuItems[0]) : (recordingMenuItems.find(m => root.props.recordingMode === m.icon + m.text) ?? recordingMenuItems[0])
                menuItems: root.tabIndex === 0 ? screenshotMenuItems : recordingMenuItems
                menu.onItemSelected: item => root.tabIndex === 0 ? root.props.screenshotMode = item.icon + item.text : root.props.recordingMode = item.icon + item.text
                stateLayer.disabled: false
            }
        }

        // Body: cross-fade between bodies and animate height smoothly
        Item {
            id: body
            Layout.fillWidth: true
            // Start at the active body's height; animation sequence will adjust when switching
            Layout.preferredHeight: root.tabIndex === 0 ? shotsBody.implicitHeight : recsBody.implicitHeight

            // Screenshots
            Loader {
                id: shotsBody
                anchors.fill: parent
                active: true
                visible: root.tabIndex === 0
                opacity: visible ? 1 : 0
                scale: visible ? 1 : 0.9
                transformOrigin: Item.Top
                sourceComponent: screenshotList

                Behavior on opacity { Anim { duration: 250; easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial } }
                Behavior on scale { Anim { duration: 250; easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial } }
            }

            // Recordings container: keep both sub-bodies alive and cross-fade
            Item {
                id: recsBody
                anchors.fill: parent
                visible: root.tabIndex === 1
                opacity: visible ? 1 : 0
                scale: visible ? 1 : 0.9
                transformOrigin: Item.Top
                implicitHeight: Math.max(recListLoader.implicitHeight || 0, recCtlLoader.implicitHeight || 0)

                // Recording list
                Loader {
                    id: recListLoader
                    anchors.fill: parent
                    active: true
                    visible: !Recorder.running
                    opacity: visible ? 1 : 0
                    scale: visible ? 1 : 0.9
                    transformOrigin: Item.Top
                    sourceComponent: recordingList

                    Behavior on opacity { Anim { duration: 250; easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial } }
                    Behavior on scale { Anim { duration: 250; easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial } }
                }

                // Recording controls
                Loader {
                    id: recCtlLoader
                    anchors.fill: parent
                    active: true
                    visible: Recorder.running
                    opacity: visible ? 1 : 0
                    scale: visible ? 1 : 0.9
                    transformOrigin: Item.Top
                    sourceComponent: recordingControls

                    Behavior on opacity { Anim { duration: 250; easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial } }
                    Behavior on scale { Anim { duration: 250; easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial } }
                }

                Behavior on opacity { Anim { duration: 250; easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial } }
                Behavior on scale { Anim { duration: 250; easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial } }
            }
            Behavior on Layout.preferredHeight { Anim {} }
        }
    }

    // --- Bodies ---
    Component {
        id: screenshotList

        MediaList {
            props: root.props
            visibilities: root.visibilities
            title: "Screenshots"
            path: Paths.shotsdir
            nameFilters: ["screenshot_*.png"]
            firstIcon: "photo_library"
            firstApp: Config.general.apps.image
            textPrefix: "Screenshot"
            expandedProp: "mediaListExpanded"
        }
    }

    Component {
        id: recordingList

        MediaList {
            props: root.props
            visibilities: root.visibilities
            title: "Recordings"
            path: Paths.recsdir
            nameFilters: ["recording_*.mp4"]
            firstIcon: "play_arrow"
            firstApp: Config.general.apps.playback
            textPrefix: "Recording"
            expandedProp: "mediaListExpanded"
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

    // Helper so dynamically-created MenuItems can trigger with a delay
    function triggerShot(cmd) {
        root.visibilities.utilities = false;
        root.visibilities.sidebar = false;
        root.pendingCommand = cmd;
        delayTimer.restart();
    }

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

    // Smooth switch: animate height, then change visibility to trigger opacity/scale animations.
    SequentialAnimation {
        id: tabSwitch
        running: false
        alwaysRunToEnd: true

        // Animate container height to the active body's height
        Anim { target: body; property: "Layout.preferredHeight"; to: root.tabIndex === 0 ? shotsBody.implicitHeight : recsBody.implicitHeight; duration: 200; easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial }

        onStopped: {
            shotsBody.visible = root.tabIndex === 0;
            recsBody.visible = root.tabIndex === 1;
        }
    }
}
