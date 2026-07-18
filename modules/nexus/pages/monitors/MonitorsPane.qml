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
            property real softSnapDistance: 6
            property var previewPositions: ({})
            property bool dragging: false

            function layoutMonitors(): var {
                return Hyprctl.monitors ?? [];
            }

            function monitorsTouch(first: var, firstPosition: var, second: var, secondPosition: var): bool {
                const firstW = first.width / (first.scale || 1);
                const firstH = first.height / (first.scale || 1);
                const secondW = second.width / (second.scale || 1);
                const secondH = second.height / (second.scale || 1);
                const horizontalTouch = Math.abs(firstPosition.x + firstW - secondPosition.x) <= 1 || Math.abs(secondPosition.x + secondW - firstPosition.x) <= 1;
                const verticalTouch = Math.abs(firstPosition.y + firstH - secondPosition.y) <= 1 || Math.abs(secondPosition.y + secondH - firstPosition.y) <= 1;
                const verticalOverlap = firstPosition.y < secondPosition.y + secondH && firstPosition.y + firstH > secondPosition.y;
                const horizontalOverlap = firstPosition.x < secondPosition.x + secondW && firstPosition.x + firstW > secondPosition.x;
                return horizontalTouch && verticalOverlap || verticalTouch && horizontalOverlap;
            }

            function layoutHasOverlaps(monitors: var, positions: var): bool {
                for (let i = 0; i < monitors.length; i++) {
                    const first = monitors[i];
                    const firstPosition = positions[first.id] ?? {
                        x: first.x,
                        y: first.y
                    };
                    const firstW = first.width / (first.scale || 1);
                    const firstH = first.height / (first.scale || 1);
                    for (let j = i + 1; j < monitors.length; j++) {
                        const second = monitors[j];
                        const secondPosition = positions[second.id] ?? {
                            x: second.x,
                            y: second.y
                        };
                        const secondW = second.width / (second.scale || 1);
                        const secondH = second.height / (second.scale || 1);
                        if (firstPosition.x < secondPosition.x + secondW && firstPosition.x + firstW > secondPosition.x && firstPosition.y < secondPosition.y + secondH && firstPosition.y + firstH > secondPosition.y)
                            return true;
                    }
                }
                return false;
            }

            function layoutIsConnected(monitors: var, positions: var): bool {
                if (monitors.length < 2)
                    return true;
                const connected = new Set([monitors[0].id]);
                let expanded = true;

                while (expanded) {
                    expanded = false;
                    for (let i = 0; i < monitors.length; i++) {
                        const first = monitors[i];
                        if (!connected.has(first.id))
                            continue;
                        const firstPosition = positions[first.id] ?? {
                            x: first.x,
                            y: first.y
                        };
                        for (let j = 0; j < monitors.length; j++) {
                            const second = monitors[j];
                            if (connected.has(second.id))
                                continue;
                            const secondPosition = positions[second.id] ?? {
                                x: second.x,
                                y: second.y
                            };
                            if (monitorsTouch(first, firstPosition, second, secondPosition)) {
                                connected.add(second.id);
                                expanded = true;
                            }
                        }
                    }
                }

                return connected.size === monitors.length;
            }

            function normalizeLayout(monitors: var, positions: var, rootId: int): bool {
                const connected = new Set([rootId]);
                let expanded = true;

                function updateConnected(): bool {
                    const previousSize = connected.size;
                    expanded = true;
                    while (expanded) {
                        expanded = false;
                        for (let i = 0; i < monitors.length; i++) {
                            const first = monitors[i];
                            if (!connected.has(first.id))
                                continue;
                            const firstPosition = positions[first.id] ?? {
                                x: first.x,
                                y: first.y
                            };
                            for (let j = 0; j < monitors.length; j++) {
                                const second = monitors[j];
                                if (connected.has(second.id))
                                    continue;
                                const secondPosition = positions[second.id] ?? {
                                    x: second.x,
                                    y: second.y
                                };
                                if (monitorsTouch(first, firstPosition, second, secondPosition)) {
                                    connected.add(second.id);
                                    expanded = true;
                                }
                            }
                        }
                    }
                    return connected.size > previousSize;
                }

                updateConnected();
                while (connected.size < monitors.length) {
                    let bestCandidate = null;
                    for (let i = 0; i < monitors.length; i++) {
                        const isolated = monitors[i];
                        if (connected.has(isolated.id))
                            continue;
                        const isolatedPosition = positions[isolated.id] ?? {
                            x: isolated.x,
                            y: isolated.y
                        };
                        const isolatedW = isolated.width / (isolated.scale || 1);
                        const isolatedH = isolated.height / (isolated.scale || 1);

                        for (let j = 0; j < monitors.length; j++) {
                            const target = monitors[j];
                            if (!connected.has(target.id))
                                continue;
                            const targetPosition = positions[target.id] ?? {
                                x: target.x,
                                y: target.y
                            };
                            const targetW = target.width / (target.scale || 1);
                            const targetH = target.height / (target.scale || 1);
                            const minY = targetPosition.y - isolatedH;
                            const maxY = targetPosition.y + targetH;
                            const minX = targetPosition.x - isolatedW;
                            const maxX = targetPosition.x + targetW;
                            const candidates = [{
                                x: targetPosition.x - isolatedW,
                                y: Math.max(minY, Math.min(maxY, isolatedPosition.y))
                            }, {
                                x: targetPosition.x + targetW,
                                y: Math.max(minY, Math.min(maxY, isolatedPosition.y))
                            }, {
                                x: Math.max(minX, Math.min(maxX, isolatedPosition.x)),
                                y: targetPosition.y - isolatedH
                            }, {
                                x: Math.max(minX, Math.min(maxX, isolatedPosition.x)),
                                y: targetPosition.y + targetH
                            }];

                            for (let k = 0; k < candidates.length; k++) {
                                const candidate = candidates[k];
                                let overlaps = false;
                                for (let l = 0; l < monitors.length; l++) {
                                    const other = monitors[l];
                                    if (other.id === isolated.id || other.id === target.id)
                                        continue;
                                    const otherPosition = positions[other.id] ?? {
                                        x: other.x,
                                        y: other.y
                                    };
                                    const otherW = other.width / (other.scale || 1);
                                    const otherH = other.height / (other.scale || 1);
                                    if (candidate.x < otherPosition.x + otherW && candidate.x + isolatedW > otherPosition.x && candidate.y < otherPosition.y + otherH && candidate.y + isolatedH > otherPosition.y) {
                                        overlaps = true;
                                        break;
                                    }
                                }
                                if (overlaps)
                                    continue;

                                const distance = Math.hypot(candidate.x - isolatedPosition.x, candidate.y - isolatedPosition.y);
                                if (bestCandidate === null || distance < bestCandidate.distance) {
                                    bestCandidate = {
                                        monitor: isolated,
                                        x: candidate.x,
                                        y: candidate.y,
                                        distance: distance
                                    };
                                }
                            }
                        }
                    }

                    if (bestCandidate === null)
                        return false;
                    positions[bestCandidate.monitor.id] = {
                        x: bestCandidate.x,
                        y: bestCandidate.y
                    };
                    if (!updateConnected())
                        return false;
                }

                return true;
            }

            function updateBoundaries(): void {
                const mons = layoutMonitors();
                if (mons.length === 0)
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

            function positionFor(mon: var): var {
                return previewPositions[mon.id] ?? mon;
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

            // Snap monitor edges while preserving the dropped offset
            function snapCandidate(mon: var, dropX: real, dropY: real): var {
                if (!mon || scaleFactor <= 0)
                    return null;
                const mons = layoutMonitors();
                if (mons.length === 0)
                    return null;

                const lw = Math.round(mon.width / (mon.scale || 1));
                const lh = Math.round(mon.height / (mon.scale || 1));
                const desiredX = Math.round(minX + (dropX - offsetX) / scaleFactor);
                const desiredY = Math.round(minY + (dropY - offsetY) / scaleFactor);
                const desiredCenterX = desiredX + lw / 2;
                const desiredCenterY = desiredY + lh / 2;
                let bestCandidate = null;

                for (let i = 0; i < mons.length; i++) {
                    const o = mons[i];
                    if (o.id === mon.id || (o.disabled ?? false))
                        continue;

                    const ow = Math.round(o.width / (o.scale || 1));
                    const oh = Math.round(o.height / (o.scale || 1));
                    const dx = desiredCenterX - (o.x + ow / 2);
                    const dy = desiredCenterY - (o.y + oh / 2);
                    const verticalOverlap = desiredY < o.y + oh && desiredY + lh > o.y;
                    const horizontalDistance = Math.abs(dx) / (ow + lw);
                    const verticalDistance = Math.abs(dy) / (oh + lh);
                    const horizontal = horizontalDistance >= verticalDistance * (verticalOverlap ? 0.75 : 1);
                    let candidate;
                    const softSnapThreshold = softSnapDistance / scaleFactor;
                    if (horizontal) {
                        const topOffset = Math.abs(desiredY - o.y);
                        const bottomOffset = Math.abs(desiredY + lh - (o.y + oh));
                        candidate = {
                            x: dx < 0 ? o.x - lw : o.x + ow,
                            y: topOffset <= softSnapThreshold && topOffset <= bottomOffset ? o.y : bottomOffset <= softSnapThreshold ? o.y + oh - lh : desiredY,
                            side: dx < 0 ? "left" : "right",
                            directionX: dx < 0 ? -1 : 1,
                            directionY: 0
                        };
                    } else {
                        const leftOffset = Math.abs(desiredX - o.x);
                        const rightOffset = Math.abs(desiredX + lw - (o.x + ow));
                        candidate = {
                            x: leftOffset <= softSnapThreshold && leftOffset <= rightOffset ? o.x : rightOffset <= softSnapThreshold ? o.x + ow - lw : desiredX,
                            y: dy < 0 ? o.y - lh : o.y + oh,
                            side: dy < 0 ? "top" : "bottom",
                            directionX: 0,
                            directionY: dy < 0 ? -1 : 1
                        };
                    }
                    candidate.targetId = o.id;
                    candidate.distance = Math.hypot(dx / (ow + lw), dy / (oh + lh));

                    if (bestCandidate === null || candidate.distance < bestCandidate.distance)
                        bestCandidate = candidate;
                }

                return bestCandidate;
            }

            function layoutPlan(mon: var, dropX: real, dropY: real): var {
                const candidate = snapCandidate(mon, dropX, dropY);
                if (candidate === null)
                    return null;
                const mons = layoutMonitors();
                const positions = {};
                positions[mon.id] = {
                    x: candidate.x,
                    y: candidate.y
                };
                const queue = [mon];
                const queued = new Set([mon.id]);
                const maxIterations = mons.length * mons.length;
                let iterations = 0;

                while (queue.length > 0 && iterations < maxIterations) {
                    const current = queue.shift();
                    queued.delete(current.id);
                    const currentPos = positions[current.id];
                    const currentW = Math.round(current.width / (current.scale || 1));
                    const currentH = Math.round(current.height / (current.scale || 1));
                    iterations++;

                    for (let i = 0; i < mons.length; i++) {
                        const other = mons[i];
                        if (other.id === current.id || (other.disabled ?? false))
                            continue;
                        const otherPos = positions[other.id] ?? {
                            x: other.x,
                            y: other.y
                        };
                        const otherW = Math.round(other.width / (other.scale || 1));
                        const otherH = Math.round(other.height / (other.scale || 1));
                        const overlaps = currentPos.x < otherPos.x + otherW && currentPos.x + currentW > otherPos.x && currentPos.y < otherPos.y + otherH && currentPos.y + currentH > otherPos.y;
                        if (!overlaps)
                            continue;

                        const nextPos = {
                            x: candidate.directionX > 0 ? currentPos.x + currentW : candidate.directionX < 0 ? currentPos.x - otherW : otherPos.x,
                            y: candidate.directionY > 0 ? currentPos.y + currentH : candidate.directionY < 0 ? currentPos.y - otherH : otherPos.y
                        };
                        if (nextPos.x === otherPos.x && nextPos.y === otherPos.y)
                            continue;
                        positions[other.id] = nextPos;
                        if (!queued.has(other.id)) {
                            queue.push(other);
                            queued.add(other.id);
                        }
                    }
                }

                if (queue.length > 0 || layoutHasOverlaps(mons, positions))
                    return null;
                if (!normalizeLayout(mons, positions, mon.id) || layoutHasOverlaps(mons, positions) || !layoutIsConnected(mons, positions))
                    return null;
                return {
                    candidate: candidate,
                    monitors: mons,
                    positions: positions
                };
            }

            function snapMonitor(mon: var, dropX: real, dropY: real): void {
                const plan = layoutPlan(mon, dropX, dropY);
                if (plan === null)
                    return;
                const movedMonitors = plan.monitors.filter(monitor => plan.positions[monitor.id] !== undefined);
                movedMonitors.sort((first, second) => {
                    const firstPos = plan.positions[first.id];
                    const secondPos = plan.positions[second.id];
                    if (plan.candidate.directionX > 0)
                        return secondPos.x - firstPos.x;
                    if (plan.candidate.directionX < 0)
                        return firstPos.x - secondPos.x;
                    if (plan.candidate.directionY > 0)
                        return secondPos.y - firstPos.y;
                    return firstPos.y - secondPos.y;
                });

                for (let i = 0; i < movedMonitors.length; i++) {
                    const moved = movedMonitors[i];
                    const position = plan.positions[moved.id];
                    Monitors.setPosition(moved.name, position.x, position.y);
                }
                updateBoundaries();
            }

            Layout.fillWidth: true
            Layout.preferredHeight: 280
            implicitHeight: 280
            color: "transparent"
            radius: Tokens.rounding.large
            border.color: previewContainer.dragging ? Colours.palette.m3primary : Colours.palette.m3outlineVariant
            border.width: 1

            onWidthChanged: updateBoundaries()
            onHeightChanged: updateBoundaries()
            Component.onCompleted: updateBoundaries()

            Connections {
                function onMonitorsChanged(): void {
                    previewContainer.updateBoundaries();
                }

                target: Hyprctl
            }

            Repeater {
                model: previewContainer.layoutMonitors()

                delegate: Item {
                    id: monitorBox

                    required property var modelData
                    required property int index

                    readonly property real targetX: previewContainer.getX(previewContainer.positionFor(monitorBox.modelData))
                    readonly property real targetY: previewContainer.getY(previewContainer.positionFor(monitorBox.modelData))
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

                    Behavior on x {
                        enabled: !dragArea.pressed
                        Anim {}
                    }
                    Behavior on y {
                        enabled: !dragArea.pressed
                        Anim {}
                    }

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

                        property real grabOffsetX
                        property real grabOffsetY
                        property real dropX
                        property real dropY
                        // Only true if the user dragged the monitor
                        property bool dragged: false

                        enabled: !monitorBox.isDisabled
                        anchors.fill: parent
                        cursorShape: enabled ? Qt.SizeAllCursor : Qt.ArrowCursor

                        onPressed: mouse => {
                            const point = dragArea.mapToItem(previewContainer, mouse.x, mouse.y);
                            grabOffsetX = point.x - monitorBox.x;
                            grabOffsetY = point.y - monitorBox.y;
                            dragged = false;
                            previewContainer.previewPositions = ({});
                            previewContainer.dragging = true;
                            monitorBox.z = 100;
                            root.nState.selectedMonitor = monitorBox.modelData;
                            root.flickable.interactive = false;
                        }

                        onPositionChanged: mouse => {
                            if (pressed) {
                                const point = dragArea.mapToItem(previewContainer, mouse.x, mouse.y);
                                const newX = point.x - grabOffsetX;
                                const newY = point.y - grabOffsetY;
                                const plan = previewContainer.layoutPlan(monitorBox.modelData, newX, newY);
                                previewContainer.previewPositions = plan?.positions ?? ({});
                                const position = previewContainer.previewPositions[monitorBox.modelData.id];
                                monitorBox.x = position ? previewContainer.getX(position) : newX;
                                monitorBox.y = position ? previewContainer.getY(position) : newY;
                                dropX = newX;
                                dropY = newY;
                                if (Math.abs(newX - monitorBox.targetX) + Math.abs(newY - monitorBox.targetY) > 5)
                                    dragged = true;
                            }
                        }

                        onReleased: {
                            monitorBox.z = 1;
                            if (dragged)
                                previewContainer.snapMonitor(monitorBox.modelData, dropX, dropY);
                            previewContainer.previewPositions = ({});
                            previewContainer.dragging = false;
                            monitorBox.x = monitorBox.targetX;
                            monitorBox.y = monitorBox.targetY;
                            root.flickable.interactive = true;
                            root.nState.selectedMonitor = monitorBox.modelData;
                        }

                        onCanceled: {
                            monitorBox.z = 1;
                            previewContainer.previewPositions = ({});
                            previewContainer.dragging = false;
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
