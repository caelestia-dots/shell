pragma ComponentBehavior: Bound

import qs.widgets
import qs.services
import qs.config
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects

MouseArea {
    id: root

    required property LazyLoader loader
    required property ShellScreen screen

    property int borderWidth
    property int rounding

    property bool onClient

    property real realBorderWidth: onClient ? borderWidth : 2
    property real realRounding: onClient ? rounding : 0

    property real ssx
    property real ssy

    property real sx: 0
    property real sy: 0
    property real ex: screen.width
    property real ey: screen.height

    property real rsx: Math.min(sx, ex)
    property real rsy: Math.min(sy, ey)
    property real sw: Math.abs(sx - ex)
    property real sh: Math.abs(sy - ey)

    property list<var> clients: Hyprland.toplevels.values.filter(c => c.workspace?.id === Hyprland.activeWsId).sort((a, b) => {
        // Pinned first, then floating, then any other
        if (a.lastIpcObject.pinned === b.lastIpcObject.pinned)
            return a.lastIpcObject.floating === b.lastIpcObject.floating ? 0 : a.lastIpcObject.floating ? -1 : 1;
        if (a.lastIpcObject.pinned)
            return -1;
        return 1;
    })

    function checkClientRects(x: real, y: real): void {
        for (const client of clients) {
            const {
                at: [cx, cy],
                size: [cw, ch]
            } = client.lastIpcObject;
            if (cx <= x && cy <= y && cx + cw >= x && cy + ch >= y) {
                onClient = true;
                sx = cx;
                sy = cy;
                ex = cx + cw;
                ey = cy + ch;
                break;
            }
        }
    }

    anchors.fill: parent
    opacity: 0
    hoverEnabled: true
    cursorShape: Qt.CrossCursor

    Component.onCompleted: {
        // Break binding if frozen
        if (loader.freeze)
            clients = clients;

        opacity = 1;
        sx = screen.width / 2 - 100;
        sy = screen.height / 2 - 100;
        ex = screen.width / 2 + 100;
        ey = screen.height / 2 + 100;
    }

    onPressed: event => {
        ssx = event.x;
        ssy = event.y;
    }

    onReleased: {
        if (closeAnim.running)
            return;

        Quickshell.execDetached(["sh", "-c", `grim -l 0 -g '${screen.x + Math.ceil(rsx)},${screen.y + Math.ceil(rsy)} ${Math.floor(sw)}x${Math.floor(sh)}' - | swappy -f -`]);
        closeAnim.start();
    }

    onPositionChanged: event => {
        const x = event.x;
        const y = event.y;

        if (pressed) {
            onClient = false;
            sx = ssx;
            sy = ssy;
            ex = x;
            ey = y;
        } else {
            checkClientRects(x, y);
        }
    }

    focus: true
    Keys.onEscapePressed: closeAnim.start()

    SequentialAnimation {
        id: closeAnim

        PropertyAction {
            target: root.loader
            property: "closing"
            value: true
        }
        ParallelAnimation {
            Anim {
                target: root
                property: "opacity"
                to: 0
                duration: Appearance.anim.durations.large
            }
            Anim {
                target: root
                properties: "rsx,rsy"
                to: 0
            }
            Anim {
                target: root
                property: "sw"
                to: root.screen.width
            }
            Anim {
                target: root
                property: "sh"
                to: root.screen.height
            }
        }
        PropertyAction {
            target: root.loader
            property: "activeAsync"
            value: false
        }
    }

    Connections {
        target: Hyprland

        function onActiveWsIdChanged(): void {
            root.checkClientRects(root.mouseX, root.mouseY);
        }
    }

    Process {
        running: true
        command: ["hyprctl", "-j", "getoption", "general:border_size"]
        stdout: StdioCollector {
            onStreamFinished: root.borderWidth = JSON.parse(text).int
        }
    }

    Process {
        running: true
        command: ["hyprctl", "-j", "getoption", "decoration:rounding"]
        stdout: StdioCollector {
            onStreamFinished: root.rounding = JSON.parse(text).int
        }
    }

    Loader {
        anchors.fill: parent

        active: root.loader.freeze
        asynchronous: true

        sourceComponent: ScreencopyView {
            captureSource: root.screen
        }
    }

    StyledRect {
        anchors.fill: parent
        color: Colours.palette.m3secondaryContainer
        opacity: 0.3

        layer.enabled: true
        layer.effect: MultiEffect {
            maskSource: selectionWrapper
            maskEnabled: true
            maskInverted: true
            maskSpreadAtMin: 1
            maskThresholdMin: 0.5
        }
    }

    Item {
        id: selectionWrapper

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            id: selectionRect

            radius: root.realRounding
            x: root.rsx
            y: root.rsy
            implicitWidth: root.sw
            implicitHeight: root.sh
        }
    }

    Rectangle {
        color: "transparent"
        radius: root.realRounding > 0 ? root.realRounding + root.realBorderWidth : 0
        border.width: root.realBorderWidth
        border.color: Colours.palette.m3primary

        x: selectionRect.x - root.realBorderWidth
        y: selectionRect.y - root.realBorderWidth
        implicitWidth: selectionRect.implicitWidth + root.realBorderWidth * 2
        implicitHeight: selectionRect.implicitHeight + root.realBorderWidth * 2

        Behavior on border.color {
            ColorAnimation {
                duration: Appearance.anim.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.standard
            }
        }
    }

    Behavior on opacity {
        Anim {
            duration: Appearance.anim.durations.large
        }
    }

    Behavior on rsx {
        enabled: !root.pressed

        Anim {}
    }

    Behavior on rsy {
        enabled: !root.pressed

        Anim {}
    }

    Behavior on sw {
        enabled: !root.pressed

        Anim {}
    }

    Behavior on sh {
        enabled: !root.pressed

        Anim {}
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.expressiveDefaultSpatial
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
    }
}
