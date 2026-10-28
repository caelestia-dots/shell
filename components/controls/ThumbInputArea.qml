import QtQuick
import QtQuick.Templates

MouseArea {
    id: root

    enum GestureState {
        Idle,
        Pressed,
        Dragging,
        Canceled
    }

    required property Slider slider
    readonly property bool dragging: gesture === ThumbInputArea.GestureState.Dragging
    property real previewValue: slider.value

    property int gesture: ThumbInputArea.GestureState.Idle
    property real pressGlobalX: 0
    property real pressGlobalY: 0
    property real pressValue: 0
    property real dragTravel: 1
    property real dragRange: 1
    property real pressThreshold: 4

    signal interactionStarted
    signal tapped
    signal dragStarted
    signal dragMoved(real nextValue)
    signal dragEnded

    function hitCircle(localX: real, localY: real): bool {
        const dx = localX - width / 2;
        const dy = localY - height / 2;
        const radius = Math.min(width, height) / 2;
        return dx * dx + dy * dy <= radius * radius;
    }

    function movePointer(globalX: real, globalY: real): void {
        if (gesture === ThumbInputArea.GestureState.Idle || gesture === ThumbInputArea.GestureState.Canceled)
            return;

        const dx = globalX - pressGlobalX;
        const dy = globalY - pressGlobalY;
        const distance = Math.hypot(dx, dy);

        if (gesture === ThumbInputArea.GestureState.Pressed && distance > pressThreshold) {
            if (Math.abs(dx) > Math.abs(dy) * 1.8) {
                gesture = ThumbInputArea.GestureState.Canceled;
                return;
            }
            gesture = ThumbInputArea.GestureState.Dragging;
            dragStarted();
        }
        if (gesture !== ThumbInputArea.GestureState.Dragging)
            return;

        const lower = Math.min(slider.from, slider.to);
        const upper = Math.max(slider.from, slider.to);
        const next = Math.max(lower, Math.min(upper, pressValue - dy * dragRange / dragTravel));

        if (Math.abs(next - previewValue) > 0.0001) {
            previewValue = next;
            dragMoved(next);
        }
    }

    function resetGesture(): void {
        gesture = ThumbInputArea.GestureState.Idle;
    }

    acceptedButtons: Qt.LeftButton
    hoverEnabled: true
    preventStealing: true
    cursorShape: Qt.PointingHandCursor

    onPressed: mouse => {
        if (gesture !== ThumbInputArea.GestureState.Idle || !hitCircle(mouse.x, mouse.y)) {
            mouse.accepted = false;
            return;
        }
        const global = mapToGlobal(mouse.x, mouse.y);
        pressGlobalX = global.x;
        pressGlobalY = global.y;
        pressValue = slider.value;
        previewValue = pressValue;
        dragTravel = Math.max(1, slider.availableHeight - slider.handle.height);
        dragRange = slider.to - slider.from;
        pressThreshold = mouse.source === Qt.MouseEventNotSynthesized ? 4 : 8;
        gesture = ThumbInputArea.GestureState.Pressed;
        interactionStarted();
    }

    onPositionChanged: mouse => {
        const global = mapToGlobal(mouse.x, mouse.y);
        movePointer(global.x, global.y);
    }

    onReleased: mouse => {
        const global = mapToGlobal(mouse.x, mouse.y);
        movePointer(global.x, global.y);
        const finished = gesture;
        resetGesture();
        if (finished === ThumbInputArea.GestureState.Pressed)
            tapped();
        else if (finished === ThumbInputArea.GestureState.Dragging)
            dragEnded();
    }

    onCanceled: {
        const wasDragging = dragging;
        resetGesture();
        if (wasDragging)
            dragEnded();
    }

    onWheel: wheel => wheel.accepted = false
}
