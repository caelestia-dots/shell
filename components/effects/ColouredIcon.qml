pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import Caelestia.Multimedia

IconImage {
    id: root

    required property color colour

    asynchronous: true

    layer.enabled: true
    layer.effect: Colouriser {
        sourceColor: analyser.dominantColour
        colorizationColor: root.colour

        VisualAnalyser {
            id: analyser

            source: root.source
        }
    }
}
