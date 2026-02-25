pragma ComponentBehavior: Bound
import ".."
import QtQuick

Item {
    id: root

    property var model
    property int cellHeight: 40
    property int spacing: Appearance.spacing.small
    property int paddingX: Appearance.padding.larger
    property int paddingY: Appearance.padding.larger
    property int minCellWidth: 0
    property int maxCellWidth: 0
    property int minCellHeight: 0
    property int columns: 0
    property bool centerCells: false

    property Component cellContent

    readonly property int modelCount: {
        if (!model)
            return 0;
        if (model.count !== undefined)
            return model.count;
        if (model.length !== undefined)
            return model.length;
        return 0;
    }

    implicitHeight: {
        if (modelCount === 0)
            return 0;
        const cols = Math.max(1, Math.floor((width + spacing) / (cellWidth + spacing)));
        const rows = Math.ceil(modelCount / cols);
        const effectiveHeight = _effectiveCellHeight;
        return rows * (effectiveHeight + spacing) - spacing;
    }

    readonly property int _effectiveCellHeight: {
        // If cellHeight is explicitly set (non-zero), use it
        if (cellHeight > 0)
            return cellHeight;
        // Otherwise use measured height (auto mode)
        const measured = Math.max(minCellHeight, Math.ceil(_maxImplicitHeight + paddingY * 2));
        return measured > 0 ? measured : 40; // Fallback to 40 if measurement incomplete
    }

    readonly property int _calculatedColumns: {
        const minWidth = Math.max(minCellWidth, Math.ceil(_maxImplicitWidth + paddingX * 2));
        const clampedWidth = maxCellWidth > 0 ? Math.min(minWidth, maxCellWidth) : minWidth;
        const availableWidth = width;
        if (availableWidth <= 0)
            return 1;

        // Calculate how many columns can fit at minimum width
        const maxCols = Math.floor((availableWidth + spacing) / (clampedWidth + spacing));
        return Math.max(1, maxCols);
    }

    readonly property int cellWidth: {
        const W = Math.floor(width);
        if (W <= 0)
            return 0;


        if (centerCells && maxCellWidth > 0) {
            return maxCellWidth;
        }

        // Use explicit columns if set, otherwise auto-calculate
        const cols = columns > 0 ? columns : Math.min(_calculatedColumns, Math.max(1, modelCount));


        let w = Math.floor(W / cols) - spacing;

        if (maxCellWidth > 0) {
            w = Math.min(w, maxCellWidth);
        }

        return Math.max(0, w);
    }

    property real _maxImplicitWidth: 0
    property real _maxImplicitHeight: 0
    property bool _measurementComplete: false
    property bool _recalcScheduled: false

    onModelChanged: {
        _measurementComplete = false;
        _maxImplicitWidth = 0;
        _maxImplicitHeight = 0;
    }

    onCellContentChanged: {
        _measurementComplete = false;
        _maxImplicitWidth = 0;
        _maxImplicitHeight = 0;
    }

    function _getMeasureWidth(item) {
        if (!item)
            return 0;
        if (item.hasOwnProperty("gridMeasureWidth"))
            return item.gridMeasureWidth;
        if (item.hasOwnProperty("measureWidth"))
            return item.measureWidth;
        return item.implicitWidth;
    }

    function _getMeasureHeight(item) {
        if (!item)
            return 0;
        if (item.hasOwnProperty("gridMeasureHeight"))
            return item.gridMeasureHeight;
        if (item.hasOwnProperty("measureHeight"))
            return item.measureHeight;
        return item.implicitHeight;
    }

    function _scheduleRecalc() {
        if (_recalcScheduled)
            return;
        _recalcScheduled = true;
        Qt.callLater(() => {
            _recalcScheduled = false;
            _recalcMax();
        });
    }

    function _recalcMax() {
        let maxW = 0;
        let maxH = 0;
        let loadedCount = 0;
        for (let i = 0; i < measurer.count; i++) {
            const o = measurer.objectAt(i);
            if (o) {
                if (o.loaded) {
                    loadedCount++;
                    maxW = Math.max(maxW, o.measuredWidth);
                    maxH = Math.max(maxH, o.measuredHeight);
                }
            }
        }
        _maxImplicitWidth = maxW;
        _maxImplicitHeight = maxH;

        _measurementComplete = (loadedCount === modelCount && modelCount > 0);
    }

    Loader {
        anchors.fill: parent
        active: root._measurementComplete

        sourceComponent: Component {
            Item {
                anchors.fill: parent

                GridView {
                    id: view

                    // When centering, constrain width to prevent extra columns
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: {
                        if (root.centerCells && root.maxCellWidth > 0) {
                            const cols = Math.min(Math.floor((parent.width + root.spacing) / (root.maxCellWidth + root.spacing)), Math.max(1, root.modelCount));
                            return cols * (root.cellWidth + root.spacing);
                        }
                        return parent.width;
                    }
                    clip: true

                    model: root.model

                    cellWidth: root.cellWidth + root.spacing
                    cellHeight: root._effectiveCellHeight + root.spacing

                    delegate: Item {
                        required property var modelData
                        required property int index

                        width: root.cellWidth
                        height: root._effectiveCellHeight

                        Loader {
                            id: loader
                            anchors.fill: parent
                            sourceComponent: root.cellContent

                            onLoaded: {
                                if (item) {
                                    if (item.hasOwnProperty("modelData")) {
                                        item.modelData = Qt.binding(() => parent.modelData);
                                    }
                                    item.anchors.fill = loader;
                                }
                            }
                        }
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
            property real measuredHeight: 0
            property bool loaded: false

            Loader {
                id: probeLoader

                sourceComponent: root.cellContent

                onLoaded: {
                    Qt.callLater(() => {
                        if (probeLoader.item) {
                            if (probeLoader.item.hasOwnProperty("modelData")) {
                                probeLoader.item.modelData = Qt.binding(() => probe.modelData);
                            }
                            probeLoader.item.anchors.fill = probeLoader;
                            probe.measuredWidth = root._getMeasureWidth(probeLoader.item);
                            probe.measuredHeight = root._getMeasureHeight(probeLoader.item);
                        } else {
                            // Component failed to load - mark as loaded anyway to avoid blocking
                            probe.measuredWidth = 0;
                            probe.measuredHeight = 0;
                        }
                        probe.loaded = true;
                        root._scheduleRecalc();
                    });
                }
            }

            Connections {
                target: probeLoader.item
                ignoreUnknownSignals: true

                function onImplicitWidthChanged() {
                    probe.measuredWidth = root._getMeasureWidth(probeLoader.item);
                    root._scheduleRecalc();
                }

                function onImplicitHeightChanged() {
                    probe.measuredHeight = root._getMeasureHeight(probeLoader.item);
                    root._scheduleRecalc();
                }

                function onGridMeasureWidthChanged() {
                    probe.measuredWidth = root._getMeasureWidth(probeLoader.item);
                    root._scheduleRecalc();
                }

                function onGridMeasureHeightChanged() {
                    probe.measuredHeight = root._getMeasureHeight(probeLoader.item);
                    root._scheduleRecalc();
                }

                function onMeasureWidthChanged() {
                    probe.measuredWidth = root._getMeasureWidth(probeLoader.item);
                    root._scheduleRecalc();
                }

                function onMeasureHeightChanged() {
                    probe.measuredHeight = root._getMeasureHeight(probeLoader.item);
                    root._scheduleRecalc();
                }
            }
        }

        onObjectAdded: root._scheduleRecalc()
        onObjectRemoved: root._scheduleRecalc()
    }
}