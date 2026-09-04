import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia
import Caelestia.Blobs
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.drawers

Item {
    id: root

    property bool open
    readonly property real padding: Tokens.padding.medium
    readonly property real popupWidth: 320
    readonly property real maxPopupHeight: 256
    readonly property real maxListHeight: 104

    implicitWidth: btn.implicitWidth * 0.9
    implicitHeight: btn.implicitHeight * 0.9

    MouseArea {
        id: dismissArea

        parent: {
            const win = QsWindow.window;
            const contentWin = win as ContentWindow;
            return contentWin ? contentWin.interactionWrapper : (win as QsWindow)?.contentItem;
        }
        anchors.fill: parent
        visible: root.open
        enabled: root.open
        z: 998

        onPressed: mouse => {
            const rPos = rect.mapFromItem(dismissArea, mouse.x, mouse.y);
            const inRect = rPos.x >= 0 && rPos.x <= rect.width && rPos.y >= 0 && rPos.y <= rect.height;

            const bPos = btn.mapFromItem(dismissArea, mouse.x, mouse.y);
            const inBtn = bPos.x >= 0 && bPos.x <= btn.width && bPos.y >= 0 && bPos.y <= btn.height;

            if (inRect || inBtn) {
                mouse.accepted = false;
            } else {
                root.open = false;
            }
        }
    }

    BlobGroup {
        id: blobGroup

        color: Colours.palette.m3surfaceContainerHighest
        smoothing: root.Tokens.rounding.medium
        cornerFill: false

        Behavior on color {
            CAnim {}
        }
    }

    BlobRect {
        id: btnRect

        anchors.fill: parent
        anchors.margins: !btn.pressed && btn.containsMouse ? -Tokens.padding.extraSmall : 0
        group: blobGroup
        radius: Tokens.rounding.medium

        Behavior on anchors.margins {
            Anim {}
        }
    }

    BlobRect {
        id: rect

        anchors.right: parent.right
        anchors.top: parent.top

        implicitWidth: parent.width
        implicitHeight: parent.height

        group: blobGroup
        radius: Tokens.rounding.medium
        deformScale: 0.00001

        states: State {
            name: "open"
            when: root.open

            PropertyChanges {
                rect.anchors.rightMargin: root.width - root.Tokens.spacing.small
                rect.anchors.topMargin: -root.Tokens.padding.medium
                rect.implicitWidth: (Lyrics.hasLyrics && !Lyrics.loading)
                    ? root.popupWidth
                    : Math.max(140, placeholder.implicitWidth + root.padding * 3)
                rect.implicitHeight: (Lyrics.hasLyrics && !Lyrics.loading)
                    ? Math.min(root.maxPopupHeight, layout.implicitHeight + root.padding * 2)
                    : placeholder.implicitHeight + root.padding * 2
                content.opacity: 1
            }
        }

        transitions: Transition {
            Anim {
                properties: "rightMargin,implicitWidth"
            }
            Anim {
                properties: "topMargin,implicitHeight"
                easing: root.Tokens.anim.expressiveFastSpatial
            }
            Anim {
                property: "opacity"
                type: Anim.DefaultEffects
            }
        }

        Behavior on implicitWidth {
            Anim {}
        }

        Behavior on implicitHeight {
            Anim {}
        }

        MouseArea {
            id: innerCatchArea

            anchors.fill: parent
            onWheel: wheel => wheel.accepted = true
        }

        Item {
            id: content

            anchors.fill: parent
            clip: true
            opacity: 0
            state: Lyrics.loading || !Lyrics.hasLyrics ? "" : "hasLyrics"

            states: State {
                name: "hasLyrics"

                PropertyChanges {
                    layout.opacity: 1
                    placeholder.opacity: 0
                }
            }

            transitions: [
                Transition {
                    from: "hasLyrics"

                    SequentialAnimation {
                        Anim {
                            target: layout
                            property: "opacity"
                            type: Anim.FastEffects
                        }
                        Anim {
                            target: placeholder
                            property: "opacity"
                            type: Anim.DefaultEffects
                        }
                    }
                },
                Transition {
                    to: "hasLyrics"

                    SequentialAnimation {
                        Anim {
                            target: placeholder
                            property: "opacity"
                            type: Anim.FastEffects
                        }
                        Anim {
                            target: layout
                            property: "opacity"
                            type: Anim.DefaultEffects
                        }
                    }
                }
            ]

            ColumnLayout {
                id: layout

                anchors.fill: parent
                anchors.margins: root.padding
                spacing: Tokens.spacing.small
                opacity: 0

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        text: "sync"
                        color: Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.small
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Lyrics.preferredBackend === LyricsBackend.Auto
                            ? qsTr("Source: %1 (Auto)").arg(CUtils.enumToString(Lyrics, "backend"))
                            : qsTr("Source: %1").arg(CUtils.enumToString(Lyrics, "backend"))
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.medium
                    }

                    StyledText {
                        visible: Lyrics.selectedCandidate.duration > 0
                        text: `${Math.floor(Lyrics.selectedCandidate.duration / 60)}:${Math.floor(Lyrics.selectedCandidate.duration % 60).toString().padStart(2, "0")}`
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: `${Lyrics.selectedCandidate.title || qsTr("Unknown")} • ${Lyrics.selectedCandidate.artist || qsTr("Unknown")}`
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.label.large
                    elide: Text.ElideRight
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    IconButton {
                        type: IconButton.Tonal
                        icon: "remove"
                        onClicked: Lyrics.offset -= 0.5
                    }

                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: qsTr("Offset: %1%2 s").arg(Lyrics.offset >= 0 ? "+" : "").arg(Lyrics.offset.toFixed(1))
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.label.large
                    }

                    IconButton {
                        type: IconButton.Tonal
                        icon: "add"
                        onClicked: Lyrics.offset += 0.5
                    }

                    TextButton {
                        visible: Lyrics.offset !== 0
                        type: TextButton.Text
                        text: qsTr("Reset")
                        onClicked: Lyrics.offset = 0
                    }
                }

                RowLayout {
                    visible: Lyrics.lyricCandidates.length > 1
                    Layout.fillWidth: true

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Candidates (%1)").arg(Lyrics.lyricCandidates.length)
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                    }

                    TextButton {
                        id: resetBtn

                        disabled: !Lyrics.hasCandidateOverride
                        type: TextButton.Text
                        text: qsTr("Reset to Default")
                        onClicked: Lyrics.resetToAuto()
                    }
                }

                StyledFlickable {
                    id: candFlickable

                    visible: Lyrics.lyricCandidates.length > 1
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.maximumHeight: root.maxListHeight
                    implicitHeight: Math.min(candCol.implicitHeight, root.maxListHeight)

                    flickableDirection: Flickable.VerticalFlick
                    clip: true
                    contentWidth: width
                    contentHeight: candCol.implicitHeight

                    StyledScrollBar.vertical: StyledScrollBar {
                        flickable: candFlickable
                    }

                    ColumnLayout {
                        id: candCol

                        width: candFlickable.width
                        spacing: Tokens.spacing.extraSmall

                        Repeater {
                            model: Lyrics.lyricCandidates

                            delegate: Rectangle {
                                id: candItem

                                required property var modelData

                                readonly property bool isSelected: Lyrics.selectedCandidate.id === modelData.id && Lyrics.selectedCandidate.backend === modelData.backend
                                readonly property bool isAuto: Lyrics.autoCandidate.id === modelData.id && Lyrics.autoCandidate.backend === modelData.backend

                                Layout.fillWidth: true
                                implicitHeight: candRow.implicitHeight + Tokens.padding.extraSmall * 2
                                radius: Tokens.rounding.small
                                color: isSelected ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainer

                                Behavior on color {
                                    CAnim {}
                                }

                                StateLayer {
                                    radius: parent.radius
                                    color: candItem.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                                    onClicked: Lyrics.selectedCandidate = candItem.modelData
                                }

                                RowLayout {
                                    id: candRow

                                    anchors.fill: parent
                                    anchors.leftMargin: Tokens.padding.medium
                                    anchors.rightMargin: Tokens.padding.medium
                                    spacing: Tokens.spacing.small

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: candItem.isAuto
                                            ? `${candItem.modelData.title} • ${candItem.modelData.artist} (${qsTr("Auto")})`
                                            : `${candItem.modelData.title} • ${candItem.modelData.artist}`
                                        color: candItem.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                                        font: Tokens.font.body.small
                                        elide: Text.ElideRight
                                    }

                                    StyledText {
                                        visible: candItem.modelData.duration > 0
                                        text: `${Math.floor(candItem.modelData.duration / 60)}:${Math.floor(candItem.modelData.duration % 60).toString().padStart(2, "0")}`
                                        color: candItem.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3outline
                                        font: Tokens.font.label.small
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item {
                id: placeholder

                anchors.centerIn: parent
                implicitWidth: placeholderText.implicitWidth
                implicitHeight: placeholderText.implicitHeight

                StyledText {
                    id: placeholderText

                    text: Lyrics.loading ? qsTr("Loading...") : qsTr("No lyrics found")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.medium
                    animate: true
                }
            }
        }
    }

    MouseArea {
        id: btn

        anchors.centerIn: parent
        implicitWidth: implicitHeight
        implicitHeight: icon.implicitHeight + Tokens.padding.extraSmall * 2
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: root.open = !root.open

        MaterialIcon {
            id: icon

            anchors.centerIn: parent
            text: "more_vert"
            fontStyle: Tokens.font.icon.medium
        }
    }
}

