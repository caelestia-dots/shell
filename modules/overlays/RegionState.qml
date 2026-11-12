import QtQuick

QtObject {
    property bool selecting
    property bool empty: true
    property point start
    property point end

    readonly property rect rect: Qt.rect(Math.min(start.x, end.x), Math.min(start.y, end.y), Math.abs(start.x - end.x), Math.abs(start.y - end.y))

    function clear(): void {
        selecting = false;
        empty = true;
    }
}
