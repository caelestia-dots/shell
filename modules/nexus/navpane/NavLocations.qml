pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services
import qs.modules.nexus

VerticalFadeFlickable {
    id: root

    required property NexusState nState

    readonly property string search: nState.searchText
    readonly property bool searching: search.length > 0
    readonly property var results: {
        if (!searching)
            return [];
        const all = SettingsSearcher.query(search);
        // The ethernet section hides itself when no ethernet device is available
        // (e.g. the cable is unplugged), so drop its settings from the results
        // too, otherwise the search would link to a page that isn't reachable.
        if (Nmcli.hasAvailableEthernet)
            return all;
        return all.filter(e => !e.anchor.startsWith("ethernet-"));
    }
    // Results grouped by their top-level page, so the list can show one heading
    // per page with the matching settings joined underneath it (like the
    // Android settings search). Each group: { page, entries: [...] }.
    readonly property var groups: {
        const out = [];
        const byPage = ({});
        for (const e of results) {
            const key = e.pageIdx;
            if (byPage[key] === undefined) {
                byPage[key] = {
                    "page": e.crumbLabels[0],
                    "icon": e.crumbIcons[0],
                    "entries": []
                };
                out.push(byPage[key]);
            }
            byPage[key].entries.push(e);
        }
        return out;
    }

    topMargin: Tokens.padding.large
    bottomMargin: Tokens.padding.large
    contentHeight: content.implicitHeight

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

        ListView {
            id: resultList

            // Grouped results: the model is one entry per top-level page, and
            // each delegate renders that page's heading plus the matching
            // settings joined into a single rounded card (first/last rounded,
            // middles square, thin dividers between them), like the Android
            // settings search. A ScriptModel diffs the groups so only changed
            // ones animate. Scrolling is delegated to the outer flickable.
            Layout.fillWidth: true
            implicitHeight: contentHeight
            interactive: false
            cacheBuffer: 10000
            spacing: Tokens.spacing.extraLargeIncreased

            model: ScriptModel {
                values: root.groups
            }

            add: Transition {
                Anim {
                    type: Anim.DefaultEffects
                    property: "opacity"
                    from: 0
                    to: 1
                }
            }

            remove: Transition {
                Anim {
                    type: Anim.DefaultEffects
                    property: "opacity"
                    from: 1
                    to: 0
                }
            }

            displaced: Transition {
                Anim {
                    type: Anim.StandardSmall
                    property: "y"
                }
                Anim {
                    type: Anim.DefaultEffects
                    property: "opacity"
                    to: 1
                }
            }

            addDisplaced: Transition {
                Anim {
                    type: Anim.StandardSmall
                    property: "y"
                }
                Anim {
                    type: Anim.DefaultEffects
                    property: "opacity"
                    to: 1
                }
            }

            delegate: ColumnLayout {
                id: group

                required property var modelData
                required property int index

                width: resultList.width
                spacing: Tokens.spacing.small

                // Group heading: the top-level page name, shown once.
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: Tokens.padding.small
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        text: group.modelData.icon
                        color: Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.small
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: group.modelData.page
                        color: Colours.palette.m3primary
                        font: Tokens.font.label.large
                        elide: Text.ElideRight
                    }
                }

                // The matching settings, joined into one card.
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Repeater {
                        model: group.modelData.entries

                        StyledRect {
                            id: result

                            required property var modelData
                            required property int index

                            readonly property bool isFirst: index === 0
                            readonly property bool isLast: index === group.modelData.entries.length - 1

                            Layout.fillWidth: true
                            implicitHeight: {
                                const h = resultLayout.implicitHeight + resultLayout.anchors.margins * 2;
                                return h % 2 === 0 ? h : h + 1;
                            }
                            // Joined card: round only the outer corners so the
                            // rows read as one block (square where they meet).
                            topLeftRadius: isFirst ? Tokens.rounding.large : 0
                            topRightRadius: isFirst ? Tokens.rounding.large : 0
                            bottomLeftRadius: isLast ? Tokens.rounding.large : 0
                            bottomRightRadius: isLast ? Tokens.rounding.large : 0
                            color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)

                            StateLayer {
                                anchors.fill: parent
                                radius: 0

                                onClicked: {
                                    // Ethernet detail settings need a selected interface
                                    // to show the right device; a search deep-link has
                                    // none, so point it at the connected (or first) one.
                                    if (result.modelData.anchor.startsWith("ethernet-")) {
                                        const active = Nmcli.activeEthernet ?? Nmcli.ethernetDevices[0] ?? null;
                                        if (active)
                                            root.nState.selectedEthernetInterface = active.iface;
                                    }
                                    root.nState.jumpToSetting(result.modelData.pageIdx, result.modelData.subPath, result.modelData.anchor);
                                }
                            }

                            // Thin divider between joined rows (not under the last one).
                            StyledRect {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: Tokens.padding.large
                                anchors.rightMargin: Tokens.padding.large
                                implicitHeight: 1
                                visible: !result.isLast
                                color: Colours.palette.m3outlineVariant
                            }

                            ColumnLayout {
                                id: resultLayout

                                anchors.fill: parent
                                anchors.margins: Tokens.padding.large
                                spacing: Tokens.spacing.small / 2

                                // Location line: deepest icon + "Section > sub", faint.
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
                                    text: result.modelData.title
                                    color: Colours.palette.m3onSurface
                                    font: Tokens.font.body.medium
                                    elide: Text.ElideRight
                                }

                                // Optional description, faintest and smallest.
                                StyledText {
                                    Layout.fillWidth: true
                                    visible: result.modelData.subtext.length > 0
                                    text: result.modelData.subtext
                                    color: Colours.palette.m3outline
                                    font: Tokens.font.label.small
                                    elide: Text.ElideRight
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

            text: qsTr("No matching settings")
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
