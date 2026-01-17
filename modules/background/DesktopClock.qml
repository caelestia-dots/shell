import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root
    implicitWidth: layout.implicitWidth + Appearance.padding.large * 2
    implicitHeight: layout.implicitHeight + Appearance.padding.large

    property real scale: Config.background.desktopClock.scale

    readonly property color safePrimary: Colours.light ? Colours.palette.m3primaryContainer : Colours.palette.m3primary
    readonly property color safeSecondary: Colours.light ? Colours.palette.m3secondaryContainer : Colours.palette.m3secondary
    readonly property color safeTertiary: Colours.light ? Colours.palette.m3tertiaryContainer : Colours.palette.m3tertiary

    Behavior on scale {
        NumberAnimation {
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    Item {
        id: clockContainer
        anchors.fill: parent

        RowLayout {
            id: layout
            anchors.centerIn: parent
            spacing: Appearance.spacing.larger * root.scale

            RowLayout {
                spacing: Appearance.spacing.small
                
                StyledText {
                    text: Time.format(Config.services.useTwelveHourClock ? "hh" : "HH")
                    font.pointSize: Appearance.font.size.extraLarge * 3 * root.scale
                    font.weight: Font.Bold
                    color: root.safePrimary 
                }

                StyledText {
                    text: ":"
                    font.pointSize: Appearance.font.size.extraLarge * 3 * root.scale
                    color: root.safeTertiary
                    opacity: 0.8
                }

                StyledText {
                    text: Time.format("mm")
                    font.pointSize: Appearance.font.size.extraLarge * 3 * root.scale
                    font.weight: Font.Bold
                    color: root.safeSecondary
                }

                StyledText {
                    visible: Config.services.useTwelveHourClock
                    text: Time.format("A")
                    font.pointSize: Appearance.font.size.large * root.scale
                    color: root.safeSecondary
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: Appearance.padding.large * 1.4 * root.scale
                    opacity: 0.8
                }
            }

            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 4 * root.scale
                Layout.topMargin: Appearance.spacing.larger * root.scale
                Layout.bottomMargin: Appearance.spacing.larger * root.scale
                radius: Appearance.rounding.full
                color: root.safePrimary
                opacity: 0.8
            }

            ColumnLayout {
                spacing: 0
                
                StyledText {
                    text: Time.format("MMMM").toUpperCase()
                    font.pointSize: Appearance.font.size.large * root.scale
                    font.letterSpacing: 4
                    font.weight: Font.Bold
                    color: root.safeSecondary 
                }

                StyledText {
                    text: Time.format("dd")
                    font.pointSize: Appearance.font.size.extraLarge * root.scale
                    font.letterSpacing: 2
                    font.weight: Font.Medium
                    color: root.safePrimary
                }

                StyledText {
                    text: Time.format("dddd")
                    font.pointSize: Appearance.font.size.larger * root.scale
                    font.letterSpacing: 2
                    color: root.safeSecondary
                    opacity: isBrightWall ? 1 : 0.8
                }
            }
        }
    }

    MultiEffect {
        source: clockContainer
        anchors.fill: clockContainer
        
        shadowEnabled: Config.background.desktopClock.shadow.enabled
        shadowColor: Colours.palette.m3shadow
        shadowOpacity: Config.background.desktopClock.shadow.opacity
        shadowBlur: Config.background.desktopClock.shadow.blur
    }
}