pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtCore
import Quickshell
import M3Shapes
import Caelestia.Components
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Models
import Caelestia.Multimedia
import Caelestia.Scheme
import qs.components
import qs.components.containers
import qs.components.controls
import qs.utils

Item {
    id: root

    required property DialogState dState

    property string currentDir: dState.cwd.join("/") || "/"

    readonly property var locToIcon: {
        const path = p => Paths.toLocalFile(StandardPaths.writableLocation(p));
        return {
            [path(StandardPaths.HomeLocation)]: "home",
            [path(StandardPaths.DesktopLocation)]: "desktop",
            [path(StandardPaths.DocumentsLocation)]: "documents",
            [path(StandardPaths.DownloadLocation)]: "downloads",
            [path(StandardPaths.MusicLocation)]: "music",
            [path(StandardPaths.PicturesLocation)]: "pictures",
            [path(StandardPaths.PublicShareLocation)]: "public",
            [path(StandardPaths.TemplatesLocation)]: "templates",
            [path(StandardPaths.MoviesLocation)]: "videos",
            [path(StandardPaths.HomeLocation) + "/Games"]: "games",
            [path(StandardPaths.HomeLocation) + "/.steam"]: "steam",
            [path(StandardPaths.GenericDataLocation) + "/Steam"]: "steam",
            [path(StandardPaths.HomeLocation) + "/.wine"]: "wine",
            [path(StandardPaths.HomeLocation) + "/VirtualBox VMs"]: "vbox",
            [path(StandardPaths.HomeLocation) + "/vmware"]: "vmware",
            [path(StandardPaths.HomeLocation) + "/Dropbox"]: "dropbox",
            [path(StandardPaths.HomeLocation) + "/Nextcloud"]: "nextcloud",
            [path(StandardPaths.HomeLocation) + "/OneDrive"]: "onedrive",
            [path(StandardPaths.HomeLocation) + "/MEGA"]: "mega",
            [path(StandardPaths.HomeLocation) + "/Sync"]: "syncthing"
        };
    }

    function getSource(file: FileSystemEntry): string {
        if (!file.isDir) {
            if (MediaUtils.isSupported(file.path))
                return file.path;
            return Quickshell.iconPath(file.mimeType.replace("/", "-"), "application-x-zerosize");
        }

        if (locToIcon[file.path])
            return Quickshell.iconPath("folder-" + locToIcon[file.path], "inode-directory");

        if (file.name === ".git")
            return Quickshell.iconPath("folder-git", "inode-directory");
        if (file.name === ".github")
            return Quickshell.iconPath("folder-github", "inode-directory");

        return Quickshell.iconPath("inode-directory");
    }

    function navBy(delta: int): void {
        if (grid.count === 0)
            return;

        const cur = filtered.indexOf(dState.selectedPath);
        const next = Math.max(0, Math.min(grid.count - 1, cur + delta));
        dState.select(filtered.entryAt(next));
    }

    function navLeft(): void {
        navBy(-1);
    }

    function navRight(): void {
        navBy(1);
    }

    function navUp(): void {
        navBy(-grid.resolvedColumns);
    }

    function navDown(): void {
        navBy(grid.resolvedColumns);
    }

    Component.onCompleted: model.path = currentDir
    onCurrentDirChanged: {
        model.path = "";
        model.path = currentDir;
        dState.select(null);
    }

    Behavior on currentDir {
        SequentialAnimation {
            Anim {
                target: view
                property: "opacity"
                to: 0
                type: Anim.FastEffects
            }
            PropertyAction {}
            Anim {
                target: view
                property: "opacity"
                to: 1
                type: Anim.DefaultEffects
            }
        }
    }

    Loader {
        asynchronous: true
        anchors.fill: parent

        opacity: grid.count === 0 ? 1 : 0
        active: opacity > 0
        z: active ? 1 : 0

        sourceComponent: MouseArea {
            id: noFiles

            property int clicks
            property int exitTrigger

            onPressed: clicks++
            opacity: clicks > 10 && clicks < 15 ? 0 : 1

            Behavior on opacity {
                Anim {
                    type: Anim.SlowEffects
                }
            }

            Timer {
                running: noFiles.clicks >= 16
                interval: Tokens.anim.durations.expressiveFastEffects + Tokens.anim.durations.expressiveDefaultEffects
                onTriggered: {
                    if (noFiles.exitTrigger === 0) {
                        interval = 300;
                        running = true;
                    } else if (noFiles.exitTrigger === 1) {
                        noFiles.opacity = 0;
                        interval = Tokens.anim.durations.expressiveSlowEffects;
                        running = true;
                    } else {
                        root.dState.rejected();
                    }
                    noFiles.exitTrigger++;
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Tokens.spacing.extraSmall

                MaterialShape {
                    Layout.alignment: Qt.AlignHCenter
                    color: Colours.tPalette.surfaceContainerHigh
                    shape: MaterialShape.Ghostish
                    implicitSize: noFilesIcon.implicitHeight + Tokens.padding.large * 2

                    MaterialIcon {
                        id: noFilesIcon

                        anchors.centerIn: parent
                        text: "folder_open"
                        color: Colours.palette.onSurfaceVariant
                        fontStyle: Tokens.font.icon.extraLarge
                    }

                    Behavior on color {
                        CAnim {}
                    }
                }

                StyledText {
                    Layout.topMargin: Tokens.spacing.small
                    Layout.alignment: Qt.AlignHCenter
                    text: {
                        if (noFiles.clicks >= 12)
                            return Tr.tr("This folder is done with you");
                        if (noFiles.clicks >= 6)
                            return Tr.tr("This folder is annoyed");
                        return Tr.tr("This folder is empty");
                    }
                    color: Colours.palette.onSurfaceVariant
                    font: Tokens.font.title.medium
                    animate: true
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: {
                        if (noFiles.clicks >= 16)
                            return Tr.tr("You win. I'm out.");
                        if (noFiles.clicks >= 12)
                            return Tr.tr("Why are you still here?? Go touch some grass.");
                        if (noFiles.clicks >= 8)
                            return Tr.tr("I really will leave...");
                        if (noFiles.clicks >= 6)
                            return Tr.tr("That's it, I'm leaving.");
                        if (noFiles.clicks >= 3)
                            return Tr.tr("Stop clicking me. Can't a folder be empty in peace?");
                        if (noFiles.clicks >= 1)
                            return Tr.tr("Hey. There really is nothing here...");
                        return Tr.tr("Nothing to see here... I mean it, really.");
                    }
                    color: Colours.palette.outline
                    font: Tokens.font.body.medium
                    animate: true
                }
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    VerticalFadeFlickable {
        id: view

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.small + Tokens.padding.medium

        contentWidth: width
        contentHeight: grid.implicitHeight

        clip: true

        StyledScrollBar.vertical: StyledScrollBar {
            flickable: view
        }

        LazyGridView {
            id: grid

            anchors.left: parent.left
            anchors.right: parent.right
            implicitHeight: contentHeight

            cellWidth: Tokens.sizes.fileDialog.itemWidth
            columnSpacing: Tokens.spacing.extraSmall
            rowSpacing: Tokens.spacing.extraSmall
            removeDuration: Tokens.anim.durations.expressiveDefaultEffects

            useCustomViewport: true
            viewport: Qt.rect(0, view.contentY, width, view.height)

            model: FilterModel {
                id: filtered

                filter: root.dState.search
                propertyName: "name"
                sourceModel: FileSystemModel {
                    id: model

                    showHidden: root.dState.showHidden
                }
            }

            delegate: FileEntry {}

            FrameAnimation {
                running: grid.animating
                onTriggered: grid.step(frameTime)
            }
        }
    }

    component FileEntry: Item {
        id: item

        required property FileSystemEntry modelData

        readonly property bool isCurrentItem: root.dState.selectedPath === modelData
        readonly property int radius: Tokens.rounding.largeIncreased

        implicitWidth: Tokens.sizes.fileDialog.itemWidth
        implicitHeight: icon.implicitHeight + name.anchors.topMargin + name.implicitHeight + Tokens.padding.medium * 2

        opacity: LazyGridView.adding || LazyGridView.removing ? 0 : 1

        StyledRect {
            anchors.fill: parent
            anchors.margins: item.isCurrentItem ? 0 : Tokens.padding.medium
            radius: item.radius
            color: Qt.alpha(Colours.palette.primaryContainer, item.isCurrentItem ? 1 : 0)

            Behavior on anchors.margins {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        StateLayer {
            onClicked: root.dState.select(item.modelData)
            onDoubleClicked: {
                if (item.modelData.isDir)
                    root.dState.cwd.push(item.modelData.name);
                else if (root.dState.selectionValid)
                    root.dState.accepted(item.modelData.path);
            }
        }

        Visual {
            id: icon

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Tokens.padding.medium

            implicitWidth: Tokens.sizes.fileDialog.itemWidth - Tokens.padding.extraLarge * 2
            implicitHeight: implicitWidth
            fillMode: VisualSource.PreserveAspectFit
            opacity: !ready ? 0 : item.modelData?.name.startsWith(".") ? 0.5 : 1

            Component.onCompleted: source = root.getSource(item.modelData)
        }

        StyledText {
            id: name

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: icon.bottom
            anchors.topMargin: Tokens.spacing.extraSmall
            anchors.margins: Tokens.padding.small

            color: item.isCurrentItem ? Colours.palette.onPrimaryContainer : Colours.palette.onSurface
            font: Tokens.font.body.small
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere

            Component.onCompleted: text = item.modelData.name
        }

        Behavior on implicitHeight {
            enabled: item.LazyGridView.ready

            Anim {}
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
