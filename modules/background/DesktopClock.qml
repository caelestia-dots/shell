pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root

    required property Item wallpaper
    required property real absX
    required property real absY

    property real scale: Config.background.desktopClock.scale
    readonly property bool bgEnabled: Config.background.desktopClock.background.enabled
    readonly property bool blurEnabled: bgEnabled && Config.background.desktopClock.background.blur
    readonly property bool invertColors: Config.background.desktopClock.invertColors
    readonly property bool useLightSet: Colours.light ? !invertColors : invertColors
    readonly property color safePrimary: useLightSet ? Colours.palette.m3primaryContainer : Colours.palette.m3primary
    readonly property color safeSecondary: useLightSet ? Colours.palette.m3secondaryContainer : Colours.palette.m3secondary
    readonly property color safeTertiary: useLightSet ? Colours.palette.m3tertiaryContainer : Colours.palette.m3tertiary

    implicitWidth: layout.implicitWidth + (Appearance.padding.large * 4 * root.scale)
    implicitHeight: layout.implicitHeight + (Appearance.padding.large * 2 * root.scale)

    Item {
        id: clockContainer

        anchors.fill: parent

        layer.enabled: Config.background.desktopClock.shadow.enabled
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Colours.palette.m3shadow
            shadowOpacity: Config.background.desktopClock.shadow.opacity
            shadowBlur: Config.background.desktopClock.shadow.blur
        }

        Loader {
            anchors.fill: parent
            active: root.blurEnabled

            sourceComponent: MultiEffect {
                source: ShaderEffectSource {
                    sourceItem: root.wallpaper
                    sourceRect: Qt.rect(root.absX, root.absY, root.width, root.height)
                }
                maskSource: backgroundPlate
                maskEnabled: true
                blurEnabled: true
                blur: 1
                blurMax: 64
                autoPaddingEnabled: false
            }
        }

        StyledRect {
            id: backgroundPlate

            visible: root.bgEnabled
            anchors.fill: parent
            radius: Appearance.rounding.large * root.scale
            opacity: Config.background.desktopClock.background.opacity
            color: Colours.palette.m3surface

            layer.enabled: root.blurEnabled
        }

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
                    Layout.topMargin: -Appearance.padding.large * 1.5 * root.scale
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
                }
            }

            StyledRect {
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
                }
            }
        }
    }

    Behavior on scale {
        Anim {
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }
    
    Behavior on implicitWidth {
        Anim {
            duration: Appearance.anim.durations.small
        }
    }
}