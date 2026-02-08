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

        anchors.fill: parent
        radius: Appearance.rounding.full
        color: Qt.alpha(Colours.palette.m3secondaryContainer, root.active ? 1 : 0)

        implicitHeight: iconItem.implicitHeight + Appearance.padding.small * 2

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
            anchors.leftMargin: Appearance.padding.small
            anchors.rightMargin: Appearance.padding.small
            spacing: Appearance.spacing.normal

            MaterialIcon {
                id: iconItem
                text: root.icon
                font.pointSize: Appearance.font.size.small
                color: root.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
            }

            StyledText {
                Layout.fillWidth: true
                text: root.text
                color: root.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                elide: Text.ElideRight
            }
        }
    }
}