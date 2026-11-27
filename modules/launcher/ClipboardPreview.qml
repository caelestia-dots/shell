pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Services
import "services"
import qs.components
import qs.components.controls
import qs.services

// Ported from Caelestia PR #1298's ClipboardPreview.qml: the selected image
// entry shown at full size in its own panel beside the launcher, decoded
// from cliphist on the fly.
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

        // implicitWidth/Height are the loaded image's intrinsic size;
        // sourceSize is never set here, so it would read 0 forever.
        if (previewImage.status === Image.Ready && previewImage.implicitHeight > 0) {
            const aspectRatio = previewImage.implicitWidth / previewImage.implicitHeight;
            const maxHeight = 600;
            const minHeight = 200;
            const availableWidth = width - (Tokens.padding.medium * 2);
            const calculatedHeight = (availableWidth / aspectRatio) + (Tokens.padding.medium * 2);
            const newHeight = Math.max(minHeight, Math.min(maxHeight, calculatedHeight));
            lastValidHeight = newHeight;
            return newHeight;
        }

        return lastValidHeight;
    }

    property string pendingImageId: ""

    function decodeImageToDataUrl(): void {
        if (!currentItem?.modelData?.isImage)
            return;
        const id = currentItem.modelData.id;
        // The command cannot change while a process runs; queue the request
        // for the exit handler instead of killing mid-stream.
        if (decodeProcess.running) {
            pendingImageId = id;
            return;
        }
        decodeProcess.decodeId = id;
        decodeProcess.command = ["sh", "-c", `cliphist decode ${id} | base64 -w 0`];
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

        // A decode queued for the previous row is stale now.
        pendingImageId = "";
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

        property string decodeId: ""

        // The collector's text is only guaranteed at streamFinished (it can
        // still be empty at onExited), so the publish lives here, guarded
        // against a decode for a row that is no longer selected.
        stdout: StdioCollector {
            onStreamFinished: {
                const row = root.currentItem?.modelData;
                if (!row || String(row.id) !== decodeProcess.decodeId)
                    return;
                const b64 = String(text).trim();
                root.imageDataUrl = b64 ? "data:" + (row.mime || "image/png") + ";base64," + b64 : "";
                root.loadingImage = false;
            }
        }

        onExited: { // qmllint disable signal-handler-parameters
            if (root.pendingImageId !== "") {
                root.pendingImageId = "";
                root.decodeImageToDataUrl();
            }
        }
    }

    Process {
        id: decodeHtmlProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.decodingHtml = false;
                const row = root.currentItem?.modelData;
                if (!row?.needsDecodeForUrl)
                    return;
                const srcMatch = String(text).match(/<img[^>]+src\s*=\s*["']([^"']+)["']/i);
                if (srcMatch?.[1])
                    root.extractedImageUrl = srcMatch[1];
            }
        }
    }

    Process {
        id: copyGrabbedImageProcess

        onExited: (exitCode, exitStatus) => { // qmllint disable signal-handler-parameters
            if (exitCode === 0) {
                Toaster.toast(Tr.tr("Image copied"), Tr.tr("Copied image to clipboard"), "image");
                Clipboard.refresh();
            } else {
                Toaster.toast(Tr.tr("Copy failed"), Tr.tr("Failed to copy image"), "error");
            }
        }
    }

    Behavior on height {
        enabled: root.targetHeight === 0 || root.height === 0 || Math.abs(root.targetHeight - root.height) > 5

        Anim {
            type: Anim.DefaultSpatial
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
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
                        duration: Tokens.anim.durations.small
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
                    duration: Tokens.anim.durations.small
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
                    duration: Tokens.anim.durations.small
                    easing.type: Easing.InOutQuad
                }
            }

            StyledText {
                anchors.centerIn: parent
                text: root.loadingImage ? Tr.tr("Loading...") : (root.decodingHtml ? Tr.tr("Loading...") : "")
                horizontalAlignment: Text.AlignHCenter
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.medium
                opacity: text !== "" ? 1 : 0
                visible: opacity > 0

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }
        }
    }

    IconButton {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Tokens.padding.medium + Tokens.padding.small
        anchors.rightMargin: Tokens.padding.medium + Tokens.padding.small
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
            previewImage.grabToImage(function(result) {
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
