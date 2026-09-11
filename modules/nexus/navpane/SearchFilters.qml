pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.services

// Narrows the search results to one page. Built from the pages that have
// matches rather than a fixed list, so it follows the index and the language.
// Styled after the dashboard tabs.
Item {
    id: root

    // Groups as NavLocations builds them: { pageIdx, page, ... }
    required property var groups
    // Selected page, -1 for all
    required property int current

    readonly property var tabs: [
        {
            "pageIdx": -1,
            "page": Tr.trCtx("All", "search filter")
        }
    ].concat(groups)
    // Tabs are keyed by page and read their label from here; see NavLocations'
    // groupsByPage for why the model only carries the key.
    readonly property var labels: {
        const out = {};
        for (const t of tabs)
            out[t.pageIdx] = t.page;
        return out;
    }
    // Set by the selected tab itself. Looking it up by position isn't safe: the
    // model removes and moves rows in separate steps, and a lookup made between
    // them lands on the wrong tab with nothing to correct it after the move.
    property Item currentTab

    signal selected(pageIdx: int)

    implicitHeight: flick.implicitHeight + separator.implicitHeight

    StyledFlickable {
        id: flick

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top

        implicitHeight: tabRow.implicitHeight + indicator.implicitHeight
        contentWidth: tabRow.implicitWidth
        flickableDirection: Flickable.HorizontalFlick
        clip: true

        Row {
            id: tabRow

            Repeater {
                model: ScriptModel {
                    values: root.tabs.map(t => t.pageIdx)
                }

                Tab {}
            }
        }

        Item {
            id: indicator

            anchors.top: tabRow.bottom

            x: root.currentTab?.x ?? 0
            implicitWidth: root.currentTab?.width ?? 0
            implicitHeight: 3
            clip: true

            // Twice the height and clipped, so only the top corners are round
            StyledRect {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                implicitHeight: parent.implicitHeight * 2

                color: Colours.palette.m3primary
                radius: Tokens.rounding.full
            }

            Behavior on x {
                Anim {}
            }

            Behavior on implicitWidth {
                Anim {}
            }
        }
    }

    StyledRect {
        id: separator

        anchors.top: flick.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        implicitHeight: 1
        color: Colours.palette.m3outlineVariant
    }

    component Tab: Item {
        id: tab

        // The page index, -1 for all
        required property int modelData

        readonly property bool isCurrent: modelData === root.current

        onIsCurrentChanged: {
            if (isCurrent)
                root.currentTab = tab;
        }
        Component.onCompleted: {
            if (isCurrent)
                root.currentTab = tab;
        }
        Component.onDestruction: {
            if (root.currentTab === tab)
                root.currentTab = null;
        }

        implicitWidth: label.implicitWidth + Tokens.padding.large * 2
        implicitHeight: label.implicitHeight + Tokens.padding.medium * 2

        StateLayer {
            radius: Tokens.rounding.medium

            onClicked: root.selected(tab.modelData)
        }

        StyledText {
            id: label

            anchors.centerIn: parent
            text: root.labels[tab.modelData] ?? ""
            color: tab.isCurrent ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
        }
    }
}
