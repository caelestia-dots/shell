pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import Caelestia.Components
import Caelestia.Config
import Caelestia.Scheme
import qs.components
import qs.components.controls

Item {
    id: root

    required property ShellScreen screen
    property alias document: canvas.document
    property alias base: canvas.base
    property bool active

    property point hoverPos
    property int hoverIndex: -1
    property int shownSelected: -1
    property int activeRect: 0

    readonly property bool overSelection: {
        if (document.selected < 0)
            return false;

        const b = padded(document.selectedBounds);
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

    readonly property alias editingText: textEditor.editing
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

    function padded(b: rect): rect {
        const pad = Tokens.padding.medium;
        return Qt.rect(b.x - pad, b.y - pad, b.width + pad * 2, b.height + pad * 2);
    }

    function updateHover(): void {
        hoverIndex = active ? document.shapeAt(hoverPos) : -1;
    }

    AnnotationCanvas {
        id: canvas

        anchors.fill: parent
        document: root.document
    }

    SelectionRect {
        id: rectA

        active: root.activeRect === 0
    }

    SelectionRect {
        id: rectB

        active: root.activeRect === 1
    }

    MouseArea {
        function globalPos(event: MouseEvent): point {
            return Qt.point(event.x + root.screen.x, event.y + root.screen.y);
        }

        anchors.fill: parent
        enabled: root.active && !textEditor.editing
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
        enabled: textEditor.editing
        onPressed: textEditor.commit()
    }

    StyledRect {
        property real opacityMult: root.document.textBackground ? 1 : 0

        opacity: textEditor.opacity * opacityMult
        scale: textEditor.scale
        transformOrigin: Item.TopLeft

        x: textEditor.x - root.document.textPadding
        y: textEditor.y - root.document.textPadding
        implicitWidth: textEditor.width + root.document.textPadding * 2
        implicitHeight: textEditor.height + root.document.textPadding * 2

        radius: root.document.textRadius
        color: root.document.textBackgroundColor

        Behavior on opacityMult {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on implicitHeight {
            Anim {
                type: Anim.FastEffects
            }
        }
    }

    TextAreaBase {
        id: textEditor

        property bool editing
        property bool committing
        property int editIndex: -1

        function open(index: int, pos: point, initial: string): void {
            committing = false;
            editIndex = index;
            x = pos.x;
            y = pos.y;
            text = initial;
            editing = true;
            forceActiveFocus();
        }

        function commit(): void {
            if (!editing)
                return;

            committing = true;
            editing = false;
            root.document.setText(editIndex, text);
            root.forceActiveFocus();
        }

        function cancel(): void {
            editing = false;
            root.forceActiveFocus();
        }

        function handleReturn(event: KeyEvent): void {
            if (event.modifiers & Qt.ShiftModifier)
                event.accepted = false;
            else
                commit();
        }

        enabled: editing
        opacity: editing ? 1 : 0
        scale: editing ? 1 : 0.8
        transformOrigin: Item.TopLeft
        wrapMode: TextEdit.NoWrap
        color: root.document.color
        font: root.document.font

        onEditingFinished: commit()
        Keys.onReturnPressed: event => handleReturn(event)
        Keys.onEnterPressed: event => handleReturn(event)
        Keys.onEscapePressed: cancel()

        Behavior on opacity {
            enabled: !textEditor.committing

            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on scale {
            enabled: !textEditor.committing

            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Connections {
        function onChanged(): void {
            root.updateHover();
        }

        function onSelectedBoundsChanged(): void {
            const sel = root.document.selected;
            if (sel !== root.shownSelected) {
                if (sel >= 0 && root.shownSelected >= 0)
                    root.activeRect = 1 - root.activeRect;
                root.shownSelected = sel;
            }
            if (sel >= 0)
                (root.activeRect === 0 ? rectA : rectB).bounds = root.padded(root.document.selectedBounds);
        }

        function onTextEditRequested(index: int, pos: point, text: string): void {
            const local = Qt.point(pos.x - root.screen.x, pos.y - root.screen.y);
            if (local.x < 0 || local.y < 0 || local.x >= root.width || local.y >= root.height)
                return;
            textEditor.open(index, local, text);
        }

        target: root.document
    }

    component SelectionRect: Shape {
        id: shape

        property rect bounds
        property bool active

        x: bounds.x - root.screen.x
        y: bounds.y - root.screen.y
        width: bounds.width
        height: bounds.height
        preferredRendererType: Shape.CurveRenderer
        opacity: active && root.document.selected >= 0 ? 1 : 0

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        ShapePath {
            strokeColor: Colours.palette.primary
            strokeWidth: 2
            strokeStyle: ShapePath.DashLine
            fillColor: "transparent"

            Behavior on strokeColor {
                CAnim {}
            }

            PathRectangle {
                radius: root.Tokens.rounding.medium
                width: shape.width
                height: shape.height
            }
        }
    }
}
