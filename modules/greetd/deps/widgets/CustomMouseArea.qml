import QtQuick

MouseArea {
    property int scrollAccumulatedY: 0

    function onWheel(event: WheelEvent): void {
    }

    onWheel: event => {
        // Update accumulated scroll
        if (Math.sign(event.angleDelta.y) !== Math.sign(scrollAccumulatedY))
            scrollAccumulatedY = 0;
        scrollAccumulatedY += event.angleDelta.y;

        // Trigger handler and reset if above threshold
        if (Math.abs(scrollAccumulatedY) >= 120) {
            onWheel(event);
            scrollAccumulatedY = 0;
        }
    }
}
