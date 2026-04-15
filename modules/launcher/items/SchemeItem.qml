import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.launcher.services

Item {
    id: root

    required property Schemes.Scheme modelData
    required property var list

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        function onClicked(): void {
            root.modelData?.onClicked(root.list);
        }

        radius: Tokens.rounding.normal
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.larger
        anchors.rightMargin: Tokens.padding.larger
        anchors.margins: Tokens.padding.smaller

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
            anchors.leftMargin: Tokens.spacing.normal
            anchors.verticalCenter: parent.verticalCenter

            width: parent.width - preview.width - anchors.leftMargin - (current.active ? current.width + Tokens.spacing.normal : 0)
            spacing: 0

            StyledText {
                text: root.modelData?.flavour ?? ""
                font.pointSize: Tokens.font.size.normal
            }

            StyledText {
                text: root.modelData?.name ?? ""
                font.pointSize: Tokens.font.size.small
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

            active: `${root.modelData?.name} ${root.modelData?.flavour}` === Schemes.currentScheme

            sourceComponent: MaterialIcon {
                text: "check"
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Tokens.font.size.large
            }
        }
    }
}
