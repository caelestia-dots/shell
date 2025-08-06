import qs.utils
import Quickshell
import Quickshell.Io
import QtQuick

Image {
    id: root

    property string path
    property string hash
    readonly property string cachePath: `${Paths.stringify(Paths.imagecache)}/${hash}@${effectiveWidth}x${effectiveHeight}.png`

    readonly property real effectiveScale: QsWindow.window?.devicePixelRatio ?? 1
    readonly property int effectiveWidth: Math.ceil(width * effectiveScale)
    readonly property int effectiveHeight: Math.ceil(height * effectiveScale)

    asynchronous: true
    fillMode: Image.PreserveAspectCrop
    sourceSize.width: effectiveWidth
    sourceSize.height: effectiveHeight

    onPathChanged: shaProc.exec(["sha256sum", Paths.strip(path)])

    onCachePathChanged: {
        if (hash)
            source = cachePath;
    }

    onStatusChanged: {
        if (source == cachePath && status === Image.Error)
            source = path;
        else if (source == path && status === Image.Ready) {
            Paths.mkdir(Paths.imagecache);
            const grabPath = cachePath;
            grabToImage(res => res.saveToFile(grabPath));
        }
    }

    Process {
        id: shaProc

        stdout: StdioCollector {
            onStreamFinished: root.hash = text.split(" ")[0]
        }
    }
}
