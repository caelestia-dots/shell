pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.Models
import qs.components
import qs.components.controls
import qs.components.filedialog
import qs.components.images
import qs.services
import qs.utils

Item {
    id: root

    required property var dialog
    readonly property FileEntry currentItem: view.currentItem as FileEntry

    StyledRect {
        anchors.fill: parent
        color: Colours.tPalette.m3surfaceContainer

        layer.enabled: true
        layer.effect: MultiEffect {
            maskSource: mask
            maskEnabled: true
            maskInverted: true
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }
    }

    Item {
        id: mask

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            anchors.fill: parent
            anchors.margins: Tokens.padding.small
            radius: Tokens.rounding.small
        }
    }

    Loader {
        asynchronous: true
        anchors.centerIn: parent

        opacity: view.count === 0 ? 1 : 0
        active: opacity > 0

        sourceComponent: ColumnLayout {
            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "scan_delete"
                color: Colours.palette.m3outline
                font.pointSize: Tokens.font.size.extraLarge * 2
                font.weight: 500
            }

            StyledText {
                text: qsTr("This folder is empty")
                color: Colours.palette.m3outline
                font.pointSize: Tokens.font.size.large
                font.weight: 500
            }
        }

        Behavior on opacity {
            Anim {}
        }
    }

    GridView {
        id: view

        anchors.fill: parent
        anchors.margins: Tokens.padding.small + Tokens.padding.normal

        cellWidth: Sizes.itemWidth + Tokens.spacing.small
        cellHeight: Sizes.itemWidth + Tokens.spacing.small * 2 + Tokens.padding.normal * 2 + 1

        clip: true
        focus: true
        currentIndex: -1
        Keys.onEscapePressed: currentIndex = -1

        Keys.onReturnPressed: {
            if (root.dialog.selectionValid)
                root.dialog.accepted((currentItem as FileEntry).modelData.path);
        }
        Keys.onEnterPressed: {
            if (root.dialog.selectionValid)
                root.dialog.accepted((currentItem as FileEntry).modelData.path);
        }

        StyledScrollBar.vertical: StyledScrollBar {
            flickable: view
        }

        model: FileSystemModel {
            path: {
                if (root.dialog.cwd[0] === "Home")
                    return Paths.home + `/${root.dialog.cwd.slice(1).join("/")}`;
                else
                    return root.dialog.cwd.join("/");
            }
            onPathChanged: view.currentIndex = -1
        }

        delegate: FileEntry {}

        add: Transition {
            Anim {
                properties: "opacity,scale"
                from: 0
                to: 1
                type: Anim.DefaultSpatial
            }
        }

        remove: Transition {
            Anim {
                property: "opacity"
                to: 0
            }
            Anim {
                property: "scale"
                to: 0.5
            }
        }

        displaced: Transition {
            Anim {
                properties: "opacity,scale"
                to: 1
                easing: Tokens.anim.standardDecel
            }
            Anim {
                properties: "x,y"
                type: Anim.DefaultSpatial
            }
        }
    }

    CurrentItem {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.padding.small

        currentItem: view.currentItem
    }

    component FileEntry: StyledRect {
        id: item

        required property int index
        required property FileSystemEntry modelData

        readonly property real nonAnimHeight: icon.implicitHeight + name.anchors.topMargin + name.implicitHeight + Tokens.padding.normal * 2

        implicitWidth: Sizes.itemWidth
        implicitHeight: nonAnimHeight

        radius: Tokens.rounding.normal
        color: Qt.alpha(Colours.tPalette.m3surfaceContainerHighest, GridView.isCurrentItem ? Colours.tPalette.m3surfaceContainerHighest.a : 0)
        z: GridView.isCurrentItem || implicitHeight !== nonAnimHeight ? 1 : 0
        clip: true

        StateLayer {
            onClicked: view.currentIndex = item.index
            onDoubleClicked: {
                if (item.modelData.isDir)
                    root.dialog.cwd.push(item.modelData.name);
                else if (root.dialog.selectionValid)
                    root.dialog.accepted(item.modelData.path);
            }
        }

        CachingIconImage {
            id: icon

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Tokens.padding.normal

            implicitSize: Sizes.itemWidth - Tokens.padding.normal * 2

            Component.onCompleted: {
                const file = item.modelData;
                if (file.isImage)
                    source = Qt.resolvedUrl(file.path);
                else if (!file.isDir)
                    source = Quickshell.iconPath(file.mimeType.replace("/", "-"), "application-x-zerosize");
                else if (root.dialog.cwd.length === 1 && ["Desktop", "Documents", "Downloads", "Music", "Pictures", "Public", "Templates", "Videos"].includes(file.name))
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
            anchors.margins: Tokens.padding.normal

            horizontalAlignment: Text.AlignHCenter
            elide: item.GridView.isCurrentItem ? Text.ElideNone : Text.ElideRight
            wrapMode: item.GridView.isCurrentItem ? Text.WrapAtWordBoundaryOrAnywhere : Text.NoWrap

            Component.onCompleted: text = item.modelData.name
        }

        Behavior on implicitHeight {
            Anim {}
        }
    }
}
