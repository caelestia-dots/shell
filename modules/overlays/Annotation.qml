pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Components
import Caelestia.Config
import Caelestia.Scheme
import qs.components

Item {
    id: root

    required property ShellScreen screen
    property alias document: canvas.document
    property alias base: canvas.base
    property bool active

    readonly property int cursorShape: {
        if (document.tool === AnnotationDocument.Select)
            return Qt.ArrowCursor;
        if (document.tool === AnnotationDocument.Text)
            return Qt.IBeamCursor;
        return Qt.CrossCursor;
    }

    readonly property alias editingText: textEditor.visible
    readonly property var tools: [
        {
            icon: "drag_pan",
            tool: AnnotationDocument.Select,
            key: Qt.Key_V
        },
        {
            icon: "edit",
            tool: AnnotationDocument.Pencil,
            key: Qt.Key_1
        },
        {
            icon: "ink_highlighter",
            tool: AnnotationDocument.Highlighter,
            key: Qt.Key_2
        },
        {
            icon: "diagonal_line",
            tool: AnnotationDocument.Line,
            key: Qt.Key_3
        },
        {
            icon: "line_end_arrow",
            tool: AnnotationDocument.Arrow,
            key: Qt.Key_4
        },
        {
            icon: "rectangle",
            tool: AnnotationDocument.Rect,
            key: Qt.Key_5
        },
        {
            icon: "circle",
            tool: AnnotationDocument.Ellipse,
            key: Qt.Key_6
        },
        {
            icon: "insert_text",
            tool: AnnotationDocument.Text,
            key: Qt.Key_7
        },
        {
            icon: "counter_1",
            tool: AnnotationDocument.Counter,
            key: Qt.Key_8
        },
        {
            icon: "blur_on",
            tool: AnnotationDocument.Blur,
            key: Qt.Key_9
        },
        {
            icon: "grain",
            tool: AnnotationDocument.Pixelate,
            key: Qt.Key_0
        }
    ]

    function handleKey(event: KeyEvent): bool {
        if (!active)
            return false;

        if (event.key === Qt.Key_Escape) {
            if (document.selected < 0)
                return false;

            document.deselect();
            return true;
        }

        if (event.modifiers & Qt.ControlModifier) {
            if (event.key === Qt.Key_Z) {
                if (event.modifiers & Qt.ShiftModifier)
                    document.redo();
                else
                    document.undo();
                return true;
            }

            if (event.key === Qt.Key_Y) {
                document.redo();
                return true;
            }

            return false;
        }

        if (event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace) {
            document.deleteSelected();
            return true;
        }

        const entry = tools.find(t => t.key === event.key);
        if (!entry)
            return false;

        document.tool = entry.tool;
        return true;
    }

    AnnotationCanvas {
        id: canvas

        anchors.fill: parent
        document: root.document
        selectionColor: Colours.palette.primary
    }

    MouseArea {
        function globalPos(event: MouseEvent): point {
            return Qt.point(event.x + root.screen.x, event.y + root.screen.y);
        }

        anchors.fill: parent
        enabled: root.active && !textEditor.visible

        onPressed: event => root.document.press(globalPos(event), event.modifiers & Qt.ShiftModifier)
        onPositionChanged: event => root.document.move(globalPos(event), event.modifiers & Qt.ShiftModifier)
        onReleased: root.document.release()
        onDoubleClicked: event => root.document.doubleClick(globalPos(event))
    }

    MouseArea {
        anchors.fill: parent
        enabled: textEditor.visible
        onPressed: textEditor.commit()
    }

    StyledRect {
        visible: textEditor.visible && root.document.textBackground
        x: textEditor.x - Tokens.padding.small
        y: textEditor.y - Tokens.padding.small
        implicitWidth: textEditor.width + Tokens.padding.small * 2
        implicitHeight: textEditor.height + Tokens.padding.small * 2
        radius: Tokens.rounding.small
        color: Qt.alpha("black", 0.67)
    }

    TextInput {
        id: textEditor

        property int editIndex: -1

        function open(index: int, pos: point, initial: string): void {
            editIndex = index;
            x = pos.x;
            y = pos.y;
            text = initial;
            visible = true;
            forceActiveFocus();
        }

        function commit(): void {
            if (!visible)
                return;
            visible = false;
            root.document.setText(editIndex, text);
            root.forceActiveFocus();
        }

        function cancel(): void {
            visible = false;
            root.forceActiveFocus();
        }

        visible: false
        width: Math.max(contentWidth, root.document.fontSize)
        height: contentHeight
        color: root.document.color
        font: root.document.font
        cursorVisible: visible
        renderType: Text.NativeRendering

        onAccepted: commit()
        Keys.onEscapePressed: cancel()
    }

    Connections {
        function onTextEditRequested(index: int, pos: point, text: string): void {
            const local = Qt.point(pos.x - root.screen.x, pos.y - root.screen.y);
            if (local.x < 0 || local.y < 0 || local.x >= root.width || local.y >= root.height)
                return;
            textEditor.open(index, local, text);
        }

        target: root.document
    }
}
