pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.modules.nexus

VerticalFadeFlickable {
    id: root

    required property NexusState nState
    // Whether the search field has focus, so the keyboard selection only shows
    // while the keys that move it actually reach the field.
    property bool keyboardActive
    // Page the results are narrowed to, -1 for all of them.
    property int pageFilter: -1
    property list<int> collapsedPages
    property string selectedAnchor
    // Only a key press moves the view along with the selection. When a new
    // query or filter changes it, the rows haven't been laid out again yet and
    // still report their old positions.
    property bool followSelection

    readonly property string search: nState.searchText
    readonly property bool searching: search.length > 0
    readonly property var results: {
        if (!searching)
            return [];
        // Sections hide themselves when what they configure isn't available -
        // the ethernet rows when no cable is plugged in, the add-network flow
        // when Wi-Fi is off. Their settings have to drop out of the results
        // as well, or search links to a page that can't be opened.
        return SettingsSearcher.query(search).filter(e => {
            if (!Nmcli.hasAvailableEthernet && e.anchor.startsWith("ethernet-"))
                return false;
            if (!Nmcli.wifiEnabled && (e.anchor.startsWith("add-network-") || e.anchor === "network-add-network"))
                return false;
            return true;
        });
    }
    // Results grouped by their top-level page, so the list can show one heading
    // per page with the matching settings joined underneath it (like the
    // Android settings search). Each group: { pageIdx, page, entries: [...] }.
    readonly property var allGroups: {
        const out = [];
        const byPage = ({});
        for (const e of results) {
            const key = e.pageIdx;
            if (byPage[key] === undefined) {
                byPage[key] = {
                    "pageIdx": e.pageIdx,
                    "page": e.crumbLabels[0],
                    "entries": []
                };
                out.push(byPage[key]);
            }
            byPage[key].entries.push(e);
        }
        return out;
    }
    // A filter whose page no longer has matches falls back to showing all.
    readonly property int activeFilter: allGroups.some(g => g.pageIdx === pageFilter) ? pageFilter : -1
    readonly property var groups: activeFilter < 0 ? allGroups : allGroups.filter(g => g.pageIdx === activeFilter)
    readonly property int resultCount: groups.reduce((n, g) => n + g.entries.length, 0)
    // The group delegates are keyed by page and read their data from here. A
    // ScriptModel given the group objects themselves moves a reordered group's
    // row without replacing its value, so it would keep showing the previous
    // query's results.
    readonly property var groupsByPage: {
        const out = {};
        for (const g of groups)
            out[g.pageIdx] = g;
        return out;
    }
    // What the arrow keys move through: the results left in expanded groups.
    readonly property var navigable: groups.filter(g => !collapsedPages.includes(g.pageIdx)).reduce((all, g) => all.concat(g.entries), [])
    // The selection falls back to the top result, which the query ranks best.
    readonly property string currentAnchor: navigable.some(e => e.anchor === selectedAnchor) ? selectedAnchor : navigable[0]?.anchor ?? ""

    function openEntry(entry: var): void {
        // Ethernet detail settings need a selected interface to show the right
        // device; a search deep-link has none, so point it at the connected (or
        // first) one.
        if (entry.anchor.startsWith("ethernet-")) {
            const active = Nmcli.activeEthernet ?? Nmcli.ethernetDevices[0] ?? null;
            if (active)
                nState.selectedEthernetInterface = active.iface;
        }
        nState.jumpToSetting(entry.pageIdx, entry.subPath, entry.anchor);
    }

    function moveSelection(delta: int): void {
        const i = navigable.findIndex(e => e.anchor === currentAnchor);
        const next = navigable[Math.max(0, Math.min(navigable.length - 1, i + delta))];
        if (!next)
            return;
        followSelection = true;
        selectedAnchor = next.anchor;
        followSelection = false;
    }

    function openSelection(): void {
        const entry = navigable.find(e => e.anchor === currentAnchor);
        if (entry)
            openEntry(entry);
    }

    // Steps through the filter tabs, in the order they're shown: all, then the
    // pages with matches.
    function moveFilter(delta: int): void {
        const pages = [-1].concat(allGroups.map(g => g.pageIdx));
        if (pages.length < 3)
            return;
        const i = pages.indexOf(activeFilter);
        pageFilter = pages[Math.max(0, Math.min(pages.length - 1, i + delta))];
    }

    function toggleCollapsed(pageIdx: int): void {
        collapsedPages = collapsedPages.includes(pageIdx) ? collapsedPages.filter(i => i !== pageIdx) : collapsedPages.concat([pageIdx]);
    }

    // A different set of results starts from the top, like the launcher.
    function scrollToTop(): void {
        scrollAnim.stop();
        contentY = -topMargin;
    }

    // Scrolls just far enough to bring a result out of the edge fades.
    function ensureVisible(item: Item): void {
        const y = item.mapToItem(contentItem, 0, 0).y;
        const margin = height * fadeAmount / 2;
        let target = contentY;
        if (y < contentY + margin)
            target = y - margin;
        else if (y + item.height > contentY + height - margin)
            target = y + item.height - height + margin;
        target = Math.max(-topMargin, Math.min(target, contentHeight - height + bottomMargin));
        if (target === contentY)
            return;
        scrollAnim.to = target;
        scrollAnim.restart();
    }

    topMargin: Tokens.padding.large
    bottomMargin: Tokens.padding.large
    contentHeight: content.implicitHeight

    // A new query starts from its top result
    onSearchChanged: {
        selectedAnchor = "";
        scrollToTop();
    }
    onActiveFilterChanged: scrollToTop()
    onSearchingChanged: {
        if (!searching) {
            pageFilter = -1;
            collapsedPages = [];
        }
    }

    StyledScrollBar.vertical: StyledScrollBar {
        flickable: root
    }

    Anim {
        id: scrollAnim

        target: root
        property: "contentY"
        type: Anim.FastSpatial
    }

    TapHandler {
        onTapped: root.focus = true
    }

    ColumnLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Tokens.spacing.extraSmall

        Repeater {
            id: list

            model: root.searching ? [] : PageRegistry.pages

            StyledRect {
                id: item

                required property var modelData
                required property int index

                readonly property bool isCurrentPage: index === root.nState.currentPageIdx
                readonly property bool isCategoryStart: index === 0 || PageRegistry.pages[index - 1]?.category !== modelData.category
                readonly property bool isCategoryEnd: index === list.model.length - 1 || PageRegistry.pages[index + 1]?.category !== modelData.category

                Layout.fillWidth: true
                Layout.topMargin: index !== 0 && isCategoryStart ? Tokens.spacing.medium : 0
                implicitHeight: {
                    const h = layout.implicitHeight + layout.anchors.margins * 2;
                    return h % 2 === 0 ? h : h + 1;
                }

                color: isCurrentPage ? Colours.palette.m3secondaryContainer : Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)

                topLeftRadius: stateLayer.pressed ? Tokens.rounding.medium : isCurrentPage ? Tokens.rounding.extraLargeIncreased : isCategoryStart ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
                topRightRadius: stateLayer.pressed ? Tokens.rounding.medium : isCurrentPage ? Tokens.rounding.extraLargeIncreased : isCategoryStart ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
                bottomLeftRadius: stateLayer.pressed ? Tokens.rounding.medium : isCurrentPage ? Tokens.rounding.extraLargeIncreased : isCategoryEnd ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
                bottomRightRadius: stateLayer.pressed ? Tokens.rounding.medium : isCurrentPage ? Tokens.rounding.extraLargeIncreased : isCategoryEnd ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall

                RadiusBehavior on topLeftRadius {}
                RadiusBehavior on topRightRadius {}
                RadiusBehavior on bottomLeftRadius {}
                RadiusBehavior on bottomRightRadius {}

                StateLayer {
                    id: stateLayer

                    anchors.fill: parent
                    topLeftRadius: parent.topLeftRadius
                    topRightRadius: parent.topRightRadius
                    bottomLeftRadius: parent.bottomLeftRadius
                    bottomRightRadius: parent.bottomRightRadius

                    onClicked: root.nState.currentPageIdx = item.index
                }

                RowLayout {
                    id: layout

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.large
                    spacing: Tokens.spacing.medium

                    StyledRect {
                        Layout.fillHeight: true
                        Layout.topMargin: -1
                        Layout.bottomMargin: -1
                        implicitWidth: height

                        radius: Tokens.rounding.full
                        color: item.isCurrentPage ? Colours.palette.m3primary : Colours.palette.m3secondaryContainer

                        MaterialIcon {
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: 1

                            text: item.modelData.icon
                            color: item.isCurrentPage ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondaryContainer
                            fontStyle: Tokens.font.icon.builders.medium.weight(Font.Medium).build()
                            grade: 25
                            fill: item.modelData.noFill ? 0 : 1
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: item.modelData.label
                            font: Tokens.font.body.medium
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: item.modelData.description
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        Column {
            id: resultList

            Layout.fillWidth: true
            spacing: Tokens.padding.large

            add: Transition {
                Anim {
                    type: Anim.DefaultEffects
                    property: "opacity"
                    from: 0
                    to: 1
                }
            }

            move: Transition {
                Anim {
                    properties: "x,y"
                }

                // A move may interrupt an in-flight add; drive opacity back to 1
                // so the interrupted fade doesn't leave the group half-visible.
                Anim {
                    type: Anim.DefaultEffects
                    property: "opacity"
                    to: 1
                }
            }

            Repeater {
                model: ScriptModel {
                    values: root.groups.map(g => g.pageIdx)
                }

                ColumnLayout {
                    id: group

                    // The page index
                    required property int modelData
                    required property int index

                    // Empty while the group is on its way out
                    readonly property var info: root.groupsByPage[modelData] ?? ({
                            "page": "",
                            "entries": []
                        })
                    readonly property bool collapsed: root.collapsedPages.includes(modelData)

                    width: resultList.width
                    spacing: Tokens.spacing.small

                    // Heading: collapses the group, and shows how many of the
                    // results it holds.
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: heading.implicitHeight + Tokens.padding.small * 2

                        StateLayer {
                            anchors.fill: parent
                            radius: Tokens.rounding.full

                            onClicked: root.toggleCollapsed(group.modelData)
                        }

                        RowLayout {
                            id: heading

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: Tokens.padding.small
                            anchors.rightMargin: Tokens.padding.small
                            spacing: Tokens.spacing.small

                            MaterialIcon {
                                text: "expand_more"
                                color: Colours.palette.m3secondary
                                fontStyle: Tokens.font.icon.small
                                rotation: group.collapsed ? -90 : 0

                                Behavior on rotation {
                                    Anim {
                                        type: Anim.FastSpatial
                                    }
                                }
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: group.info.page
                                color: Colours.palette.m3secondary
                                font: Tokens.font.label.large
                                elide: Text.ElideRight
                            }

                            StyledRect {
                                implicitWidth: Math.max(implicitHeight, count.implicitWidth + Tokens.padding.small * 2)
                                implicitHeight: count.implicitHeight + Tokens.padding.extraSmall * 2
                                radius: Tokens.rounding.full
                                color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)

                                StyledText {
                                    id: count

                                    anchors.centerIn: parent
                                    text: group.info.entries.length
                                    color: Colours.palette.m3outline
                                    font: Tokens.font.label.small
                                }
                            }
                        }
                    }

                    // Clips the cards while the group folds away
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: group.collapsed ? 0 : cardList.implicitHeight
                        clip: true

                        Behavior on implicitHeight {
                            Anim {}
                        }

                        Column {
                            id: cardList

                            anchors.left: parent.left
                            anchors.right: parent.right
                            spacing: 0

                            add: Transition {
                                Anim {
                                    type: Anim.DefaultEffects
                                    property: "opacity"
                                    from: 0
                                    to: 1
                                }
                            }

                            move: Transition {
                                Anim {
                                    properties: "x,y"
                                }

                                Anim {
                                    type: Anim.DefaultEffects
                                    property: "opacity"
                                    to: 1
                                }
                            }

                            Repeater {
                                model: ScriptModel {
                                    objectProp: "anchor"
                                    values: group.info.entries
                                }

                                StyledRect {
                                    id: result

                                    required property var modelData
                                    required property int index

                                    readonly property bool isFirst: index === 0
                                    readonly property bool isLast: index === group.info.entries.length - 1
                                    readonly property bool isCurrent: root.keyboardActive && root.currentAnchor === modelData.anchor

                                    width: cardList.width
                                    implicitHeight: {
                                        const h = resultLayout.implicitHeight + resultLayout.anchors.margins * 2;
                                        return h % 2 === 0 ? h : h + 1;
                                    }
                                    // Joined card: round only the outer corners so the
                                    // rows read as one block (square where they meet),
                                    // matching the page tabs' corner radius.
                                    topLeftRadius: isFirst ? Tokens.rounding.extraLarge : 0
                                    topRightRadius: isFirst ? Tokens.rounding.extraLarge : 0
                                    bottomLeftRadius: isLast ? Tokens.rounding.extraLarge : 0
                                    bottomRightRadius: isLast ? Tokens.rounding.extraLarge : 0
                                    color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)

                                    onIsCurrentChanged: {
                                        if (isCurrent && root.followSelection)
                                            root.ensureVisible(result);
                                    }

                                    StyledRect {
                                        anchors.bottom: parent.bottom
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: Tokens.padding.large
                                        anchors.rightMargin: Tokens.padding.large
                                        implicitHeight: 1
                                        visible: !result.isLast
                                        color: Qt.alpha(Colours.palette.m3outlineVariant, 0.5)
                                    }

                                    RowLayout {
                                        id: resultLayout

                                        anchors.fill: parent
                                        anchors.margins: Tokens.padding.large
                                        // Leave room on the right for the toggle switch.
                                        anchors.rightMargin: result.modelData.isToggle ? toggle.width + Tokens.padding.large * 2 : Tokens.padding.large
                                        spacing: Tokens.spacing.medium

                                        // The setting's own icon, baked into the index
                                        // per anchor.
                                        MaterialIcon {
                                            text: result.modelData.icon
                                            color: Colours.palette.m3onSurfaceVariant
                                            fontStyle: Tokens.font.icon.medium
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: Tokens.spacing.small / 2

                                            // Location line: "Section > sub", faint.
                                            StyledText {
                                                Layout.fillWidth: true
                                                text: {
                                                    const labels = result.modelData.crumbLabels.slice(1);
                                                    const section = result.modelData.section;
                                                    const parts = section && section !== labels[labels.length - 1] ? labels.concat(section) : labels;
                                                    return parts.join("  \u203a  ");
                                                }
                                                visible: text.length > 0
                                                color: Colours.palette.m3onSurfaceVariant
                                                font: Tokens.font.label.small
                                                elide: Text.ElideRight
                                            }

                                            // The setting itself, most prominent.
                                            StyledText {
                                                Layout.fillWidth: true
                                                text: SettingsSearcher.highlight(result.modelData.title, root.search, Colours.palette.m3primary)
                                                // Only pay for rich-text parsing when the
                                                // string actually carries a highlight tag.
                                                textFormat: text.includes("<font") ? Text.StyledText : Text.PlainText
                                                color: result.isCurrent ? Colours.palette.m3primary : Colours.palette.m3onSurface
                                                font: Tokens.font.body.medium
                                                elide: Text.ElideRight
                                            }

                                            // Optional description, faintest and smallest.
                                            StyledText {
                                                Layout.fillWidth: true
                                                visible: result.modelData.subtext.length > 0
                                                text: SettingsSearcher.highlight(result.modelData.subtext, root.search, Colours.palette.m3primary)
                                                // Most subtexts have no match, so skip the
                                                // rich-text parse unless there's a highlight.
                                                textFormat: text.includes("<font") ? Text.StyledText : Text.PlainText
                                                color: Colours.palette.m3outline
                                                font: Tokens.font.label.small
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }

                                    StateLayer {
                                        anchors.fill: parent
                                        z: 1
                                        radius: 0

                                        onClicked: root.openEntry(result.modelData)
                                    }

                                    StyledSwitch {
                                        id: toggle

                                        anchors.right: parent.right
                                        anchors.rightMargin: Tokens.padding.large
                                        anchors.verticalCenter: parent.verticalCenter
                                        z: 2
                                        visible: result.modelData.isToggle
                                        checked: result.modelData.toggleValue
                                        cLayer: 3
                                        // A touch smaller than the in-page switches since
                                        // the result rows are denser.
                                        scale: 0.85
                                        transformOrigin: Item.Right

                                        onToggled: result.modelData.setToggle(checked)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.padding.large
            visible: root.searching && root.results.length === 0

            text: Tr.tr("No matching settings")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.medium
            horizontalAlignment: Text.AlignHCenter
        }
    }

    component RadiusBehavior: Behavior {
        Anim {
            type: Anim.DefaultEffects
        }
    }
}
