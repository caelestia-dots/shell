import QtQuick
import Caelestia.Scheme

QtObject {
    property bool annotate
    property bool open
    property bool selectClients: true
    property bool showCrosshair
    property bool annotating
    readonly property RegionState selection: RegionState {}
    readonly property rect region: selection.rect
    property color customColour: Colours.palette.outline
    property color customBackgroundColour: Colours.palette.outlineVariant

    signal cancelled
}
