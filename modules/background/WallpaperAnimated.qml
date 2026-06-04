import QtQuick
import Quickshell
import qs.services

AnimatedImage {
    id: root

    required property string path
    readonly property bool ready: status === Image.Ready

    source: path
    asynchronous: true
    fillMode: Image.PreserveAspectCrop
    paused: !Wallpapers.animationsActiveOn((QsWindow.window as QsWindow)?.screen ?? null)
}
