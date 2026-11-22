pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.hallownest
import qs.services
import qs.modules.nexus

ColumnLayout {
    id: root

    required property string title
    required property NexusState nState
    property bool isSubPage
    readonly property int cappedWidth: Math.min(Tokens.sizes.nexus.maxContentWidth, width)
    readonly property alias flickable: flickable

    default property Item contentChild

    spacing: Tokens.spacing.extraLargeIncreased

    MouseArea { // Prevent clicks from reaching flickable
        z: 1
        Layout.fillWidth: true
        implicitWidth: headerCol.implicitWidth
        implicitHeight: headerCol.implicitHeight - Layout.bottomMargin
        Layout.bottomMargin: -flickable.topMargin // Extra height to block clicks on flickable top margin
        onClicked: focus = true

        ColumnLayout {
            id: headerCol

            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Tokens.spacing.small

            RowLayout {
                id: header

                Layout.fillWidth: true
                spacing: Tokens.spacing.largeIncreased

                Loader {
                    visible: active
                    active: root.isSubPage
                    asynchronous: true
                    sourceComponent: IconButton {
                        icon: "arrow_back"
                        font: Tokens.font.icon.medium
                        type: IconButton.Tonal
                        isRound: true
                        inactiveColour: Hallownest.button
                        inactiveOnColour: Hallownest.subtext
                        onClicked: root.nState.closeSubPage()
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.title
                    color: Hallownest.soul
                    font.family: Hallownest.serif
                    font.pointSize: Tokens.font.title.large.pointSize + 2
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }
            }

            HkDivider {
                Layout.fillWidth: true
                Layout.maximumWidth: root.cappedWidth
                Layout.alignment: Qt.AlignHCenter
                lineRatio: 0.46
            }
        }
    }

    VerticalFadeFlickable {
        id: flickable

        Layout.fillWidth: true
        Layout.fillHeight: true

        Layout.topMargin: -topMargin
        topMargin: Tokens.padding.large
        bottomMargin: Tokens.padding.extraLarge

        contentHeight: root.contentChild?.implicitHeight ?? 0
        contentItem.children: [root.contentChild]

        TapHandler {
            onTapped: flickable.focus = true
        }
    }
}
