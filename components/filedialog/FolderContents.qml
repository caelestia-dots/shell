pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
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

    readonly property FileEntry currentItem: {
        CUtils.dependency(grid.itemsDirty);
        return grid.itemAtIndex(grid.currentIndex) as FileEntry;
    }
    required property DialogState dState

    property string currentDir: dState.cwd.join("/")

    Component.onCompleted: model.path = currentDir
    onCurrentDirChanged: {
        model.path = "";
        model.path = currentDir;
        grid.currentIndex = -1;
    }

    Behavior on currentDir {
        SequentialAnimation {
            Anim {
                target: view
                property: "opacity"
                to: 0
                type: Anim.DefaultEffects
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
        Keys.onEscapePressed: grid.currentIndex = -1
        Keys.onReturnPressed: {
            if (root.dState.selectionValid)
                root.dState.accepted(root.currentItem.modelData.path);
        }
        Keys.onEnterPressed: {
            if (root.dState.selectionValid)
                root.dState.accepted(root.currentItem.modelData.path);
        }

        StyledScrollBar.vertical: StyledScrollBar {
            flickable: view
        }

        LazyGridView {
            id: grid

            property int currentIndex: -1

            anchors.left: parent.left
            anchors.right: parent.right
            implicitHeight: contentHeight

            cellWidth: Tokens.sizes.fileDialog.itemWidth
            columnSpacing: Tokens.spacing.small
            rowSpacing: Tokens.spacing.small
            removeDuration: Tokens.anim.durations.expressiveDefaultEffects

            useCustomViewport: true
            viewport: Qt.rect(0, view.contentY, width, view.height)

            model: FileSystemModel {
                id: model
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

        readonly property bool isCurrentItem: grid.currentIndex === index
        readonly property real nonAnimHeight: icon.implicitHeight + name.anchors.topMargin + name.implicitHeight + Tokens.padding.medium * 2

        implicitWidth: Tokens.sizes.fileDialog.itemWidth
        implicitHeight: nonAnimHeight

        radius: Tokens.rounding.large
        color: isCurrentItem ? Colours.tPalette.surfaceContainerHighest : Qt.alpha(Colours.tPalette.surfaceContainerHighest, 0)
        z: isCurrentItem || implicitHeight !== nonAnimHeight ? 1 : 0
        clip: true

        opacity: LazyGridView.adding || LazyGridView.removing ? 0 : 1

        StateLayer {
            onClicked: grid.currentIndex = item.index
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

            implicitWidth: Tokens.sizes.fileDialog.itemWidth - Tokens.padding.medium * 2
            implicitHeight: implicitWidth
            fillMode: VisualSource.PreserveAspectFit

            Component.onCompleted: {
                const file = item.modelData;
                if (MediaUtils.isSupported(file.path))
                    source = file.path;
                else if (!file.isDir)
                    source = Quickshell.iconPath(file.mimeType.replace("/", "-"), "application-x-zerosize");
                else if (root.dState.cwd.length === 1 && ["Desktop", "Documents", "Downloads", "Music", "Pictures", "Public", "Templates", "Videos"].includes(file.name))
                    source = Quickshell.iconPath(`folder-${file.name.toLowerCase()}`);
                else
                    source = Quickshell.iconPath("inode-directory");
            }
        }

        StyledText {
            id: name

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: icon.bottom
            anchors.topMargin: Tokens.spacing.small
            anchors.margins: Tokens.padding.medium

            horizontalAlignment: Text.AlignHCenter
            elide: item.isCurrentItem ? Text.ElideNone : Text.ElideRight
            wrapMode: item.isCurrentItem ? Text.WrapAtWordBoundaryOrAnywhere : Text.NoWrap

            Component.onCompleted: text = item.modelData.name
        }

        Behavior on implicitHeight {
            Anim {}
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
