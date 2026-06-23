pragma ComponentBehavior: Bound
import Caelestia.Config
import QtQuick
import Quickshell

import "items"
import qs.components.controls
import qs.services

PathView {
    id: root

    required property var content
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
    required property var panels
    required property StyledTextField search
    required property var visibilities

    cacheItemCount: 4
    highlightRangeMode: PathView.StrictlyEnforceRange
    implicitWidth: Math.min(numItems, count) * itemWidth
    pathItemCount: numItems
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5
    snapMode: PathView.SnapToItem

    delegate: WallpaperItem {
        visibilities: root.visibilities
    }
    model: ScriptModel {
        id: scriptModel

        readonly property string search: root.search.text.split(" ").slice(1).join(" ")

        values: Wallpapers.query(search)

        // Ensures the picker index stays within bounds to prevent crashes when flipping between static and animated modes.
        onValuesChanged: {
            const idx = values.findIndex(w => w.path === Wallpapers.actualCurrent);
            root.currentIndex = search ? 0 : Math.max(0, idx);
            syncTimer.restart();
        }
    }
    path: Path {
        startY: root.height / 2

        PathAttribute {
            name: "z"
            value: 0
        }
        PathLine {
            relativeY: 0
            x: root.width / 2
        }
        PathAttribute {
            name: "z"
            value: 1
        }
        PathLine {
            relativeY: 0
            x: root.width
        }
    }

    Component.onCompleted: {
        currentIndex = Math.max(0, Wallpapers.list.findIndex(w => w.path === Wallpapers.actualCurrent));
        syncTimer.restart();
    }
    Component.onDestruction: Wallpapers.stopPreview()
    onCurrentIndexChanged: {
        if (scriptModel.values && scriptModel.values[currentIndex]) {
            Wallpapers.preview(scriptModel.values[currentIndex].path);
        }
    }

    Timer {
        id: syncTimer

        interval: 50
        repeat: false

        onTriggered: {
            if (scriptModel.values && scriptModel.values[root.currentIndex]) {
                Wallpapers.preview(scriptModel.values[root.currentIndex].path);
            }
        }
    }
}
