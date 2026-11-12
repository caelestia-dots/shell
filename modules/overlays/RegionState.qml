import QtQuick

QtObject {
    property bool selecting
    property bool empty: true
    property bool selectClients: true
    property bool showCrosshair
    property point start
    property point end

    readonly property rect rect: Qt.rect(Math.min(start.x, end.x), Math.min(start.y, end.y), Math.abs(start.x - end.x), Math.abs(start.y - end.y))

    signal cancelled

    function clear(): void {
        selecting = false;
        empty = true;
    }
}
