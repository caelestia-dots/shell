import QtQuick

QtObject {
    property bool annotate
    property bool open
    property bool selectClients: true
    property bool showCrosshair

    signal saved(path: string)
    signal cancelled
}
