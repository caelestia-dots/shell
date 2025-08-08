pragma ComponentBehavior: Bound

import "items"
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Controls

PathView {
    id: root

    required property TextField search
    required property PersistentProperties visibilities
    readonly property int numItems: {
        const screenWidth = QsWindow.window?.screen.width * 0.8;
        if (!screenWidth)
            return 0;
        const itemWidth = Config.launcher.sizes.wallpaperWidth * 0.8;
        const max = Config.launcher.maxWallpapers;
        const maxItemsOnScreen = Math.floor(screenWidth / itemWidth);

        const visible = Math.min(maxItemsOnScreen, max, scriptModel.values.length);
        if (visible === 2)
            return 1;
        else if (visible > 1 && visible % 2 === 0)
            return visible - 1;
        return visible;
    }

    model: ScriptModel {
        id: scriptModel

        readonly property string search: root.search.text.split(" ").slice(1).join(" ")

        values: Wallpapers.query(search)
        onValuesChanged: root.currentIndex = search ? 0 : values.findIndex(w => w.path === Wallpapers.actualCurrent)
    }

    Component.onCompleted: currentIndex = Wallpapers.list.findIndex(w => w.path === Wallpapers.actualCurrent)
    Component.onDestruction: Wallpapers.stopPreview()

    onCurrentItemChanged: {
        if (currentItem)
            Wallpapers.preview(currentItem.modelData.path);
    }

    implicitWidth: Math.min(numItems, count) * (Config.launcher.sizes.wallpaperWidth * 0.8 + Appearance.padding.larger * 2)
    pathItemCount: numItems
    cacheItemCount: 4

    snapMode: PathView.SnapToItem
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5
    highlightRangeMode: PathView.StrictlyEnforceRange

    delegate: WallpaperItem {
        visibilities: root.visibilities
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
}
