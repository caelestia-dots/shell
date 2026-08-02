pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    required property var bar
    required property Brightness.Monitor monitor
    required property bool horizontal
    property color colour: Colours.palette.m3primary

    readonly property string windowTitle: {
        const title = Hypr.activeToplevel?.title;
        if (!title)
            return qsTr("Desktop");
        if (Config.bar.activeWindow.compact) {
            // " - " (standard hyphen), " — " (em dash), " – " (en dash)
            const parts = title.split(/\s+[\-\u2013\u2014]\s+/);
            if (parts.length > 1)
                return parts[parts.length - 1].trim();
        }
        return title;
    }

    readonly property int maxSize: {
        const otherModules = bar.children.filter(c => c.entryId && c.item !== this && c.entryId !== "spacer");
        const otherSize = otherModules.reduce((acc, curr) => acc + (horizontal ? (curr.item.nonAnimWidth ?? curr.width) : (curr.item.nonAnimHeight ?? curr.height)), 0);
        // Length - 2 cause repeater counts as a child
        return horizontal ? bar.width - otherSize - bar.columnSpacing * (bar.children.length - 1) - bar.axisPadding * 2 : bar.height - otherSize - bar.rowSpacing * (bar.children.length - 1) - bar.axisPadding * 2;
    }
    property Title current: text1

    clip: true
    implicitWidth: horizontal ? icon.implicitWidth + current.implicitWidth + current.anchors.leftMargin : Math.max(icon.implicitWidth, current.implicitHeight)
    implicitHeight: horizontal ? Math.max(icon.implicitHeight, current.implicitHeight) : icon.implicitHeight + current.implicitWidth + current.anchors.topMargin

    Loader {
        asynchronous: true
        anchors.fill: parent
        active: !Config.bar.activeWindow.showOnHover

        sourceComponent: MouseArea {
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onPositionChanged: {
                const popouts = root.bar.popouts;
                if (popouts.hasCurrent && popouts.currentName !== "activewindow")
                    popouts.hasCurrent = false;
            }
            onClicked: {
                const popouts = root.bar.popouts;
                if (popouts.hasCurrent) {
                    popouts.hasCurrent = false;
                } else {
                    popouts.currentName = "activewindow";
                    popouts.currentCenter = root.bar.axisCenterOf(root);
                    popouts.hasCurrent = true;
                }
            }
        }
    }

    MaterialIcon {
        id: icon

        anchors.horizontalCenter: root.horizontal ? undefined : parent.horizontalCenter
        anchors.verticalCenter: root.horizontal ? parent.verticalCenter : undefined
        anchors.left: root.horizontal ? parent.left : undefined

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
        elideWidth: root.maxSize - (root.horizontal ? icon.width + root.current.anchors.leftMargin : icon.height)

        onTextChanged: {
            const next = root.current === text1 ? text2 : text1;
            next.text = elidedText;
            root.current = next;
        }
        onElideWidthChanged: root.current.text = elidedText
    }

    Behavior on implicitHeight {
        Anim {}
    }

    Behavior on implicitWidth {
        enabled: root.horizontal

        Anim {}
    }

    component Title: StyledText {
        id: text

        anchors.horizontalCenter: root.horizontal ? undefined : icon.horizontalCenter
        anchors.verticalCenter: root.horizontal ? icon.verticalCenter : undefined
        anchors.left: root.horizontal ? icon.right : undefined
        anchors.top: root.horizontal ? undefined : icon.bottom
        anchors.leftMargin: root.horizontal ? Tokens.spacing.small : 0
        anchors.topMargin: root.horizontal ? 0 : Tokens.spacing.small

        font: metrics.font
        color: root.colour
        opacity: root.current === this ? 1 : 0
        horizontalAlignment: Text.AlignLeft

        transform: [
            Translate {
                x: !root.horizontal && root.Config.bar.activeWindow.inverted ? -text.implicitWidth + text.implicitHeight : 0
            },
            Rotation {
                angle: root.horizontal ? 0 : root.Config.bar.activeWindow.inverted ? 270 : 90
                origin.x: text.implicitHeight / 2
                origin.y: text.implicitHeight / 2
            }
        ]

        width: root.horizontal ? implicitWidth : implicitHeight
        height: root.horizontal ? implicitHeight : implicitWidth

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
