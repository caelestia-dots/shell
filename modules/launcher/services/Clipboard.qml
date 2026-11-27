pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Services

// Ported from Caelestia PR #1298's services/Clipboard.qml. The pinned list
// lives in a small JSON side-file instead of LauncherConfig, which is
// compiled into the caelestia-shell package here and cannot grow new keys.
Singleton {
    id: root

    // Shell state lives in XDG_STATE_HOME (notifs, apps.sqlite, ...); the
    // pin list joins it instead of cluttering .config with runtime files.
    readonly property string pinsPath: `${Quickshell.env("XDG_STATE_HOME") || `${Quickshell.env("HOME")}/.local/state`}/caelestia/clipboard-pins.json`

    property var history: []
    property var pinnedItems: []

    function loadPinnedItems(): void {
        try {
            const raw = pinsFile.text();
            const parsed = JSON.parse(raw);
            root.pinnedItems = Array.isArray(parsed) ? parsed : [];
        } catch (e) {
            root.pinnedItems = [];
        }
    }

    function savePinnedItems(): void {
        pinsFile.setText(JSON.stringify(root.pinnedItems) + "\n");
    }

    function refresh(): void {
        cliphistProcess.running = true;
    }

    function copyToClipboard(item: var): void {
        const input = item.id + "\t" + item.content;
        Quickshell.execDetached(["sh", "-c", `echo '${input}' | cliphist decode | wl-copy`]);
        Toaster.toast(Tr.tr("Copied to clipboard"), item.preview, "content_paste");
    }

    // Enter pastes into the window the launcher opened over, as Omacale's
    // clipboard does: put the entry back on the clipboard, wait for the
    // launcher to close and focus to return, then ydotool ctrl+v. Shift keeps
    // the PR's copy-only behaviour.
    function pasteIntoWindow(item: var): void {
        const escapedId = item.id.replace(/'/g, "'\\''");
        let set;
        if (item.isImage) {
            set = `printf '%s\\t' '${escapedId}' | cliphist decode | wl-copy --type '${item.mime}'`;
        } else {
            set = `printf '%s\\t' '${escapedId}' | cliphist decode | wl-copy`;
        }
        Quickshell.execDetached(["sh", "-c", `${set}; sleep 0.5; ydotool key 29:1 47:1 47:0 29:0`]);
    }

    // Alt+Enter: open the entry where something can show it — an image in
    // the image viewer, a URL in the browser. Plain text has no home.
    function openItem(item: var): void {
        let target = "";
        if (item.isImage) {
            target = `/tmp/caelestia-clipboard-${item.id}.png`;
            const escapedId = item.id.replace(/'/g, "'\\''");
            openProcess.command = ["sh", "-c", `printf '%s\\t' '${escapedId}' | cliphist decode > '${target}'; xdg-open '${target}'`];
            openProcess.running = true;
            return;
        } else if (item.imageUrl) {
            target = item.imageUrl;
        } else if (/^https?:\/\//.test(item.content.trim())) {
            target = item.content.trim().split(/\s+/)[0];
        }

        if (target === "") {
            Toaster.toast(Tr.tr("Nothing to open"), Tr.tr("Plain text entries can only be copied or pasted"), "info");
            return;
        }
        Quickshell.execDetached(["sh", "-c", `xdg-open '${target.replace(/'/g, "'\\''")}'`]);
    }

    function deleteItem(item: var): void {
        const escapedId = item.id.replace(/'/g, "'\\''");
        deleteProcess.command = ["sh", "-c", `printf '%s' '${escapedId}' | cliphist delete`];
        deleteProcess.running = true;
    }

    function togglePin(item: var): void {
        const index = root.pinnedItems.indexOf(item.id);
        if (index !== -1) {
            // quickshell's JS engine has no Array.toSpliced.
            root.pinnedItems = root.pinnedItems.filter((_, i) => i !== index);
        } else {
            root.pinnedItems = [...root.pinnedItems, item.id];
        }
        savePinnedItems();
        root.refresh();
    }

    function clearAll(category: string): void {
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
            Toaster.toast(Tr.tr("Nothing to clear"), Tr.tr("No non-pinned items in this category"), "info");
            return;
        }

        const deleteCommands = itemsToDelete.map(item => {
            const escapedId = item.id.replace(/'/g, "'\\''");
            return `printf '%s' '${escapedId}' | cliphist delete`;
        }).join('; ');

        deleteProcess.command = ["sh", "-c", deleteCommands];
        deleteProcess.running = true;

        const categoryName = category === "all" ? Tr.tr("All") : category === "images" ? Tr.tr("Images") : Tr.tr("Misc");
        const count = itemsToDelete.length;
        Toaster.toast(Tr.tr("Clipboard cleared"), Tr.tr("%1 %2 item(s) deleted (pinned items preserved)").arg(count).arg(categoryName.toLowerCase()), "delete_sweep");
    }

    function parseClipboardItem(line: string, index: int): var {
        const parts = line.split('\t');
        const id = parts[0] || "";
        const content = parts.slice(1).join('\t') || line;
        const isImage = content.includes("[[ binary data");
        const hasHtmlImage = !isImage && content.includes("<img");
        const isDirectImageUrl = !isImage && !hasHtmlImage && content.match(/^https?:\/\/.*\.(png|jpg|jpeg|gif|webp|bmp)/i);
        // cliphist previews images as "[[ binary data 310 KiB png 1359x675 ]]"
        // — the format is the extension, not a mime type.
        const mime = isImage ? `image/${content.match(/\[\[\s*binary data.*?\s(png|jpe?g|gif|webp|bmp)/i)?.[1]?.toLowerCase() ?? "png"}` : "";

        return {
            id: id,
            content: content,
            preview: isImage ? `${mime.replace("image/", "")} image` : content.substring(0, 100),
            mime: mime,
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

    FileView {
        id: pinsFile

        path: root.pinsPath
        watchChanges: false

        onLoadFailed: {
            // First run: no pins yet, nothing to load.
        }
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
        id: openProcess

        stdout: StdioCollector {}
    }

    Process {
        id: deleteProcess

        stdout: StdioCollector {}
        onExited: root.refresh() // qmllint disable signal-handler-parameters
    }
}
