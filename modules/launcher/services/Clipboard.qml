pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import qs.config

Singleton {
    id: root

    property var history: []
    property var pinnedItems: []
    property string pendingImageUrl: ""
    property string pendingImageMime: ""

    function loadPinnedItems(): void {
        const pinned = Config.launcher.pinnedClipboardItems || [];
        root.pinnedItems = pinned;
    }

    function savePinnedItems(): void {
        Config.launcher.pinnedClipboardItems = root.pinnedItems;
        Config.save();
    }

    function refresh(): void {
        cliphistProcess.running = true;
    }

    function getMimeTypeFromUrl(url): string {
        if (url.match(/\.jpe?g$/i))
            return "image/jpeg";
        if (url.match(/\.png$/i))
            return "image/png";
        if (url.match(/\.gif$/i))
            return "image/gif";
        if (url.match(/\.webp$/i))
            return "image/webp";
        return "image/png";
    }

    function copyImageFromUrl(url): void {
        if (copyImageProcess.running) {
            return;
        }

        const escapedUrl = url.replace(/'/g, "'\\''");
        const mimeType = getMimeTypeFromUrl(url);

        root.pendingImageUrl = escapedUrl;
        root.pendingImageMime = mimeType;

        const cmd = `curl -sL '${escapedUrl}' | wl-copy --type '${mimeType}'`;
        copyImageProcess.command = ["sh", "-c", cmd];
        copyImageProcess.running = true;
    }

    function copyToClipboard(item): void {
        const input = item.id + "\t" + item.content;
        Quickshell.execDetached(["sh", "-c", `echo '${input}' | cliphist decode | wl-copy`]);
        Toaster.toast("Copied to clipboard", item.preview, "content_paste");
    }

    function deleteItem(item): void {
        const escapedId = item.id.replace(/'/g, "'\\''");
        deleteProcess.command = ["sh", "-c", `printf '%s' '${escapedId}' | cliphist delete`];
        deleteProcess.running = true;
    }

    function togglePin(item): void {
        const index = root.pinnedItems.indexOf(item.id);
        if (index !== -1) {
            root.pinnedItems.splice(index, 1);
        } else {
            root.pinnedItems.push(item.id);
        }
        savePinnedItems();
        root.refresh();
    }

    function clearAll(category): void {
        const itemsToDelete = root.history.filter(item => {
            if (item.isPinned)
                return false;
            if (category === "images")
                return item.isImage;
            if (category === "misc")
                return !item.isImage;
            return true;
        });

        if (itemsToDelete.length === 0) {
            Toaster.toast("Nothing to clear", "No non-pinned items in this category", "info");
            return;
        }

        const deleteCommands = itemsToDelete.map(item => {
            const escapedId = item.id.replace(/'/g, "'\\''");
            return `printf '%s' '${escapedId}' | cliphist delete`;
        }).join('; ');

        deleteProcess.command = ["sh", "-c", deleteCommands];
        deleteProcess.running = true;

        const categoryName = category === "all" ? "All" : category === "images" ? "Images" : "Misc";
        const count = itemsToDelete.length;
        Toaster.toast("Clipboard cleared", `${count} ${categoryName.toLowerCase()} item${count !== 1 ? 's' : ''} deleted (pinned items preserved)`, "delete_sweep");
    }

    function parseClipboardItem(line, index): var {
        const parts = line.split('\t');
        const id = parts[0] || "";
        const content = parts.slice(1).join('\t') || line;
        const isImage = content.includes("[[ binary data");
        const hasHtmlImage = !isImage && content.includes("<img");
        const isDirectImageUrl = !isImage && !hasHtmlImage && content.match(/^https?:\/\/.*\.(png|jpg|jpeg|gif|webp|bmp)/i);

        return {
            id: id,
            content: content,
            preview: content.substring(0, 100),
            isPinned: root.pinnedItems.includes(id),
            isImage: isImage,
            imageUrl: isDirectImageUrl ? content.trim() : "",
            hasImageUrl: hasHtmlImage || isDirectImageUrl,
            needsDecodeForUrl: hasHtmlImage,
            index: index
        };
    }

    Component.onCompleted: {
        loadPinnedItems();
        refresh();
    }

    Process {
        id: cliphistProcess

        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    root.history = text.trim().split('\n').map((line, index) => root.parseClipboardItem(line, index));
                } else {
                    // Empty clipboard - clear history
                    root.history = [];
                }
            }
        }
    }

    Process {
        id: copyImageProcess

        stdout: StdioCollector {}
        onExited: (exitCode, exitStatus) => { // qmllint disable signal-handler-parameters
            if (exitCode === 0) {
                Toaster.toast("Image copied", "Downloaded and copied image to clipboard", "image");
                Qt.callLater(() => root.refresh());
            } else {
                Toaster.toast("Copy failed", "Failed to download or copy image", "error");
            }
        }
    }

    Process {
        id: deleteProcess

        stdout: StdioCollector {}
        onExited: root.refresh() // qmllint disable signal-handler-parameters
    }
}
