pragma Singleton

import "../config"
import "../utils"
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property list<string> colourNames: ["rosewater", "flamingo", "pink", "mauve", "red", "maroon", "peach", "yellow", "green", "teal", "sky", "sapphire", "blue", "lavender"]

    property bool showPreview: false
    property string scheme: "default"
    property string flavour: "mocha"
    property bool light: false
    readonly property M3Palette palette: current
    readonly property M3Palette current: M3Palette {
        // Default dark theme colors for greetd
        m3primary: "#89b4fa"
        m3onPrimary: "#1e1e2e"
        m3primaryContainer: "#45475a"
        m3onPrimaryContainer: "#cdd6f4"
        m3secondary: "#f5c2e7"
        m3onSecondary: "#1e1e2e"
        m3secondaryContainer: "#45475a"
        m3onSecondaryContainer: "#cdd6f4"
        m3tertiary: "#94e2d5"
        m3onTertiary: "#1e1e2e"
        m3tertiaryContainer: "#45475a"
        m3onTertiaryContainer: "#cdd6f4"
        m3error: "#f38ba8"
        m3onError: "#1e1e2e"
        m3errorContainer: "#45475a"
        m3onErrorContainer: "#cdd6f4"
        m3surface: "#1e1e2e"
        m3onSurface: "#cdd6f4"
        m3surfaceContainer: "#313244"
        m3onSurfaceVariant: "#a6adc8"
        m3outline: "#6c7086"
        m3outlineVariant: "#585b70"
        m3inverseSurface: "#cdd6f4"
        m3inverseOnSurface: "#1e1e2e"
        m3inversePrimary: "#89b4fa"
        m3scrim: "#11111b"
        m3shadow: "#11111b"
    }
    readonly property M3Palette preview: M3Palette {}
    readonly property Transparency transparency: Transparency {}

    function alpha(c: color, layer: bool): color {
        if (!transparency.enabled)
            return c;
        c = Qt.rgba(c.r, c.g, c.b, layer ? transparency.layers : transparency.base);
        if (layer)
            c.hsvValue = Math.max(0, Math.min(1, c.hslLightness + (light ? -0.2 : 0.2)));
        return c;
    }

    function on(c: color): color {
        if (c.hslLightness < 0.5)
            return Qt.hsla(c.hslHue, c.hslSaturation, 0.9, 1);
        return Qt.hsla(c.hslHue, c.hslSaturation, 0.1, 1);
    }

    function load(data: string, isPreview: bool): void {
        // Simplified for greetd - no dynamic loading
    }

    function setMode(mode: string): void {
        // Simplified for greetd - no mode switching
    }

    component Transparency: QtObject {
        readonly property bool enabled: false
        readonly property real base: 0.78
        readonly property real layers: 0.58
    }

    component M3Palette: QtObject {
        property color m3primary
        property color m3onPrimary
        property color m3primaryContainer
        property color m3onPrimaryContainer
        property color m3primaryFixed
        property color m3onPrimaryFixed
        property color m3primaryFixedDim
        property color m3onPrimaryFixedVariant
        property color m3secondary
        property color m3onSecondary
        property color m3secondaryContainer
        property color m3onSecondaryContainer
        property color m3secondaryFixed
        property color m3onSecondaryFixed
        property color m3secondaryFixedDim
        property color m3onSecondaryFixedVariant
        property color m3tertiary
        property color m3onTertiary
        property color m3tertiaryContainer
        property color m3onTertiaryContainer
        property color m3tertiaryFixed
        property color m3onTertiaryFixed
        property color m3tertiaryFixedDim
        property color m3onTertiaryFixedVariant
        property color m3error
        property color m3onError
        property color m3errorContainer
        property color m3onErrorContainer
        property color m3surface
        property color m3onSurface
        property color m3surfaceVariant
        property color m3onSurfaceVariant
        property color m3outline
        property color m3outlineVariant
        property color m3inverseSurface
        property color m3inverseOnSurface
        property color m3inversePrimary
        property color m3surfaceDim
        property color m3surfaceBright
        property color m3surfaceContainerLowest
        property color m3surfaceContainerLow
        property color m3surfaceContainer
        property color m3surfaceContainerHigh
        property color m3surfaceContainerHighest
        property color m3scrim
        property color m3shadow

        property color rosewater
        property color flamingo
        property color pink
        property color mauve
        property color red
        property color maroon
        property color peach
        property color yellow
        property color green
        property color teal
        property color sky
        property color sapphire
        property color blue
        property color lavender
    }
}