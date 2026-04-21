import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

ColumnLayout {
    id: root

    required property string title
    property string description: ""
    property bool expanded: false
    property bool showBackground: false
    property bool nested: false

    default property alias content: contentColumn.data

    signal toggleRequested

    spacing: Tokens.spacing.small
    Layout.fillWidth: true

    Item {
        id: sectionHeaderItem

        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(titleRow.implicitHeight + Tokens.padding.normal * 2, 48)

        RowLayout {
            id: titleRow

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.padding.normal
            anchors.rightMargin: Tokens.padding.normal
            spacing: Tokens.spacing.normal

            StyledText {
                text: root.title
                font.pointSize: Tokens.font.size.larger
                font.weight: 500
            }

            Item {
                Layout.fillWidth: true
            }

            MaterialIcon {
                text: "expand_more"
                rotation: root.expanded ? 180 : 0
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Tokens.font.size.normal

                Behavior on rotation {
                    Anim {
                        type: Anim.StandardSmall
                    }
                }
            }
        }

        StateLayer {
            anchors.fill: parent
            color: Colours.palette.m3onSurface
            radius: Tokens.rounding.normal
            showHoverBackground: false
            onClicked: {
                root.toggleRequested();
                root.expanded = !root.expanded;
            }
        }
    }

    Item {
        id: contentWrapper

        Layout.fillWidth: true
        Layout.preferredHeight: root.expanded ? (contentColumn.implicitHeight + Tokens.spacing.small * 2) : 0
        clip: true

        Behavior on Layout.preferredHeight {
            Anim {}
        }

        StyledRect {
            id: backgroundRect

            anchors.fill: parent
            radius: Tokens.rounding.normal
            color: Colours.transparency.enabled ? Colours.layer(Colours.palette.m3surfaceContainer, root.nested ? 3 : 2) : (root.nested ? Colours.palette.m3surfaceContainerHigh : Colours.palette.m3surfaceContainer)
            opacity: root.showBackground && root.expanded ? 1.0 : 0.0
            visible: root.showBackground

            Behavior on opacity {
                Anim {}
            }
        }

        ColumnLayout {
            id: contentColumn

            anchors.left: parent.left
            anchors.right: parent.right
            y: Tokens.spacing.small
            anchors.leftMargin: Tokens.padding.normal
            anchors.rightMargin: Tokens.padding.normal
            anchors.bottomMargin: Tokens.spacing.small
            spacing: Tokens.spacing.small
            opacity: root.expanded ? 1.0 : 0.0

            Behavior on opacity {
                Anim {}
            }

            StyledText {
                id: descriptionText

                Layout.fillWidth: true
                Layout.topMargin: root.description !== "" ? Tokens.spacing.smaller : 0
                Layout.bottomMargin: root.description !== "" ? Tokens.spacing.small : 0
                visible: root.description !== ""
                text: root.description
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Tokens.font.size.small
                wrapMode: Text.Wrap
            }
        }
    }
}
