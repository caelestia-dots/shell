import QtQuick

Item {
    property alias asynchronous: image.asynchronous
    property alias status: image.status
    property alias mipmap: image.mipmap
    property alias backer: image

    property real implicitSize
    readonly property real actualSize: Math.min(width, height)

    property url source

    onSourceChanged: {
        if (source?.toString().startsWith("image://icon/"))
            // Directly skip the path prop and treat like a normal Image component
            image.source = source;
        else if (source)
            image.path = source;
    }

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    CachingImage {
        id: image

        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
    }
}
