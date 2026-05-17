pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    property int activeTabIndex: 0

    StackLayout {
        anchors.fill: parent
        currentIndex: root.activeTabIndex

        Item {
            ColumnLayout {
                anchors.centerIn: parent
                spacing: Tokens.spacing.normal

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "construction"
                    font.pointSize: Tokens.font.size.extraLarge
                    color: Qt.alpha(Colours.palette.m3onSurface, 0.3)
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Panel not yet implemented")
                    font.pointSize: Tokens.font.size.larger
                    color: Qt.alpha(Colours.palette.m3onSurface, 0.5)
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("This settings page will be available in a future update.")
                    font.pointSize: Tokens.font.size.normal
                    color: Qt.alpha(Colours.palette.m3onSurface, 0.35)
                }
            }
        }

        Item {
            ColumnLayout {
                anchors.centerIn: parent
                spacing: Tokens.spacing.normal

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Second tab placeholder")
                    font.pointSize: Tokens.font.size.larger
                    color: Qt.alpha(Colours.palette.m3onSurface, 0.5)
                }
            }
        }
    }
}
