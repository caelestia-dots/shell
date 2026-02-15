pragma ComponentBehavior: Bound

import "items"
import qs.components.controls
import qs.services
import qs.config
import Quickshell
import QtQuick

PathView {
    id: root

    required property StyledTextField search
    required property var visibilities
    required property var panels
    required property var content

    readonly property int itemWidth: Config.launcher.sizes.wallpaperWidth * 0.8 + Appearance.padding.larger * 2

    readonly property int numItems: {
        const screen = QsWindow.window?.screen;
        if (!screen)
            return 0;

        // Screen width - 4x outer rounding - 2x max side thickness (cause centered)
        const barMargins = Math.max(Config.border.thickness, panels.bar.implicitWidth);
        let outerMargins = 0;
        if (panels.popouts.hasCurrent && panels.popouts.currentCenter + panels.popouts.nonAnimHeight / 2 > screen.height - content.implicitHeight - Config.border.thickness * 2)
            outerMargins = panels.popouts.nonAnimWidth;
        if ((visibilities.utilities || visibilities.sidebar) && panels.utilities.implicitWidth > outerMargins)
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

    implicitWidth: Math.min(numItems, count) * itemWidth
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
