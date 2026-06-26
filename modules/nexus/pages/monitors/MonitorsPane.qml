pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Displays")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.large

        StyledClippingRect {
            id: previewContainer

            property real minX: 0
            property real minY: 0
            property real maxX: 0
            property real maxY: 0
            property real spanX: 0
            property real spanY: 0
            property real scaleFactor: 1.0
            property real offsetX: 0
            property real offsetY: 0
            property real padding: 24

            function updateBoundaries(): void {
                const mons = Hyprctl.monitors;
                if (!mons || mons.length === 0)
                    return;

                let min_x = Infinity;
                let min_y = Infinity;
                let max_x = -Infinity;
                let max_y = -Infinity;

                for (let i = 0; i < mons.length; i++) {
                    const m = mons[i];
                    const w = m.width / (m.scale || 1.0);
                    const h = m.height / (m.scale || 1.0);
                    if (m.x < min_x)
                        min_x = m.x;
                    if (m.y < min_y)
                        min_y = m.y;
                    if (m.x + w > max_x)
                        max_x = m.x + w;
                    if (m.y + h > max_y)
                        max_y = m.y + h;
                }

                minX = min_x;
                minY = min_y;
                maxX = max_x;
                maxY = max_y;
                spanX = Math.max(1, maxX - minX);
                spanY = Math.max(1, maxY - minY);

                const availW = previewContainer.width - 2 * padding;
                const availH = previewContainer.height - 2 * padding;
                scaleFactor = Math.min(availW / spanX, availH / spanY);

                offsetX = padding + (availW - spanX * scaleFactor) / 2;
                offsetY = padding + (availH - spanY * scaleFactor) / 2;
            }

            function getX(mon: var): real {
                return offsetX + (mon.x - minX) * scaleFactor;
            }

            function getY(mon: var): real {
                return offsetY + (mon.y - minY) * scaleFactor;
            }

            function getWidth(mon: var): real {
                return (mon.width / (mon.scale || 1.0)) * scaleFactor;
            }

            function getHeight(mon: var): real {
                return (mon.height / (mon.scale || 1.0)) * scaleFactor;
            }

            function snapMonitor(mon: var, currentX: real, currentY: real): void {
                const mons = Hyprctl.monitors;
                if (!mons || mons.length <= 1)
                    return;

                const otherMons = [];
                for (let i = 0; i < mons.length; i++) {
                    if (mons[i].id !== mon.id) {
                        otherMons.push({
                            id: mons[i].id,
                            name: mons[i].name,
                            previewX: getX(mons[i]),
                            previewY: getY(mons[i]),
                            previewW: getWidth(mons[i]),
                            previewH: getHeight(mons[i])
                        });
                    }
                }

                const w = getWidth(mon);
                const h = getHeight(mon);

                let minDistance = Infinity;
                let bestTarget = null;
                let bestPos = "";

                for (let i = 0; i < otherMons.length; i++) {
                    const other = otherMons[i];

                    const snaps = [
                        {
                            pos: "left",
                            x: other.previewX - w,
                            y: other.previewY + (other.previewH - h) / 2
                        },
                        {
                            pos: "right",
                            x: other.previewX + other.previewW,
                            y: other.previewY + (other.previewH - h) / 2
                        },
                        {
                            pos: "top",
                            x: other.previewX + (other.previewW - w) / 2,
                            y: other.previewY - h
                        },
                        {
                            pos: "bottom",
                            x: other.previewX + (other.previewW - w) / 2,
                            y: other.previewY + other.previewH
                        }
                    ];

                    for (let j = 0; j < snaps.length; j++) {
                        const snap = snaps[j];
                        const dx = currentX - snap.x;
                        const dy = currentY - snap.y;
                        const dist = dx * dx + dy * dy;
                        if (dist < minDistance) {
                            minDistance = dist;
                            bestTarget = other;
                            bestPos = snap.pos;
                        }
                    }
                }

                if (bestTarget && bestPos !== "") {
                    Monitors.arrange(mon.name, bestPos, bestTarget.id);
                }
            }

            Layout.fillWidth: true
            implicitHeight: 220
            color: Colours.tPalette.m3surfaceContainer
            radius: Tokens.rounding.large

            onWidthChanged: updateBoundaries()
            Component.onCompleted: updateBoundaries()

            Connections {
                function onMonitorsChanged(): void {
                    previewContainer.updateBoundaries();
                }

                target: Hyprctl
            }

            Repeater {
                model: Hyprctl.monitors

                delegate: StyledRect {
                    id: monitorBox

                    required property var modelData
                    required property int index

                    readonly property real targetX: previewContainer.getX(modelData)
                    readonly property real targetY: previewContainer.getY(modelData)
                    readonly property real targetW: previewContainer.getWidth(modelData)
                    readonly property real targetH: previewContainer.getHeight(modelData)

                    x: targetX
                    y: targetY
                    width: targetW
                    height: targetH
                    color: (root.nState.selectedMonitor && root.nState.selectedMonitor.id === modelData.id) ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceVariant
                    radius: Tokens.rounding.medium
                    border.color: (root.nState.selectedMonitor && root.nState.selectedMonitor.id === modelData.id) ? Colours.palette.m3primary : "transparent"
                    border.width: 2

                    onTargetXChanged: {
                        if (!dragArea.pressed) {
                            x = targetX;
                        }
                    }
                    onTargetYChanged: {
                        if (!dragArea.pressed) {
                            y = targetY;
                        }
                    }

                    Behavior on color {
                        CAnim {}
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: monitorBox.modelData.name
                            font: Tokens.font.body.small
                            color: (root.nState.selectedMonitor && root.nState.selectedMonitor.id === modelData.id) ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: `${monitorBox.modelData.width}x${monitorBox.modelData.height}`
                            font: Tokens.font.label.small
                            color: (root.nState.selectedMonitor && root.nState.selectedMonitor.id === modelData.id) ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                            opacity: 0.8
                        }
                    }

                    MouseArea {
                        id: dragArea

                        property real startX
                        property real startY

                        anchors.fill: parent

                        onPressed: mouse => {
                            startX = mouse.x;
                            startY = mouse.y;
                            monitorBox.z = 100;
                            root.nState.selectedMonitor = monitorBox.modelData;
                        }

                        onPositionChanged: mouse => {
                            if (pressed) {
                                const newX = monitorBox.x + mouse.x - startX;
                                const newY = monitorBox.y + mouse.y - startY;
                                monitorBox.x = Math.max(0, Math.min(previewContainer.width - monitorBox.width, newX));
                                monitorBox.y = Math.max(0, Math.min(previewContainer.height - monitorBox.height, newY));
                            }
                        }

                        onReleased: {
                            monitorBox.z = 1;
                            previewContainer.snapMonitor(monitorBox.modelData, monitorBox.x, monitorBox.y);
                            monitorBox.x = monitorBox.targetX;
                            monitorBox.y = monitorBox.targetY;
                        }

                        onDoubleClicked: {
                            root.nState.selectedMonitor = monitorBox.modelData;
                            root.nState.openSubPage(1);
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall / 2

            ToggleRow {
                Layout.fillWidth: true
                first: true
                text: qsTr("Identify displays")
                font: Tokens.font.body.medium
                horizontalPadding: Tokens.padding.largeIncreased
                checked: Monitors.identifying
                onToggled: Monitors.toggleIdentification()
            }

            Repeater {
                model: Hyprctl.monitors

                delegate: ConnectedRect {
                    id: monitorItem

                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    implicitHeight: itemLayout.implicitHeight + itemLayout.anchors.margins * 2
                    first: false
                    last: index === Hyprctl.monitors.length - 1

                    StateLayer {
                        onClicked: {
                            root.nState.selectedMonitor = monitorItem.modelData;
                            root.nState.openSubPage(1);
                        }
                    }

                    RowLayout {
                        id: itemLayout

                        anchors.fill: parent
                        anchors.margins: Tokens.padding.medium
                        anchors.leftMargin: Tokens.padding.largeIncreased
                        anchors.rightMargin: Tokens.padding.largeIncreased
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            text: "monitor"
                            fontStyle: Tokens.font.icon.medium
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                Layout.fillWidth: true
                                text: monitorItem.modelData.name
                                font: Tokens.font.body.small
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: {
                                    const m = monitorItem.modelData;
                                    if (!m || !m.width || !m.height)
                                        return qsTr("Unavailable");
                                    const rr = m.refreshRate ?? 0;
                                    return qsTr("%1×%2 @ %3 Hz").arg(m.width).arg(m.height).arg(rr.toFixed(0));
                                }
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.small
                                elide: Text.ElideRight
                            }
                        }

                        MaterialIcon {
                            text: (monitorItem.modelData.focused ?? false) ? "settings" : "chevron_right"
                            color: (monitorItem.modelData.focused ?? false) ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.medium
                        }
                    }
                }
            }
        }
    }
}
