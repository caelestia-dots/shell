pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Caelestia.Config
import Caelestia.Models
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.utils

ColumnLayout {
    id: root

    required property var props
    required property ScreenState screenState
    property var recordingTimes: ({})

    function reloadRecordingTimes(): void {
        const paths = [];
        for (let i = 0; i < recordingsModel.entries.length; i++)
            paths.push(recordingsModel.entries[i].path);
        if (paths.length === 0) {
            root.recordingTimes = ({});
            return;
        }
        statProc.running = false;
        statProc.command = ["stat", "-c", "%W %Y %n", ...paths];
        statProc.running = true;
    }

    spacing: 0

    WrapperMouseArea {
        Layout.fillWidth: true

        cursorShape: Qt.PointingHandCursor
        onClicked: root.props.recordingListExpanded = !root.props.recordingListExpanded

        RowLayout {
            spacing: Tokens.spacing.medium

            MaterialIcon {
                Layout.alignment: Qt.AlignVCenter
                text: "list"
                fontStyle: Tokens.font.icon.large
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                text: qsTr("Recordings")
                font: Tokens.font.body.medium
            }

            IconButton {
                icon: root.props.recordingListExpanded ? "unfold_less" : "unfold_more"
                type: IconButton.Text
                label.animate: true
                onClicked: root.props.recordingListExpanded = !root.props.recordingListExpanded
            }
        }
    }

    FileSystemModel {
        id: recordingsModel

        path: Paths.recsdir
        nameFilters: ["recording_*.mp4"]
        onEntriesChanged: root.reloadRecordingTimes()
    }

    Process {
        id: statProc

        stdout: StdioCollector {
            onStreamFinished: {
                const times = {};
                for (const line of text.split("\n")) {
                    const first = line.indexOf(" ");
                    const second = line.indexOf(" ", first + 1);
                    if (first < 0 || second < 0)
                        continue;
                    const birth = parseInt(line.slice(0, first), 10) || 0;
                    const mtime = parseInt(line.slice(first + 1, second), 10) || 0;
                    times[line.slice(second + 1)] = birth > 0 ? birth : mtime;
                }
                root.recordingTimes = times;
            }
        }
    }

    StyledListView {
        id: list

        model: ScriptModel {
            values: {
                const times = root.recordingTimes;
                const entries = [];
                for (let i = 0; i < recordingsModel.entries.length; i++)
                    entries.push(recordingsModel.entries[i]);
                return entries.sort((a, b) => (times[b.path] ?? 0) - (times[a.path] ?? 0));
            }
        }

        Layout.fillWidth: true
        Layout.rightMargin: -Tokens.spacing.small
        implicitHeight: (Tokens.font.body.large.pointSize + Tokens.padding.small) * (root.props.recordingListExpanded ? 10 : 3)
        clip: true

        StyledScrollBar.vertical: StyledScrollBar {
            flickable: list
        }

        delegate: RowLayout {
            id: recording

            required property FileSystemEntry modelData

            anchors.left: list.contentItem.left
            anchors.right: list.contentItem.right
            anchors.rightMargin: Tokens.spacing.small
            spacing: Tokens.spacing.extraSmall

            StyledText {
                Layout.fillWidth: true
                Layout.rightMargin: Tokens.spacing.extraSmall
                text: {
                    const time = root.recordingTimes[recording.modelData.path];
                    return time ? qsTr("Recording at %1").arg(Qt.formatDateTime(new Date(time * 1000), Qt.locale())) : recording.modelData.baseName;
                }
                color: Colours.palette.m3onSurfaceVariant
                elide: Text.ElideRight
            }

            IconButton {
                icon: "play_arrow"
                type: IconButton.Text
                onClicked: {
                    root.screenState.utilities = false;
                    root.screenState.sidebar = false;
                    Quickshell.execDetached([...GlobalConfig.general.apps.playback, recording.modelData.path]);
                }
            }

            IconButton {
                icon: "folder"
                type: IconButton.Text
                onClicked: {
                    root.screenState.utilities = false;
                    root.screenState.sidebar = false;
                    Quickshell.execDetached([...GlobalConfig.general.apps.explorer, recording.modelData.path]);
                }
            }

            IconButton {
                icon: "delete_forever"
                type: IconButton.Text
                label.color: Colours.palette.m3error
                stateLayer.color: Colours.palette.m3error
                onClicked: root.props.recordingConfirmDelete = recording.modelData.path
            }
        }

        add: Transition {
            Anim {
                type: Anim.DefaultEffects
                property: "opacity"
                from: 0
                to: 1
            }
        }

        remove: Transition {
            Anim {
                type: Anim.DefaultEffects
                property: "opacity"
                to: 0
            }
        }

        displaced: Transition {
            Anim {
                type: Anim.DefaultEffects
                property: "opacity"
                to: 1
            }
            Anim {
                property: "y"
            }
        }

        Loader {
            asynchronous: true
            anchors.centerIn: parent

            opacity: list.count === 0 ? 1 : 0
            active: opacity > 0

            sourceComponent: ColumnLayout {
                spacing: Tokens.spacing.small

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "scan_delete"
                    color: Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.extraLarge

                    opacity: root.props.recordingListExpanded ? 1 : 0
                    scale: root.props.recordingListExpanded ? 1 : 0
                    Layout.preferredHeight: root.props.recordingListExpanded ? implicitHeight : 0

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }

                    Behavior on scale {
                        Anim {}
                    }

                    Behavior on Layout.preferredHeight {
                        Anim {}
                    }
                }

                RowLayout {
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "scan_delete"
                        color: Colours.palette.m3outline

                        opacity: !root.props.recordingListExpanded ? 1 : 0
                        scale: !root.props.recordingListExpanded ? 1 : 0
                        Layout.preferredWidth: !root.props.recordingListExpanded ? implicitWidth : 0

                        Behavior on opacity {
                            Anim {
                                type: Anim.DefaultEffects
                            }
                        }

                        Behavior on scale {
                            Anim {}
                        }

                        Behavior on Layout.preferredWidth {
                            Anim {}
                        }
                    }

                    StyledText {
                        text: qsTr("No recordings found")
                        color: Colours.palette.m3outline
                    }
                }
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        Behavior on implicitHeight {
            Anim {}
        }
    }
}
