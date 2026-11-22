pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.hallownest
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

        spacing: Tokens.spacing.medium

        StyledText {
            Layout.fillWidth: true
            text: Tr.tr("Move to workspace")
            color: Hallownest.text
            elide: Text.ElideRight
        }

        HkButton {
            icon: root.moveToWsExpanded ? "expand_more" : "keyboard_arrow_right"
            filled: true
            onClicked: root.moveToWsExpanded = !root.moveToWsExpanded
        }
    }

    GridLayout {
        id: wsGrid

        Layout.fillWidth: true
        Layout.leftMargin: Tokens.padding.large
        Layout.rightMargin: Tokens.padding.large
        Layout.bottomMargin: root.moveToWsExpanded ? Tokens.spacing.medium : 0
        Layout.preferredHeight: root.moveToWsExpanded ? implicitHeight : 0
        opacity: root.moveToWsExpanded ? 1 : 0
        clip: true

        rowSpacing: Tokens.spacing.small
        columnSpacing: Tokens.spacing.small
        columns: 5

        Behavior on Layout.bottomMargin {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on Layout.preferredHeight {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Repeater {
            model: 10

            HkButton {
                required property int index
                readonly property int wsId: Math.floor((Hypr.activeWsId - 1) / 10) * 10 + index + 1
                readonly property bool isCurrent: root.client?.workspace.id === wsId

                Layout.fillWidth: true
                text: String(wsId)
                tinted: isCurrent
                disabled: isCurrent
                onClicked: {
                    Hypr.dispatch(Hypr.usingLua ? `hl.dsp.window.move({ window = "address:0x${root.client?.address}", workspace = "${wsId}", follow = true })` : `movetoworkspace ${wsId},address:0x${root.client?.address}`);
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Tokens.padding.large
        Layout.rightMargin: Tokens.padding.large
        Layout.bottomMargin: Tokens.padding.large

        spacing: root.client?.lastIpcObject.floating ? Tokens.spacing.medium : Tokens.spacing.small

        HkButton {
            Layout.fillWidth: true
            text: root.client?.lastIpcObject.floating ? Tr.tr("Tile") : Tr.tr("Float")
            onClicked: Hypr.dispatch(Hypr.usingLua ? `hl.dsp.window.float({ window = "address:0x${root.client?.address}" })` : `togglefloating address:0x${root.client?.address}`)
        }

        Loader {
            asynchronous: true
            active: root.client?.lastIpcObject.floating ?? false
            Layout.fillWidth: active
            Layout.leftMargin: active ? 0 : -parent.spacing
            Layout.rightMargin: active ? 0 : -parent.spacing

            sourceComponent: HkButton {
                text: root.client?.lastIpcObject.pinned ? Tr.tr("Unpin") : Tr.tr("Pin")
                onClicked: Hypr.dispatch(Hypr.usingLua ? `hl.dsp.window.pin({ window = "address:0x${root.client?.address}" })` : `pin address:0x${root.client?.address}`)
            }
        }

        HkButton {
            Layout.fillWidth: true
            text: Tr.tr("Kill")
            accent: Hallownest.grimm
            tinted: true
            onClicked: Hypr.dispatch(Hypr.usingLua ? `hl.dsp.window.kill({ window = "address:0x${root.client?.address}" })` : `killwindow address:0x${root.client?.address}`)
        }
    }
}
