import QtQuick

QtObject {
    property bool annotate
    property bool open
    property bool selectClients: true
    property bool showCrosshair
    property bool annotating
    property rect region

    signal cancelled
}
