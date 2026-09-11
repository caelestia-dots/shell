pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components.containers
import qs.components.controls

// Narrows the search results to one page. Built from the pages that have
// matches rather than a fixed list, so it follows the index and the language.
StyledFlickable {
    id: root

    // Groups as NavLocations builds them: { pageIdx, page, ... }
    required property var groups
    // Selected page, -1 for all
    required property int current

    signal selected(pageIdx: int)

    implicitHeight: chips.implicitHeight
    contentWidth: chips.implicitWidth
    flickableDirection: Flickable.HorizontalFlick
    clip: true

    Row {
        id: chips

        spacing: Tokens.spacing.small

        FilterChip {
            text: Tr.tr("All")
            checked: root.current === -1
            onClicked: root.selected(-1)
        }

        Repeater {
            model: ScriptModel {
                objectProp: "pageIdx"
                values: root.groups
            }

            FilterChip {
                required property var modelData

                text: modelData.page
                checked: root.current === modelData.pageIdx
                onClicked: root.selected(modelData.pageIdx)
            }
        }
    }

    // Driven through `checked` only (no isToggle), so a click on the selected
    // chip can't flip its look out of sync with the filter.
    component FilterChip: TextButton {
        type: TextButton.Tonal
        isRound: true
        checkedRadius: implicitHeight / 2 * Math.min(1, Tokens.rounding.scale)
        font: Tokens.font.label.large
        horizontalPadding: Tokens.padding.medium
        verticalPadding: Tokens.padding.small
    }
}
