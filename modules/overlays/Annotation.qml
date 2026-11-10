pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
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

    property point hoverPos
    property int hoverIndex: -1

    readonly property bool overSelection: {
        if (document.selected < 0)
            return false;
        const b = document.selectedBounds;
        return hoverPos.x >= b.x && hoverPos.x <= b.x + b.width && hoverPos.y >= b.y && hoverPos.y <= b.y + b.height;
    }

    readonly property int cursorShape: {
        if (document.tool === AnnotationDocument.Select) {
            if (overSelection)
                return Qt.SizeAllCursor;
            return hoverIndex >= 0 ? Qt.PointingHandCursor : Qt.ArrowCursor;
        }
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

            if (event.key === Qt.Key_C) {
                document.copy();
                return true;
            }

            if (event.key === Qt.Key_V) {
                document.paste();
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

    function updateHover(): void {
        hoverIndex = active ? document.shapeAt(hoverPos) : -1;
    }

    AnnotationCanvas {
        id: canvas

        anchors.fill: parent
        document: root.document
    }

    Shape {
        id: selection

        readonly property rect bounds: root.document.selectedBounds

        visible: root.document.selected >= 0
        x: bounds.x - root.screen.x
        y: bounds.y - root.screen.y
        width: bounds.width
        height: bounds.height
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: Colours.palette.primary
            strokeWidth: 1.5
            strokeStyle: ShapePath.DashLine
            fillColor: "transparent"

            PathRectangle {
                width: selection.width
                height: selection.height
            }
        }
    }

    MouseArea {
        function globalPos(event: MouseEvent): point {
            return Qt.point(event.x + root.screen.x, event.y + root.screen.y);
        }

        anchors.fill: parent
        enabled: root.active && !textEditor.visible
        hoverEnabled: true

        onPressed: event => root.document.press(globalPos(event), event.modifiers & Qt.ShiftModifier)
        onPositionChanged: event => {
            root.hoverPos = globalPos(event);
            if (pressed)
                root.document.move(root.hoverPos, event.modifiers & Qt.ShiftModifier);
            else
                root.updateHover();
        }
        onReleased: {
            root.document.release();
            root.updateHover();
        }
        onDoubleClicked: event => root.document.doubleClick(globalPos(event))
        onExited: root.hoverIndex = -1
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
        function onChanged(): void {
            root.updateHover();
        }

        function onTextEditRequested(index: int, pos: point, text: string): void {
            const local = Qt.point(pos.x - root.screen.x, pos.y - root.screen.y);
            if (local.x < 0 || local.y < 0 || local.x >= root.width || local.y >= root.height)
                return;
            textEditor.open(index, local, text);
        }

        target: root.document
    }
}
