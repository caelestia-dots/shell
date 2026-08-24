import QtQuick
import qs.components.effects

Item {
    id: iconItem

    required property string url
    required property color colour
    property int size: 18

    implicitWidth: size
    implicitHeight: size

    Image {
        id: img
        anchors.fill: parent
        source: iconItem.url
        sourceSize: Qt.size(iconItem.size, iconItem.size)
        fillMode: Image.PreserveAspectFit
        smooth: true
        asynchronous: true
        visible: status !== Image.Error

        layer.enabled: true
        layer.effect: Colouriser {
            sourceColor: analyser.dominantColour
            colorizationColor: iconItem.colour
        }

        layer.onEnabledChanged: {
            if (layer.enabled && img.status === Image.Ready)
                analyser.requestUpdate();
        }

        onStatusChanged: {
            if (layer.enabled && img.status === Image.Ready)
                analyser.requestUpdate();
        }
    }

    ImageAnalyser {
        id: analyser
        sourceItem: img
    }
}
