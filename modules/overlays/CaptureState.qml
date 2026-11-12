import QtQuick
import Caelestia.Scheme

QtObject {
    id: root

    property bool annotate
    property bool open
    property bool annotating

    property color customColour: Colours.palette.outline
    property color customBackgroundColour: Colours.palette.outlineVariant

    readonly property alias region: selection.rect
    readonly property RegionState selection: RegionState {
        id: selection

        onCancelled: root.cancelled()
    }

    signal cancelled
}
