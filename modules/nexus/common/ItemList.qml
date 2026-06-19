pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

ConnectedRect {
    id: root

    property bool showList
    property string placeholderIcon
    property string placeholderText
    property int extraHeight
    // Number of columns. 1 (default) keeps the original single-column ListView
    // so existing usages are unaffected. >1 switches to a grid.
    property int columns: 1
    // Fixed row height used in grid (multi-column) mode.
    property int gridCellHeight: Math.round(Tokens.font.body.medium.pointSize * 2 + Tokens.font.label.small.pointSize * 2 + Tokens.padding.medium * 2)

    property alias model: list.model
    property alias delegate: list.delegate
    readonly property alias list: list

    readonly property int contentCount: root.columns > 1 ? grid.count : list.count
    readonly property real activeContentHeight: root.columns > 1 ? grid.contentHeight : list.contentHeight

    Layout.fillWidth: true
    implicitHeight: (showList && contentCount > 0 ? activeContentHeight : placeholder.implicitHeight + Tokens.padding.extraLarge * 2) + extraHeight
    color: Colours.tPalette.m3surfaceContainer
    clip: true

    Behavior on implicitHeight {
        Anim {}
    }

    Loader {
        id: placeholder

        anchors.centerIn: parent
        active: opacity > 0
        opacity: root.showList && root.contentCount > 0 ? 0 : 1

        sourceComponent: ColumnLayout {
            spacing: Tokens.spacing.extraSmall

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: root.placeholderIcon
                color: Colours.palette.m3outline
                fontStyle: Tokens.font.icon.large
                animate: true
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.placeholderText
                color: Colours.palette.m3outline
                font: Tokens.font.body.large
                animate: true
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    ListView {
        id: list

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        visible: root.columns <= 1
        spacing: 0
        interactive: false
        opacity: root.showList && root.columns <= 1 ? 1 : 0

        add: Transition {
            Anim {
                property: "opacity"
                from: 0
                to: 1
                type: Anim.DefaultEffects
            }
        }

        remove: Transition {
            Anim {
                property: "opacity"
                to: 0
                type: Anim.DefaultEffects
            }
        }

        move: Transition {
            Anim {
                property: "opacity"
                to: 1
                type: Anim.DefaultEffects
            }
            Anim {
                property: "y"
            }
        }

        displaced: Transition {
            Anim {
                property: "opacity"
                to: 1
                type: Anim.DefaultEffects
            }
            Anim {
                property: "y"
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    GridView {
        id: grid

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        visible: root.columns > 1
        interactive: false
        opacity: root.showList && root.columns > 1 ? 1 : 0

        cellWidth: width / Math.max(1, root.columns)
        cellHeight: root.gridCellHeight
        model: root.columns > 1 ? list.model : null
        delegate: list.delegate

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
