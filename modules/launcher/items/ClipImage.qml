import QtQuick
import Quickshell.Io
import qs.modules.launcher.services

// Decodes a clipboard image to the cache and shows it. When the entry changes, the previous
// image stays on screen until the new one is ready, so there is no blank flash in between.
Item {
    id: root

    required property var entry

    property int fillMode: Image.PreserveAspectCrop
    property int decodeSize // Max size to decode the image to, 0 for the original size
    property string loadedPath // The path a decode was last requested for
    property Image front: bufferA

    readonly property string path: Clipboard.imagePath(entry)

    signal loaded

    function load(): void {
        if (path === loadedPath)
            return;

        loadedPath = path;
        proc.exec(Clipboard.imageCommand(entry));
    }

    // Load into whichever buffer isn't on screen
    function show(): void {
        const back = front === bufferA ? bufferB : bufferA;
        back.source = `file://${loadedPath}`;
    }

    function swap(buffer: Image): void {
        if (buffer === front || buffer.status !== Image.Ready)
            return;

        const old = front;
        front = buffer;
        old.source = "";
        loaded();
    }

    onPathChanged: load()
    Component.onCompleted: load()

    Image {
        id: bufferA

        anchors.fill: parent

        visible: root.front === bufferA
        asynchronous: true
        cache: false
        fillMode: root.fillMode
        sourceSize: root.decodeSize > 0 ? Qt.size(root.decodeSize, root.decodeSize) : Qt.size(0, 0)
        onStatusChanged: root.swap(bufferA)
    }

    Image {
        id: bufferB

        anchors.fill: parent

        visible: root.front === bufferB
        asynchronous: true
        cache: false
        fillMode: root.fillMode
        sourceSize: root.decodeSize > 0 ? Qt.size(root.decodeSize, root.decodeSize) : Qt.size(0, 0)
        onStatusChanged: root.swap(bufferB)
    }

    Process {
        id: proc

        onExited: code => {
            if (code === 0)
                root.show();
        }
    }
}
