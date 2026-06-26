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
    readonly property var results: searching ? SettingsSearcher.query(search) : []

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

            // A ListView fed by a ScriptModel (same approach as the launcher):
            // when the query changes the model diffs the result list, so only
            // entries that actually appear/disappear/move are animated. The
            // rest stay put, which avoids re-animating the whole list on every
            // keystroke. Scrolling is delegated to the outer flickable.
            Layout.fillWidth: true
            implicitHeight: contentHeight
            interactive: false
            spacing: Tokens.spacing.extraSmall

            model: ScriptModel {
                values: root.results
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

            delegate: StyledRect {
                id: result

                required property var modelData
                required property int index

                width: resultList.width
                implicitHeight: {
                    const h = resultLayout.implicitHeight + resultLayout.anchors.margins * 2;
                    return h % 2 === 0 ? h : h + 1;
                }

                radius: Tokens.rounding.medium
                color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)

                StateLayer {
                    anchors.fill: parent
                    radius: parent.radius

                    onClicked: root.nState.jumpToSetting(result.modelData.pageIdx, result.modelData.subPath, result.modelData.anchor)
                }

                ColumnLayout {
                    id: resultLayout

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.large
                    spacing: Tokens.spacing.small / 2

                    // Location line: page icon + "Page \u203a Section", faint.
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small

                        MaterialIcon {
                            Layout.alignment: Qt.AlignVCenter
                            text: result.modelData.crumbIcons[result.modelData.crumbIcons.length - 1]
                            color: Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.small
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: {
                                const labels = result.modelData.crumbLabels;
                                const section = result.modelData.section;
                                // Skip the section if it just repeats the last
                                // breadcrumb label (e.g. page and section share a name).
                                const parts = section && section !== labels[labels.length - 1] ? labels.concat(section) : labels;
                                return parts.join("  \u203a  ");
                            }
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                        }
                    }

                    // The setting itself, most prominent.
                    StyledText {
                        Layout.fillWidth: true
                        Layout.topMargin: Tokens.spacing.small / 2
                        text: result.modelData.title
                        color: Colours.palette.m3primary
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
