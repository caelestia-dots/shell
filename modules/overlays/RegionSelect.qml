import QtQuick
import Caelestia.Scheme
import qs.components
import qs.services

MouseArea {
    id: root

    property alias screen: clients.screen
    property alias freeze: clients.freeze
    property bool selectClients: true
    property bool showCrosshair
    property bool resizeMode

    property var hoveredRect // var so it can be null
    property bool selecting
    property bool pendingSelect
    property bool selectCancelled
    property bool movingRegion
    property point moveStart
    property rect moveBase

    property real ssx
    property real ssy

    signal selected(region: rect)
    signal resized(region: rect)

    anchors.fill: parent
    hoverEnabled: !resizeMode
    cursorShape: Qt.CrossCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    Component.onCompleted: Hypr.extras.cursorPosition(pos => hoveredRect = clients.rectAt(pos.x - screen.x, pos.y - screen.y))

    onPressed: event => {
        if (resizeMode) {
            if (event.button === Qt.LeftButton && event.modifiers & Qt.ControlModifier) {
                movingRegion = true;
                moveStart = Qt.point(event.x, event.y);
                moveBase = selection.rect;
                return;
            }

            event.accepted = false;
            return;
        }

        if (event.button === Qt.RightButton) {
            selecting = false;
            pendingSelect = false;
            selectCancelled = true;
            selection.clear();
            hoveredRect = clients.rectAt(event.x, event.y);
            return;
        }

        selectCancelled = false;
        pendingSelect = true;
        ssx = event.x;
        ssy = event.y;
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

        selecting = false;
        pendingSelect = false;

        if (selectClients && hoveredRect) {
            selection.sx = hoveredRect.x;
            selection.sy = hoveredRect.y;
            selection.ex = hoveredRect.x + hoveredRect.width;
            selection.ey = hoveredRect.y + hoveredRect.height;
        }

        const rect = selection.rect;
        if (rect.width > 0 && rect.height > 0)
            selected(rect);
    }

    onPositionChanged: event => {
        if (movingRegion) {
            const dx = Math.max(-moveBase.x, Math.min(width - moveBase.x - moveBase.width, event.x - moveStart.x));
            const dy = Math.max(-moveBase.y, Math.min(height - moveBase.y - moveBase.height, event.y - moveStart.y));
            selection.sx = moveBase.x + dx;
            selection.sy = moveBase.y + dy;
            selection.ex = moveBase.x + moveBase.width + dx;
            selection.ey = moveBase.y + moveBase.height + dy;
            return;
        }

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
            selection.sx = ssx;
            selection.sy = ssy;
            selection.ex = x;
            selection.ey = y;
        } else {
            hoveredRect = clients.rectAt(x, y);
        }
    }

    onExited: hoveredRect = null

    RegionClients {
        id: clients

        anchors.fill: parent
        hoveredRect: root.hoveredRect
        highlight: root.selectClients && !root.resizeMode && !root.selecting
    }

    RegionSelection {
        id: selection

        anchors.fill: parent
        resizeMode: root.resizeMode

        onRectChanged: {
            if (root.resizeMode)
                root.resized(rect);
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
}
