pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Caelestia.Services
import Quickshell
import QtQuick
import QtQuick.Effects
import Caelestia.Internal

Item {
    id: root
    anchors.fill: parent

    required property ShellScreen screen
    required property Wallpaper wallpaper

    readonly property bool shouldBeActive: Config.background.visualiser.enabled && (!Config.background.visualiser.autoHide || (Hypr.monitorFor(screen)?.activeWorkspace?.toplevels?.values.every(t => t.lastIpcObject?.floating) ?? true))
    property real offset: shouldBeActive ? 0 : screen.height * 0.2
    opacity: shouldBeActive ? 1 : 0

    Behavior on opacity {
        Anim {}
    }

    readonly property bool shouldLoadBars: root.opacity > 0

    ServiceRef {
        id: cavaRefVis
        service: Audio.cava
    }

    ShaderEffectSource {
        id: wallpaperSource
        sourceItem: root.wallpaper
        live: true
    }

    ShaderEffectSource {
        id: barsSource
        sourceItem: barsLoader
        live: true
    }

    property color barColorTop: Qt.alpha(Colours.palette.m3primary, 0.7)
    property color barColorBottom: Qt.alpha(Colours.palette.m3inversePrimary, 0.7)

    Behavior on barColorTop {
        CAnim {}
    }
    Behavior on barColorBottom {
        CAnim {}
    }

    property real barRadius: Appearance.rounding.small * Config.background.visualiser.rounding

    Loader {
        anchors.fill: parent
        active: root.shouldLoadBars && Config.background.visualiser.blur && barsLoader.item

        sourceComponent: MultiEffect {
            source: wallpaperSource
            maskSource: barsSource
            maskEnabled: true
            maskSpreadAtMax: 0
            maskSpreadAtMin: 0
            maskThresholdMin: 0.67
            blurEnabled: true
            blur: 1
            blurMax: 32
            autoPaddingEnabled: false
            shadowEnabled: false
        }
    }

    Loader {
        id: barsLoader
        anchors.fill: parent
        active: root.shouldLoadBars

        sourceComponent: Item {
            anchors.fill: parent
            anchors.topMargin: Config.border.thickness + root.offset
            anchors.bottomMargin: Config.border.thickness - root.offset
            anchors.leftMargin: Visibilities.bars.get(root.screen).exclusiveZone + Appearance.spacing.small * Config.background.visualiser.spacing
            anchors.margins: Config.border.thickness

            Behavior on anchors.topMargin {
                Anim {}
            }
            Behavior on anchors.bottomMargin {
                Anim {}
            }

            VisualiserBars {

                anchors.fill: parent
                barCount: Config.services.visualiserBars
                spacing: Appearance.spacing.small * Config.background.visualiser.spacing
                smoothing: Config.background.visualiser.smoothing
                curvature: Config.background.visualiser.curvature
                barRadius: Appearance.rounding.small * Config.background.visualiser.rounding
                barColorTop: root.barColorTop
                barColorBottom: root.barColorBottom
                animationDuration: Appearance.anim.durations.small
                audioValues: Audio.cava.values
            }
        }
    }
}
