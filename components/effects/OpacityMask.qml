import Quickshell
import QtQuick

ShaderEffect {
    required property Item source
    required property Item maskSource
    readonly property string shellDir: Quickshell.shellDir

    fragmentShader: Qt.resolvedUrl(`${shellDir}/assets/shaders/opacitymask.frag.qsb`)
}
