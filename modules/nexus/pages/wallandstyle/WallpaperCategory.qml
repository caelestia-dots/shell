pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Components
import Caelestia.Config
import Caelestia.Models
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: {
        const c = nState.selectedWallpaperCategory;
        return c.slice(0, 1).toUpperCase() + c.slice(1);
    }
    isSubPage: true

    // A category can hold hundreds of wallpapers, so only the rows near the visible part of the
    // page are created (each row is one list item, padded so every column keeps the same width)
    LazyListView {
        id: rows

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        implicitHeight: contentHeight
        spacing: Tokens.spacing.medium

        cacheBuffer: 600
        useCustomViewport: true
        viewport: {
            tWatcher.transform; // mapToItem is not reactive so use this to trigger updates
            return Qt.rect(0, root.flickable.contentY - mapToItem(root.flickable.contentItem, 0, 0).y, width, root.flickable.height);
        }

        model: ScriptModel {
            values: {
                const perRow = Math.max(1, Config.nexus.wallpapersPerRow);
                const walls = Wallpapers.list.filter(w => Wallpapers.getCategoryFor(w) === root.nState.selectedWallpaperCategory).sort((a, b) => a.name.localeCompare(b.name));
                const result = [];
                for (let i = 0; i < walls.length; i += perRow) {
                    const row = walls.slice(i, i + perRow);
                    while (row.length < perRow)
                        row.push(null);
                    result.push(row);
                }
                return result;
            }
        }

        delegate: Component {
            RowLayout {
                id: wallRow

                required property var modelData

                spacing: Tokens.spacing.large

                Repeater {
                    model: wallRow.modelData

                    WallItem {
                        required property FileSystemEntry modelData

                        // Empty placeholders for sizing
                        opacity: modelData ? 1 : 0
                        enabled: modelData

                        source: String(modelData?.path ?? "")
                        text: modelData?.name ?? ""
                        onClicked: {
                            Wallpapers.setWallpaper(modelData.path);
                            root.nState.closeSubPage();
                            root.nState.closeSubPage();
                        }
                    }
                }
            }
        }

        TransformWatcher {
            id: tWatcher

            a: root.flickable.contentItem
            b: rows
        }
    }
}
