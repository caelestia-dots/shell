import QtQuick
import Quickshell
import Quickshell.Hyprland
import Caelestia.Config
import Caelestia.Scheme
import Caelestia.Shaders
import qs.components
import qs.components.effects
import qs.services
import qs.modules.drawers

MouseArea {
    id: root

    required property ShellScreen screen
    property bool freeze
    property bool selectClients: true
    property bool showCrosshair
    property bool resizeMode

    property var hoveredRect // var so it can be null
    property bool selecting
    property bool pendingSelect
    property bool selectCancelled
    property var zOrder: ({}) // address -> clients request index
    property var clientProps: ({}) // address -> { rounding, rounding_power, border_size }
    property list<HyprlandToplevel> clients: sortClients(zOrder)

    readonly property var shellComponents: ShellState.componentsFor(screen)
    property var frozenCoverage // ItemGrabResult, keeps the grabbed image alive

    readonly property int borderWidth: 1

    property real ssx
    property real ssy

    property real sx: -1
    property real sy: -1
    property real ex: -1
    property real ey: -1

    property real rsx: Math.min(sx, ex)
    property real rsy: Math.min(sy, ey)
    property real sw: Math.abs(sx - ex)
    property real sh: Math.abs(sy - ey)

    readonly property real handleSize: Tokens.padding.medium
    readonly property real handleLength: Tokens.padding.extraLarge
    readonly property real handlePadding: Tokens.padding.small
    readonly property real handleSpace: handleLength + handleSize + handlePadding * 4

    signal selected(region: rect)
    signal resized(region: rect)

    function rectForClient(client: HyprlandToplevel): rect {
        const ipc = client.lastIpcObject;
        if (!ipc || !ipc.at || !ipc.size)
            return Qt.rect(0, 0, 0, 0);
        return Qt.rect(ipc.at[0] - screen.x, ipc.at[1] - screen.y, ipc.size[0], ipc.size[1]);
    }

    function sortClients(order: var): list<HyprlandToplevel> {
        const mon = Hypr.monitorFor(screen);
        if (!mon)
            return [];

        const wsAddress = mon.specialWorkspace?.address ?? mon.activeWorkspace?.address;
        if (!wsAddress)
            return [];

        return Hypr.toplevelsForWs(wsAddress).sort((a, b) => {
            // Pinned first, then fullscreen, then floating, then by stacking order
            const ac = a?.lastIpcObject;
            const bc = b?.lastIpcObject;
            if (!ac || !bc)
                return !ac - !bc; // Missing IPC last
            return (bc.pinned - ac.pinned) || ((bc.fullscreen !== 0) - (ac.fullscreen !== 0)) || (bc.floating - ac.floating) || ((order[bc.address] ?? -1) - (order[ac.address] ?? -1));
        });
    }

    function sameOrder(a: var, b: var): bool {
        const ka = Object.keys(a);
        const kb = Object.keys(b);
        return ka.length === kb.length && ka.every(k => a[k] === b[k]);
    }

    function refreshZOrder(): void {
        Hypr.extras.batchRequest(["j/clients"], list => {
            if (typeof list !== "object")
                return;

            const order = {};
            list.forEach((c, i) => order[c.address] = i);
            if (sameOrder(order, zOrder))
                return;

            zOrder = order;
            if (freeze)
                clients = sortClients(order);
        });
    }

    function refreshClientProps(): void {
        const props = ["rounding", "rounding_power", "border_size"];
        const addresses = clients.map(c => c.address).filter(a => !(a in clientProps));
        if (addresses.length === 0)
            return;

        const requests = [];
        for (const address of addresses)
            for (const prop of props)
                requests.push(`j/getprop address:0x${address} ${prop}`);
        // qmlformat off

        Hypr.extras.batchRequest(requests, (...replies) => {
            // qmlformat on
            const result = Object.assign({}, clientProps);
            replies.forEach((reply, i) => {
                const address = addresses[Math.floor(i / props.length)];
                if (typeof reply === "object" && address)
                    result[address] = Object.assign(result[address] ?? {}, reply);
            });
            clientProps = result;
        });
    }

    function checkRects(x: real, y: real): void {
        for (const c of clients) {
            const rect = rectForClient(c);
            if (rect.x <= x && rect.y <= y && rect.x + rect.width >= x && rect.y + rect.height >= y) {
                hoveredRect = rect;
                return;
            }
        }
        hoveredRect = null;
    }

    onRsxChanged: {
        if (resizeMode)
            resized(Qt.rect(rsx, rsy, sw, sh));
    }
    onRsyChanged: {
        if (resizeMode)
            resized(Qt.rect(rsx, rsy, sw, sh));
    }
    onSwChanged: {
        if (resizeMode)
            resized(Qt.rect(rsx, rsy, sw, sh));
    }
    onShChanged: {
        if (resizeMode)
            resized(Qt.rect(rsx, rsy, sw, sh));
    }

    anchors.fill: parent
    hoverEnabled: !resizeMode
    cursorShape: Qt.CrossCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    Component.onCompleted: {
        Hypr.extras.refreshOptions();

        if (freeze) {
            clients = clients; // Break binding
            const drawers = shellComponents?.rootWindow;
            if (drawers?.panelsAboveToplevels)
                drawers.panelBlobs.grabToImage(result => frozenCoverage = result);
        }

        refreshZOrder();
        Hypr.extras.cursorPosition(pos => checkRects(pos.x - screen.x, pos.y - screen.y));
    }
    onClientsChanged: refreshClientProps()

    onPressed: event => {
        if (resizeMode) {
            event.accepted = false;
            return;
        }

        if (event.button === Qt.RightButton) {
            selecting = false;
            pendingSelect = false;
            selectCancelled = true;
            sx = sy = ex = ey = -1;
            checkRects(event.x, event.y);
            return;
        }

        selectCancelled = false;
        pendingSelect = true;
        ssx = event.x;
        ssy = event.y;
    }

    onReleased: event => {
        if (resizeMode) {
            event.accepted = false;
            return;
        }

        if (selectCancelled || event.button !== Qt.LeftButton)
            return;

        selecting = false;
        pendingSelect = false;

        if (selectClients && hoveredRect) {
            selected(hoveredRect);
            return;
        }

        const rect = Qt.rect(Math.min(sx, ex), Math.min(sy, ey), Math.abs(sx - ex), Math.abs(sy - ey));
        if (rect.width > 0 && rect.height > 0)
            selected(rect);
    }

    onPositionChanged: event => {
        if (resizeMode) {
            event.accepted = false;
            return;
        }

        const x = event.x;
        const y = event.y;

        if (pendingSelect) {
            selecting = true;
            pendingSelect = false;
        }

        if (selecting) {
            hoveredRect = null;
            sx = ssx;
            sy = ssy;
            ex = x;
            ey = y;
        } else {
            checkRects(x, y);
        }
    }

    onExited: hoveredRect = null

    Connections {
        function onRawEvent(event: HyprlandEvent): void {
            if (["activewindowv2", "openwindow", "closewindow", "changefloatingmode", "pin", "fullscreen", "workspace", "activespecial"].includes(event.name))
                root.refreshZOrder();
        }

        target: Hyprland
        enabled: !root.freeze
    }

    StyledRect {
        id: overlay

        anchors.fill: parent
        color: Qt.alpha("black", Colours.mode === Colours.Light ? 0.3 : 0.4)

        layer.enabled: true
        layer.effect: Mask {
            maskSource: selectionWrapper
            maskInverted: true
        }
    }

    Item {
        id: selectionWrapper

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            id: selectionRect

            x: root.rsx
            y: root.rsy
            implicitWidth: root.sw
            implicitHeight: root.sh
        }
    }

    Rectangle {
        id: border

        color: "transparent"
        border.width: root.borderWidth
        border.color: Colours.palette.primary

        x: selectionRect.x - root.borderWidth
        y: selectionRect.y - root.borderWidth
        implicitWidth: selectionRect.implicitWidth + root.borderWidth * 2
        implicitHeight: selectionRect.implicitHeight + root.borderWidth * 2

        Behavior on border.color {
            CAnim {}
        }

        StyledRect {
            id: geomContainer

            readonly property bool inCorner: root.sw > implicitWidth * 2 && root.sh > implicitHeight * 4
            property real heightMult: inCorner ? 1 : 0

            x: parent.width - implicitWidth
            y: parent.height - implicitHeight * heightMult

            topLeftRadius: inCorner || root.sw < implicitWidth ? Tokens.rounding.small : 0
            bottomLeftRadius: inCorner ? 0 : Tokens.rounding.small
            bottomRightRadius: inCorner ? 0 : Tokens.rounding.small

            color: Colours.palette.primary
            implicitWidth: geomLabelMetrics.width + Tokens.padding.extraSmall * 2
            implicitHeight: geomLabelMetrics.height + Tokens.padding.extraSmall * 2

            Behavior on heightMult {
                Anim {}
            }

            Behavior on topLeftRadius {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on bottomRightRadius {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on bottomLeftRadius {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on implicitWidth {
                Anim {}
            }

            TextMetrics {
                id: geomLabelMetrics

                text: "0".repeat(Math.round(root.sw).toString().length) + " x " + "0".repeat(Math.round(root.sh).toString().length)
                font: geomLabel.font
            }

            StyledText {
                id: geomLabel

                anchors.centerIn: parent
                width: geomLabelMetrics.width
                height: geomLabelMetrics.height
                horizontalAlignment: Text.AlignHCenter

                text: Math.round(root.sw) + " x " + Math.round(root.sh)
                color: Colours.palette.onPrimary
                font: Tokens.font.label.small
            }
        }

        ResizeHandle {
            anchors.horizontalCenter: parent.left
            anchors.verticalCenter: parent.verticalCenter
            cursorShape: Qt.SizeHorCursor
            innerHeight: root.handleLength
            xProp: "sx"
        }

        ResizeHandle {
            anchors.horizontalCenter: parent.left
            anchors.verticalCenter: parent.top
            cursorShape: Qt.SizeFDiagCursor
            xProp: "sx"
            yProp: "sy"
        }

        ResizeHandle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.top
            cursorShape: Qt.SizeVerCursor
            innerWidth: root.handleLength
            yProp: "sy"
        }

        ResizeHandle {
            anchors.horizontalCenter: parent.right
            anchors.verticalCenter: parent.top
            cursorShape: Qt.SizeBDiagCursor
            xProp: "ex"
            yProp: "sy"
        }

        ResizeHandle {
            anchors.horizontalCenter: parent.right
            anchors.verticalCenter: parent.verticalCenter
            cursorShape: Qt.SizeHorCursor
            innerHeight: root.handleLength
            xProp: "ex"
        }

        ResizeHandle {
            anchors.horizontalCenter: parent.right
            anchors.verticalCenter: parent.bottom
            cursorShape: Qt.SizeFDiagCursor
            xProp: "ex"
            yProp: "ey"
        }

        ResizeHandle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.bottom
            cursorShape: Qt.SizeVerCursor
            innerWidth: root.handleLength
            yProp: "ey"
        }

        ResizeHandle {
            anchors.horizontalCenter: parent.left
            anchors.verticalCenter: parent.bottom
            cursorShape: Qt.SizeBDiagCursor
            xProp: "sx"
            yProp: "ey"
        }
    }

    Item {
        id: occluders

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Repeater {
            model: root.clients

            ShaderEffect {
                required property HyprlandToplevel modelData
                required property int index
                readonly property rect rect: root.rectForClient(modelData)

                readonly property real weight: index < 24 ? (1 << (index % 8)) / 255 : 0
                readonly property vector4d value: Qt.vector4d(index < 8 ? weight : 0, index >= 8 && index < 16 ? weight : 0, index >= 16 ? weight : 0, 0)
                readonly property size fullSize: Qt.size(width, height)

                readonly property var props: root.clientProps[modelData.address]
                readonly property real rounding: props?.rounding ?? 0
                readonly property real roundingPower: props?.rounding_power ?? 0
                readonly property real radius: rounding * roundingPower / 2

                x: rect.x
                y: rect.y
                implicitWidth: rect.width
                implicitHeight: rect.height
                fragmentShader: Shaders.occluder
            }
        }
    }

    Item {
        id: panelMask

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Loader {
            anchors.fill: parent
            active: {
                if (root.freeze || !root.shellComponents)
                    return false;

                const c = root.shellComponents;
                return c.rootWindow.panelsAboveToplevels && c.panels && c.bar;
            }

            sourceComponent: PanelBlobs {
                panels: root.shellComponents.panels
                bar: root.shellComponents.bar
                color: "white"
                smoothing: Config.border.smoothing
                deformScale: 0
                borderThickness: root.shellComponents.rootWindow.borderThickness
                borderRounding: root.shellComponents.rootWindow.borderRounding
                sdfBorderOffset: root.shellComponents.rootWindow.sdfBorderOffset
            }
        }

        Image {
            anchors.fill: parent
            source: root.frozenCoverage?.url ?? ""
        }
    }

    Repeater {
        model: root.clients

        ShaderEffect {
            required property HyprlandToplevel modelData
            required property int index
            readonly property rect rect: root.rectForClient(modelData)

            property color fillColor: Qt.alpha(Colours.palette.primary, root.hoveredRect === rect ? 0.2 : 0)
            property color borderColor: Colours.palette.primary

            readonly property var props: root.clientProps[modelData.address]
            readonly property real rounding: modelData.lastIpcObject?.fullscreen === 2 ? 0 : (props?.rounding ?? 0)
            readonly property real roundingPower: props?.rounding_power ?? 0
            readonly property real thick: props?.border_size ?? root.borderWidth

            readonly property real radius: rounding * roundingPower / 2
            readonly property real radiusOuter: radius + thick - thick * (Math.SQRT2 - 1) * Math.max(2 - roundingPower, 0)
            readonly property size fullSize: Qt.size(width, height)
            readonly property size screenSize: Qt.size(root.width, root.height)
            readonly property point itemPos: Qt.point(x, y)
            readonly property real ownIndex: index
            readonly property Item occlusion: occluders
            readonly property Item panelCoverage: panelMask
            property real hovered: root.hoveredRect === rect ? 1 : 0

            x: rect.x - thick
            y: rect.y - thick
            implicitWidth: rect.width + thick * 2
            implicitHeight: rect.height + thick * 2
            fragmentShader: Shaders.superellipse

            opacity: root.selectClients && !root.resizeMode && !root.selecting ? 1 : 0

            Behavior on fillColor {
                CAnim {}
            }

            Behavior on borderColor {
                CAnim {}
            }

            Behavior on hovered {
                Anim {
                    type: Anim.SlowEffects
                }
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }
    }

    StyledRect {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        x: root.mouseX - 1
        color: Colours.palette.secondary
        width: 1
        opacity: root.showCrosshair && !root.resizeMode && !root.selecting ? 1 : 0

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    StyledRect {
        anchors.left: parent.left
        anchors.right: parent.right
        y: root.mouseY - 1
        color: Colours.palette.secondary
        height: 1
        opacity: root.showCrosshair && !root.resizeMode && !root.selecting ? 1 : 0

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    component ResizeHandle: MouseArea {
        property alias innerWidth: resizeInner.implicitWidth
        property alias innerHeight: resizeInner.implicitHeight
        property string xProp
        property string yProp
        readonly property bool fits: (xProp && yProp) || (xProp ? root.sh : root.sw) >= root.handleSpace

        enabled: root.resizeMode && fits
        preventStealing: true

        onPositionChanged: event => {
            if (!pressed)
                return;

            const p = mapToItem(root, event.x, event.y);
            if (xProp)
                root[xProp] = Math.max(0, Math.min(root.width, p.x));
            if (yProp)
                root[yProp] = Math.max(0, Math.min(root.height, p.y));
        }
        onReleased: {
            if (root.sx > root.ex)
                [root.sx, root.ex] = [root.ex, root.sx];
            if (root.sy > root.ey)
                [root.sy, root.ey] = [root.ey, root.sy];
        }

        implicitWidth: resizeInner.implicitWidth + root.handlePadding * 2
        implicitHeight: resizeInner.implicitHeight + root.handlePadding * 2

        scale: root.resizeMode && fits ? 1 : 0

        Behavior on scale {
            Anim {
                type: Anim.FastSpatial
            }
        }

        StyledRect {
            id: resizeInner

            anchors.centerIn: parent
            color: Colours.palette.primary
            radius: Tokens.rounding.full
            implicitWidth: root.handleSize
            implicitHeight: root.handleSize
        }
    }
}
