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

        // Wallpaper & Scheme
        Item {
            ColumnLayout {
                anchors.centerIn: parent
                spacing: Tokens.spacing.normal

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Wallpaper & Scheme"
                    font.pointSize: Tokens.font.size.larger
                    font.weight: Font.Medium
                    color: Colours.palette.m3onSurface
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Theme mode, color scheme, and wallpaper settings"
                    font.pointSize: Tokens.font.size.normal
                    color: Qt.alpha(Colours.palette.m3onSurface, 0.5)
                }
            }
        }

        // Typography & Motion
        Item {
            ColumnLayout {
                anchors.centerIn: parent
                spacing: Tokens.spacing.normal

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Typography & Motion"
                    font.pointSize: Tokens.font.size.larger
                    font.weight: Font.Medium
                    color: Colours.palette.m3onSurface
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Font and animation settings"
                    font.pointSize: Tokens.font.size.normal
                    color: Qt.alpha(Colours.palette.m3onSurface, 0.5)
                }
            }
        }

        // Effects
        Item {
            ColumnLayout {
                anchors.centerIn: parent
                spacing: Tokens.spacing.normal

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Effects"
                    font.pointSize: Tokens.font.size.larger
                    font.weight: Font.Medium
                    color: Colours.palette.m3onSurface
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Shadows, rounding, and visual effects"
                    font.pointSize: Tokens.font.size.normal
                    color: Qt.alpha(Colours.palette.m3onSurface, 0.5)
                }
            }
        }
    }
}
