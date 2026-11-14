import QtQuick
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.launcher.services

Item {
    id: root

    required property var modelData
    required property var list

    // Whether this is what the clipboard holds right now
    readonly property bool active: Clipboard.isActive(modelData)

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StyledRect {
        anchors.fill: parent

        visible: root.active
        color: Qt.alpha(Colours.palette.m3secondaryContainer, 0.6)
        radius: Tokens.rounding.large
    }

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: {
            Clipboard.copy(root.modelData);
            root.list.screenState.launcher = false;
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        anchors.margins: Tokens.padding.small

        Item {
            id: icon

            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: parent.height * 0.8
            implicitHeight: implicitWidth

            MaterialIcon {
                anchors.centerIn: parent

                visible: !(root.modelData?.image ?? false)
                text: "content_paste"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.builders.large.scale(1.3).build()
            }

            Loader {
                anchors.fill: parent

                active: root.modelData?.image ?? false
                asynchronous: true

                sourceComponent: ClipRect {
                    radius: Tokens.rounding.small

                    ClipImage {
                        anchors.fill: parent

                        entry: root.modelData
                        decodeSize: 96
                    }
                }
            }
        }

        Row {
            id: trailing

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            spacing: Tokens.spacing.small

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter

                visible: root.modelData?.pinned ?? false
                text: "push_pin"
                fill: 1
                color: Colours.palette.m3primary
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter

                visible: root.modelData?.image ?? false
                text: Tr.tr("Image")
                color: Colours.palette.m3outline
                font: Tokens.font.label.medium
            }
        }

        Item {
            anchors.left: icon.right
            anchors.leftMargin: Tokens.spacing.medium
            anchors.right: trailing.left
            anchors.rightMargin: Tokens.spacing.medium
            anchors.verticalCenter: icon.verticalCenter

            implicitHeight: name.implicitHeight + desc.implicitHeight

            StyledText {
                id: name

                anchors.left: parent.left
                anchors.right: parent.right

                text: root.modelData?.preview ?? ""
                color: root.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                font: Tokens.font.body.medium
                elide: Text.ElideRight
            }

            StyledText {
                id: desc

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: name.bottom

                text: root.modelData?.info ?? ""
                font: Tokens.font.body.small
                color: Colours.palette.m3outline
                elide: Text.ElideRight
            }
        }
    }
}
