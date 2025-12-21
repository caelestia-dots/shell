import ".."
import qs.components.effects
import qs.services
import qs.config
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root

    required property Item target
    required property string text
    property int delay: 500
    property int timeout: 0

    property bool tooltipVisible: false
    property Timer showTimer: Timer {
        interval: root.delay
        onTriggered: root.tooltipVisible = true
    }
    property Timer hideTimer: Timer {
        interval: root.timeout
        onTriggered: root.tooltipVisible = false
    }

    // Popup properties - doesn't affect layout
    parent: {
        let p = target;
        // Walk up to find the root Item (usually has anchors.fill: parent)
        while (p && p.parent) {
            const parentItem = p.parent;
            // Check if this looks like a root pane Item
            if (parentItem && parentItem.anchors && parentItem.anchors.fill !== undefined) {
                return parentItem;
            }
            p = parentItem;
        }
        // Fallback
        return target.parent?.parent?.parent ?? target.parent?.parent ?? target.parent ?? target;
    }

    visible: tooltipVisible
    modal: false
    closePolicy: Popup.NoAutoClose
    padding: 0
    margins: 0
    background: Item {}

    // Update position when target moves or tooltip becomes visible
    onTooltipVisibleChanged: {
        if (tooltipVisible) {
            Qt.callLater(updatePosition);
        }
    }
    Connections {
        target: root.target
        function onXChanged() { if (root.tooltipVisible) root.updatePosition(); }
        function onYChanged() { if (root.tooltipVisible) root.updatePosition(); }
        function onWidthChanged() { if (root.tooltipVisible) root.updatePosition(); }
        function onHeightChanged() { if (root.tooltipVisible) root.updatePosition(); }
    }

    function updatePosition() {
        if (!target || !parent) return;
        
        // Wait for tooltipRect to have its size calculated
        Qt.callLater(() => {
            if (!target || !parent || !tooltipRect) return;
            
            // Get target position in parent's coordinate system
            const targetPos = target.mapToItem(parent, 0, 0);
            const targetCenterX = targetPos.x + target.width / 2;
            
            // Get tooltip size (use width/height if available, otherwise implicit)
            const tooltipWidth = tooltipRect.width > 0 ? tooltipRect.width : tooltipRect.implicitWidth;
            const tooltipHeight = tooltipRect.height > 0 ? tooltipRect.height : tooltipRect.implicitHeight;
            
            // Center tooltip horizontally on target
            let newX = targetCenterX - tooltipWidth / 2;
            
            // Position tooltip above target
            let newY = targetPos.y - tooltipHeight - Appearance.spacing.small;
            
            // Keep within bounds
            const padding = Appearance.padding.normal;
            if (newX < padding) {
                newX = padding;
            } else if (newX + tooltipWidth > (parent.width - padding)) {
                newX = parent.width - tooltipWidth - padding;
            }
            
            // Update popup position
            x = newX;
            y = newY;
        });
    }

    enter: Transition {
        Anim {
            property: "opacity"
            from: 0
            to: 1
            duration: Appearance.anim.durations.expressiveFastSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
        }
    }

    exit: Transition {
        Anim {
            property: "opacity"
            from: 1
            to: 0
            duration: Appearance.anim.durations.expressiveFastSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
        }
    }

    // Monitor hover state
    Connections {
        target: root.target
        function onHoveredChanged() {
            if (target.hovered) {
                showTimer.start();
                if (timeout > 0) {
                    hideTimer.stop();
                    hideTimer.start();
                }
            } else {
                showTimer.stop();
                hideTimer.stop();
                tooltipVisible = false;
            }
        }
    }

    contentItem: StyledRect {
        id: tooltipRect

        implicitWidth: tooltipText.implicitWidth + Appearance.padding.normal * 2
        implicitHeight: tooltipText.implicitHeight + Appearance.padding.smaller * 2

        color: Colours.palette.m3surfaceContainerHighest
        radius: Appearance.rounding.small
        antialiasing: true

        // Add elevation for depth
        Elevation {
            anchors.fill: parent
            radius: parent.radius
            z: -1
            level: 3
        }

        StyledText {
            id: tooltipText

            anchors.centerIn: parent
            
            text: root.text
            color: Colours.palette.m3onSurface
            font.pointSize: Appearance.font.size.small
        }
    }

    Component.onCompleted: {
        if (tooltipVisible) {
            updatePosition();
        }
    }
}

