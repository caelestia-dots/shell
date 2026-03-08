pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    required property real contentHeight

    implicitHeight: contentHeight

    radius: Appearance.rounding.large
    color: Colours.tPalette.m3surfaceContainer

    function searchCandidates(title, artist) {
        LyricsService.currentRequestId++;
        LyricsService.fetchNetEaseCandidates(title, artist, LyricsService.currentRequestId);
    }

    Loader {
        anchors.fill: parent
        active: root.height > 0

        sourceComponent: ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.padding.large
            spacing: Appearance.spacing.normal

            // Header: icon, backend name, refresh, toggle
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.padding.small

                MaterialIcon {
                    text: "lyrics"
                    fill: 1
                    color: Colours.palette.m3primary
                    font.pointSize: Appearance.spacing.large
                }

                StyledText {
                    Layout.fillWidth: true
                    text: LyricsService.backend
                    font.pointSize: Appearance.font.size.normal
                    color: Colours.palette.m3secondary
                    elide: Text.ElideRight
                }

                IconButton {
                    icon: "refresh"
                    type: IconButton.Text
                    onClicked: LyricsService.loadLyrics()
                }

                StyledSwitch {
                    checked: LyricsService.lyricsVisible
                    onToggled: LyricsService.toggleVisibility()
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: "Fetched Candidates:"
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
                elide: Text.ElideRight
            }

            // Candidates list
            ListView {
                id: candidatesView

                Layout.fillWidth: true
                Layout.fillHeight: true

                visible: LyricsService.candidatesModel.count > 0
                model: LyricsService.candidatesModel
                clip: true
                spacing: Appearance.spacing.small

                opacity: visible ? 1 : 0
                // Behavior on opacity {
                //     NumberAnimation { duration: Appearance.anim.durations.normal }
                // }

                delegate: Item {
                    id: delegateRoot
                    width: ListView.view.width * 0.98
                    height: 70
                    anchors.horizontalCenter: parent?.horizontalCenter

                    required property real id
                    required property string title
                    required property string artist

                    property bool hovered: false
                    property bool pressed: false

                    scale: hovered ? 1.02 : 1.0
                    Behavior on scale {
                        NumberAnimation {
                            duration: Appearance.anim.durations.small
                            easing.type: Easing.OutCubic
                        }
                    }

                    Rectangle {
                        id: background
                        anchors.fill: parent
                        radius: Appearance.rounding.small

                        color: pressed
                        ? Qt.rgba(Colours.palette.m3primary.r,
                                  Colours.palette.m3primary.g,
                                  Colours.palette.m3primary.b, 0.25)
                        : hovered
                        ? Qt.rgba(Colours.palette.m3primary.r,
                                  Colours.palette.m3primary.g,
                                  Colours.palette.m3primary.b, 0.06)
                        : Qt.rgba(Colours.palette.m3primary.r,
                                  Colours.palette.m3primary.g,
                                  Colours.palette.m3primary.b, 0.03)

                        border.width: hovered ? 1 : 0
                        border.color: Colours.palette.m3primary

                        Behavior on color { ColorAnimation { duration: Appearance.anim.durations.small } }
                        Behavior on border.width { NumberAnimation { duration: Appearance.anim.durations.small } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onEntered: delegateRoot.hovered = true
                        onExited: delegateRoot.hovered = false
                        onPressed: delegateRoot.pressed = true
                        onReleased: delegateRoot.pressed = false
                        onClicked: LyricsService.selectCandidate(id)
                    }

                    Row {
                        anchors.fill: parent
                        anchors.margins: Appearance.padding.normal
                        spacing: Appearance.spacing.small

                        // Active indicator bar
                        Rectangle {
                            width: 4
                            height: parent.height * 0.6
                            radius: 2
                            anchors.verticalCenter: parent.verticalCenter
                            color: LyricsService.currentSongId === id
                            ? Colours.palette.m3primary
                            : "transparent"
                            Behavior on color { ColorAnimation { duration: Appearance.anim.durations.small } }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 30
                            spacing: 4

                            Text {
                                text: title
                                font.pointSize: Appearance.font.size.normal
                                font.bold: true
                                color: delegateRoot.hovered
                                ? Colours.palette.m3primary
                                : Colours.palette.m3onSurface
                                width: parent.width
                                elide: Text.ElideRight
                                Behavior on color { ColorAnimation { duration: Appearance.anim.durations.small } }
                            }

                            Text {
                                text: artist
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3onSurfaceVariant
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: true
                visible: LyricsService.candidatesModel.count == 0
            }

            // Manual search
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.padding.small

                StyledText {
                    Layout.fillWidth: true
                    text: "Manual Search"
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3onSurfaceVariant
                    elide: Text.ElideRight
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.padding.small

                    StyledInputField {
                        id: searchTitle
                        Layout.fillWidth: true
                        horizontalAlignment: TextInput.AlignLeft

                        Binding {
                            target: searchTitle
                            property: "text"
                            value: (Players.active?.trackTitle ?? qsTr("title")) || qsTr("title")
                        }
                    }

                    StyledInputField {
                        id: searchArtist
                        Layout.fillWidth: true
                        horizontalAlignment: TextInput.AlignLeft

                        Binding {
                            target: searchArtist
                            property: "text"
                            value: (Players.active?.trackArtist ?? qsTr("artist")) || qsTr("artist")
                        }
                    }

                    IconButton {
                        icon: "search"
                        onClicked: searchCandidates(searchTitle.text, searchArtist.text)
                    }
                }
            }

            // Offset controls
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.padding.small

                MaterialIcon {
                    text: "contrast_square"
                    font.pointSize: Appearance.font.size.large
                    color: Colours.palette.m3secondary
                }

                StyledText {
                    text: "Offset"
                    color: Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.normal
                }

                Item { Layout.fillWidth: true }

                IconButton {
                    icon: "remove"
                    type: IconButton.Text
                    onClicked: {
                        LyricsService.offset = parseFloat((LyricsService.offset - 0.1).toFixed(1));
                        LyricsService.savePrefs();
                    }
                }

                TextInput {
                    id: offsetInput
                    horizontalAlignment: TextInput.AlignHCenter
                    color: Colours.palette.m3secondary
                    font.pointSize: Appearance.font.size.normal
                    selectByMouse: true
                    text: (LyricsService.offset >= 0 ? "+" : "") + LyricsService.offset.toFixed(1) + "s"

                    Binding {
                        target: offsetInput
                        property: "text"
                        value: (LyricsService.offset >= 0 ? "+" : "") + LyricsService.offset.toFixed(1) + "s"
                        when: !offsetInput.activeFocus
                    }

                    Connections {
                        target: LyricsService
                        function onCurrentRequestIdChanged() {
                            offsetInput.focus = false;
                        }
                    }

                    onEditingFinished: {
                        let cleaned = offsetInput.text.replace(/[+s]/g, "").trim();
                        let val = parseFloat(cleaned);
                        if (!isNaN(val)) {
                            LyricsService.offset = parseFloat(val.toFixed(1));
                            LyricsService.savePrefs();
                        } else {
                            offsetInput.text = (LyricsService.offset >= 0 ? "+" : "") + LyricsService.offset.toFixed(1) + "s";
                        }
                    }
                }

                IconButton {
                    icon: "add"
                    type: IconButton.Text
                    onClicked: {
                        LyricsService.offset = parseFloat((LyricsService.offset + 0.1).toFixed(1));
                        LyricsService.savePrefs();
                    }
                }
            }
        }
    }
}
