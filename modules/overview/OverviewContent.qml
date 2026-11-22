pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.hallownest
import qs.services
import qs.utils

Item {
    id: root

    required property HyprlandMonitor monitor
    readonly property real monX: monitor?.lastIpcObject.x ?? 0
    readonly property real monY: monitor?.lastIpcObject.y ?? 0
    readonly property real monW: (monitor?.width ?? 1920) / (monitor?.scale ?? 1)
    readonly property real monH: (monitor?.height ?? 1080) / (monitor?.scale ?? 1)

    readonly property int columns: 5
    readonly property int count: {
        let max = Math.max(columns, Hypr.activeWsId);
        for (const t of Hypr.toplevels.values)
            if ((t.workspace?.id ?? 0) > max)
                max = t.workspace.id;
        return Math.min(20, Math.ceil(max / columns) * columns);
    }
    // Map layout: rooms (workspaces) joined by corridors drawn in ink
    readonly property real gap: Tokens.spacing.extraLargeIncreased
    readonly property real outset: 3
    readonly property real doorWidth: 10
    readonly property var areas: ["Dirtmouth", "Forgotten Crossroads", "Greenpath", "Fungal Wastes", "City of Tears", "Crystal Peak", "Resting Grounds", "Royal Waterways", "Fog Canyon", "Queen's Gardens", "Deepnest", "Kingdom's Edge", "Howling Cliffs", "Ancient Basin", "The Abyss", "The Hive", "Blue Lake", "Colosseum of Fools", "White Palace", "Godhome"]
    readonly property real cardW: Math.min(340, (width - Tokens.padding.extraLarge * 4 - gap * (columns - 1)) / columns)
    readonly property real cardH: cardW * monH / monW
    property int selected: Hypr.activeWsId - 1
    property var dragWindow: null
    property int draggingWs: -1
    property string pendingRequest
    // Cornifer's sheet: aged paper (gold pulled towards ochre by a touch of unn), ink always darker than the paper (light styles flip the ends)
    readonly property color paper: {
        const base = Hallownest.light ? Hallownest.void_ : Hallownest.text;
        return Hallownest.isMono ? Qt.tint(base, Qt.alpha(Hallownest.card, 0.25)) : Qt.tint(Qt.tint(Qt.tint(base, Qt.alpha(Hallownest.gold, Hallownest.light ? 0.3 : 0.42)), Qt.alpha(Hallownest.unn, Hallownest.light ? 0 : 0.1)), Qt.alpha(Hallownest.card, Hallownest.light ? 0 : 0.16));
    }
    readonly property color ink: {
        const base = Hallownest.light ? Hallownest.text : Hallownest.void_;
        return Hallownest.isMono ? base : Qt.tint(base, Qt.alpha(Hallownest.gold, 0.22));
    }
    // 0-1 while the rooms are traced in on open
    property real drawn

    signal close

    // Dispatch after the overlay drops keyboard focus, otherwise Hyprland refocuses the previous window
    function closeThen(request: string): void {
        pendingRequest = request;
        close();
        dispatchTimer.restart();
    }

    function hash(n: real): real {
        const x = Math.sin(n * 12.9898) * 43758.5453;
        return x - Math.floor(x);
    }

    // Vertical position (0-1) of the door on the right wall of a room
    function doorRight(ws: int): real {
        return 0.3 + 0.4 * hash(ws * 3.1);
    }

    // Horizontal position of the door on the bottom wall, kept right of the next room's label
    function doorDown(ws: int): real {
        return 0.72 + 0.14 * hash(ws * 5.7);
    }

    // Every row gets at least one way down, the rest is left to chance
    function hasDown(ws: int): bool {
        if (ws < 1 || ws + columns > count)
            return false;
        const col = (ws - 1) % columns;
        const row = Math.floor((ws - 1) / columns);
        return col === row % columns || hash(ws * 7.3) > 0.55;
    }

    // Hand-drawn wall around a w×h room: jittered segments, with gaps where the doors are.
    // doors = [top, right, bottom, left] as 0-1 positions along the wall, -1 for none.
    function inkPath(w: real, h: real, seed: real, doors: var): string {
        const o = outset;
        const W = w + o * 2;
        const H = h + o * 2;
        let path = "";
        let k = 0;
        let started = false;
        const side = (x0, y0, x1, y1, door) => {
            const len = Math.hypot(x1 - x0, y1 - y0);
            const n = Math.max(2, Math.round(len / 16));
            const ts = [];
            for (let i = 0; i <= n; i++)
                ts.push(i / n);
            const gap = door >= 0 ? [door - doorWidth / 2 / len, door + doorWidth / 2 / len] : null;
            if (gap)
                ts.push(gap[0], gap[1]);
            ts.sort((a, b) => a - b);
            const nx = -(y1 - y0) / len;
            const ny = (x1 - x0) / len;
            let prev = 0;
            for (const t of ts) {
                const mid = (prev + t) / 2;
                const inGap = gap && mid > gap[0] && mid < gap[1];
                const edge = t === 0 || t === 1 || (gap && (t === gap[0] || t === gap[1]));
                const d = edge ? 0 : (hash(seed * 31 + k++) - 0.5) * 2.4;
                const px = (x0 + (x1 - x0) * t + nx * d).toFixed(1);
                const py = (y0 + (y1 - y0) * t + ny * d).toFixed(1);
                path += `${started && !inGap ? "L" : "M"} ${px} ${py} `;
                started = true;
                prev = t;
            }
        };
        const at = (f, size, total) => f < 0 ? -1 : (o + f * size) / total;
        side(0, 0, W, 0, at(doors[0], w, W));
        side(W, 0, W, H, at(doors[1], h, H));
        side(W, H, 0, H, doors[2] < 0 ? -1 : 1 - at(doors[2], w, W));
        side(0, H, 0, 0, doors[3] < 0 ? -1 : 1 - at(doors[3], h, H));
        return path;
    }

    function goTo(ws: int): void {
        closeThen(Hypr.usingLua ? `hl.dsp.focus({ workspace = "${ws}" })` : `workspace ${ws}`);
    }

    function focusWindow(t: var): void {
        closeThen(Hypr.usingLua ? `hl.dsp.focus({ window = "address:0x${t.address}" })` : `focuswindow address:0x${t.address}`);
    }

    function moveWindow(t: var, ws: int): void {
        Hypr.dispatch(Hypr.usingLua ? `hl.dsp.window.move({ window = "address:0x${t.address}", workspace = "${ws}", follow = false })` : `movetoworkspacesilent ${ws},address:0x${t.address}`);
        Qt.callLater(() => Hyprland.refreshToplevels());
    }

    function killWindow(t: var): void {
        Hypr.dispatch(Hypr.usingLua ? `hl.dsp.window.kill({ window = "address:0x${t.address}" })` : `killwindow address:0x${t.address}`);
    }

    // Each room is traced over 40 % of the run, staggered across the rest
    function drawnFor(index: int): real {
        return Math.max(0, Math.min(1, (drawn - index / count * 0.6) / 0.4));
    }

    Component.onCompleted: {
        Hyprland.refreshToplevels();
        forceActiveFocus();
    }

    focus: true
    Keys.onEscapePressed: close()
    Keys.onReturnPressed: goTo(selected + 1)
    Keys.onEnterPressed: goTo(selected + 1)
    Keys.onLeftPressed: selected = Math.max(0, selected - 1)
    Keys.onRightPressed: selected = Math.min(count - 1, selected + 1)
    Keys.onUpPressed: selected = Math.max(0, selected - columns)
    Keys.onDownPressed: selected = Math.min(count - 1, selected + columns)
    Keys.onPressed: event => {
        const n = parseInt(event.text);
        if (!isNaN(n)) {
            goTo(n === 0 ? 10 : n);
            event.accepted = true;
        } else if (event.key === Qt.Key_Tab) {
            selected = (selected + 1) % count;
            event.accepted = true;
        }
    }

    // Waits out Hyprland's layer slide-in (~500 ms), otherwise most of the tracing happens unseen
    SequentialAnimation on drawn {
        PauseAnimation {
            duration: 350
        }
        NumberAnimation {
            from: 0
            to: 1
            duration: 1300
            easing.type: Easing.InOutQuad
        }
    }

    Timer {
        id: dispatchTimer

        interval: 60
        onTriggered: Hypr.dispatch(root.pendingRequest)
    }

    // Backdrop, click to close
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Hallownest.void_, 0.94)

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    Parchment {
        anchors.fill: mapLayout
        anchors.margins: -(Tokens.padding.extraExtraLarge + margin)
    }

    ColumnLayout {
        id: mapLayout

        anchors.centerIn: parent
        spacing: Tokens.spacing.extraLarge

        // Area title card, like entering a new region
        Column {
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing.small

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: (root.areas[root.selected] ?? "").toUpperCase()
                color: root.ink
                font.family: Hallownest.serif
                font.pointSize: 20
                font.letterSpacing: 4
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 90
                    height: 1
                    color: Qt.alpha(root.ink, 0.5)
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 6
                    height: 6
                    rotation: 45
                    color: root.ink
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 90
                    height: 1
                    color: Qt.alpha(root.ink, 0.5)
                }
            }
        }

        GridLayout {
            Layout.alignment: Qt.AlignHCenter
            columns: root.columns
            columnSpacing: root.gap
            rowSpacing: root.gap

            Repeater {
                model: root.count

                WorkspaceCard {}
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Tr.tr("Click to go · Drag windows between workspaces · Middle click closes a window")
            color: Qt.alpha(root.ink, 0.55)
            font.pointSize: 9
        }
    }

    component WorkspaceCard: Item {
        id: card

        required property int index
        readonly property int wsId: index + 1
        readonly property bool active: Hypr.activeWsId === wsId
        readonly property bool isSelected: root.selected === index
        readonly property var windows: Hypr.toplevels.values.filter(t => t.workspace?.id === wsId && t.lastIpcObject?.mapped !== false && t.lastIpcObject?.at)
        readonly property real scale: root.cardW / root.monW
        readonly property int col: index % root.columns
        readonly property bool explored: windows.length > 0 || active
        readonly property color ink: Qt.alpha(root.ink, active ? 1 : isSelected || dropArea.containsDrag ? 0.85 : explored ? 0.6 : 0.4)
        readonly property real drawn: root.drawnFor(index)
        readonly property var doors: [root.hasDown(wsId - root.columns) ? root.doorDown(wsId - root.columns) : -1, col < root.columns - 1 ? root.doorRight(wsId) : -1, root.hasDown(wsId) ? root.doorDown(wsId) : -1, col > 0 ? root.doorRight(wsId - 1) : -1]

        z: root.draggingWs === wsId ? 10 : 0
        Layout.preferredWidth: root.cardW
        Layout.preferredHeight: root.cardH + label.implicitHeight + Tokens.spacing.small

        StyledText {
            id: label

            anchors.left: parent.left
            anchors.leftMargin: 2
            width: card.doors[0] >= 0 ? card.doors[0] * root.cardW - root.doorWidth : root.cardW - 30
            text: `${card.wsId}  ${root.areas[card.index] ?? ""}`
            elide: Text.ElideRight
            opacity: card.drawn
            color: Qt.alpha(root.ink, card.active ? 1 : card.explored ? 0.75 : 0.45)
            font.family: Hallownest.serif
            font.pointSize: 10
            font.weight: Font.Bold
        }

        // Room floor
        Rectangle {
            anchors.fill: frame
            anchors.margins: -root.outset
            radius: 2
            opacity: card.drawn
            color: Qt.alpha(root.ink, card.explored ? 0.07 : 0.03)
        }

        // Corridor to the room on the right
        Corridor {
            visible: card.doors[1] >= 0
            opacity: card.drawn
            x: root.cardW + root.outset - 1
            y: frame.y + card.doors[1] * root.cardH - height / 2
            width: root.gap - root.outset * 2 + 2
            height: root.doorWidth
        }

        // Corridor to the room below
        Corridor {
            visible: card.doors[2] >= 0
            opacity: card.drawn
            vertical: true
            x: card.doors[2] * root.cardW - width / 2
            y: card.height + root.outset - 1
            width: root.doorWidth
            height: root.gap + label.implicitHeight + Tokens.spacing.small - root.outset * 2 + 2
        }

        // Ink walls, traced twice like a quick sketch; unexplored rooms are dashed
        Shape {
            anchors.fill: frame
            anchors.margins: -root.outset
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: "transparent"
                strokeColor: card.ink
                strokeWidth: card.active ? 2.4 : 1.6
                trim.end: card.drawn
                strokeStyle: card.explored ? ShapePath.SolidLine : ShapePath.DashLine
                dashPattern: [3, 3]
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                PathSvg {
                    path: root.inkPath(root.cardW, root.cardH, card.wsId, card.doors)
                }
            }

            ShapePath {
                fillColor: "transparent"
                strokeColor: Qt.alpha(card.ink, 0.35)
                strokeWidth: 0.8
                trim.end: card.drawn
                strokeStyle: card.explored ? ShapePath.SolidLine : ShapePath.DashLine
                dashPattern: [2, 5]

                PathSvg {
                    path: root.inkPath(root.cardW, root.cardH, card.wsId + 0.5, card.doors)
                }
            }
        }

        Rectangle {
            id: frame

            anchors.bottom: parent.bottom
            width: root.cardW
            height: root.cardH
            radius: 3
            color: dropArea.containsDrag ? Qt.alpha(root.ink, 0.1) : "transparent"
            clip: root.draggingWs !== card.wsId

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: root.selected = card.index
                onClicked: root.goTo(card.wsId)
            }

            DropArea {
                id: dropArea

                anchors.fill: parent
                keys: ["overview-window"]
                onDropped: {
                    if (root.dragWindow && root.dragWindow.workspace?.id !== card.wsId)
                        root.moveWindow(root.dragWindow, card.wsId);
                }
            }

            Repeater {
                model: card.windows

                Item {
                    id: win

                    required property var modelData
                    readonly property var ipc: modelData.lastIpcObject
                    readonly property real baseX: (ipc.at[0] - root.monX) * card.scale
                    readonly property real baseY: (ipc.at[1] - root.monY) * card.scale

                    x: baseX
                    y: baseY
                    z: ipc.floating ? 2 : 1
                    opacity: card.drawn
                    width: Math.max(12, ipc.size[0] * card.scale)
                    height: Math.max(12, ipc.size[1] * card.scale)

                    Drag.active: winMouse.drag.active
                    Drag.keys: ["overview-window"]
                    Drag.hotSpot.x: width / 2
                    Drag.hotSpot.y: height / 2

                    Rectangle {
                        anchors.fill: parent
                        radius: 3
                        color: Hallownest.shell
                        border.width: 1
                        border.color: winMouse.containsMouse ? root.ink : Qt.alpha(root.ink, 0.5)
                        clip: true

                        ScreencopyView {
                            id: copy

                            anchors.fill: parent
                            anchors.margins: 1
                            captureSource: win.modelData.wayland ?? null
                            live: true
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: root.paper
                            opacity: winMouse.containsMouse ? 0 : 0.14

                            Behavior on opacity {
                                Anim {
                                    type: Anim.FastEffects
                                }
                            }
                        }

                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: Math.min(28, parent.height * 0.4)
                            source: Icons.getAppIcon(win.ipc.class ?? "", "image-missing")
                            visible: !copy.hasContent
                        }
                    }

                    MouseArea {
                        id: winMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                        drag.target: win
                        drag.threshold: 6

                        onEntered: root.selected = card.index
                        onPositionChanged: {
                            if (drag.active)
                                root.draggingWs = card.wsId;
                        }
                        onPressed: event => {
                            if (event.button === Qt.LeftButton) {
                                root.dragWindow = win.modelData;
                                win.z = 10;
                            }
                        }
                        onReleased: {
                            if (drag.active)
                                win.Drag.drop();
                            root.draggingWs = -1;
                            win.x = Qt.binding(() => win.baseX);
                            win.y = Qt.binding(() => win.baseY);
                            win.z = Qt.binding(() => win.ipc.floating ? 2 : 1);
                        }
                        onClicked: event => {
                            if (event.button === Qt.MiddleButton)
                                root.killWindow(win.modelData);
                            else
                                root.focusWindow(win.modelData);
                        }
                    }
                }
            }
        }

        // Wayward Compass: the Knight's mask marks the current room
        HealthMask {
            id: pin

            property real bob

            visible: card.active
            opacity: card.drawn
            x: root.cardW - size * 0.7
            y: frame.y - size * 0.45 - bob * 3
            z: 20
            size: 26
            colour: root.ink

            SequentialAnimation on bob {
                running: pin.visible
                loops: Animation.Infinite

                NumberAnimation {
                    to: 1
                    duration: 1100
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: 0
                    duration: 1100
                    easing.type: Easing.InOutSine
                }
            }
        }
    }

    // Passage between two rooms: floor plus two hand-sketched ink walls
    component Corridor: Rectangle {
        id: corridor

        property bool vertical

        function wallPath(second: bool, jitter: real): string {
            const len = vertical ? height : width;
            const n = Math.max(2, Math.round(len / 12));
            const fixed = second ? (vertical ? width : height) : 0;
            const seed = (x * 0.13 + y * 0.29 + (second ? 17 : 3) + jitter * 5);
            let d = "";
            for (let i = 0; i <= n; i++) {
                const t = i / n;
                const off = i === 0 || i === n ? 0 : (root.hash(seed + i * 2.1) - 0.5) * 1.8;
                const px = (vertical ? fixed + off : t * len).toFixed(1);
                const py = (vertical ? t * len : fixed + off).toFixed(1);
                d += `${i === 0 ? "M" : "L"} ${px} ${py} `;
            }
            return d;
        }

        color: Qt.alpha(root.ink, 0.07)

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: "transparent"
                strokeColor: Qt.alpha(root.ink, 0.65)
                strokeWidth: 1.4
                capStyle: ShapePath.RoundCap

                PathSvg {
                    path: `${corridor.wallPath(false, 0)} ${corridor.wallPath(true, 0)}`
                }
            }

            ShapePath {
                fillColor: "transparent"
                strokeColor: Qt.alpha(root.ink, 0.25)
                strokeWidth: 0.7
                capStyle: ShapePath.RoundCap

                PathSvg {
                    path: `${corridor.wallPath(false, 1)} ${corridor.wallPath(true, 1)}`
                }
            }
        }
    }

    // Aged sheet with torn edges, grain and two fold creases; margin leaves room for its shadow
    component Parchment: Canvas {
        id: sheet

        readonly property real margin: 28

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            const m = margin;
            const w = width - m * 2;
            const h = height - m * 2;
            ctx.reset();
            // Torn outline: jittered points every ~14 px, with a deeper nick now and then
            const pts = [];
            const edge = (x0, y0, x1, y1, nx, ny, seed) => {
                const n = Math.max(2, Math.round(Math.hypot(x1 - x0, y1 - y0) / 14));
                for (let i = 0; i < n; i++) {
                    const t = i / n;
                    const r = root.hash(seed + i * 1.37);
                    const d = (r - 0.5) * 4 + (r > 0.93 ? 6 : 0);
                    pts.push([m + x0 + (x1 - x0) * t + nx * d, m + y0 + (y1 - y0) * t + ny * d]);
                }
            };
            edge(0, 0, w, 0, 0, 1, 11);
            edge(w, 0, w, h, -1, 0, 23);
            edge(w, h, 0, h, 0, -1, 37);
            edge(0, h, 0, 0, 1, 0, 51);
            ctx.beginPath();
            ctx.moveTo(pts[0][0], pts[0][1]);
            for (const p of pts)
                ctx.lineTo(p[0], p[1]);
            ctx.closePath();
            ctx.fillStyle = root.paper;
            ctx.fill();
            ctx.strokeStyle = Qt.alpha(root.ink, 0.3);
            ctx.lineWidth = 1.2;
            ctx.stroke();
            ctx.save();
            ctx.clip();
            // Darker, worn edges
            const g = ctx.createRadialGradient(width / 2, height / 2, Math.min(w, h) * 0.35, width / 2, height / 2, Math.hypot(w, h) * 0.6);
            g.addColorStop(0, Qt.alpha(root.ink, 0));
            g.addColorStop(1, Qt.alpha(root.ink, 0.16));
            ctx.fillStyle = g;
            ctx.fillRect(0, 0, width, height);
            // Fold creases into thirds across, half down
            ctx.lineWidth = 1;
            for (const [x0, y0, x1, y1] of [[m + w / 3, m, m + w / 3, m + h], [m + w * 2 / 3, m, m + w * 2 / 3, m + h], [m, m + h / 2, m + w, m + h / 2]]) {
                ctx.strokeStyle = Qt.alpha(root.ink, 0.07);
                ctx.beginPath();
                ctx.moveTo(x0, y0);
                ctx.lineTo(x1, y1);
                ctx.stroke();
                ctx.strokeStyle = Qt.alpha(root.paper, 0.5);
                ctx.beginPath();
                ctx.moveTo(x0 + (y0 === y1 ? 0 : 1), y0 + (y0 === y1 ? 1 : 0));
                ctx.lineTo(x1 + (y0 === y1 ? 0 : 1), y1 + (y0 === y1 ? 1 : 0));
                ctx.stroke();
            }
            // Grain
            for (let i = 0; i < w * h / 900; i++) {
                const r = root.hash(i * 0.731 + 3);
                ctx.fillStyle = Qt.alpha(root.ink, 0.04 + r * 0.07);
                ctx.fillRect(m + root.hash(i * 1.913) * w, m + root.hash(i * 2.417 + 7) * h, 1 + r, 1 + r);
            }
            ctx.restore();
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "black"
            shadowOpacity: 0.6
            shadowBlur: 1
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 6
            blurMax: 32
        }

        Connections {
            function onPaperChanged(): void {
                sheet.requestPaint();
            }

            target: root
        }
    }
}
