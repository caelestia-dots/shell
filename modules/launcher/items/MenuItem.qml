import QtQuick
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property var modelData
    required property var list

    readonly property bool isSeparator: root.modelData?.type === "separator"
    readonly property string iconValue: root.modelData?.icon ?? ""
    readonly property bool isMaterialIcon: /^[a-z0-9_]+$/.test(root.iconValue)

    implicitHeight: root.isSeparator ? Math.round(Tokens.sizes.launcher.itemHeight * 0.4) : Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    opacity: root.modelData?.type === "item" && root.modelData?.disabled ? 0.45 : 1

    StateLayer {
        radius: Tokens.rounding.large
        disabled: root.isSeparator || (root.modelData?.type === "item" && root.modelData?.disabled === true)
        onClicked: root.list.enterRow(root.modelData)
    }

    StyledRect {
        visible: root.isSeparator
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Tokens.padding.medium
        anchors.verticalCenter: parent.verticalCenter
        implicitHeight: 1
        color: Colours.palette.m3outline
        opacity: 0.5
    }

    Item {
        visible: !root.isSeparator
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        anchors.margins: Tokens.padding.small

        Item {
            id: leadingIcon

            implicitWidth: parent.height * 0.8
            implicitHeight: parent.height * 0.8
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            IconImage {
                visible: root.modelData?.type === "app"
                asynchronous: true
                source: root.modelData?.type === "app" ? Quickshell.iconPath(root.modelData?.entry?.icon ?? root.iconValue, "image-missing") : ""
                implicitSize: parent.implicitWidth
                anchors.centerIn: parent
            }

            MaterialIcon {
                visible: root.modelData?.type !== "app" && root.isMaterialIcon
                text: root.iconValue
                color: root.modelData?.checked ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.builders.large.scale(1.15).build()
                anchors.centerIn: parent
            }

            StyledText {
                visible: root.modelData?.type !== "app" && !root.isMaterialIcon && root.iconValue !== ""
                text: root.iconValue
                color: root.modelData?.checked ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                font: Tokens.font.mono.builders.large.scale(1.15).build()
                anchors.centerIn: parent
            }
        }

        Column {
            anchors.left: leadingIcon.right
            anchors.leftMargin: Tokens.spacing.medium
            anchors.right: trailing.visible ? trailing.left : parent.right
            anchors.rightMargin: trailing.visible ? Tokens.spacing.medium : 0
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.spacing.small

            StyledText {
                id: name

                text: root.modelData?.label ?? ""
                font: Tokens.font.body.medium
                color: root.modelData?.checked ? Colours.palette.m3primary : Colours.palette.m3onSurface

                width: parent.width
                elide: Text.ElideRight
            }

            StyledText {
                id: desc

                text: root.modelData?.desc ?? ""
                visible: text.length > 0
                font: Tokens.font.body.small
                color: Colours.palette.m3outline

                width: parent.width
                elide: Text.ElideRight
            }
        }

        MaterialIcon {
            id: trailing

            visible: root.modelData?.checked || root.modelData?.toggle || root.modelData?.type === "submenu"
            text: {
                if (root.modelData?.type === "submenu")
                    return "chevron_right";
                if (!root.modelData?.toggle)
                    return "check";
                return root.modelData?.checked ? "check_box" : "check_box_outline_blank";
            }
            color: root.modelData?.checked && root.modelData?.type !== "submenu" ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.medium

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
