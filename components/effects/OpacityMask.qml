import QtQuick
import Quickshell

ShaderEffect {
    required property Item source
    required property Item maskSource

    fragmentShader: Quickshell.shellPath("assets/shaders/opacitymask.frag.qsb")
}
