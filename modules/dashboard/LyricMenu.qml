pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    required property real contentHeight

    function searchCandidates(title, artist) {
        LyricsService.currentRequestId++;
        LyricsService.fetchNetEaseCandidates(title, artist, LyricsService.currentRequestId);
    }

    implicitHeight: contentHeight

    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer

    Loader {
        asynchronous: true
        anchors.fill: parent
        active: root.height > 0

        sourceComponent: ColumnLayout {
            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.normal

            // Header: icon, backend selector, refresh, toggle
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.padding.small

                MaterialIcon {
                    text: "lyrics"
                    fill: 1
                    color: Colours.palette.m3primary
                    font.pointSize: Tokens.spacing.large
                }

                Rectangle {
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: 80
                    radius: Tokens.rounding.small
                    color: Qt.rgba(Colours.palette.m3primary.r, Colours.palette.m3primary.g, Colours.palette.m3primary.b, 0.15)

                    StyledText {
                        anchors.centerIn: parent
                        text: LyricsService.preferredBackend
                        font.pointSize: Tokens.font.size.small
                        color: Colours.palette.m3primary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const backends = ["Auto", "Local", "NetEase"];
                            const currentIndex = backends.indexOf(LyricsService.preferredBackend);
                            const nextIndex = (currentIndex + 1) % backends.length;
                            LyricsService.preferredBackend = backends[nextIndex];
                            LyricsService.loadLyrics();
                        }
                    }
                }

                Rectangle {
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: 60
                    radius: Tokens.rounding.small
                    visible: LyricsService.preferredBackend === "Auto"
                    color: LyricsService.backend === "Local" ? Qt.rgba(Colours.palette.m3tertiary.r, Colours.palette.m3tertiary.g, Colours.palette.m3tertiary.b, 0.15) : Qt.rgba(Colours.palette.m3secondary.r, Colours.palette.m3secondary.g, Colours.palette.m3secondary.b, 0.15)

                    StyledText {
                        anchors.centerIn: parent
                        text: LyricsService.backend
                        font.pointSize: Tokens.font.size.small
                        color: LyricsService.backend === "Local" ? Colours.palette.m3tertiary : Colours.palette.m3secondary
                    }
                }

                Item {
                    Layout.fillWidth: true
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
                text: LyricsService.preferredBackend === "Local" ? "Loaded File:" : "Fetched Candidates:"
                color: Colours.palette.m3outline
                font.pointSize: Tokens.font.size.small
                elide: Text.ElideRight
                visible: LyricsService.preferredBackend === "Local" ? LyricsService.loadedLocalFile.length > 0 : LyricsService.candidatesModel.count > 0
            }

            // Local file info (shown in Local mode)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                visible: LyricsService.preferredBackend === "Local" && LyricsService.loadedLocalFile.length > 0
                radius: Tokens.rounding.small
                color: Qt.rgba(Colours.palette.m3tertiary.r, Colours.palette.m3tertiary.g, Colours.palette.m3tertiary.b, 0.1)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.small
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: {
                            const path = LyricsService.loadedLocalFile;
                            const parts = path.split('/');
                            return parts[parts.length - 1];
                        }
                        font.pointSize: Tokens.font.size.small
                        color: Colours.palette.m3tertiary
                        elide: Text.ElideMiddle
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: {
                            const path = LyricsService.loadedLocalFile;
                            const parts = path.split('/');
                            if (parts.length > 2) {
                                return parts.slice(-3, -1).join('/');
                            }
                            return "";
                        }
                        font.pointSize: Tokens.font.size.small
                        color: Colours.palette.m3outline
                        elide: Text.ElideMiddle
                    }
                }
            }

            // Candidates list
            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true

                active: LyricsService.preferredBackend !== "Local"

                sourceComponent: ListView {
                    id: candidatesView

                    model: LyricsService.candidatesModel
                    clip: true
                    spacing: Tokens.spacing.small
                    visible: LyricsService.candidatesModel.count > 0
                    opacity: visible ? 1 : 0

                    delegate: Item {
                        id: delegateRoot

                        required property real id
                        required property string title
                        required property string artist

                        property bool hovered: false
                        property bool pressed: false

                        width: ListView.view.width * 0.98
                        height: 70

                        anchors.horizontalCenter: parent?.horizontalCenter
                        scale: hovered ? 1.02 : 1.0

                        Behavior on scale {
                            NumberAnimation {
                                duration: Tokens.anim.durations.small
                                easing.type: Easing.OutCubic
                            }
                        }

                        Rectangle {
                            id: background

                            anchors.fill: parent
                            radius: Tokens.rounding.small

                            color: delegateRoot.pressed ? Qt.rgba(Colours.palette.m3primary.r, Colours.palette.m3primary.g, Colours.palette.m3primary.b, 0.25) : delegateRoot.hovered ? Qt.rgba(Colours.palette.m3primary.r, Colours.palette.m3primary.g, Colours.palette.m3primary.b, 0.06) : Qt.rgba(Colours.palette.m3primary.r, Colours.palette.m3primary.g, Colours.palette.m3primary.b, 0.03)

                            border.width: delegateRoot.hovered ? 1 : 0
                            border.color: Colours.palette.m3primary

                            Behavior on color {
                                ColorAnimation {
                                    duration: Tokens.anim.durations.small
                                }
                            }
                            Behavior on border.width {
                                NumberAnimation {
                                    duration: Tokens.anim.durations.small
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onEntered: delegateRoot.hovered = true
                            onExited: delegateRoot.hovered = false
                            onPressed: delegateRoot.pressed = true
                            onReleased: delegateRoot.pressed = false
                            onClicked: LyricsService.selectCandidate(delegateRoot.id)
                        }

                        Row {
                            anchors.fill: parent
                            anchors.margins: Tokens.padding.normal
                            spacing: Tokens.spacing.small

                            // Active indicator bar
                            Rectangle {
                                width: 4
                                height: parent.height * 0.6
                                radius: 2
                                anchors.verticalCenter: parent.verticalCenter
                                color: LyricsService.currentSongId === delegateRoot.id ? Colours.palette.m3primary : "transparent"

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Tokens.anim.durations.small
                                    }
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 30
                                spacing: 4

                                Text {
                                    text: delegateRoot.title
                                    font.pointSize: Tokens.font.size.normal
                                    font.bold: true
                                    color: delegateRoot.hovered ? Colours.palette.m3primary : Colours.palette.m3onSurface
                                    width: parent.width
                                    elide: Text.ElideRight

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Tokens.anim.durations.small
                                        }
                                    }
                                }

                                Text {
                                    text: delegateRoot.artist
                                    font.pointSize: Tokens.font.size.small
                                    color: Colours.palette.m3onSurfaceVariant
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: true
                visible: LyricsService.candidatesModel.count == 0 && LyricsService.preferredBackend !== "Local"
            }

            // Manual search
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.padding.small

                StyledText {
                    Layout.fillWidth: true
                    text: "Manual Search"
                    font.pointSize: Tokens.font.size.small
                    color: Colours.palette.m3onSurfaceVariant
                    elide: Text.ElideRight
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.padding.small

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
                        onClicked: root.searchCandidates(searchTitle.text, searchArtist.text)
                    }
                }
            }

            // Offset controls
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.padding.small

                MaterialIcon {
                    text: "contrast_square"
                    font.pointSize: Tokens.font.size.large
                    color: Colours.palette.m3secondary
                }

                StyledText {
                    text: "Offset"
                    color: Colours.palette.m3outline
                    font.pointSize: Tokens.font.size.normal
                }

                Item {
                    Layout.fillWidth: true
                }

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
                    font.pointSize: Tokens.font.size.normal
                    selectByMouse: true
                    text: (LyricsService.offset >= 0 ? "+" : "") + LyricsService.offset.toFixed(1) + "s"
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

                    Binding {
                        target: offsetInput
                        property: "text"
                        value: (LyricsService.offset >= 0 ? "+" : "") + LyricsService.offset.toFixed(1) + "s"
                        when: !offsetInput.activeFocus
                    }

                    Connections {
                        function onCurrentRequestIdChanged() {
                            offsetInput.focus = false;
                        }

                        target: LyricsService
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
