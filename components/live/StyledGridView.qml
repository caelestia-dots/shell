pragma ComponentBehavior: Bound
import ".."
import QtQuick

Item {
    id: root

    property var model
    property int cellHeight: 40
    property int spacing: 8
    property int paddingX: 12
    property int minCellWidth: 0

    property Component cellContent

    implicitHeight: {
        if (!model || model.length === 0) return 0
        const cols = Math.max(1, Math.floor(width / (cellWidth + spacing)))
        const rows = Math.ceil(model.length / cols)
        return rows * (cellHeight + spacing) - spacing
    }

    readonly property int cellWidth: {
        const minWidth = Math.max(minCellWidth, Math.ceil(_maxImplicitWidth + paddingX * 2))
        const availableWidth = width
        if (availableWidth <= 0) return minWidth

        // Calculate how many columns can fit at minimum width
        const maxCols = Math.floor(availableWidth / (minWidth + spacing))
        if (maxCols <= 0) return minWidth

        // Distribute available width evenly across columns
        const optimalWidth = Math.floor((availableWidth - (spacing * maxCols)) / maxCols)
        return Math.max(minWidth, optimalWidth)
    }

    property real _maxImplicitWidth: 0

    function _recalcMax() {
        let m = 0
        for (let i = 0; i < measurer.count; i++) {
            const o = measurer.objectAt(i)
            if (o) m = Math.max(m, o.measuredWidth)
        }
        _maxImplicitWidth = m
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
    }

    GridView {
        id: view

        anchors.fill: parent
        clip: true

        model: root.model

        cellWidth: root.cellWidth + root.spacing
        cellHeight: root.cellHeight + root.spacing

        delegate: Item {
            required property var modelData
            required property int index

            width: view.cellWidth - root.spacing
            height: view.cellHeight - root.spacing

            Loader {
                anchors.fill: parent
                sourceComponent: root.cellContent

                onLoaded: {
                    if (item && item.hasOwnProperty("modelData")) {
                        item.modelData = Qt.binding(() => parent.modelData)
                    }
                }
            }
        }
    }

    Item {
        id: measureHost

        visible: false
        opacity: 0
        width: 0
        height: 0
    }

    Instantiator {
        id: measurer

        model: root.model

        delegate: Item {
            id: probe

            required property var modelData
            required property int index

            parent: measureHost

            property real measuredWidth: 0

            Loader {
                id: probeLoader

                sourceComponent: root.cellContent

                onLoaded: {
                    Qt.callLater(() => {
                        if (probeLoader.item) {
                            probeLoader.item.modelData = Qt.binding(() => probe.modelData)
                            probe.measuredWidth = probeLoader.item.implicitWidth
                        }
                        root._recalcMax()
                    })
                }
            }

            Connections {
                target: probeLoader.item
                function onImplicitWidthChanged() {
                    probe.measuredWidth = probeLoader.item.implicitWidth
                    root._recalcMax()
                }
            }
        }

        onObjectAdded: root._recalcMax()
        onObjectRemoved: root._recalcMax()
    }

    onModelChanged: _recalcMax()
    onCellContentChanged: _recalcMax()
}