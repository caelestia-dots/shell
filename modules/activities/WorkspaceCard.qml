pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

Item {
    id: root

    required property ShellScreen screen
    required property int wsId
    required property real cardWidth

    property bool dropHover: Activities.overviewDropTargetWs === wsId

    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)
    readonly property bool isActive: Hypr.activeWsId === wsId
    readonly property var windows: Hypr.toplevelsForWs(wsId)
    readonly property real aspect: {
        const mon = root.monitor;
        if (!mon || mon.width <= 0 || mon.height <= 0)
            return screen.width / Math.max(1, screen.height);
        return mon.width / mon.height;
    }

    implicitWidth: cardWidth
    implicitHeight: cardWidth / Math.max(0.5, aspect)

    function containsDragPoint(globalPos: point): bool {
        const local = cardFrame.mapFromGlobal(globalPos.x, globalPos.y);
        return local.x >= 0 && local.y >= 0 && local.x <= cardFrame.width && local.y <= cardFrame.height;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Tokens.spacing.extraSmall

        Rectangle {
            id: cardFrame

            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Tokens.rounding.large
            color: "transparent"
            border.width: root.dropHover ? 3 : (root.isActive ? 2 : 1)
            border.color: root.dropHover ? Colours.palette.m3tertiary : (root.isActive ? Colours.palette.m3primary : Colours.palette.m3outlineVariant)

            Behavior on border.color {
                CAnim {}
            }

            ClipRect {
                id: card

                anchors.fill: parent
                anchors.margins: cardFrame.border.width
                radius: Math.max(0, Tokens.rounding.large - anchors.margins)
                color: root.dropHover ? Colours.palette.m3tertiaryContainer : (root.isActive ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainerHigh)

                Behavior on color {
                    CAnim {}
                }

                MouseArea {
                    anchors.fill: parent
                    z: 0
                    onClicked: Activities.selectWorkspace(root.wsId)
                }

                Item {
                    id: stage

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.extraSmall
                    clip: true
                    z: 1

                    Repeater {
                        model: root.windows

                        Item {
                            id: winItem

                            required property var modelData

                            readonly property var toplevel: modelData
                            readonly property var ipc: modelData.lastIpcObject
                            readonly property bool pinned: Activities.isWindowPinned(modelData)
                            readonly property real monX: root.monitor?.x ?? 0
                            readonly property real monY: root.monitor?.y ?? 0
                            readonly property real monW: Math.max(1, root.monitor?.width ?? screen.width)
                            readonly property real monH: Math.max(1, root.monitor?.height ?? screen.height)
                            readonly property real layoutX: ((ipc?.at?.[0] ?? 0) - monX) / monW * stage.width
                            readonly property real layoutY: ((ipc?.at?.[1] ?? 0) - monY) / monH * stage.height

                            property bool dragging
                            property bool didDrag
                            property Item homeParent: stage

                            width: Math.max(8, ((ipc?.size?.[0] ?? monW) / monW) * stage.width)
                            height: Math.max(8, ((ipc?.size?.[1] ?? monH) / monH) * stage.height)
                            z: dragging ? 100 : (dragArea.containsMouse ? 10 : 1)
                            opacity: dragging ? 0.9 : (pinned ? 0.88 : 1)
                            scale: dragging ? 1.06 : (dragArea.containsMouse ? 1.04 : 1)

                            Binding on x {
                                when: !winItem.dragging
                                value: winItem.layoutX
                            }

                            Binding on y {
                                when: !winItem.dragging
                                value: winItem.layoutY
                            }

                            Behavior on scale {
                                Anim {
                                    type: Anim.DefaultEffects
                                }
                            }

                            function beginDrag(): void {
                                if (pinned)
                                    return;
                                const layer = Activities.overviewDragLayer;
                                if (!layer)
                                    return;
                                const pos = mapToItem(layer, 0, 0);
                                homeParent = parent;
                                parent = layer;
                                x = pos.x;
                                y = pos.y;
                                dragging = true;
                            }

                            function updateDropTarget(): void {
                                const layer = Activities.overviewDragLayer;
                                if (!layer)
                                    return;
                                const center = Qt.point(winItem.x + winItem.width / 2, winItem.y + winItem.height / 2);
                                const global = layer.mapToGlobal(center.x, center.y);
                                // Walk overview cards via drag layer siblings' content — use registered cards
                                Activities.overviewDropTargetWs = Activities.hitTestOverviewWorkspace(global) ?? -1;
                            }

                            function endDrag(): void {
                                const tl = winItem.toplevel;
                                dragging = false;
                                if (homeParent)
                                    parent = homeParent;
                                if (didDrag)
                                    Activities.finishWindowDrag(tl);
                                Activities.overviewDropTargetWs = -1;
                            }

                            ClipRect {
                                anchors.fill: parent
                                radius: Tokens.rounding.extraSmall
                                color: Colours.tPalette.m3surfaceContainerLowest

                                ScreencopyView {
                                    anchors.centerIn: parent
                                    captureSource: winItem.modelData?.wayland ?? null
                                    live: Activities.overviewOpen && root.visible && !winItem.dragging
                                    constraintSize.width: winItem.width
                                    constraintSize.height: winItem.height
                                }

                                // Soft hover glow
                                Rectangle {
                                    anchors.fill: parent
                                    radius: Tokens.rounding.extraSmall
                                    color: Colours.palette.m3primary
                                    opacity: dragArea.containsMouse && !winItem.dragging ? 0.16 : 0

                                    Behavior on opacity {
                                        Anim {
                                            type: Anim.DefaultEffects
                                        }
                                    }
                                }

                                MaterialIcon {
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 2
                                    visible: winItem.pinned
                                    text: "push_pin"
                                    color: Colours.palette.m3primary
                                    fontStyle: Tokens.font.icon.small
                                }
                            }

                            MouseArea {
                                id: dragArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: winItem.pinned ? Qt.ForbiddenCursor : (pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor)
                                preventStealing: true

                                property real pressX
                                property real pressY
                                property real grabOffsetX
                                property real grabOffsetY
                                readonly property real dragThreshold: 10

                                function moveToCursor(mouse: var): void {
                                    const layer = Activities.overviewDragLayer;
                                    if (!layer || !winItem.dragging)
                                        return;
                                    const p = mapToItem(layer, mouse.x, mouse.y);
                                    winItem.x = p.x - grabOffsetX;
                                    winItem.y = p.y - grabOffsetY;
                                    winItem.updateDropTarget();
                                }

                                onPressed: mouse => {
                                    winItem.didDrag = false;
                                    pressX = mouse.x;
                                    pressY = mouse.y;
                                    grabOffsetX = mouse.x;
                                    grabOffsetY = mouse.y;
                                }

                                onPositionChanged: mouse => {
                                    if (winItem.pinned || !pressed)
                                        return;
                                    if (!winItem.dragging) {
                                        const dist = Math.hypot(mouse.x - pressX, mouse.y - pressY);
                                        if (dist <= dragThreshold)
                                            return;
                                        winItem.didDrag = true;
                                        winItem.beginDrag();
                                    }
                                    moveToCursor(mouse);
                                }

                                onReleased: {
                                    if (winItem.pinned) {
                                        Activities.selectWorkspace(root.wsId);
                                        return;
                                    }
                                    const moved = winItem.didDrag;
                                    winItem.endDrag();
                                    if (!moved)
                                        Activities.selectWorkspace(root.wsId);
                                    winItem.didDrag = false;
                                }

                                onCanceled: {
                                    winItem.dragging = false;
                                    if (winItem.homeParent)
                                        winItem.parent = winItem.homeParent;
                                    Activities.overviewDropTargetWs = -1;
                                    winItem.didDrag = false;
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        visible: root.windows.length === 0
                        spacing: Tokens.spacing.extraSmall

                        MaterialIcon {
                            Layout.alignment: Qt.AlignHCenter
                            text: "desktop_windows"
                            color: Colours.palette.m3outline
                            fontStyle: Tokens.font.icon.large
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: Tr.tr("Empty")
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: Activities.registerOverviewCard(root)
    Component.onDestruction: Activities.unregisterOverviewCard(root)
}
