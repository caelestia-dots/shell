pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components.live
import qs.services
import qs.config

// Responsive grid layout for PageSection content
// More flexible than KeybindingSection - works with any content
GridLayout {
    id: root

    // Grid configuration
    property int targetColumns: 2
    property int minColumns: 1
    property int maxColumns: 3
    property real responsiveBreakpoint: 800
    
    // Responsive column calculation
    columns: {
        if (parent && parent.width < root.responsiveBreakpoint) {
            return root.minColumns
        }
        return Math.min(root.targetColumns, root.maxColumns)
    }
    
    // Spacing
    columnSpacing: Appearance.spacing.large
    rowSpacing: Appearance.spacing.large
    
    // Make all cells in a row match the height of the tallest cell
    property bool uniformCellHeight: true
    
    Layout.fillWidth: true
    
    // Apply fillHeight to all children if uniformCellHeight is enabled
    Component.onCompleted: {
        if (uniformCellHeight) {
            for (let i = 0; i < children.length; i++) {
                if (children[i].Layout) {
                    children[i].Layout.fillHeight = true
                }
            }
        }
    }
}
