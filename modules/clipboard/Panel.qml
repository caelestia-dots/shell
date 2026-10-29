pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.containers
import qs.components.effects
import qs.services

StyledWindow {
    id: win

    readonly property ShellScreen targetScreen: {
        const screens = Screens.screens;
        for (let i = 0; i < screens.length; i++) {
            const s = screens[i];
            if (Clipboard.cursorX >= s.x && Clipboard.cursorX < s.x + s.width && Clipboard.cursorY >= s.y && Clipboard.cursorY < s.y + s.height)
                return s;
        }
        return screens[0] ?? null;
    }

    screen: targetScreen
    name: "clipboard"
    color: "transparent"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    onTargetScreenChanged: {
        if (targetScreen)
            Qt.callLater(() => search.forceActiveFocus());
    }

    Component.onCompleted: Qt.callLater(() => search.forceActiveFocus())

    Keys.onEscapePressed: Clipboard.close()
    Keys.onUpPressed: Clipboard.moveSelection(-1)
    Keys.onDownPressed: Clipboard.moveSelection(1)
    Keys.onReturnPressed: Clipboard.activateCurrent()
    Keys.onEnterPressed: Clipboard.activateCurrent()
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Delete || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_D)) {
            const item = Clipboard.flatItems[Clipboard.currentIndex];
            if (item)
                Clipboard.deleteEntry(item);
            event.accepted = true;
        }
    }

    // Click outside to dismiss
    MouseArea {
        anchors.fill: parent
        onClicked: event => {
            const p = mapToItem(card, event.x, event.y);
            if (p.x < 0 || p.y < 0 || p.x > card.width || p.y > card.height)
                Clipboard.close();
        }
    }

    Elevation {
        id: card

        readonly property real localX: Clipboard.cursorX - (win.screen?.x ?? 0)
        readonly property real localY: Clipboard.cursorY - (win.screen?.y ?? 0)
        readonly property real margin: Tokens.padding.large
        readonly property real maxW: Math.min(420, (win.screen?.width ?? 420) - margin * 2)
        readonly property real maxH: Math.min(520, (win.screen?.height ?? 520) - margin * 2)

        x: Math.min(Math.max(margin, localX), (win.screen?.width ?? width) - width - margin)
        y: Math.min(Math.max(margin, localY), (win.screen?.height ?? height) - height - margin)
        width: maxW
        height: Math.min(maxH, col.implicitHeight + Tokens.padding.large * 2)
        radius: Tokens.rounding.extraLarge
        level: 3

        StyledRect {
            id: panel

            anchors.fill: parent
            radius: parent.radius
            color: Colours.tPalette.m3surface
            clip: true

            ColumnLayout {
                id: col

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.small

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        text: "content_paste"
                        color: Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.large
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Tr.tr("Clipboard")
                        font: Tokens.font.title.small
                        color: Colours.palette.m3onSurface
                    }

                    IconButton {
                        icon: "delete_sweep"
                        type: IconButton.Text
                        onClicked: Clipboard.clearHistory()
                    }

                    IconButton {
                        icon: "close"
                        type: IconButton.Text
                        onClicked: Clipboard.close()
                    }
                }

                SearchBar {
                    id: search

                    Layout.fillWidth: true
                    placeholderText: Tr.tr("Search clipboard…")
                    text: Clipboard.search
                    onTextChanged: {
                        Clipboard.search = text;
                        Clipboard.currentIndex = 0;
                    }
                    onAccepted: Clipboard.activateCurrent()

                    Keys.onUpPressed: Clipboard.moveSelection(-1)
                    Keys.onDownPressed: Clipboard.moveSelection(1)
                    Keys.onEscapePressed: Clipboard.close()
                }

                StyledText {
                    visible: Clipboard.flatItems.length === 0
                    Layout.fillWidth: true
                    Layout.topMargin: Tokens.padding.medium
                    Layout.bottomMargin: Tokens.padding.medium
                    horizontalAlignment: Text.AlignHCenter
                    text: Clipboard.search.length ? Tr.tr("No matches") : Tr.tr("Clipboard is empty")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.medium
                }

                ListView {
                    id: list

                    visible: Clipboard.flatItems.length > 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 360)
                    clip: true
                    model: Clipboard.flatItems
                    currentIndex: Clipboard.currentIndex
                    spacing: Tokens.spacing.extraSmall / 2
                    boundsBehavior: Flickable.StopAtBounds

                    onCurrentIndexChanged: {
                        if (currentIndex !== Clipboard.currentIndex)
                            Clipboard.currentIndex = currentIndex;
                        positionViewAtIndex(currentIndex, ListView.Contain);
                    }

                    Connections {
                        target: Clipboard
                        function onCurrentIndexChanged(): void {
                            list.currentIndex = Clipboard.currentIndex;
                        }
                    }

                    delegate: Item {
                        id: row

                        required property var modelData
                        required property int index

                        readonly property bool isFav: modelData.section === "favorite" || Clipboard.isFavorite(modelData)
                        readonly property bool selected: index === Clipboard.currentIndex
                        readonly property bool hovered: rowLayer.containsMouse

                        width: list.width
                        height: Tokens.font.body.medium.pointSize + Tokens.padding.large * 2

                        StyledRect {
                            anchors.fill: parent
                            radius: Tokens.rounding.large
                            color: row.selected ? Colours.palette.m3secondaryContainer : "transparent"

                            Behavior on color {
                                Anim {
                                    type: Anim.DefaultEffects
                                }
                            }
                        }

                        StateLayer {
                            id: rowLayer

                            anchors.fill: parent
                            radius: Tokens.rounding.large
                            onClicked: {
                                Clipboard.currentIndex = row.index;
                                Clipboard.select(row.modelData);
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Tokens.padding.medium
                            anchors.rightMargin: Tokens.padding.small
                            spacing: Tokens.spacing.small

                            Item {
                                id: leading

                                readonly property bool isImage: row.modelData.kind === "image"
                                readonly property string thumbPath: Clipboard.thumbPathFor(row.modelData)
                                property bool thumbReady: false

                                Layout.preferredWidth: height
                                Layout.preferredHeight: parent.height * 0.78
                                Layout.alignment: Qt.AlignVCenter

                                function ensureThumb(): void {
                                    if (!isImage || !thumbPath.length) {
                                        thumbReady = false;
                                        return;
                                    }
                                    if (row.modelData.path) {
                                        thumbReady = true;
                                        return;
                                    }
                                    thumbReady = false;
                                    if (!thumbProc.running)
                                        thumbProc.running = true;
                                }

                                Component.onCompleted: ensureThumb()
                                onThumbPathChanged: ensureThumb()

                                Process {
                                    id: thumbProc

                                    command: ["bash", "-c", `mkdir -p \"$1\" && f=\"$2\"; [ -s \"$f\" ] || cliphist decode \"$3\" > \"$f\"`, "_", Clipboard.thumbsDir, leading.thumbPath, String(row.modelData.id || "")]
                                    onExited: code => {
                                        leading.thumbReady = code === 0;
                                    }
                                }

                                ClipRect {
                                    anchors.fill: parent
                                    radius: Tokens.rounding.small
                                    visible: leading.isImage

                                    StyledRect {
                                        anchors.fill: parent
                                        color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
                                    }

                                    Image {
                                        id: thumbImage

                                        anchors.fill: parent
                                        asynchronous: true
                                        cache: true
                                        fillMode: Image.PreserveAspectCrop
                                        // Decode to the on-screen thumb size, not the full
                                        // 1440p file (each history row would otherwise ship
                                        // a multi-megapixel texture into VRAM).
                                        sourceSize: Qt.size(Math.max(1, width), Math.max(1, height))
                                        source: leading.thumbReady && leading.thumbPath.length ? Qt.resolvedUrl(leading.thumbPath) : ""
                                        visible: status === Image.Ready
                                    }

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        visible: thumbImage.status !== Image.Ready
                                        text: "image"
                                        color: row.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                                        fontStyle: Tokens.font.icon.small
                                    }
                                }

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    visible: !leading.isImage
                                    text: Clipboard.iconForKind(row.modelData.kind)
                                    color: row.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                                }
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: row.modelData.label || row.modelData.preview || ""
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                color: row.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                                font: Tokens.font.body.medium
                            }

                            IconButton {
                                icon: "star"
                                type: IconButton.Text
                                isToggle: true
                                checked: row.isFav
                                implicitWidth: implicitHeight
                                opacity: row.isFav || row.hovered ? 1 : 0
                                visible: opacity > 0
                                enabled: visible
                                // Keep star empty on hover until favourited
                                activeOnColour: Colours.palette.m3primary
                                inactiveOnColour: row.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                                onClicked: Clipboard.toggleFavorite(row.modelData)

                                Behavior on opacity {
                                    Anim {
                                        type: Anim.DefaultEffects
                                    }
                                }
                            }

                            IconButton {
                                icon: "close"
                                type: IconButton.Text
                                implicitWidth: implicitHeight
                                opacity: row.selected || row.hovered ? 1 : 0.55
                                onClicked: Clipboard.deleteEntry(row.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
