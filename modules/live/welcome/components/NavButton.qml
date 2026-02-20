import QtQuick
import QtQuick.Layouts
import qs.services
import qs.config
import qs.components

Item {
    id: root

    property string text: ""
    property string icon: ""
    property bool active: false

    signal clicked()

    implicitHeight: background.implicitHeight
    implicitWidth: background.implicitWidth

    StyledRect {
        id: background

        radius: Appearance.rounding.full
        color: Qt.alpha(Colours.palette.m3secondaryContainer, root.active ? 1 : 0)

        implicitHeight: iconItem.implicitHeight + Appearance.padding.small * 2
        implicitWidth: root.text != "" ? iconItem.implicitWidth + Appearance.spacing.small + labelItem.implicitWidth + Appearance.padding.normal * 2 : iconItem.implicitHeight + Appearance.padding.small * 2

        Behavior on color {
            ColorAnimation {
                duration: Appearance.anim.durations.normal
                easing.type: Easing.OutCubic
            }
        }

        StateLayer {
            color: root.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface

            function onClicked() {
                root.clicked()
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: root.text != "" ? Appearance.padding.normal : Appearance.padding.small
            anchors.rightMargin: root.text != "" ? Appearance.padding.normal : Appearance.padding.small
            spacing: Appearance.spacing.small

            MaterialIcon {
                id: iconItem
                Layout.alignment: Qt.AlignHCenter
                text: root.icon
                font.pointSize: Appearance.font.size.normal
                fill: 1
                color: root.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
            }

            StyledText {
                id: labelItem
                visible: root.text != ""
                text: root.text
                color: root.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                elide: Text.ElideRight
            }
        }
    }
}