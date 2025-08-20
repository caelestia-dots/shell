pragma ComponentBehavior: Bound

import Quickshell.Widgets
import QtQuick

IconImage {
    id: root

    required property color colour
    property color sourceColour
    property url lastSource

    asynchronous: true

    layer.enabled: true
    layer.effect: Colouriser {
        sourceColor: root.sourceColour
        colorizationColor: root.colour
    }

    layer.onEnabledChanged: {
        if (layer.enabled)
            canvas.requestPaint();
    }

    onStatusChanged: {
        if (layer.enabled && status === Image.Ready)
            canvas.requestPaint();
    }

    Canvas {
        id: canvas

        property int retryCount

        implicitWidth: 32
        implicitHeight: 32
        visible: false

        onPaint: {
            if (!root.layer.enabled)
                return;

            const ctx = getContext("2d");
            ctx.reset();
            ctx.drawImage(root.backer, 0, 0, width, height);

            const colours = {} as Object;
            const data = ctx.getImageData(0, 0, width, height).data;

            for (let i = 0; i < data.length; i += 4) {
                if (data[i + 3] === 0)
                    continue;

                const c = `${data[i]},${data[i + 1]},${data[i + 2]}`;
                if (colours.hasOwnProperty(c))
                    colours[c]++;
                else
                    colours[c] = 1;
            }

            // Canvas is empty, try again next frame
            if (retryCount < 5 && !Object.keys(colours).length) {
                retryCount++;
                Qt.callLater(() => requestPaint());
                return;
            }

            let max = 0;
            let maxColour = "0,0,0";
            for (const [colour, occurences] of Object.entries(colours)) {
                if (occurences > max) {
                    max = occurences;
                    maxColour = colour;
                }
            }

            const [r, g, b] = maxColour.split(",");
            root.sourceColour = Qt.rgba(r / 255, g / 255, b / 255, 1);
            retryCount = 0;
        }
    }
}
