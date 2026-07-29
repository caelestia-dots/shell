pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
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

    topMargin: Tokens.padding.large
    bottomMargin: Tokens.padding.large
    contentHeight: content.implicitHeight

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
                    objectProp: "pageIdx"
                    values: root.groups
                }

                ColumnLayout {
                    id: group

                    required property var modelData
                    required property int index

                    width: resultList.width
                    spacing: Tokens.spacing.small

                    StyledText {
                        Layout.fillWidth: true
                        Layout.leftMargin: Tokens.padding.medium
                        text: group.modelData.page
                        color: Colours.palette.m3secondary
                        font: Tokens.font.label.large
                        elide: Text.ElideRight
                    }

                    Column {
                        id: cardList

                        Layout.fillWidth: true
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
                                values: group.modelData.entries
                            }

                            StyledRect {
                                id: result

                                required property var modelData
                                required property int index

                                readonly property bool isFirst: index === 0
                                readonly property bool isLast: index === group.modelData.entries.length - 1

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
                                    anchors.rightMargin: result.modelData.togglePath ? toggle.width + Tokens.padding.large * 2 : Tokens.padding.large
                                    spacing: Tokens.spacing.medium

                                    // The setting's own icon, baked into the
                                    // index per anchor.
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
                                            color: Colours.palette.m3onSurface
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

                                StyledSwitch {
                                    id: toggle

                                    anchors.right: parent.right
                                    anchors.rightMargin: Tokens.padding.large
                                    anchors.verticalCenter: parent.verticalCenter
                                    z: 2
                                    visible: result.modelData.togglePath
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
