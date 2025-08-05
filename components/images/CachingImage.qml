import qs.utils
import Quickshell.Io
import QtQuick
import Quickshell

Image {
    id: root

    property string path
    property string hash
    property string cachePath

    readonly property real effectiveScale: QsWindow.window ? QsWindow.window.devicePixelRatio : Screen.devicePixelRatio
    readonly property int effectiveWidth: Math.round(width * effectiveScale)
    readonly property int effectiveHeight: Math.round(height * effectiveScale)

    asynchronous: true
    fillMode: Image.PreserveAspectCrop
    sourceSize.width: effectiveWidth
    sourceSize.height: effectiveHeight

    onHashChanged: {
        cachePath = `${Paths.imagecache}/${hash}@${effectiveWidth}x${effectiveHeight}.png`;
    }
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
