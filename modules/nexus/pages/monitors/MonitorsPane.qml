pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
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
            id: arranger

            // Nothing is sent to Hyprland until Apply, so the arrangement is a
            // draft the user edits freely. `slots` is the delegate model and
            // only changes when displays are added, removed or resized;
            // positions live apart from it so a drag never rebuilds the item
            // that is holding the mouse grab.
            property var slots: []
            property string slotsKey: ""
            property var positions: ({})
            property var appliedPositions: ({})
            property int dragId: -1

            readonly property bool dirty: !arranger.samePositions(arranger.positions, arranger.appliedPositions)
            readonly property string issue: Monitors.layoutIssue(arranger.draftRects())
            readonly property bool applicable: arranger.dirty && arranger.issue === ""

            // Magnet range, in view pixels, converted per drag so the pull feels
            // the same however far the arrangement is zoomed out.
            readonly property real snapDistance: 10

            property real minX: 0
            property real minY: 0
            property real scaleFactor: 1
            property real offsetX: 0
            property real offsetY: 0
            property real padding: 16

            function slotKey(rects: var): string {
                return rects.map(r => `${r.id}:${r.name}:${r.w}x${r.h}`).join("|");
            }

            function positionsOf(rects: var): var {
                const out = ({});
                for (let i = 0; i < rects.length; i++)
                    out[rects[i].id] = {
                        x: rects[i].x,
                        y: rects[i].y
                    };
                return out;
            }

            function samePositions(a: var, b: var): bool {
                const keys = Object.keys(a);
                if (keys.length !== Object.keys(b).length)
                    return false;
                for (let i = 0; i < keys.length; i++) {
                    const mine = a[keys[i]];
                    const theirs = b[keys[i]];
                    if (!theirs || theirs.x !== mine.x || theirs.y !== mine.y)
                        return false;
                }
                return true;
            }

            // The draft as plain rects, for the snapper and the validator.
            function draftRects(): var {
                return arranger.slots.map(s => {
                    const pos = arranger.positions[s.id] ?? {
                        x: 0,
                        y: 0
                    };
                    return {
                        id: s.id,
                        name: s.name,
                        x: pos.x,
                        y: pos.y,
                        w: s.w,
                        h: s.h
                    };
                });
            }

            // Hyprland keeps being polled while the user arranges, and adopting
            // those positions would wipe the edit, so only a change to the set
            // of displays is allowed to reset an unapplied draft.
            function sync(): void {
                const rects = Monitors.currentRects();
                const key = arranger.slotKey(rects);
                if (key !== arranger.slotsKey) {
                    arranger.slotsKey = key;
                    arranger.slots = rects;
                    arranger.reset();
                } else if (!arranger.dirty) {
                    arranger.reset();
                }
            }

            function reset(): void {
                const applied = arranger.positionsOf(Monitors.currentRects());
                arranger.positions = applied;
                arranger.appliedPositions = applied;
                arranger.fit();
            }

            function apply(): void {
                const rects = arranger.draftRects();
                Monitors.applyArrangement(rects);
                // applyArrangement pulls the layout back to the origin, so adopt
                // what was actually sent. The next poll confirms it.
                const applied = arranger.positionsOf(rects);
                arranger.positions = applied;
                arranger.appliedPositions = applied;
                arranger.fit();
            }

            function moveTo(id: int, logicalX: real, logicalY: real): void {
                const rects = arranger.draftRects();
                const snapped = Monitors.snapDrag(rects, id, logicalX, logicalY, arranger.snapDistance / arranger.scaleFactor);
                const next = ({});
                for (let i = 0; i < rects.length; i++) {
                    const rect = rects[i];
                    next[rect.id] = rect.id === id ? snapped : {
                        x: rect.x,
                        y: rect.y
                    };
                }
                arranger.positions = next;
            }

            // The view mapping is deliberately never recomputed mid-drag: it
            // feeds back into the pointer-to-logical conversion and would
            // oscillate. Half a display of slack is left on every side so there
            // is always somewhere to drag one past the current extent.
            function fit(): void {
                const rects = arranger.draftRects();
                if (arranger.dragId >= 0 || rects.length === 0)
                    return;

                let left = Infinity;
                let top = Infinity;
                let right = -Infinity;
                let bottom = -Infinity;
                let widest = 0;
                let tallest = 0;

                for (let i = 0; i < rects.length; i++) {
                    const rect = rects[i];
                    left = Math.min(left, rect.x);
                    top = Math.min(top, rect.y);
                    right = Math.max(right, rect.x + rect.w);
                    bottom = Math.max(bottom, rect.y + rect.h);
                    widest = Math.max(widest, rect.w);
                    tallest = Math.max(tallest, rect.h);
                }

                const slackX = widest / 2;
                const slackY = tallest / 2;
                const spanX = Math.max(1, right - left + slackX * 2);
                const spanY = Math.max(1, bottom - top + slackY * 2);
                const availW = Math.max(0, arranger.width - arranger.padding * 2);
                const availH = Math.max(0, arranger.height - arranger.padding * 2);

                arranger.minX = left - slackX;
                arranger.minY = top - slackY;
                arranger.scaleFactor = Math.max(0.0001, Math.min(availW / spanX, availH / spanY));
                arranger.offsetX = arranger.padding + (availW - spanX * arranger.scaleFactor) / 2;
                arranger.offsetY = arranger.padding + (availH - spanY * arranger.scaleFactor) / 2;
            }

            function toViewX(logicalX: real): real {
                return arranger.offsetX + (logicalX - arranger.minX) * arranger.scaleFactor;
            }

            function toViewY(logicalY: real): real {
                return arranger.offsetY + (logicalY - arranger.minY) * arranger.scaleFactor;
            }

            function toLogicalX(viewX: real): real {
                return arranger.minX + (viewX - arranger.offsetX) / arranger.scaleFactor;
            }

            function toLogicalY(viewY: real): real {
                return arranger.minY + (viewY - arranger.offsetY) / arranger.scaleFactor;
            }

            Layout.fillWidth: true
            Layout.preferredHeight: 300
            implicitHeight: 300
            color: "transparent"
            radius: Tokens.rounding.large
            border.color: arranger.issue ? Colours.palette.m3error : arranger.dirty ? Colours.palette.m3primary : Colours.palette.m3outlineVariant
            border.width: 1

            onWidthChanged: arranger.fit()
            onHeightChanged: arranger.fit()
            Component.onCompleted: arranger.sync()

            Behavior on border.color {
                CAnim {}
            }

            Connections {
                function onMonitorsChanged(): void {
                    arranger.sync();
                }

                target: Hyprctl
            }

            Repeater {
                model: arranger.slots

                delegate: Item {
                    id: monitorBox

                    required property var modelData
                    required property int index

                    readonly property var mon: Hyprctl.monitors.find(m => m.name === monitorBox.modelData.name) ?? null
                    readonly property var pos: arranger.positions[monitorBox.modelData.id] ?? ({
                            x: 0,
                            y: 0
                        })
                    readonly property bool isCurrentScreen: monitorBox.mon != null && root.nState.screen != null && monitorBox.mon.name === root.nState.screen.name
                    readonly property bool isSelected: root.nState.selectedMonitor != null && root.nState.selectedMonitor.name === monitorBox.modelData.name
                    readonly property bool isDragging: arranger.dragId === monitorBox.modelData.id

                    x: arranger.toViewX(monitorBox.pos.x)
                    y: arranger.toViewY(monitorBox.pos.y)
                    width: monitorBox.modelData.w * arranger.scaleFactor
                    height: monitorBox.modelData.h * arranger.scaleFactor
                    z: monitorBox.isDragging ? 2 : 1
                    visible: width > 0 && height > 0

                    Behavior on x {
                        enabled: !monitorBox.isDragging

                        Anim {}
                    }

                    Behavior on y {
                        enabled: !monitorBox.isDragging

                        Anim {}
                    }

                    Behavior on width {
                        enabled: !monitorBox.isDragging

                        Anim {}
                    }

                    Behavior on height {
                        enabled: !monitorBox.isDragging

                        Anim {}
                    }

                    // Box background
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: Tokens.rounding.medium
                        color: monitorBox.isSelected ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHigh
                        border.color: monitorBox.isSelected ? Colours.palette.m3primary : monitorBox.isCurrentScreen ? Colours.palette.m3secondary : "transparent"
                        border.width: monitorBox.isSelected || monitorBox.isCurrentScreen ? 2 : 0

                        Behavior on color {
                            CAnim {}
                        }

                        Behavior on border.color {
                            CAnim {}
                        }
                    }

                    // Content: icon + name + resolution. Zooming out to make room
                    // for a drag shrinks the boxes, so drop the trimmings before
                    // they spill out of one.
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Tokens.spacing.extraSmall / 2

                        MaterialIcon {
                            Layout.alignment: Qt.AlignHCenter
                            visible: monitorBox.height > 78
                            text: "monitor"
                            fontStyle: Tokens.font.icon.medium
                            color: monitorBox.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: monitorBox.width
                            text: monitorBox.modelData.name
                            font: Tokens.font.body.small
                            color: monitorBox.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            visible: monitorBox.height > 54
                            text: monitorBox.mon ? Monitors.modeResolution(monitorBox.mon) : ""
                            font: Tokens.font.label.small
                            color: monitorBox.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                            opacity: 0.85
                        }

                        // Indicate hosting screen
                        MaterialIcon {
                            Layout.alignment: Qt.AlignHCenter
                            visible: monitorBox.isCurrentScreen && monitorBox.height > 96
                            text: "lock"
                            fontStyle: Tokens.font.icon.small
                            color: monitorBox.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                            opacity: 0.55
                        }
                    }

                    MouseArea {
                        id: dragArea

                        // Pointer, in arranger coordinates, at press
                        property real pressX
                        property real pressY
                        property real grabOffsetX
                        property real grabOffsetY
                        // Only true once the pointer has moved far enough to
                        // count as a drag rather than a click
                        property bool moved: false

                        function finish(): void {
                            if (arranger.dragId !== monitorBox.modelData.id)
                                return;
                            arranger.dragId = -1;
                            root.flickable.interactive = true;
                            if (dragArea.moved)
                                arranger.fit();
                        }

                        anchors.fill: parent
                        cursorShape: Qt.SizeAllCursor

                        onPressed: mouse => {
                            const point = dragArea.mapToItem(arranger, mouse.x, mouse.y);
                            dragArea.pressX = point.x;
                            dragArea.pressY = point.y;
                            dragArea.grabOffsetX = point.x - monitorBox.x;
                            dragArea.grabOffsetY = point.y - monitorBox.y;
                            dragArea.moved = false;
                            arranger.dragId = monitorBox.modelData.id;
                            root.nState.selectedMonitor = monitorBox.mon;
                            root.flickable.interactive = false;
                        }

                        onPositionChanged: mouse => {
                            if (!dragArea.pressed)
                                return;
                            const point = dragArea.mapToItem(arranger, mouse.x, mouse.y);
                            if (!dragArea.moved) {
                                if (Math.hypot(point.x - dragArea.pressX, point.y - dragArea.pressY) < 4)
                                    return;
                                dragArea.moved = true;
                            }
                            // Clamping in view space keeps the display inside the
                            // frame, so it can never be dragged out of sight.
                            const viewX = Math.max(0, Math.min(arranger.width - monitorBox.width, point.x - dragArea.grabOffsetX));
                            const viewY = Math.max(0, Math.min(arranger.height - monitorBox.height, point.y - dragArea.grabOffsetY));
                            arranger.moveTo(monitorBox.modelData.id, arranger.toLogicalX(viewX), arranger.toLogicalY(viewY));
                        }

                        onReleased: dragArea.finish()
                        onCanceled: dragArea.finish()

                        onDoubleClicked: {
                            root.nState.selectedMonitor = monitorBox.mon;
                            root.nState.openSubPage(1);
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: -Tokens.spacing.small
            visible: arranger.dirty
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: arranger.issue ? "error" : "pending"
                fontStyle: Tokens.font.icon.small
                color: arranger.issue ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                Layout.fillWidth: true
                text: arranger.issue || qsTr("Arrangement not applied yet")
                font: Tokens.font.label.medium
                color: arranger.issue ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                elide: Text.ElideRight
            }

            TextButton {
                type: TextButton.Text
                isRound: true
                horizontalPadding: Tokens.padding.large
                text: qsTr("Cancel")
                onClicked: arranger.reset()
            }

            TextButton {
                type: TextButton.Filled
                isRound: true
                horizontalPadding: Tokens.padding.large
                disabled: !arranger.applicable
                text: qsTr("Apply")
                onClicked: arranger.apply()
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
                                    return qsTr("%1×%2 @ %3 Hz").arg(m.width).arg(m.height).arg(Monitors.formatRate(rr));
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
