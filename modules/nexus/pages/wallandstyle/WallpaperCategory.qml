pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: {
        const c = nState.selectedWallpaperCategory;
        return c.slice(0, 1).toUpperCase() + c.slice(1);
    }
    isSubPage: true

    GridLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        columns: Config.nexus.wallpapersPerRow
        rowSpacing: Tokens.spacing.medium
        columnSpacing: Tokens.spacing.large

        Repeater {
            model: {
                const walls = Wallpapers.list.filter(w => Wallpapers.getCategoryFor(w.path) === root.nState.selectedWallpaperCategory).sort((a, b) => a.name.localeCompare(b.name));
                while (walls.length < Config.nexus.wallpapersPerRow)
                    walls.push(null);
                return walls;
            }

            WallItem {
                required property QtObject modelData

                opacity: modelData ? 1 : 0
                enabled: modelData
                source: {
                    if (!modelData) return "";
                    const thumb = Wallpapers.getThumbnailPath(modelData.path);
                    if (!thumb) return "";
                    return "file://" + thumb + "?v=" + Wallpapers.thumbnailVersion;
                }
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
