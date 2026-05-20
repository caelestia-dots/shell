import QtQuick
import Quickshell

AnimatedImage {
    id: root

    property string path

    asynchronous: true
    fillMode: AnimatedImage.PreserveAspectCrop
    source: path || ""
    playing: true

    onSourceChanged: playing = true
}