pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.hallownest
import qs.services
import qs.utils
import qs.modules.notch

NotchPage {
    id: root

    readonly property int columns: 4
    readonly property real cellSize: 104
    readonly property bool hasItems: Shelf.items.length > 0
    property var selected: []
    property int anchorIndex: -1
    property var dragIds: []

    function itemsFor(id: string): var {
        const ids = selected.includes(id) ? selected : [id];
        return Shelf.items.filter(i => ids.includes(i.id));
    }

    function mimeFor(items: var): var {
        const files = items.filter(i => i.type === "file");
        const texts = items.filter(i => i.type === "text").map(i => i.text);
        const data = {};
        if (files.length)
            data["text/uri-list"] = files.map(i => i.uri).join("\r\n") + "\r\n";
        const plain = files.map(i => Shelf.pathOf(i.uri)).concat(texts).join("\n");
        if (plain)
            data["text/plain"] = plain;
        return data;
    }

    function click(index: int, item: var, modifiers: int): void {
        if (modifiers & Qt.ControlModifier) {
            selected = selected.includes(item.id) ? selected.filter(id => id !== item.id) : selected.concat([item.id]);
            anchorIndex = index;
        } else if ((modifiers & Qt.ShiftModifier) && anchorIndex >= 0) {
            const from = Math.min(anchorIndex, index);
            const to = Math.max(anchorIndex, index);
            selected = Shelf.items.slice(from, to + 1).map(i => i.id);
        } else {
            anchorIndex = index;
            if (item.type === "text") {
                selected = [];
                Shelf.copyText(item.text);
            } else {
                selected = selected.length === 1 && selected[0] === item.id ? [] : [item.id];
            }
        }
    }

    function finishDrag(dropAction: int): void {
        Shelf.dragging = false;
        if (dropAction !== Qt.IgnoreAction) {
            Shelf.remove(dragIds);
            selected = selected.filter(id => !dragIds.includes(id));
        }
        dragIds = [];
    }

    implicitWidth: hasItems ? summary.implicitWidth + Tokens.spacing.large + cellSize * columns : 420
    implicitHeight: hasItems ? Math.max(summary.implicitHeight, layout.implicitHeight) : layout.implicitHeight

    HkCard {
        id: summary

        anchors.left: parent.left
        anchors.top: parent.top
        visible: root.hasItems
        implicitWidth: 140
        implicitHeight: Math.max(140, layout.implicitHeight)
        ornate: true

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Tokens.spacing.small

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.selected.length || Shelf.items.length
                color: Hallownest.soul
                font.family: Hallownest.serif
                font.pointSize: 26
                font.weight: Font.Bold
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.selected.length ? Tr.tr("selected") : Shelf.items.length === 1 ? Tr.tr("item") : Tr.tr("items")
                color: Hallownest.subtext
                font.pointSize: 9
            }

            HkButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Tokens.spacing.small
                visible: root.selected.length > 0
                icon: "delete"
                text: Tr.tr("Remove")
                accent: Hallownest.grimm
                tinted: true
                onClicked: {
                    Shelf.remove(root.selected);
                    root.selected = [];
                }
            }

            HkButton {
                readonly property var targets: Shelf.items.filter(i => root.selected.includes(i.id) && Shelf.canConvert(i))

                Layout.alignment: Qt.AlignHCenter
                visible: targets.length > 0
                icon: Shelf.converting ? "hourglass_top" : "markdown"
                text: Tr.tr("To Markdown")
                disabled: Shelf.converting
                onClicked: Shelf.toMarkdown(targets)
            }

            HkButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: root.selected.length ? 0 : Tokens.spacing.small
                icon: "clear_all"
                text: Tr.tr("Clear")
                onClicked: {
                    root.selected = [];
                    Shelf.clear();
                }
            }
        }
    }

    ColumnLayout {
        id: layout

        anchors.left: root.hasItems ? summary.right : parent.left
        anchors.leftMargin: root.hasItems ? Tokens.spacing.large : 0
        anchors.right: parent.right
        spacing: Tokens.spacing.small

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Tokens.spacing.large
            Layout.bottomMargin: Tokens.spacing.large
            visible: Shelf.items.length === 0
            spacing: Tokens.spacing.small

            Mask {
                Layout.alignment: Qt.AlignHCenter
                size: 48
                filled: false
                colour: Hallownest.steel
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Tr.tr("Drop files here")
                color: Hallownest.subtext
                font.family: Hallownest.serif
                font.pointSize: 11
            }
        }

        GridView {
            id: grid

            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(2, Math.ceil(count / root.columns)) * root.cellSize
            visible: count > 0
            clip: true
            interactive: contentHeight > height
            cellWidth: root.cellSize
            cellHeight: root.cellSize + 12

            model: ScriptModel {
                values: Shelf.items
                objectProp: "id"
            }

            add: Transition {
                Anim {
                    property: "opacity"
                    from: 0
                    to: 1
                    type: Anim.DefaultEffects
                }
                Anim {
                    property: "scale"
                    from: 0.6
                    to: 1
                }
            }

            remove: Transition {
                Anim {
                    property: "opacity"
                    to: 0
                    type: Anim.DefaultEffects
                }
                Anim {
                    property: "scale"
                    to: 0.6
                }
            }

            displaced: Transition {
                Anim {
                    properties: "x,y"
                }
            }

            delegate: Item {
                id: card

                required property var modelData
                required property int index
                readonly property bool isText: modelData.type === "text"
                readonly property bool isImage: (modelData.mime ?? "").startsWith("image/")
                readonly property bool isSelected: root.selected.includes(modelData.id)

                width: grid.cellWidth
                height: grid.cellHeight

                StyledRect {
                    id: bg

                    anchors.fill: parent
                    anchors.margins: Tokens.spacing.extraSmall
                    radius: 12
                    color: card.isSelected ? Qt.alpha(Hallownest.soul, 0.1) : Hallownest.card
                    border.width: 1
                    border.color: card.isSelected ? Qt.alpha(Hallownest.soul, 0.6) : Hallownest.border

                    Drag.dragType: Drag.Automatic
                    Drag.supportedActions: Qt.CopyAction
                    Drag.proposedAction: Qt.CopyAction
                    Drag.onDragFinished: dropAction => root.finishDrag(dropAction)

                    StyledText {
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.small
                        visible: card.isText
                        text: card.modelData.text ?? ""
                        color: Hallownest.text
                        font.pointSize: 9
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        maximumLineCount: 5
                        elide: Text.ElideRight
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.small
                        visible: !card.isText
                        spacing: Tokens.spacing.extraSmall

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Image {
                                anchors.fill: parent
                                visible: card.isImage
                                source: card.isImage ? card.modelData.uri : ""
                                sourceSize.width: 160
                                sourceSize.height: 160
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                            }

                            Image {
                                anchors.centerIn: parent
                                visible: !card.isImage
                                width: 44
                                height: 44
                                sourceSize.width: 44
                                sourceSize.height: 44
                                source: {
                                    const mime = card.modelData.mime ?? "";
                                    if (mime === "inode/directory")
                                        return Icons.iconPath("folder", "inode-directory");
                                    return Icons.iconPath(mime.replace("/", "-"), "text-x-generic");
                                }
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: Shelf.nameOf(card.modelData)
                            color: Hallownest.soul
                            font.pointSize: 9
                            font.weight: Font.DemiBold
                            elide: Text.ElideMiddle
                        }

                        StyledText {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: Shelf.sizeStr(card.modelData)
                            color: Hallownest.subtext
                            font.pointSize: 8
                        }
                    }

                    HoverHandler {
                        onHoveredChanged: {
                            if (hovered)
                                bg.grabToImage(r => bg.Drag.imageSource = r.url);
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: mouse => root.click(card.index, card.modelData, mouse?.modifiers ?? 0)
                        onDoubleClicked: Shelf.open(card.modelData)
                    }

                    DragHandler {
                        target: null

                        onActiveChanged: {
                            if (!active)
                                return;
                            const items = root.itemsFor(card.modelData.id);
                            root.dragIds = items.map(i => i.id);
                            bg.Drag.mimeData = root.mimeFor(items);
                            Shelf.dragging = true;
                            bg.Drag.active = true;
                        }
                    }
                }
            }
        }
    }
}
