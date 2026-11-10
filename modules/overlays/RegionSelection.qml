pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import Caelestia.Scheme
import qs.components
import qs.components.effects

Item {
    id: root

    required property bool resizeMode

    property real sx: -1
    property real sy: -1
    property real ex: -1
    property real ey: -1

    readonly property rect rect: Qt.rect(Math.min(sx, ex), Math.min(sy, ey), Math.abs(sx - ex), Math.abs(sy - ey))

    readonly property int borderWidth: 1
    readonly property real handleSize: Tokens.padding.medium
    readonly property real handleLength: Tokens.padding.extraLarge
    readonly property real handlePadding: Tokens.padding.small
    readonly property real handleSpace: handleLength + handleSize + handlePadding * 4

    function clear(): void {
        sx = -1;
        sy = -1;
        ex = -1;
        ey = -1;
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

            x: root.rect.x
            y: root.rect.y
            implicitWidth: root.rect.width
            implicitHeight: root.rect.height
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

    component ResizeHandle: MouseArea {
        property alias innerWidth: resizeInner.implicitWidth
        property alias innerHeight: resizeInner.implicitHeight
        property string xProp
        property string yProp
        readonly property bool fits: (xProp && yProp) || (xProp ? root.rect.height : root.rect.width) >= root.handleSpace

        property point pressPos
        property real startX
        property real startY

        enabled: root.resizeMode && fits
        preventStealing: true

        onPressed: event => {
            if (root.sx > root.ex)
                [root.sx, root.ex] = [root.ex, root.sx];
            if (root.sy > root.ey)
                [root.sy, root.ey] = [root.ey, root.sy];

            pressPos = mapToItem(root, event.x, event.y);
            if (xProp)
                startX = root[xProp];
            if (yProp)
                startY = root[yProp];
        }
        onPositionChanged: event => {
            if (!pressed)
                return;

            const p = mapToItem(root, event.x, event.y);
            if (xProp)
                root[xProp] = Math.max(0, Math.min(root.width, startX + p.x - pressPos.x));
            if (yProp)
                root[yProp] = Math.max(0, Math.min(root.height, startY + p.y - pressPos.y));
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
