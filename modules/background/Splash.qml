import QtQuick
import QtQuick.Effects
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.services

StyledText {
    id: root

    readonly property list<string> command: Config.background.splash.command
    readonly property bool darkText: Colours.wallLuminance > 0.5
    property string splash

    text: splash
    visible: splash.length > 0
    color: darkText ? Colours.palette.m3surface : Colours.palette.m3onSurface
    font: Tokens.font.body.builders.medium.size(Math.round(Tokens.font.body.medium.pointSize * Config.background.splash.scale)).build()

    layer.enabled: !darkText
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Colours.palette.m3shadow
        shadowOpacity: 0.7
        shadowBlur: 0.4
    }

    Process {
        running: root.command.length > 0
        command: root.command
        stdout: StdioCollector {
            onStreamFinished: root.splash = text.trim()
        }
    }
}
