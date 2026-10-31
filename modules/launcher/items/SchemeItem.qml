import QtQuick
import Caelestia.Config
import Caelestia.Scheme
import qs.components
import qs.modules.launcher.services // qmllint disable unused-imports

Item {
    id: root

    required property Schemes.Scheme modelData
    required property var list

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    SchemeOpener {
        id: opener

        name: root.modelData?.name ?? ""
        flavour: root.modelData?.flavour ?? ""
        mode: !root.modelData || root.modelData.modes.includes(Colours.mode) ? Colours.mode : root.modelData.modes[0]
    }

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: root.modelData?.onClicked(root.list)
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        anchors.margins: Tokens.padding.small

        StyledRect {
            id: preview

            anchors.verticalCenter: parent.verticalCenter

            border.width: 1
            border.color: Qt.alpha(opener.palette.outline, 0.5)

            color: opener.palette.surface
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
                    color: opener.palette.primary
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
                text: root.modelData?.flavour ?? ""
                font: Tokens.font.body.medium
            }

            StyledText {
                text: root.modelData?.name ?? ""
                font: Tokens.font.body.small
                color: Colours.palette.outline

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

            active: root.modelData?.name === Colours.scheme && root.modelData?.flavour === Colours.flavour

            sourceComponent: MaterialIcon {
                text: "check"
                color: Colours.palette.onSurfaceVariant
                fontStyle: Tokens.font.icon.large
            }
        }
    }
}
