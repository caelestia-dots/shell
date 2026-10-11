pragma ComponentBehavior: Bound

import "items"
import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.Models
import qs.components.controls
import qs.services
import qs.utils

PathView {
    id: root

    required property SearchBar search
    required property var screenState
    required property var panels
    required property var content

    property string currentDir: Paths.wallsdir

    function navigateTo(path: string): void {
        const rootPath = Paths.wallsdir;
        if (path !== rootPath && !path.startsWith(`${rootPath}/`))
            return;

        currentDir = path;
        currentIndex = 0;
    }

    function navigateUp(): void {
        if (currentDir === Paths.wallsdir)
            return;

        const parent = currentDir.slice(0, currentDir.lastIndexOf("/"));
        navigateTo(parent.length < Paths.wallsdir.length ? Paths.wallsdir : parent);
    }

    function activateEntry(entry: var): bool {
        if (entry.isDir) {
            navigateTo(entry.path);
            return false;
        }

        if (Colours.scheme === "dynamic" && entry.path !== Wallpapers.actualCurrent)
            Wallpapers.previewColourLock = true;

        Wallpapers.setWallpaper(entry.path);
        screenState.launcher = false;
        return true;
    }

    function activateCurrent(): bool {
        if (!currentItem)
            return false;

        return activateEntry((currentItem as WallpaperItem).modelData);
    }

    readonly property int itemWidth: Tokens.sizes.launcher.wallpaperWidth * 0.8 + Tokens.padding.medium * 2

    readonly property int numItems: {
        const screen = (QsWindow.window as QsWindow)?.screen;
        if (!screen)
            return 0;

        // Screen width - 4x outer rounding - 2x max side thickness (cause centered)
        const barMargins = Math.max(Config.border.thickness, panels.bar.implicitWidth);
        let outerMargins = 0;
        if (panels.popouts.hasCurrent && panels.popouts.currentCenter + panels.popouts.nonAnimHeight / 2 > screen.height - content.implicitHeight - Config.border.thickness * 2)
            outerMargins = panels.popouts.nonAnimWidth;
        if ((screenState.utilities || screenState.sidebar) && panels.utilities.implicitWidth > outerMargins)
            outerMargins = panels.utilities.implicitWidth;
        const maxWidth = screen.width - Config.border.rounding * 4 - (barMargins + outerMargins) * 2;

        if (maxWidth <= 0)
            return 0;

        const maxItemsOnScreen = Math.floor(maxWidth / itemWidth);
        const visible = Math.min(maxItemsOnScreen, Config.launcher.maxWallpapers, scriptModel.values.length);

        if (visible === 2)
            return 1;
        if (visible > 1 && visible % 2 === 0)
            return visible - 1;
        return visible;
    }

    FileSystemModel {
        id: folders

        path: root.currentDir
        filter: FileSystemModel.Dirs
        recursive: false
    }

    model: ScriptModel {
        id: scriptModel

        readonly property string search: root.search.text.split(" ").slice(1).join(" ")

        values: {
            const foldersInSearch = folders.entries.filter(folder =>
                !search || folder.name.toLowerCase().includes(search.toLowerCase())
            );
            const imagesInSearch = Wallpapers.query(search).filter(image =>
                image.parentDir === root.currentDir
            );

            const parentEntry = root.currentDir === Paths.wallsdir ? [] : [{
                path: root.currentDir.slice(0, root.currentDir.lastIndexOf("/")),
                relativePath: "..",
                name: "..",
                isDir: true,
                isParent: true
            }];

            const entries = [...parentEntry, ...foldersInSearch, ...imagesInSearch];

            if (entries.length === 2 && root.numItems >= 3) {
                const wallpaper = entries.find(entry => !entry.isDir);
                if (wallpaper)
                    return [entries[0], wallpaper, wallpaper];
            }

            return entries;
        }

        onValuesChanged: {
            const firstEntry = values[0]?.isParent && values.length > 1 ? 1 : 0;
            const activeIndex = search ? -1 : values.findIndex(w => w.path === Wallpapers.actualCurrent);
            const nextIndex = activeIndex >= 0
                ? activeIndex
                : values.length > firstEntry ? firstEntry : values.length > 0 ? 0 : -1;

            if (root.currentIndex !== nextIndex)
                root.currentIndex = nextIndex;
        }
    }

    Component.onCompleted: {
        const values = scriptModel.values;
        const firstEntry = values[0]?.isParent && values.length > 1 ? 1 : 0;
        const index = values.findIndex(w => w.path === Wallpapers.actualCurrent);

        currentIndex = index >= 0 ? index : (values.length > firstEntry ? firstEntry : (values.length > 0 ? 0 : -1));
    }

    Component.onDestruction: Wallpapers.stopPreview()

    onCurrentItemChanged: {
        if (currentItem && !(currentItem as WallpaperItem).modelData.isDir)
            Wallpapers.preview((currentItem as WallpaperItem).modelData.path);
    }

    implicitWidth: Math.min(numItems, count) * itemWidth
    pathItemCount: numItems
    cacheItemCount: 4

    snapMode: PathView.SnapToItem
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5
    highlightRangeMode: PathView.StrictlyEnforceRange

    delegate: WallpaperItem {
        screenState: root.screenState
        wallpaperList: root
    }

    path: Path {
        startY: root.height / 2

        PathAttribute {
            name: "z"
            value: 0
        }
        PathLine {
            x: root.width / 2
            relativeY: 0
        }
        PathAttribute {
            name: "z"
            value: 1
        }
        PathLine {
            x: root.width
            relativeY: 0
        }
    }

    CustomMouseArea {
        function onWheel(event: WheelEvent): void {
            if (event.angleDelta.y > 0)
                root.decrementCurrentIndex();
            else if (event.angleDelta.y < 0)
                root.incrementCurrentIndex();
        }

        anchors.fill: parent
    }
}
