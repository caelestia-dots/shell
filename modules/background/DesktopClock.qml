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

    readonly property bool shadowEnabled: Config.background.desktopClock.shadow.enabled
    readonly property real shadowOpacity: Config.background.desktopClock.shadow.opacity
    readonly property real shadowBlur: Config.background.desktopClock.shadow.blur

    readonly property bool isBrightWall: Colours.wallLuminance > 0.6
    
    readonly property color safePrimary: isBrightWall ? Colours.palette.m3onPrimary : Colours.palette.m3primary
    readonly property color safeSecondary: isBrightWall ? Colours.palette.m3onSecondary : Colours.palette.m3secondary
    readonly property color safeTertiary: isBrightWall ? Colours.palette.m3onTertiary : Colours.palette.m3tertiary

    component DebugSwatch : Rectangle {
        width: 16; height: 16
        border.color: "white"
        border.width: 1
    }

    Behavior on scale {
        NumberAnimation {
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    // DEBUG OVERLAY
    ColumnLayout {
        id: debugOverlay
        anchors.bottom: clockContainer.top
        anchors.left: clockContainer.left
        anchors.bottomMargin: 10
        spacing: 5
        z: 100 

        RowLayout {
            spacing: 8
            Rectangle {
                width: 12; height: 12
                radius: 6
                color: root.isBrightWall ? "#ff0000" : "#444444"
                border.color: "white"
                border.width: 1
            }
            Text { 
                text: root.isBrightWall ? "BRIGHT WALL (Using Dark Colors)" : "DARK WALL (Using Light Colors)"
                color: "white"
                font.pixelSize: 10
                style: Text.Outline; styleColor: "black"
            }
            Text {
                text: Colours.wallLuminance
                color: "#ff0000"
                font.pixelSize: 10
            }
        }

        RowLayout {
            spacing: 15
            
            ColumnLayout {
                spacing: 2
                Text { text: "Normal Palette"; color: "white"; font.pixelSize: 8; style: Text.Outline; styleColor: "black" }
                Row {
                    spacing: 2
                    DebugSwatch { color: Colours.palette.m3primary }
                    DebugSwatch { color: Colours.palette.m3secondary }
                    DebugSwatch { color: Colours.palette.m3tertiary }
                }
            }

            ColumnLayout {
                spacing: 2
                Text { text: "Safe"; color: "white"; font.pixelSize: 8; style: Text.Outline; styleColor: "black" }
                Row {
                    spacing: 2
                    DebugSwatch { color: root.safePrimary }
                    DebugSwatch { color: root.safeSecondary }
                    DebugSwatch { color: root.safeTertiary }
                }
            }
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
        
        shadowEnabled: root.shadowEnabled
        shadowColor: root.isBrightWall ? Qt.rgba(0,0,0,0.6) : Colours.palette.m3shadow
        shadowOpacity: root.shadowOpacity
        shadowBlur: root.shadowBlur
    }
}