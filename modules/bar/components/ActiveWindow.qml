pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    required property var bar
    required property Brightness.Monitor monitor
    property color colour: Colours.palette.m3primary

    readonly property string edge: Config.bar.alignment
    readonly property bool isHorizontal: edge === "top" || edge === "bottom"

    readonly property string windowTitle: {
        const title = Hypr.activeToplevel?.title;
        if (!title)
            return qsTr("Desktop");
        if (Config.bar.activeWindow.compact) {
            const parts = title.split(/\s+[\-\u2013\u2014]\s+/);
            if (parts.length > 1)
                return parts[parts.length - 1].trim();
        }
        return title;
    }

    readonly property int maxAllowedLength: {
        if (!root.bar || !root.bar.children)
            return 300;
        
        const otherModules = root.bar.children.filter(c => c.entryId && c.item !== root && c.entryId !== "spacer");
        let consumedSpace = 0;
        
        for (let i = 0; i < otherModules.length; i++) {
            const wrapper = otherModules[i];
            if (!wrapper || !wrapper.item)
                continue;
            
            let size = root.isHorizontal 
                ? (wrapper.item.nonAnimWidth ?? wrapper.implicitWidth) 
                : (wrapper.item.nonAnimHeight ?? wrapper.implicitHeight);
                
            if (!isNaN(size) && size > 0) {
                consumedSpace += size;
            }
        }
        
        const spacing = root.isHorizontal ? root.bar.columnSpacing : root.bar.rowSpacing;
        const totalSpacing = spacing * (root.bar.children.length - 1);
        const totalSize = root.isHorizontal ? root.bar.width : root.bar.height;
        const paddings = root.bar.edgePadding * 2;
        
        let space = totalSize - consumedSpace - totalSpacing - paddings - Tokens.spacing.large;
        
        if (isNaN(space) || space < 50)
            return 300; 
        return space;
    }

    property Title current: text1
    clip: true

    readonly property int desiredLength: icon.implicitWidth + (windowTitle !== "" ? root.current.implicitWidth + Tokens.spacing.small : 0)
    readonly property int clampedLength: Math.min(desiredLength, maxAllowedLength)

    implicitWidth: isHorizontal ? clampedLength : Tokens.sizes.bar.innerWidth
    implicitHeight: isHorizontal ? Tokens.sizes.bar.innerWidth : clampedLength

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
                    popouts.currentCenter = root.isHorizontal 
                        ? root.mapToItem(root.bar, root.implicitWidth / 2, 0).x 
                        : root.mapToItem(root.bar, 0, root.implicitHeight / 2).y;
                    popouts.hasCurrent = true;
                }
            }
        }
    }

    Item {
        anchors.centerIn: parent
        width: root.isHorizontal ? parent.width : parent.height
        height: root.isHorizontal ? parent.height : parent.width
        
        rotation: root.isHorizontal ? 0 : (Config.bar.activeWindow.inverted ? 270 : 90)

        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: Tokens.spacing.small

            MaterialIcon {
                id: icon
                anchors.verticalCenter: parent.verticalCenter
                animate: true
                text: Icons.getAppCategoryIcon(Hypr.activeToplevel?.lastIpcObject.class, "desktop_windows")
                color: root.colour
                rotation: root.isHorizontal ? 0 : (Config.bar.activeWindow.inverted ? -270 : -90)
            }

            Item {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.windowTitle !== ""
                width: root.current.implicitWidth
                height: root.current.implicitHeight

                Title {
                    id: text1
                }

                Title {
                    id: text2
                }
            }
        }
    }

    property font metricsFont: Tokens.font.body.builders.small.letterSpacing(1.4).build()
    property real metricsElideWidth: Math.max(20, root.maxAllowedLength - icon.implicitWidth - Tokens.spacing.small)

    TextMetrics {
        id: metrics
        text: root.windowTitle || ""
        font: root.metricsFont
        elide: Qt.ElideRight
        elideWidth: root.metricsElideWidth

        onTextChanged: {
            const next = root.current === text1 ? text2 : text1;
            next.text = elidedText || ""; 
            root.current = next;
        }
        onElideWidthChanged: root.current.text = elidedText || "" 
    }

    Behavior on implicitHeight {
        Anim {}
    }
    Behavior on implicitWidth {
        Anim {}
    }

    component Title: StyledText {
        id: titleText
        property string textVal: ""
        text: textVal || ""
        anchors.verticalCenter: parent.verticalCenter
        font: root.metricsFont
        color: root.colour
        opacity: root.current === this ? 1 : 0
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        Behavior on opacity {
            Anim { type: Anim.DefaultEffects }
        }
    }
}