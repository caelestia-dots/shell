import qs.services
import qs.utils
import Quickshell.Io
import QtQuick

Image {
    id: root

    property string path
    property string hash
    readonly property string cachePath: `${Paths.stringify(Paths.imagecache)}/${hash}@${width}x${height}.png`.slice(7)

    asynchronous: true
    cache: false
    fillMode: Image.PreserveAspectCrop
    sourceSize.width: width
    sourceSize.height: height

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
