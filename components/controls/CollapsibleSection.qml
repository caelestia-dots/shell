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

    signal toggleRequested

    spacing: 0
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

    Item {
        visible: root.description !== ""
        Layout.fillWidth: true
        Layout.preferredHeight: root.expanded ? descriptionText.implicitHeight + Appearance.spacing.smaller + Appearance.spacing.small : 0
        clip: true

        Behavior on Layout.preferredHeight {
            Anim {
                easing.bezierCurve: Appearance.anim.curves.standard
            }
        }

        StyledText {
            id: descriptionText
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: Appearance.padding.normal
            anchors.rightMargin: Appearance.padding.normal
            anchors.topMargin: Appearance.spacing.smaller
            text: root.description
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Appearance.font.size.small
            opacity: root.expanded ? 1.0 : 0.0

            Behavior on opacity {
                Anim {
                    easing.bezierCurve: Appearance.anim.curves.standard
                }
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

        ColumnLayout {
            id: contentColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: Appearance.padding.normal
            anchors.rightMargin: Appearance.padding.normal
            anchors.topMargin: Appearance.spacing.small
            anchors.bottomMargin: Appearance.spacing.small
            spacing: Appearance.spacing.small
            opacity: root.expanded ? 1.0 : 0.0

            Behavior on opacity {
                Anim {
                    easing.bezierCurve: Appearance.anim.curves.standard
                }
            }
        }
    }
}

