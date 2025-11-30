import ".."
import qs.services
import qs.config
import QtQuick
import QtQuick.Templates

ScrollBar {
    id: root

    required property Flickable flickable
    property bool shouldBeActive
    property real nonAnimPosition
    property bool animating

    onHoveredChanged: {
        if (hovered)
            shouldBeActive = true;
        else
            shouldBeActive = flickable.moving;
    }

    property bool _updatingFromFlickable: false
    property bool _updatingFromUser: false

    // Sync nonAnimPosition with Qt's automatic position binding
    onPositionChanged: {
        if (_updatingFromUser) {
            _updatingFromUser = false;
            return;
        }
        if (position === nonAnimPosition) {
            animating = false;
            return;
        }
        if (!animating && !_updatingFromFlickable && !fullMouse.pressed) {
            nonAnimPosition = position;
        }
    }

    // Sync nonAnimPosition with flickable when not animating
    Connections {
        target: flickable
        function onContentYChanged() {
            if (!animating && !fullMouse.pressed) {
                _updatingFromFlickable = true;
                const contentHeight = flickable.contentHeight;
                const height = flickable.height;
                if (contentHeight > height) {
                    nonAnimPosition = Math.max(0, Math.min(1, flickable.contentY / (contentHeight - height)));
                } else {
                    nonAnimPosition = 0;
                }
                _updatingFromFlickable = false;
            }
        }
    }

    Component.onCompleted: {
        if (flickable) {
            const contentHeight = flickable.contentHeight;
            const height = flickable.height;
            if (contentHeight > height) {
                nonAnimPosition = Math.max(0, Math.min(1, flickable.contentY / (contentHeight - height)));
            }
        }
    }
    implicitWidth: Appearance.padding.small

    contentItem: StyledRect {
        anchors.left: parent.left
        anchors.right: parent.right
        opacity: {
            if (root.size === 1)
                return 0;
            if (fullMouse.pressed)
                return 1;
            if (mouse.containsMouse)
                return 0.8;
            if (root.policy === ScrollBar.AlwaysOn || root.shouldBeActive)
                return 0.6;
            return 0;
        }
        radius: Appearance.rounding.full
        color: Colours.palette.m3secondary

        MouseArea {
            id: mouse

            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }

        Behavior on opacity {
            Anim {}
        }
    }

    Connections {
        target: root.flickable

        function onMovingChanged(): void {
            if (root.flickable.moving)
                root.shouldBeActive = true;
            else
                hideDelay.restart();
        }
    }

    Timer {
        id: hideDelay

        interval: 600
        onTriggered: root.shouldBeActive = root.flickable.moving || root.hovered
    }

    CustomMouseArea {
        id: fullMouse

        anchors.fill: parent
        preventStealing: true

        onPressed: event => {
            root.animating = true;
            root._updatingFromUser = true;
            const newPos = Math.max(0, Math.min(1 - root.size, event.y / root.height - root.size / 2));
            root.nonAnimPosition = newPos;
            // Update flickable position
            // Map scrollbar position [0, 1-size] to contentY [0, maxContentY]
            if (root.flickable) {
                const contentHeight = root.flickable.contentHeight;
                const height = root.flickable.height;
                if (contentHeight > height) {
                    const maxContentY = contentHeight - height;
                    const maxPos = 1 - root.size;
                    const contentY = maxPos > 0 ? (newPos / maxPos) * maxContentY : 0;
                    root.flickable.contentY = Math.max(0, Math.min(maxContentY, contentY));
                }
            }
        }

        onPositionChanged: event => {
            root._updatingFromUser = true;
            const newPos = Math.max(0, Math.min(1 - root.size, event.y / root.height - root.size / 2));
            root.nonAnimPosition = newPos;
            // Update flickable position
            // Map scrollbar position [0, 1-size] to contentY [0, maxContentY]
            if (root.flickable) {
                const contentHeight = root.flickable.contentHeight;
                const height = root.flickable.height;
                if (contentHeight > height) {
                    const maxContentY = contentHeight - height;
                    const maxPos = 1 - root.size;
                    const contentY = maxPos > 0 ? (newPos / maxPos) * maxContentY : 0;
                    root.flickable.contentY = Math.max(0, Math.min(maxContentY, contentY));
                }
            }
        }

        function onWheel(event: WheelEvent): void {
            root.animating = true;
            root._updatingFromUser = true;
            let newPos = root.nonAnimPosition;
            if (event.angleDelta.y > 0)
                newPos = Math.max(0, root.nonAnimPosition - 0.1);
            else if (event.angleDelta.y < 0)
                newPos = Math.min(1 - root.size, root.nonAnimPosition + 0.1);
            root.nonAnimPosition = newPos;
            // Update flickable position
            // Map scrollbar position [0, 1-size] to contentY [0, maxContentY]
            if (root.flickable) {
                const contentHeight = root.flickable.contentHeight;
                const height = root.flickable.height;
                if (contentHeight > height) {
                    const maxContentY = contentHeight - height;
                    const maxPos = 1 - root.size;
                    const contentY = maxPos > 0 ? (newPos / maxPos) * maxContentY : 0;
                    root.flickable.contentY = Math.max(0, Math.min(maxContentY, contentY));
                }
            }
        }
    }

    Behavior on position {
        enabled: !fullMouse.pressed

        Anim {}
    }
}
