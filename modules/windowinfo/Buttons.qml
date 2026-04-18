pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services

ColumnLayout {
    id: root

    required property var client
    property bool moveToWsExpanded

    anchors.fill: parent
    spacing: Tokens.spacing.small

    RowLayout {
        Layout.topMargin: Tokens.padding.large
        Layout.leftMargin: Tokens.padding.large
        Layout.rightMargin: Tokens.padding.large

        spacing: Tokens.spacing.normal

        StyledText {
            Layout.fillWidth: true
            text: qsTr("Move to workspace")
            elide: Text.ElideRight
        }

        StyledRect {
            color: Colours.palette.m3primary
            radius: Tokens.rounding.small

            implicitWidth: moveToWsIcon.implicitWidth + Tokens.padding.small * 2
            implicitHeight: moveToWsIcon.implicitHeight + Tokens.padding.small

            StateLayer {
                color: Colours.palette.m3onPrimary
                onClicked: root.moveToWsExpanded = !root.moveToWsExpanded
            }

            MaterialIcon {
                id: moveToWsIcon

                anchors.centerIn: parent

                animate: true
                text: root.moveToWsExpanded ? "expand_more" : "keyboard_arrow_right"
                color: Colours.palette.m3onPrimary
                font.pointSize: Tokens.font.size.large
            }
        }
    }

    WrapperItem {
        Layout.fillWidth: true
        Layout.leftMargin: Tokens.padding.large * 2
        Layout.rightMargin: Tokens.padding.large * 2

        Layout.preferredHeight: root.moveToWsExpanded ? implicitHeight : 0
        clip: true

        topMargin: Tokens.spacing.normal
        bottomMargin: Tokens.spacing.normal

        GridLayout {
            id: wsGrid

            rowSpacing: Tokens.spacing.smaller
            columnSpacing: Tokens.spacing.normal
            columns: 5

            Repeater {
                model: 10

                Button {
                    required property int index
                    readonly property int wsId: Math.floor((Hypr.activeWsId - 1) / 10) * 10 + index + 1
                    readonly property bool isCurrent: root.client?.workspace.id === wsId

                    onClicked: {
                        Hypr.dispatch(`movetoworkspace ${wsId},address:0x${root.client?.address}`);
                    }

                    color: isCurrent ? Colours.tPalette.m3surfaceContainerHighest : Colours.palette.m3tertiaryContainer
                    onColor: isCurrent ? Colours.palette.m3onSurface : Colours.palette.m3onTertiaryContainer
                    text: wsId
                    disabled: isCurrent
                }
            }
        }

        Behavior on Layout.preferredHeight {
            Anim {}
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Tokens.padding.large
        Layout.rightMargin: Tokens.padding.large
        Layout.bottomMargin: Tokens.padding.large

        spacing: root.client?.lastIpcObject.floating ? Tokens.spacing.normal : Tokens.spacing.small

        Button {
            color: Colours.palette.m3secondaryContainer
            onColor: Colours.palette.m3onSecondaryContainer
            text: root.client?.lastIpcObject.floating ? qsTr("Tile") : qsTr("Float")
            onClicked: Hypr.dispatch(`togglefloating address:0x${root.client?.address}`)
        }

        Loader {
            asynchronous: true
            active: root.client?.lastIpcObject.floating ?? false
            Layout.fillWidth: active
            Layout.leftMargin: active ? 0 : -parent.spacing
            Layout.rightMargin: active ? 0 : -parent.spacing

            sourceComponent: Button {
                color: Colours.palette.m3secondaryContainer
                onColor: Colours.palette.m3onSecondaryContainer
                text: root.client?.lastIpcObject.pinned ? qsTr("Unpin") : qsTr("Pin")
                onClicked: Hypr.dispatch(`pin address:0x${root.client?.address}`)
            }
        }

        Button {
            color: Colours.palette.m3errorContainer
            onColor: Colours.palette.m3onErrorContainer
            text: qsTr("Kill")
            onClicked: Hypr.dispatch(`killwindow address:0x${root.client?.address}`)
        }
    }

    component Button: StyledRect {
        property color onColor: Colours.palette.m3onSurface
        property alias disabled: stateLayer.disabled
        property alias text: label.text

        signal clicked

        radius: Tokens.rounding.small

        Layout.fillWidth: true
        implicitHeight: label.implicitHeight + Tokens.padding.small * 2

        StateLayer {
            id: stateLayer

            color: parent.onColor
            onClicked: parent.clicked()
        }

        StyledText {
            id: label

            anchors.centerIn: parent

            animate: true
            color: parent.onColor
            font.pointSize: Tokens.font.size.normal
        }
    }
}
