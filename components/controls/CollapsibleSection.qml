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
        Layout.preferredHeight: Math.max(titleRow.implicitHeight + Tokens.padding.medium * 2, 48)

        RowLayout {
            id: titleRow

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.padding.medium
            anchors.rightMargin: Tokens.padding.medium
            spacing: Tokens.spacing.medium

            StyledText {
                text: root.title
                font: Tokens.font.title.builders.medium.weight(Font.Medium).build()
            }

            Item {
                Layout.fillWidth: true
            }

            MaterialIcon {
                text: "expand_more"
                rotation: root.expanded ? 180 : 0
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium

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
            radius: Tokens.rounding.large
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
        Layout.preferredHeight: root.expanded ? (contentColumn.implicitHeight + Tokens.spacing.large) : 0
        clip: true

        Behavior on Layout.preferredHeight {
            Anim {}
        }

        StyledRect {
            id: backgroundRect

            anchors.fill: parent
            radius: Tokens.rounding.large
            color: Colours.transparency.enabled ? Colours.layer(Colours.palette.m3surfaceContainer, root.nested ? 3 : 2) : (root.nested ? Colours.palette.m3surfaceContainerHigh : Colours.palette.m3surfaceContainer)
            opacity: root.showBackground && root.expanded ? 1.0 : 0.0
            visible: root.showBackground

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        ColumnLayout {
            id: contentColumn

            anchors.left: parent.left
            anchors.right: parent.right
            y: Tokens.spacing.small
            anchors.leftMargin: Tokens.padding.medium
            anchors.rightMargin: Tokens.padding.medium
            anchors.bottomMargin: Tokens.spacing.small
            spacing: Tokens.spacing.small
            opacity: root.expanded ? 1.0 : 0.0

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            StyledText {
                id: descriptionText

                Layout.fillWidth: true
                Layout.topMargin: root.description !== "" ? Tokens.spacing.medium : 0
                Layout.bottomMargin: root.description !== "" ? Tokens.spacing.small : 0
                visible: root.description !== ""
                text: root.description
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                wrapMode: Text.Wrap
            }
        }
    }
}
