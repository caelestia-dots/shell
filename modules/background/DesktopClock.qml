import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    implicitWidth: layout.implicitWidth + Appearance.padding.large * 2
    implicitHeight: layout.implicitHeight + Appearance.padding.large

    property real scale: Config.background.desktopClock.scale

    Behavior on scale {
        NumberAnimation {
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: Appearance.spacing.larger

        RowLayout {
            spacing: Appearance.spacing.small
            
            StyledText {
                text: Time.format(Config.services.useTwelveHourClock ? "hh" : "HH")
                font.pointSize: Appearance.font.size.extraLarge * 3 * root.scale
                font.weight: Font.Bold
                color: Colours.palette.m3primary 
            }

            StyledText {
                text: ":"
                font.pointSize: Appearance.font.size.extraLarge * 3 * root.scale
                color: Colours.palette.m3tertiary
            }

            StyledText {
                text: Time.format("mm")
                font.pointSize: Appearance.font.size.extraLarge * 3 * root.scale
                font.weight: Font.Bold
                color: Colours.palette.m3secondary
            }

            StyledText {
                visible: Config.services.useTwelveHourClock
                text: Time.format("A")
                font.pointSize: Appearance.font.size.large * root.scale
                color: Colours.palette.m3secondary
                Layout.alignment: Qt.AlignTop
                Layout.topMargin: Appearance.padding.large * 1.4 * root.scale // 1.4 aligns with clock top
            }
        }

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 4 * root.scale
            Layout.topMargin: Appearance.spacing.larger * root.scale
            Layout.bottomMargin: Appearance.spacing.larger * root.scale
            radius: Appearance.rounding.full
            color: Colours.palette.m3primary
            opacity: 0.8
        }

        ColumnLayout {
            spacing: 0
            
            StyledText {
                text: Time.format("MMMM").toUpperCase()
                font.pointSize: Appearance.font.size.large * root.scale
                font.letterSpacing: 4
                font.weight: Font.Bold
                color: Colours.palette.m3onSurface
            }

            StyledText {
                text: Time.format("dd")
                font.pointSize: Appearance.font.size.extraLarge * root.scale
                font.letterSpacing: 2
                font.weight: Font.Medium
                color: Colours.palette.m3secondary
            }

            StyledText {
                text: Time.format("dddd")
                font.pointSize: Appearance.font.size.larger * root.scale
                font.letterSpacing: 2
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }
}
