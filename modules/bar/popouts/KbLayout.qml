import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell
import QtQuick.Layouts

ColumnLayout {
    id: root

    spacing: Appearance.spacing.normal

    StyledText {
        Layout.topMargin: Appearance.padding.normal
        Layout.rightMargin: Appearance.padding.normal
        text: qsTr("Keyboard layout: %1").arg(Hypr.kbLayoutFull)
        font.weight: 500
    }

    StyledRect {
            Layout.topMargin: Appearance.spacing.small

            implicitWidth: expandBtn.implicitWidth + Appearance.padding.normal * 2
            implicitHeight: expandBtn.implicitHeight + Appearance.padding.small

            Layout.fillWidth: true

            radius: Appearance.rounding.normal
            color: Colours.palette.m3primaryContainer

            StateLayer {
                color: Colours.palette.m3onPrimaryContainer
                onClicked: Hypr.extras.message("switchxkblayout all next")
            }

            RowLayout {
                id: expandBtn

                anchors.centerIn: parent
                spacing: Appearance.spacing.small

                MaterialIcon {
                    Layout.leftMargin: Appearance.padding.smaller
                    text: "keyboard"
                    color: Colours.palette.m3onPrimaryContainer
                    font.pointSize: Appearance.font.size.large
                }

                StyledText {
                    text: qsTr("Switch layout")
                    color: Colours.palette.m3onPrimaryContainer
                }
            }
        }
}