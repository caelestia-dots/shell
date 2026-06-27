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
            // Track monitor to be refreshed after layout updates
            property string pendingRefreshName: ""

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

                const availW = Math.max(0, previewContainer.width - 2 * padding);
                const availH = Math.max(0, previewContainer.height - 2 * padding);

                if (spanX > 0 && spanY > 0) {
                    scaleFactor = Math.min(availW / spanX, availH / spanY);
                } else {
                    scaleFactor = 1.0;
                }

                offsetX = padding + (availW - spanX * scaleFactor) / 2;
                offsetY = padding + (availH - spanY * scaleFactor) / 2;
            }

            function getX(mon: var): real {
                if (!mon)
                    return 0;
                return offsetX + ((mon.x ?? 0) - minX) * scaleFactor;
            }

            function getY(mon: var): real {
                if (!mon)
                    return 0;
                return offsetY + ((mon.y ?? 0) - minY) * scaleFactor;
            }

            function getWidth(mon: var): real {
                if (!mon)
                    return 0;
                return (mon.width / (mon.scale || 1.0)) * scaleFactor;
            }

            function getHeight(mon: var): real {
                if (!mon)
                    return 0;
                return (mon.height / (mon.scale || 1.0)) * scaleFactor;
            }

            // Overlap detection
            function rectsOverlap(ax: real, ay: real, aw: real, ah: real, bx: real, by: real, bw: real, bh: real): bool {
                return ax < bx + bw && ax + aw > bx && ay < by + bh && ay + ah > by;
            }

            // Snap logic based on angular offset from neighbor center
            function snapMonitor(mon: var, dropCX: real, dropCY: real): void {
                if (!mon)
                    return;
                const mons = Hyprctl.monitors;
                if (!mons || mons.length === 0)
                    return;

                const lw = Math.round(mon.width / (mon.scale || 1));
                const lh = Math.round(mon.height / (mon.scale || 1));

                let bestLX = 0;
                let bestLY = 0;
                let bestDist = Infinity;
                let found = false;

                for (let i = 0; i < mons.length; i++) {
                    const o = mons[i];
                    if (o.id === mon.id || (o.disabled ?? false))
                        continue;

                    const ow = Math.round(o.width / (o.scale || 1));
                    const oh = Math.round(o.height / (o.scale || 1));

                    // Center of the other monitor in preview pixel coordinates
                    const ocx = getX(o) + getWidth(o) * 0.5;
                    const ocy = getY(o) + getHeight(o) * 0.5;

                    // Vector from other's center to where the user dropped
                    const dx = dropCX - ocx;
                    const dy = dropCY - ocy;

                    // Determine target side using aspect ratio comparison
                    let snapLX, snapLY;
                    if (Math.abs(dx) * oh > Math.abs(dy) * ow) {
                        // ── Horizontal snap ────────────────────────────────
                        if (dx > 0) {
                            snapLX = o.x + ow;                          // right of other
                            snapLY = o.y + Math.round((oh - lh) / 2);
                        } else {
                            snapLX = o.x - lw;                          // left of other
                            snapLY = o.y + Math.round((oh - lh) / 2);
                        }
                    } else {
                        // ── Vertical snap ──────────────────────────────────
                        if (dy > 0) {
                            snapLX = o.x + Math.round((ow - lw) / 2);  // below other
                            snapLY = o.y + oh;
                        } else {
                            snapLX = o.x + Math.round((ow - lw) / 2);  // above other
                            snapLY = o.y - lh;
                        }
                    }

                    const dist = dx * dx + dy * dy;
                    if (dist < bestDist) {
                        bestDist = dist;
                        bestLX = Math.round(snapLX);
                        bestLY = Math.round(snapLY);
                        found = true;
                    }
                }

                if (!found)
                    return;

                // Avoid overlapping existing displays
                for (let i = 0; i < mons.length; i++) {
                    const o = mons[i];
                    if (o.id === mon.id)
                        continue;
                    const ow = Math.round(o.width / (o.scale || 1));
                    const oh = Math.round(o.height / (o.scale || 1));
                    if (rectsOverlap(bestLX, bestLY, lw, lh, o.x, o.y, ow, oh))
                        return;
                }

                // Apply changes to Hyprland
                const scale = mon.scale || 1;
                const transform = mon.transform || 0;
                const rr = (mon.refreshRate || 60).toFixed(3);
                let s = `${mon.name},${mon.width}x${mon.height}@${rr},${bestLX}x${bestLY},${scale}`;
                if (transform !== 0)
                    s += `,transform,${transform}`;
                Monitors.sendKeyword(s);
            }

            Layout.fillWidth: true
            Layout.preferredHeight: 280
            implicitHeight: 280
            color: "transparent"
            radius: Tokens.rounding.large

            onWidthChanged: updateBoundaries()
            Component.onCompleted: updateBoundaries()

            Connections {
                function onMonitorsChanged(): void {
                    previewContainer.updateBoundaries();
                    // Trigger refresh on the moved monitor
                    if (previewContainer.pendingRefreshName !== "") {
                        const name = previewContainer.pendingRefreshName;
                        previewContainer.pendingRefreshName = "";
                        Monitors.refresh(name);
                    }
                }

                target: Hyprctl
            }

            Repeater {
                model: Hyprctl.monitors

                delegate: Item {
                    id: monitorBox

                    required property var modelData
                    required property int index

                    readonly property real targetX: previewContainer.getX(monitorBox.modelData)
                    readonly property real targetY: previewContainer.getY(monitorBox.modelData)
                    readonly property real targetW: previewContainer.getWidth(monitorBox.modelData)
                    readonly property real targetH: previewContainer.getHeight(monitorBox.modelData)
                    readonly property bool isCurrentScreen: monitorBox.modelData != null && root.nState.screen != null && monitorBox.modelData.name === root.nState.screen.name
                    readonly property bool isSelected: root.nState.selectedMonitor != null && root.nState.selectedMonitor.id === monitorBox.modelData.id
                    readonly property bool isDisabled: monitorBox.modelData != null && (monitorBox.modelData.disabled ?? false)

                    x: targetX
                    y: targetY
                    width: targetW
                    height: targetH
                    visible: monitorBox.modelData != null && targetW > 0 && targetH > 0

                    onTargetXChanged: {
                        if (!dragArea.pressed)
                            x = targetX;
                    }
                    onTargetYChanged: {
                        if (!dragArea.pressed)
                            y = targetY;
                    }

                    // Box background
                    Rectangle {
                        anchors.fill: parent
                        radius: Tokens.rounding.medium
                        color: monitorBox.isSelected ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHigh
                        opacity: monitorBox.isDisabled ? 0.45 : 1.0
                        border.color: monitorBox.isSelected ? Colours.palette.m3primary : monitorBox.isCurrentScreen ? Colours.palette.m3secondary : "transparent"
                        border.width: monitorBox.isSelected || monitorBox.isCurrentScreen ? 2 : 0

                        Behavior on color {
                            CAnim {}
                        }
                        Behavior on border.color {
                            CAnim {}
                        }
                    }

                    // Content: icon + name + resolution
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Tokens.spacing.extraSmall / 2

                        MaterialIcon {
                            Layout.alignment: Qt.AlignHCenter
                            text: monitorBox.isDisabled ? "desktop_access_disabled" : "monitor"
                            fontStyle: Tokens.font.icon.medium
                            color: monitorBox.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                            opacity: monitorBox.isDisabled ? 0.5 : 1.0
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: monitorBox.modelData.name + " - " + monitorBox.modelData.id
                            font: Tokens.font.body.small
                            color: monitorBox.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: monitorBox.isDisabled ? qsTr("Disconnected") : `${monitorBox.modelData.width}x${monitorBox.modelData.height}`
                            font: Tokens.font.label.small
                            color: monitorBox.isSelected ? Colours.palette.m3onPrimaryContainer : monitorBox.isDisabled ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                            opacity: 0.85
                        }

                        // Indicate hosting screen
                        MaterialIcon {
                            Layout.alignment: Qt.AlignHCenter
                            visible: monitorBox.isCurrentScreen
                            text: "lock"
                            fontStyle: Tokens.font.icon.small
                            color: monitorBox.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                            opacity: 0.55
                        }
                    }

                    MouseArea {
                        id: dragArea

                        property real startX
                        property real startY
                        // Only true if the user dragged the monitor
                        property bool dragged: false

                        enabled: !monitorBox.isDisabled
                        anchors.fill: parent
                        cursorShape: enabled ? Qt.SizeAllCursor : Qt.ArrowCursor

                        onPressed: mouse => {
                            startX = mouse.x;
                            startY = mouse.y;
                            dragged = false;
                            monitorBox.z = 100;
                            root.nState.selectedMonitor = monitorBox.modelData;
                            root.flickable.interactive = false;
                        }

                        onPositionChanged: mouse => {
                            if (pressed) {
                                const newX = monitorBox.x + mouse.x - startX;
                                const newY = monitorBox.y + mouse.y - startY;
                                monitorBox.x = Math.max(0, Math.min(previewContainer.width - monitorBox.width, newX));
                                monitorBox.y = Math.max(0, Math.min(previewContainer.height - monitorBox.height, newY));
                                // Register drag only after moving past threshold
                                if (Math.abs(monitorBox.x - monitorBox.targetX) + Math.abs(monitorBox.y - monitorBox.targetY) > 5)
                                    dragged = true;
                            }
                        }

                        onReleased: {
                            monitorBox.z = 1;
                            if (dragged) {
                                previewContainer.pendingRefreshName = monitorBox.modelData ? monitorBox.modelData.name : "";
                                previewContainer.snapMonitor(monitorBox.modelData, monitorBox.x + monitorBox.width * 0.5, monitorBox.y + monitorBox.height * 0.5);
                            }
                            monitorBox.x = monitorBox.targetX;
                            monitorBox.y = monitorBox.targetY;
                            root.flickable.interactive = true;
                            root.nState.selectedMonitor = monitorBox.modelData;
                        }

                        onCanceled: {
                            monitorBox.z = 1;
                            monitorBox.x = monitorBox.targetX;
                            monitorBox.y = monitorBox.targetY;
                            root.flickable.interactive = true;
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

                    readonly property bool isDisabled: monitorItem.modelData != null && (monitorItem.modelData.disabled ?? false)

                    Layout.fillWidth: true
                    implicitHeight: monitorItem.modelData != null ? itemLayout.implicitHeight + itemLayout.anchors.margins * 2 : 0
                    visible: monitorItem.modelData != null
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
                            text: monitorItem.isDisabled ? "desktop_access_disabled" : "monitor"
                            fontStyle: Tokens.font.icon.medium
                            color: monitorItem.isDisabled ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                            opacity: monitorItem.isDisabled ? 0.7 : 1.0
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
                                    if (!m)
                                        return "";
                                    if (monitorItem.isDisabled)
                                        return qsTr("Disconnected");
                                    if (!m.width || !m.height)
                                        return qsTr("Unavailable");
                                    const rr = m.refreshRate ?? 0;
                                    return qsTr("%1×%2 @ %3 Hz").arg(m.width).arg(m.height).arg(rr.toFixed(0));
                                }
                                color: monitorItem.isDisabled ? Colours.palette.m3error : Colours.palette.m3outline
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
