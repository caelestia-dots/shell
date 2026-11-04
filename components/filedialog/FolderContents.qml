pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtCore
import Quickshell
import Caelestia
import Caelestia.Components
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Models
import Caelestia.Multimedia
import Caelestia.Scheme
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.effects
import qs.utils

Item {
    id: root

    property int currentIndex: -1
    readonly property FileEntry currentItem: {
        CUtils.dependency(grid.itemsDirty);
        return grid.itemAtIndex(currentIndex) as FileEntry;
    }
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

    Component.onCompleted: model.path = currentDir
    onCurrentDirChanged: {
        model.path = "";
        model.path = currentDir;
        currentIndex = -1;
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

    StyledRect {
        anchors.fill: parent
        color: Colours.tPalette.surfaceContainer

        layer.enabled: true
        layer.effect: Mask {
            maskSource: mask
            maskInverted: true
        }
    }

    Item {
        id: mask

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            anchors.fill: parent
            anchors.margins: Tokens.padding.extraSmall
            radius: Tokens.rounding.medium
        }
    }

    Loader {
        asynchronous: true
        anchors.centerIn: parent

        opacity: grid.count === 0 ? 1 : 0
        active: opacity > 0

        sourceComponent: ColumnLayout {
            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "scan_delete"
                color: Colours.palette.outline
                fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).weight(Font.Medium).build()
            }

            StyledText {
                text: Tr.tr("This folder is empty")
                color: Colours.palette.outline
                font: Tokens.font.body.builders.large.weight(Font.Medium).build()
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    StyledFlickable {
        id: view

        anchors.fill: parent
        anchors.margins: Tokens.padding.extraSmall + Tokens.padding.medium

        flickableDirection: Flickable.VerticalFlick
        contentWidth: width
        contentHeight: grid.implicitHeight

        clip: true
        focus: true
        Keys.onEscapePressed: root.currentIndex = -1
        Keys.onReturnPressed: {
            if (root.dState.selectionValid)
                root.dState.accepted(root.currentItem.modelData.path);
        }
        Keys.onEnterPressed: {
            if (root.dState.selectionValid)
                root.dState.accepted(root.currentItem.modelData.path);
        }
        Keys.onPressed: event => {
            if (event.key === Qt.Key_H && event.modifiers & Qt.ControlModifier)
                root.dState.showHidden = !root.dState.showHidden;
        }

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

            model: FileSystemModel {
                id: model

                showHidden: root.dState.showHidden
            }

            delegate: FileEntry {}

            FrameAnimation {
                running: grid.animating
                onTriggered: grid.step(frameTime)
            }
        }
    }

    CurrentItem {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.padding.extraSmall

        currentItem: root.currentItem
    }

    component FileEntry: StyledRect {
        id: item

        required property int index
        required property FileSystemEntry modelData

        readonly property bool isCurrentItem: root.currentIndex === index
        readonly property real nonAnimHeight: icon.implicitHeight + name.anchors.topMargin + name.implicitHeight + Tokens.padding.medium * 2

        implicitWidth: Tokens.sizes.fileDialog.itemWidth
        implicitHeight: nonAnimHeight

        radius: Tokens.rounding.large
        color: isCurrentItem ? Colours.tPalette.surfaceContainerHighest : Qt.alpha(Colours.tPalette.surfaceContainerHighest, 0)
        z: isCurrentItem || implicitHeight !== nonAnimHeight ? 1 : 0
        clip: true

        opacity: LazyGridView.adding || LazyGridView.removing ? 0 : 1

        StateLayer {
            onClicked: root.currentIndex = item.index
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
            opacity: item.modelData?.name.startsWith(".") ? 0.5 : 1

            Component.onCompleted: source = root.getSource(item.modelData)
        }

        StyledText {
            id: name

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: icon.bottom
            anchors.topMargin: Tokens.spacing.extraSmall
            anchors.margins: Tokens.padding.small

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
