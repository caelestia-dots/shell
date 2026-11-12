import QtQuick
import Caelestia.Scheme
import qs.components
import qs.services

MouseArea {
    id: root

    required property RegionState selection
    property alias screen: clients.screen
    property alias freeze: clients.freeze
    property bool selectClients: true
    property bool showCrosshair
    property bool resizeMode

    property var hoveredRect // var so it can be null
    property bool pendingSelect
    property bool selectCancelled
    property bool movingRegion
    property point moveStart
    property rect moveBase
    property point pressPos

    signal selected(region: rect)

    function toGlobal(x: real, y: real): point {
        return Qt.point(x + screen.x, y + screen.y);
    }

    anchors.fill: parent
    hoverEnabled: !resizeMode
    cursorShape: Qt.CrossCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    Component.onCompleted: Hypr.extras.cursorPosition(pos => hoveredRect = clients.rectAt(pos.x - screen.x, pos.y - screen.y))

    onPressed: event => {
        if (resizeMode) {
            if (event.button === Qt.LeftButton && event.modifiers & Qt.ControlModifier) {
                movingRegion = true;
                moveStart = toGlobal(event.x, event.y);
                moveBase = selection.rect;
                return;
            }

            event.accepted = false;
            return;
        }

        if (event.button === Qt.RightButton) {
            pendingSelect = false;
            selectCancelled = true;
            selection.clear();
            hoveredRect = clients.rectAt(event.x, event.y);
            return;
        }

        selectCancelled = false;
        pendingSelect = true;
        pressPos = toGlobal(event.x, event.y);
    }

    onReleased: event => {
        if (movingRegion) {
            movingRegion = false;
            return;
        }

        if (resizeMode) {
            event.accepted = false;
            return;
        }

        if (selectCancelled || event.button !== Qt.LeftButton)
            return;

        selection.selecting = false;
        pendingSelect = false;

        if (selectClients && hoveredRect) {
            selection.start = toGlobal(hoveredRect.x, hoveredRect.y);
            selection.end = toGlobal(hoveredRect.x + hoveredRect.width, hoveredRect.y + hoveredRect.height);
        }

        const rect = selection.rect;
        if (rect.width > 0 && rect.height > 0)
            selected(rect);
    }

    onPositionChanged: event => {
        if (movingRegion) {
            const pos = toGlobal(event.x, event.y);
            const dx = pos.x - moveStart.x;
            const dy = pos.y - moveStart.y;
            selection.start = Qt.point(moveBase.x + dx, moveBase.y + dy);
            selection.end = Qt.point(moveBase.x + moveBase.width + dx, moveBase.y + moveBase.height + dy);
            return;
        }

        if (resizeMode) {
            event.accepted = false;
            return;
        }

        if (pendingSelect) {
            selection.selecting = true;
            selection.start = pressPos;
            pendingSelect = false;
        }

        if (selection.selecting) {
            hoveredRect = null;
            selection.end = toGlobal(event.x, event.y);
        } else {
            hoveredRect = clients.rectAt(event.x, event.y);
        }
    }

    onExited: hoveredRect = null

    RegionClients {
        id: clients

        anchors.fill: parent
        hoveredRect: root.hoveredRect
        highlight: root.selectClients && !root.resizeMode && !root.selection.selecting
    }

    RegionSelection {
        anchors.fill: parent
        selection: root.selection
        origin: Qt.point(root.screen.x, root.screen.y)
        resizeMode: root.resizeMode
    }

    StyledRect {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        x: root.mouseX - 1
        color: Colours.palette.secondary
        width: 1
        opacity: root.showCrosshair && !root.resizeMode && !root.selection.selecting ? 1 : 0

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
        opacity: root.showCrosshair && !root.resizeMode && !root.selection.selecting ? 1 : 0

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
