pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    required property var bar
    property bool isHorizontal: false
    property color colour: Colours.palette.m3primary

    readonly property string windowTitle: {
        const title = Hypr.activeToplevel?.title;
        if (!title)
            return Tr.trCtx("Desktop", "shown when no window is focused");
        if (Config.bar.activeWindow.compact) {
            const parts = title.split(/\s+[\-\u2013\u2014]\s+/);
            if (parts.length > 1)
                return parts[parts.length - 1].trim();
        }
        return title;
    }

    readonly property real minimumAlong: (isHorizontal ? icon.implicitWidth : icon.implicitHeight) + Tokens.spacing.small
    readonly property real maxAlong: {
        let otherAlong = 0;
        for (const child of bar.children) {
            if (child.entryId && child.item !== this && child.entryId !== "spacer")
                otherAlong += child.item.nonAnimAlong ?? (isHorizontal ? child.item.implicitWidth : child.item.implicitHeight);
        }
        const totalAlong = isHorizontal ? bar.width : bar.height;
        const spacing = isHorizontal ? bar.columnSpacing : bar.rowSpacing;
        return Math.max(0, totalAlong - otherAlong - spacing * Math.max(0, bar.entryCount - 1) - bar.axisPadding * 2);
    }
    property Title current: text1

    clip: true
    implicitWidth: isHorizontal ? (icon.implicitWidth + current.implicitWidth + (current.text.length > 0 ? Tokens.spacing.small : 0)) : Math.max(icon.implicitWidth, current.implicitHeight)
    implicitHeight: isHorizontal ? Math.max(icon.implicitHeight, current.implicitHeight) : (icon.implicitHeight + current.implicitWidth + current.anchors.topMargin)

    Loader {
        asynchronous: true
        width: root.width
        height: parent.height
        active: Config.bar.popouts.activeWindow && !Config.bar.activeWindow.showOnHover

        sourceComponent: MouseArea {
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            containmentMask: QtObject {
                function contains(point: point): bool {
                    return root.bar.activeWindowContains(root, point.x);
                }
            }
            onPositionChanged: {
                const popouts = root.bar.popouts;
                if (popouts.hasCurrent && popouts.currentName !== "activewindow")
                    popouts.hasCurrent = false;
            }
            onClicked: event => {
                // Keep delivered edge clicks consistent with hover ownership.
                if (!root.bar.activeWindowContains(root, event.x))
                    return;
                const popouts = root.bar.popouts;
                if (popouts.hasCurrent) {
                    popouts.hasCurrent = false;
                } else {
                    popouts.currentName = "activewindow";
                    popouts.currentCenter = root.bar.activeWindowCenter(root);
                    popouts.hasCurrent = true;
                }
            }
        }
    }

    MaterialIcon {
        id: icon

        anchors.horizontalCenter: root.isHorizontal ? undefined : parent.horizontalCenter
        anchors.left: root.isHorizontal ? parent.left : undefined
        anchors.verticalCenter: root.isHorizontal ? parent.verticalCenter : undefined

        animate: true
        text: Icons.getAppCategoryIcon(Hypr.activeToplevel?.lastIpcObject.class, "desktop_windows")
        color: root.colour
    }

    Title {
        id: text1
    }

    Title {
        id: text2
    }

    TextMetrics {
        id: metrics

        text: root.windowTitle
        font: root.Tokens.font.body.builders.small.letterSpacing(1.4).build()
        elide: Qt.ElideRight
        elideWidth: Math.max(0, root.maxAlong - root.minimumAlong)

        onTextChanged: {
            const next = root.current === text1 ? text2 : text1;
            next.text = elidedText;
            root.current = next;
        }
        onElideWidthChanged: root.current.text = elidedText
    }

    Behavior on implicitWidth {
        Anim {}
    }

    Behavior on implicitHeight {
        Anim {}
    }

    component Title: StyledText {
        id: text

        anchors.horizontalCenter: root.isHorizontal ? undefined : icon.horizontalCenter
        anchors.top: root.isHorizontal ? undefined : icon.bottom
        anchors.topMargin: root.isHorizontal ? 0 : Tokens.spacing.small

        anchors.left: root.isHorizontal ? icon.right : undefined
        anchors.leftMargin: root.isHorizontal ? Tokens.spacing.small : 0
        anchors.verticalCenter: root.isHorizontal ? icon.verticalCenter : undefined

        font: metrics.font
        color: root.colour
        opacity: root.current === this ? 1 : 0
        horizontalAlignment: Text.AlignLeft

        transform: [
            Translate {
                x: root.isHorizontal ? 0 : (root.Config.bar.activeWindow.inverted ? -text.implicitWidth + text.implicitHeight : 0)
            },
            Rotation {
                angle: root.isHorizontal ? 0 : (root.Config.bar.activeWindow.inverted ? 270 : 90)
                origin.x: text.implicitHeight / 2
                origin.y: text.implicitHeight / 2
            }
        ]

        width: root.isHorizontal ? implicitWidth : implicitHeight
        height: root.isHorizontal ? implicitHeight : implicitWidth

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
