pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import Caelestia.Scheme
import qs.components

Item {
    id: root

    required property RegionState selection
    required property point origin
    required property bool resizeMode

    readonly property rect rect: Qt.rect(selection.rect.x - origin.x, selection.rect.y - origin.y, selection.rect.width, selection.rect.height)
    readonly property real dim: Colours.mode === Colours.Light ? 0.3 : 0.4

    readonly property int borderWidth: 1
    readonly property real handleSize: Tokens.padding.medium
    readonly property real handleLength: Tokens.padding.extraLarge
    readonly property real handlePadding: Tokens.padding.small
    readonly property real handleSpace: handleLength + handleSize + handlePadding * 4

    StyledRect {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: selectionRect.top
        color: Qt.alpha("black", root.dim)
    }

    StyledRect {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: selectionRect.bottom
        anchors.bottom: parent.bottom
        color: Qt.alpha("black", root.dim)
    }

    StyledRect {
        anchors.left: parent.left
        anchors.right: selectionRect.left
        anchors.top: selectionRect.top
        anchors.bottom: selectionRect.bottom
        color: Qt.alpha("black", root.dim)
    }

    StyledRect {
        anchors.left: selectionRect.right
        anchors.right: parent.right
        anchors.top: selectionRect.top
        anchors.bottom: selectionRect.bottom
        color: Qt.alpha("black", root.dim)
    }

    StyledRect {
        id: selectionRect

        x: Math.round(root.rect.x)
        y: Math.round(root.rect.y)
        implicitWidth: Math.round(root.rect.width)
        implicitHeight: Math.round(root.rect.height)

        color: Qt.alpha("black", root.dim * (root.selection.empty ? 1 : 0))
    }

    Rectangle {
        id: border

        opacity: root.selection.empty ? 0 : 1
        color: "transparent"
        border.width: root.borderWidth
        border.color: Colours.palette.primary

        x: selectionRect.x - root.borderWidth
        y: selectionRect.y - root.borderWidth
        implicitWidth: selectionRect.implicitWidth + root.borderWidth * 2
        implicitHeight: selectionRect.implicitHeight + root.borderWidth * 2

        Behavior on opacity {
            Anim {
                type: Anim.SlowEffects
            }
        }

        Behavior on border.color {
            CAnim {}
        }

        StyledRect {
            id: geomContainer

            readonly property bool inCorner: root.rect.width > implicitWidth * 2 && root.rect.height > implicitHeight * 4
            property real heightMult: inCorner ? 1 : 0

            x: parent.width - implicitWidth
            y: parent.height - implicitHeight * heightMult

            topLeftRadius: inCorner || root.rect.width < implicitWidth ? Tokens.rounding.small : 0
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

                text: "0".repeat(Math.round(root.rect.width).toString().length) + " x " + "0".repeat(Math.round(root.rect.height).toString().length)
                font: geomLabel.font
            }

            StyledText {
                id: geomLabel

                anchors.centerIn: parent
                width: geomLabelMetrics.width
                height: geomLabelMetrics.height
                horizontalAlignment: Text.AlignHCenter

                text: Math.round(root.rect.width) + " x " + Math.round(root.rect.height)
                color: Colours.palette.onPrimary
                font: Tokens.font.label.small
            }
        }

        ResizeHandle {
            anchors.horizontalCenter: parent.left
            anchors.verticalCenter: parent.verticalCenter
            cursorShape: Qt.SizeHorCursor
            innerHeight: root.handleLength
            xPoint: "start"
        }

        ResizeHandle {
            anchors.horizontalCenter: parent.left
            anchors.verticalCenter: parent.top
            cursorShape: Qt.SizeFDiagCursor
            xPoint: "start"
            yPoint: "start"
        }

        ResizeHandle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.top
            cursorShape: Qt.SizeVerCursor
            innerWidth: root.handleLength
            yPoint: "start"
        }

        ResizeHandle {
            anchors.horizontalCenter: parent.right
            anchors.verticalCenter: parent.top
            cursorShape: Qt.SizeBDiagCursor
            xPoint: "end"
            yPoint: "start"
        }

        ResizeHandle {
            anchors.horizontalCenter: parent.right
            anchors.verticalCenter: parent.verticalCenter
            cursorShape: Qt.SizeHorCursor
            innerHeight: root.handleLength
            xPoint: "end"
        }

        ResizeHandle {
            anchors.horizontalCenter: parent.right
            anchors.verticalCenter: parent.bottom
            cursorShape: Qt.SizeFDiagCursor
            xPoint: "end"
            yPoint: "end"
        }

        ResizeHandle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.bottom
            cursorShape: Qt.SizeVerCursor
            innerWidth: root.handleLength
            yPoint: "end"
        }

        ResizeHandle {
            anchors.horizontalCenter: parent.left
            anchors.verticalCenter: parent.bottom
            cursorShape: Qt.SizeBDiagCursor
            xPoint: "start"
            yPoint: "end"
        }
    }

    component ResizeHandle: MouseArea {
        property alias innerWidth: resizeInner.implicitWidth
        property alias innerHeight: resizeInner.implicitHeight
        property string xPoint
        property string yPoint
        readonly property bool fits: (xPoint && yPoint) || (xPoint ? root.rect.height : root.rect.width) >= root.handleSpace

        property point pressPos
        property real startX
        property real startY
        property real startRatio

        enabled: root.resizeMode && !root.selection.empty && fits
        preventStealing: true

        onPressed: event => {
            if (event.modifiers & Qt.ControlModifier) {
                event.accepted = false;
                return;
            }

            const r = root.selection.rect;
            const topLeft = Qt.point(r.x, r.y);
            const bottomRight = Qt.point(r.x + r.width, r.y + r.height);
            root.selection.start = topLeft;
            root.selection.end = bottomRight;

            pressPos = mapToItem(root, event.x, event.y);
            if (xPoint)
                startX = root.selection[xPoint].x;
            if (yPoint)
                startY = root.selection[yPoint].y;
            startRatio = root.rect.width > 0 ? root.rect.height / root.rect.width : 1;
        }
        onPositionChanged: event => {
            if (!pressed)
                return;

            const p = mapToItem(root, event.x, event.y);
            let dx = p.x - pressPos.x;
            let dy = p.y - pressPos.y;

            if (xPoint && yPoint && event.modifiers & Qt.ShiftModifier) {
                const diagX = xPoint === "start" ? -1 : 1;
                const diagY = (yPoint === "start" ? -1 : 1) * startRatio;
                const t = (dx * diagX + dy * diagY) / (diagX * diagX + diagY * diagY);
                dx = t * diagX;
                dy = t * diagY;
            }

            if (xPoint)
                root.selection[xPoint] = Qt.point(startX + dx, root.selection[xPoint].y);
            if (yPoint)
                root.selection[yPoint] = Qt.point(root.selection[yPoint].x, startY + dy);
        }

        implicitWidth: resizeInner.implicitWidth + root.handlePadding * 2
        implicitHeight: resizeInner.implicitHeight + root.handlePadding * 2

        scale: root.resizeMode && !root.selection.empty && fits ? 1 : 0

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
