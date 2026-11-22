import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    // Schemes.Scheme or Flavours.Flavour: title, subtitle, current, colours, onClicked
    required property var modelData
    required property var list

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: root.modelData?.onClicked(root.list)
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium + 16
        anchors.rightMargin: Tokens.padding.medium + 16
        anchors.margins: Tokens.padding.small

        StyledRect {
            id: preview

            anchors.verticalCenter: parent.verticalCenter

            border.width: 1
            border.color: Qt.alpha(`#${root.modelData?.colours?.outline}`, 0.5)

            color: `#${root.modelData?.colours?.surface}`
            radius: Tokens.rounding.full
            implicitWidth: parent.height * 0.8
            implicitHeight: parent.height * 0.8

            Item {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right

                implicitWidth: parent.implicitWidth / 2
                clip: true

                StyledRect {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right

                    implicitWidth: preview.implicitWidth
                    color: `#${root.modelData?.colours?.primary}`
                    radius: Tokens.rounding.full
                }
            }
        }

        Column {
            anchors.left: preview.right
            anchors.leftMargin: Tokens.spacing.medium
            anchors.verticalCenter: parent.verticalCenter

            width: parent.width - preview.width - anchors.leftMargin - (current.active ? current.width + Tokens.spacing.medium : 0)
            spacing: 0

            StyledText {
                text: root.modelData?.title ?? ""
                font: Tokens.font.body.medium
            }

            StyledText {
                text: root.modelData?.subtitle ?? ""
                font: Tokens.font.body.small
                color: Colours.palette.m3outline

                elide: Text.ElideRight
                anchors.left: parent.left
                anchors.right: parent.right
            }
        }

        Loader {
            id: current

            asynchronous: true
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            active: root.modelData?.current ?? false

            sourceComponent: MaterialIcon {
                text: "check"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.large
            }
        }
    }
}
