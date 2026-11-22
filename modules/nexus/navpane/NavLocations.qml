pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services
import qs.modules.nexus

VerticalFadeFlickable {
    id: root

    required property NexusState nState

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

            model: PageRegistry.pages

            StyledRect {
                id: item

                required property var modelData
                required property int index

                readonly property bool isCurrentPage: index === root.nState.currentPageIdx
                readonly property bool isCategoryStart: index === 0 || PageRegistry.pages[index - 1].category !== modelData.category
                readonly property bool isCategoryEnd: index === list.model.length - 1 || PageRegistry.pages[index + 1].category !== modelData.category

                Layout.fillWidth: true
                Layout.topMargin: index !== 0 && isCategoryStart ? Tokens.spacing.medium : 0
                implicitHeight: {
                    const h = layout.implicitHeight + layout.anchors.margins * 2;
                    return h % 2 === 0 ? h : h + 1;
                }

                color: isCurrentPage ? Qt.alpha(Hallownest.soul, 0.1) : Hallownest.card
                border.width: 1
                border.color: isCurrentPage ? Qt.alpha(Hallownest.soul, 0.38) : Hallownest.border

                topLeftRadius: stateLayer.pressed ? 8 : isCurrentPage ? 12 : isCategoryStart ? 12 : 4
                topRightRadius: stateLayer.pressed ? 8 : isCurrentPage ? 12 : isCategoryStart ? 12 : 4
                bottomLeftRadius: stateLayer.pressed ? 8 : isCurrentPage ? 12 : isCategoryEnd ? 12 : 4
                bottomRightRadius: stateLayer.pressed ? 8 : isCurrentPage ? 12 : isCategoryEnd ? 12 : 4

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

                Item {
                    anchors.left: parent.left
                    anchors.leftMargin: 5
                    anchors.verticalCenter: parent.verticalCenter
                    width: 10
                    height: 10
                    opacity: item.isCurrentPage ? 1 : 0
                    layer.enabled: opacity > 0
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Hallownest.soul
                        shadowBlur: 0.7
                        shadowHorizontalOffset: 0
                        shadowVerticalOffset: 0
                        blurMax: 8
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 5
                        height: 5
                        rotation: 45
                        color: Hallownest.soul
                    }

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }

                RowLayout {
                    id: layout

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.large
                    anchors.leftMargin: Tokens.padding.large + 6
                    spacing: Tokens.spacing.medium

                    StyledRect {
                        Layout.fillHeight: true
                        Layout.topMargin: -1
                        Layout.bottomMargin: -1
                        implicitWidth: height

                        radius: 8
                        color: item.isCurrentPage ? Qt.alpha(Hallownest.soul, 0.14) : Hallownest.button
                        border.width: 1
                        border.color: item.isCurrentPage ? Qt.alpha(Hallownest.soul, 0.5) : Hallownest.border

                        MaterialIcon {
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: 1

                            text: item.modelData.icon
                            color: item.isCurrentPage ? Hallownest.soul : Hallownest.subtext
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
                            color: item.isCurrentPage ? Hallownest.soul : Hallownest.text
                            font: Tokens.font.body.medium
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: item.modelData.description
                            color: Hallownest.subtext
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    component RadiusBehavior: Behavior {
        Anim {
            type: Anim.DefaultEffects
        }
    }
}
