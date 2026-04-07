pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Caelestia
import "services"
import qs.components
import qs.components.controls
import qs.services
import qs.config

Item {
    id: root

    property var currentItem: null
    property bool shouldShow: false

    property string imageDataUrl: ""
    property string extractedImageUrl: ""
    property bool loadingImage: false
    property bool decodingHtml: false
    property bool imageLoadError: false

    readonly property bool hasImage: {
        if (!currentItem?.modelData || imageLoadError)
            return false;
        const data = currentItem.modelData;
        return data.isImage === true || data.hasImageUrl === true;
    }

    readonly property string imageSource: {
        if (!currentItem?.modelData)
            return "";
        const data = currentItem.modelData;

        if (data.isImage === true && imageDataUrl !== "")
            return imageDataUrl;
        if (data.hasImageUrl === true)
            return extractedImageUrl || data.imageUrl || "";

        return "";
    }

    readonly property real rounding: Config.border.rounding

    property real lastValidHeight: 0

    readonly property real targetHeight: {
        if (!shouldShow || !hasImage) {
            return 0;
        }

        if (previewImage.status === Image.Ready && previewImage.sourceSize.height > 0) {
            const aspectRatio = previewImage.sourceSize.width / previewImage.sourceSize.height;
            const maxHeight = 600;
            const minHeight = 200;
            const availableWidth = width - (Appearance.padding.normal * 2);
            const calculatedHeight = (availableWidth / aspectRatio) + (Appearance.padding.normal * 2);
            const newHeight = Math.max(minHeight, Math.min(maxHeight, calculatedHeight));
            lastValidHeight = newHeight;
            return newHeight;
        }

        return lastValidHeight;
    }

    function decodeImageToDataUrl(): void {
        if (!currentItem?.modelData?.isImage)
            return;
        decodeProcess.command = ["sh", "-c", `cliphist decode ${currentItem.modelData.id} | base64 -w 0`];
        decodeProcess.running = true;
    }

    function decodeHtmlForImageUrl(): void {
        if (!currentItem?.modelData?.needsDecodeForUrl)
            return;
        decodeHtmlProcess.command = ["cliphist", "decode", currentItem.modelData.id];
        decodeHtmlProcess.running = true;
    }

    width: 400

    height: targetHeight

    enabled: shouldShow && hasImage

    visible: height > (rounding * 2)

    clip: false

    onCurrentItemChanged: {
        const wasImage = imageDataUrl !== "" || extractedImageUrl !== "";
        const isImage = currentItem?.modelData?.isImage === true || currentItem?.modelData?.hasImageUrl === true || currentItem?.modelData?.imageUrl;

        if (wasImage && !isImage)
            lastValidHeight = 0;

        imageDataUrl = "";
        loadingImage = false;
        extractedImageUrl = "";
        imageLoadError = false;
        decodingHtml = false;

        if (currentItem && currentItem.modelData) {
            const data = currentItem.modelData;
            if (data.isImage === true) {
                loadingImage = true;
                decodeImageToDataUrl();
            } else if (data.needsDecodeForUrl === true) {
                decodingHtml = true;
                decodeHtmlForImageUrl();
            } else if (data.imageUrl) {
                extractedImageUrl = data.imageUrl;
            }
        }
    }

    Process {
        id: decodeProcess

        stdout: StdioCollector {}
        onExited: { // qmllint disable signal-handler-parameters
            if (root.currentItem?.modelData?.isImage) {
                const b64 = String(stdout.text).trim(); // qmllint disable missing-property
                if (b64)
                    root.imageDataUrl = "data:image/png;base64," + b64;
            }
            root.loadingImage = false;
        }
    }

    Process {
        id: decodeHtmlProcess

        stdout: StdioCollector {}
        onExited: { // qmllint disable signal-handler-parameters
            root.decodingHtml = false;
            if (root.currentItem?.modelData?.needsDecodeForUrl) {
                const srcMatch = String(stdout.text).match(/<img[^>]+src\s*=\s*["']([^"']+)["']/i); // qmllint disable missing-property
                if (srcMatch?.[1])
                    root.extractedImageUrl = srcMatch[1];
            }
        }
    }

    Process {
        id: copyGrabbedImageProcess

        onExited: (exitCode, exitStatus) => { // qmllint disable signal-handler-parameters
            if (exitCode === 0) {
                Toaster.toast("Image copied", "Copied image to clipboard", "image");
                Clipboard.refresh(); // qmllint disable missing-property
            } else {
                Toaster.toast("Copy failed", "Failed to copy image", "error");
            }
        }
    }

    Behavior on height {
        enabled: root.targetHeight === 0 || root.height === 0 || Math.abs(root.targetHeight - root.height) > 5

        Anim {
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Appearance.padding.normal
        spacing: 0

        Item {
            id: imageContainer

            Layout.fillWidth: true
            Layout.fillHeight: true

            property string pendingSource: ""

            onPendingSourceChanged: {
                if (pendingSource !== "")
                    fadeOutIn.restart();
            }

            Image {
                id: previewImage

                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: false
                visible: opacity > 0
                opacity: (root.shouldShow && root.hasImage && status === Image.Ready) ? 1 : 0

                onStatusChanged: {
                    if (status === Image.Error)
                        root.imageLoadError = true;
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.anim.durations.small
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            Connections {
                function onImageSourceChanged() {
                    imageContainer.pendingSource = root.imageSource;
                }

                target: root
            }

            SequentialAnimation {
                id: fadeOutIn

                NumberAnimation {
                    target: previewImage
                    property: "opacity"
                    to: 0
                    duration: Appearance.anim.durations.small
                    easing.type: Easing.InOutQuad
                }

                ScriptAction {
                    script: {
                        previewImage.source = imageContainer.pendingSource;
                        imageContainer.pendingSource = "";
                    }
                }

                NumberAnimation {
                    target: previewImage
                    property: "opacity"
                    to: 1
                    duration: Appearance.anim.durations.small
                    easing.type: Easing.InOutQuad
                }
            }

            StyledText {
                anchors.centerIn: parent
                text: root.loadingImage ? "Loading..." : (root.decodingHtml ? "Loading..." : "")
                horizontalAlignment: Text.AlignHCenter
                color: Colours.palette.m3onSurfaceVariant
                opacity: text !== "" ? 1 : 0
                visible: opacity > 0

                Behavior on opacity {
                    Anim {
                        duration: Appearance.anim.durations.small
                        easing.bezierCurve: Appearance.anim.curves.standard
                    }
                }
            }
        }
    }

    IconButton {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Appearance.padding.normal + Appearance.padding.small
        anchors.rightMargin: Appearance.padding.normal + Appearance.padding.small
        z: 10
        icon: "content_copy"
        type: IconButton.Filled
        visible: {
            if (!root.currentItem?.modelData)
                return false;
            const data = root.currentItem.modelData;
            return (data.hasImageUrl === true || data.needsDecodeForUrl === true) && root.extractedImageUrl !== "" && previewImage.status === Image.Ready;
        }
        onClicked: {
            previewImage.grabToImage(function (result) {
                const tempPath = "/tmp/quickshell-clipboard-grab-" + Date.now() + ".png";
                if (result.saveToFile(tempPath)) {
                    const cmd = `wl-copy < '${tempPath}' --type image/png && rm '${tempPath}'`;
                    copyGrabbedImageProcess.command = ["sh", "-c", cmd];
                    copyGrabbedImageProcess.running = true;
                }
            });
        }
    }
}
