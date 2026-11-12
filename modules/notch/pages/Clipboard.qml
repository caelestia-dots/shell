pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.hallownest
import qs.services
import qs.modules.notch

NotchPage {
    id: root

    readonly property string query: search.text.trim().toLowerCase()
    readonly property var items: {
        const pinned = Clipboard.pins.map(text => ({
                    id: `pin-${text}`,
                    preview: text,
                    image: false,
                    pinned: true
                }));
        const rest = Clipboard.entries.filter(e => e.image || !Clipboard.isPinned(e.preview));
        return pinned.concat(rest).filter(e => !root.query || (!e.image && e.preview.toLowerCase().includes(root.query)));
    }
    property string copiedId

    function copy(entry: var): void {
        if (entry.pinned)
            Clipboard.copyText(entry.preview);
        else
            Clipboard.copy(entry);
        copiedId = entry.id;
        copiedTimer.restart();
    }

    implicitWidth: 520
    implicitHeight: layout.implicitHeight

    Component.onCompleted: Clipboard.refresh()

    Timer {
        id: copiedTimer

        interval: 1200
        onTriggered: root.copiedId = ""
    }

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            HkField {
                id: search

                Layout.fillWidth: true
                leadingIcon: "search"
                placeholderText: Tr.tr("Search clipboard")
                onActiveFocusChanged: {
                    if (activeFocus)
                        root.screenState.notch = true;
                }
                onAccepted: {
                    if (root.items.length)
                        root.copy(root.items[0]);
                }
            }

            HkButton {
                icon: "refresh"
                onClicked: Clipboard.refresh()
            }

            HkButton {
                icon: "delete_sweep"
                text: Tr.tr("Clear")
                accent: Hallownest.grimm
                tinted: true
                disabled: Clipboard.entries.length === 0
                onClicked: Clipboard.wipe()
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Tokens.spacing.large
            Layout.bottomMargin: Tokens.spacing.large
            visible: root.items.length === 0
            text: Clipboard.loading ? Tr.tr("Loading…") : root.query ? Tr.tr("Nothing matches") : Tr.tr("Clipboard is empty")
            color: Hallownest.subtext
            font.family: Hallownest.serif
            font.pointSize: 10
        }

        StyledListView {
            id: list

            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 300)
            visible: count > 0
            clip: true
            spacing: Tokens.spacing.extraSmall

            model: ScriptModel {
                values: root.items
                objectProp: "id"
            }

            delegate: StyledRect {
                id: entry

                required property var modelData
                readonly property bool copied: root.copiedId === modelData.id

                width: list.width
                implicitHeight: modelData.image ? 64 : 34
                radius: modelData.image ? 12 : implicitHeight / 2
                color: entryHover.hovered ? Hallownest.raise(Hallownest.card, 1.3) : Hallownest.card
                border.width: 1
                border.color: copied ? Hallownest.soul : modelData.pinned ? Qt.alpha(Hallownest.gold, 0.35) : Hallownest.border

                HoverHandler {
                    id: entryHover
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.copy(entry.modelData)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Tokens.padding.medium
                    anchors.rightMargin: Tokens.padding.small
                    spacing: Tokens.spacing.small

                    Rectangle {
                        visible: !!entry.modelData.pinned
                        implicitWidth: 7
                        implicitHeight: 7
                        rotation: 45
                        color: Hallownest.gold
                    }

                    Image {
                        Layout.preferredWidth: 96
                        Layout.preferredHeight: 52
                        visible: entry.modelData.image
                        source: entry.modelData.image ? `${Clipboard.thumb(entry.modelData)}?v=${Clipboard.thumbVersion}` : ""
                        fillMode: Image.PreserveAspectFit
                        horizontalAlignment: Image.AlignLeft
                        sourceSize.height: 104
                        asynchronous: true
                        cache: false
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: entry.copied ? Tr.tr("Copied") : entry.modelData.image ? Tr.tr("Image") : entry.modelData.preview.replace(/\s+/g, " ")
                        color: entry.copied ? Hallownest.soul : entry.modelData.image ? Hallownest.subtext : Hallownest.text
                        font.pointSize: 10
                        elide: Text.ElideRight
                    }

                    HkButton {
                        visible: !entry.modelData.image && (entryHover.hovered || !!entry.modelData.pinned)
                        icon: "push_pin"
                        accent: Hallownest.gold
                        tinted: !!entry.modelData.pinned
                        onClicked: Clipboard.togglePin(entry.modelData.preview)
                    }

                    HkButton {
                        visible: !entry.modelData.pinned && entryHover.hovered
                        icon: "close"
                        onClicked: Clipboard.remove(entry.modelData)
                    }
                }
            }
        }
    }
}
