import QtQuick

QtObject {
    property bool selecting
    property point start: Qt.point(-1, -1)
    property point end: Qt.point(-1, -1)

    readonly property bool empty: start.x < 0
    readonly property rect rect: Qt.rect(Math.min(start.x, end.x), Math.min(start.y, end.y), Math.abs(start.x - end.x), Math.abs(start.y - end.y))

    function clear(): void {
        selecting = false;
        start = Qt.point(-1, -1);
        end = Qt.point(-1, -1);
    }
}
