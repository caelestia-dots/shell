pragma ComponentBehavior: Bound

import "items"
import QtQuick
import Quickshell
import Caelestia.Config
import qs.components.controls
import qs.services

PathView {
    id: root

    required property SearchBar search
    required property var screenState
    required property var panels

    readonly property int itemWidth: Tokens.sizes.launcher.wallpaperWidth * 0.8 + Tokens.padding.medium * 2

    readonly property int numItems: {
        // Read only the positioned vertical span: launcher width is an output
        // of this binding, so reading launcherRect here would create a cycle.
        const top = panels.y + panels.launcher.y;
        const bottom = top + panels.launcher.height;
        const center = panels.x + panels.width / 2;
        let halfWidth = panels.width / 2;
        if (panels.popouts.hasCurrent)
            halfWidth = Math.min(halfWidth, spaceBeside(panels.popoutsRect, top, bottom, center));
        if (panels.utilities.shouldBeActive)
            halfWidth = Math.min(halfWidth, spaceBeside(panels.utilitiesRect, top, bottom, center));
        if (panels.sidebar.shouldBeActive)
            halfWidth = Math.min(halfWidth, spaceBeside(panels.sidebarRect, top, bottom, center));
        const maxWidth = halfWidth * 2 - Config.border.rounding * 4;

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

    function spaceBeside(bounds: rect, top: real, bottom: real, center: real): real {
        // Upper Utilities and the sidebar are separate obstacles; disjoint
        // vertical spans do not consume horizontal wallpaper capacity.
        if (bounds.width <= 0 || bounds.height <= 0 || bottom <= top || bounds.y >= bottom || top >= bounds.y + bounds.height)
            return Infinity;
        return bounds.x + bounds.width / 2 < center ? center - bounds.x - bounds.width : bounds.x - center;
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
