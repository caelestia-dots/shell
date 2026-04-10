import QtQuick
import Quickshell
import qs.utils

ShaderEffect {
    required property Item source
    required property Item maskSource

    fragmentShader: Paths.resolve(Quickshell.shellPath("assets/shaders/opacitymask.frag.qsb"))
}
