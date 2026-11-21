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
    property bool keyboardActive
    property string selectedAnchor
    // Only set for key presses, after a new query the rows still report their old positions
    property bool followSelection

    readonly property var screenConfig: Config.screen ? GlobalConfig.forScreen(Config.screen) : GlobalConfig

    readonly property string search: nState.searchText
    readonly property bool searching: search.length > 0
    readonly property var results: {
        if (!searching)
            return [];
        return SettingsSearcher.query(search);
    }
    readonly property var groups: {
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
    readonly property int resultCount: groups.reduce((n, g) => n + g.entries.length, 0)
    // Delegates are keyed by page and read from here, a ScriptModel of the groups themselves
    // keeps a reordered group's old value and shows the previous query's results
    readonly property var groupsByPage: {
        const out = {};
        for (const g of groups)
            out[g.pageIdx] = g;
        return out;
    }
    readonly property var navigable: groups.reduce((all, g) => all.concat(g.entries), [])
    readonly property string currentAnchor: navigable.some(e => e.anchor === selectedAnchor) ? selectedAnchor : navigable[0]?.anchor ?? ""

    // Global-only options must be read from GlobalConfig, reading them from a screen's layer logs a warning
    function configValue(path: string, global: bool): bool {
        let obj = global ? GlobalConfig : screenConfig;
        for (const part of path.split(".")) {
            if (obj === undefined || obj === null)
                return false;
            obj = obj[part];
        }
        return obj ?? false;
    }

    function openEntry(entry: var): void {
        // The ethernet detail page shows the selected interface, which a deep link doesn't set
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

    function scrollToTop(): void {
        scrollAnim.stop();
        contentY = -topMargin;
    }

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

    onSearchChanged: {
        selectedAnchor = "";
        scrollToTop();
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

            model: PageRegistry.pages

            StyledRect {
                id: item

                required property var modelData
                required property int index

                readonly property bool isCurrentPage: index === root.nState.currentPageIdx
                readonly property bool isCategoryStart: index === 0 || PageRegistry.pages[index - 1]?.category !== modelData.category
                readonly property bool isCategoryEnd: index === list.model.length - 1 || PageRegistry.pages[index + 1]?.category !== modelData.category

                visible: !root.searching
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
            spacing: Tokens.padding.medium

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

                // A move can interrupt an add's fade, which would leave the group half visible
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

                    required property int modelData
                    required property int index

                    // Gone from groupsByPage while the group is being removed
                    readonly property var info: root.groupsByPage[modelData] ?? ({
                            "page": "",
                            "entries": []
                        })

                    width: resultList.width
                    spacing: Tokens.spacing.small

                    StyledText {
                        Layout.fillWidth: true
                        Layout.leftMargin: Tokens.padding.medium
                        text: group.info.page
                        color: Colours.palette.m3secondary
                        font: Tokens.font.label.large
                        elide: Text.ElideRight
                    }

                    Column {
                        id: cardList

                        Layout.fillWidth: true
                        spacing: Tokens.spacing.extraSmall / 2

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
                                topLeftRadius: isFirst ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
                                topRightRadius: isFirst ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
                                bottomLeftRadius: isLast ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
                                bottomRightRadius: isLast ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
                                color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)

                                onIsCurrentChanged: {
                                    if (isCurrent && root.followSelection)
                                        root.ensureVisible(result);
                                }

                                RowLayout {
                                    id: resultLayout

                                    anchors.fill: parent
                                    anchors.margins: Tokens.padding.medium
                                    anchors.rightMargin: result.modelData.isToggle ? toggle.width + anchors.margins * 2 : anchors.margins
                                    spacing: Tokens.spacing.small

                                    StyledRect {
                                        implicitWidth: implicitHeight
                                        implicitHeight: resultIcon.implicitHeight + Tokens.padding.small * 2
                                        radius: Tokens.rounding.full
                                        color: result.isCurrent ? Colours.palette.m3primary : Colours.palette.m3secondaryContainer

                                        MaterialIcon {
                                            id: resultIcon

                                            anchors.centerIn: parent
                                            text: result.modelData.icon
                                            color: result.isCurrent ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondaryContainer
                                            fontStyle: Tokens.font.icon.small
                                            fill: result.isCurrent ? 1 : 0

                                            Behavior on fill {
                                                Anim {
                                                    type: Anim.DefaultEffects
                                                }
                                            }
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: {
                                                const labels = result.modelData.crumbLabels.slice(1);
                                                const section = result.modelData.section;
                                                const parts = section && section !== labels[labels.length - 1] ? labels.concat(section) : labels;
                                                return parts.join("  \u203a  ");
                                            }
                                            visible: text.length > 0
                                            color: Colours.palette.m3outline
                                            font: Tokens.font.label.small
                                            elide: Text.ElideRight
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: SettingsSearcher.highlight(result.modelData.title, root.search, Colours.palette.m3primary)
                                            // Must stay PlainText without a highlight, unhighlighted text isn't escaped
                                            textFormat: text.includes("<font") ? Text.StyledText : Text.PlainText
                                            color: result.isCurrent ? Colours.palette.m3primary : Colours.palette.m3onSurface
                                            font: Tokens.font.body.medium
                                            elide: Text.ElideRight
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            visible: result.modelData.subtext.length > 0
                                            text: SettingsSearcher.highlight(result.modelData.subtext, root.search, Colours.palette.m3primary)
                                            // Must stay PlainText without a highlight, unhighlighted text isn't escaped
                                            textFormat: text.includes("<font") ? Text.StyledText : Text.PlainText
                                            color: Colours.palette.m3outline
                                            font: Tokens.font.label.small
                                            elide: Text.ElideRight
                                        }
                                    }
                                }

                                // The StateLayer is heavy, so it's only created on first hover. Taps before that go to the TapHandler
                                HoverHandler {
                                    cursorShape: Qt.PointingHandCursor
                                    onHoveredChanged: {
                                        if (hovered)
                                            stateLoader.active = true;
                                    }
                                }

                                TapHandler {
                                    enabled: !stateLoader.item
                                    onTapped: root.openEntry(result.modelData)
                                }

                                Loader {
                                    id: stateLoader

                                    anchors.fill: parent
                                    z: 1
                                    active: false

                                    sourceComponent: StateLayer {
                                        topLeftRadius: result.topLeftRadius
                                        topRightRadius: result.topRightRadius
                                        bottomLeftRadius: result.bottomLeftRadius
                                        bottomRightRadius: result.bottomRightRadius

                                        onClicked: root.openEntry(result.modelData)
                                    }
                                }

                                Loader {
                                    id: toggle

                                    anchors.right: parent.right
                                    anchors.rightMargin: Tokens.padding.medium
                                    anchors.verticalCenter: parent.verticalCenter
                                    z: 2
                                    active: result.modelData.isToggle
                                    visible: active

                                    sourceComponent: StyledSwitch {
                                        checked: root.configValue(result.modelData.togglePath, result.modelData.toggleGlobal)
                                        cLayer: 3
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
