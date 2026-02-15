import ".."
import qs.components
import qs.components.effects
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property string title
    property string description: ""
    property bool expanded: false
    property bool showBackground: false
    property bool nested: false

    signal toggleRequested

    spacing: Appearance.spacing.small
    Layout.fillWidth: true

    Item {
        id: sectionHeaderItem
        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(titleRow.implicitHeight + Appearance.padding.normal * 2, 48)

        RowLayout {
            id: titleRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Appearance.padding.normal
            anchors.rightMargin: Appearance.padding.normal
            spacing: Appearance.spacing.normal

            StyledText {
                text: root.title
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            Item {
                Layout.fillWidth: true
            }

            MaterialIcon {
                text: "expand_more"
                rotation: root.expanded ? 180 : 0
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.normal
                Behavior on rotation {
                    Anim {
                        duration: Appearance.anim.durations.small
                        easing.bezierCurve: Appearance.anim.curves.standard
                    }
                }
            }
        }

        StateLayer {
            anchors.fill: parent
            color: Colours.palette.m3onSurface
            radius: Appearance.rounding.normal
            showHoverBackground: false
            function onClicked(): void {
                root.toggleRequested();
                root.expanded = !root.expanded;
            }
        }
    }

    default property alias content: contentColumn.data

    Item {
        id: contentWrapper
        Layout.fillWidth: true
        Layout.preferredHeight: root.expanded ? (contentColumn.implicitHeight + Appearance.spacing.small * 2) : 0
        clip: true

        Behavior on Layout.preferredHeight {
            Anim {
                easing.bezierCurve: Appearance.anim.curves.standard
            }
        }

        StyledRect {
            id: backgroundRect
            anchors.fill: parent
            radius: Appearance.rounding.normal
            color: Colours.transparency.enabled 
                   ? Colours.layer(Colours.palette.m3surfaceContainer, root.nested ? 3 : 2)
                   : (root.nested ? Colours.palette.m3surfaceContainerHigh : Colours.palette.m3surfaceContainer)
            opacity: root.showBackground && root.expanded ? 1.0 : 0.0
            visible: root.showBackground

            Behavior on opacity {
                Anim {
                    easing.bezierCurve: Appearance.anim.curves.standard
                }
            }
        }

        ColumnLayout {
            id: contentColumn
            anchors.left: parent.left
            anchors.right: parent.right
            y: Appearance.spacing.small
            anchors.leftMargin: Appearance.padding.normal
            anchors.rightMargin: Appearance.padding.normal
            anchors.bottomMargin: Appearance.spacing.small
            spacing: Appearance.spacing.small
            opacity: root.expanded ? 1.0 : 0.0

            Behavior on opacity {
                Anim {
                    easing.bezierCurve: Appearance.anim.curves.standard
                }
            }

            StyledText {
                id: descriptionText
                Layout.fillWidth: true
                Layout.topMargin: root.description !== "" ? Appearance.spacing.smaller : 0
                Layout.bottomMargin: root.description !== "" ? Appearance.spacing.small : 0
                visible: root.description !== ""
                text: root.description
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.small
                wrapMode: Text.Wrap
            }
        }
    }
}

