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

    Behavior on offset {
        Anim {}
    }
    Behavior on opacity {
        Anim {}
    }

    ServiceRef {
        id: cavaRef
        service: Audio.cava
    }

    ShaderEffectSource {
        id: wallpaperSource
        sourceItem: root.wallpaper
        live: true
    }

    ShaderEffectSource {
        id: maskSource
        sourceItem: bars
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
        y: root.offset
        height: parent.height - root.offset * 2
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Visibilities.bars.get(root.screen).exclusiveZone + Appearance.spacing.small * Config.background.visualiser.spacing
        anchors.margins: Config.border.thickness
        active: root.opacity > 0 && Config.background.visualiser.blur
        sourceComponent: MultiEffect {
            source: wallpaperSource
            maskSource: maskSource
            maskEnabled: true
            maskSpreadAtMax: 0
            maskSpreadAtMin: 0
            maskThresholdMin: 0.67 // eliminates blur spreading out of bounds
            blurEnabled: true
            blur: 1
            blurMax: 32
            autoPaddingEnabled: false
            shadowEnabled: false
        }
    }

    Item {
        id: canvasWrapper
        anchors.fill: parent
        y: root.offset
        height: parent.height - root.offset * 2
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Visibilities.bars.get(root.screen).exclusiveZone + Appearance.spacing.small * Config.background.visualiser.spacing
        anchors.margins: Config.border.thickness
        // z: 0
        VisualiserBars {
            id: bars
            anchors.fill: parent
            layer.enabled: true

            barCount: Config.services.visualiserBars
            spacing: Appearance.spacing.small * Config.background.visualiser.spacing
            smoothing: 1 - (0.95 * Config.background.visualiser.smoothing)
            curvature: Config.background.visualiser.curvature

            barRadius: Appearance.rounding.small * Config.background.visualiser.rounding

            barColorTop: root.barColorTop
            barColorBottom: root.barColorBottom

            audioValues: Audio.cava.values
        }
    }
}
