pragma ComponentBehavior: Bound

import ".."
import "../controls"
import "../images"
import qs.services
import qs.config
import qs.utils
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Controls
import Qt.labs.folderlistmodel

Item {
    id: root

    required property var dialog
    property alias currentItem: view.currentItem

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
            anchors.margins: Appearance.padding.small
            radius: Appearance.rounding.small
        }
    }

    Loader {
        anchors.centerIn: parent
        active: view.count === 0
        asynchronous: true
        sourceComponent: ColumnLayout {
            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "scan_delete"
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.extraLarge * 2
                font.weight: 500
            }

            StyledText {
                text: qsTr("This folder is empty")
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.large
                font.weight: 500
            }
        }
    }

    GridView {
        id: view

        anchors.fill: parent
        anchors.margins: Appearance.padding.small + Appearance.padding.normal

        cellWidth: Sizes.itemWidth + Appearance.spacing.small
        cellHeight: Sizes.itemWidth + Appearance.spacing.small * 2 + Appearance.padding.normal * 2 + 1

        clip: true
        focus: true
        currentIndex: -1
        Keys.onEscapePressed: currentIndex = -1

        Keys.onReturnPressed: {
            if (root.dialog.selectionValid)
                root.dialog.accepted(currentItem.filePath);
        }
        Keys.onEnterPressed: {
            if (root.dialog.selectionValid)
                root.dialog.accepted(currentItem.filePath);
        }

        ScrollBar.vertical: StyledScrollBar {}

        model: FolderListModel {
            showDirsFirst: true
            folder: {
                let url = "file://";
                if (root.dialog.cwd[0] === "Home")
                    url += `${Paths.strip(Paths.home)}/${root.dialog.cwd.slice(1).join("/")}`;
                else
                    url += root.dialog.cwd.join("/");
                return url;
            }
            onFolderChanged: view.currentIndex = -1
        }

        delegate: StyledRect {
            id: item

            required property int index
            required property string fileName
            required property string filePath
            required property url fileUrl
            required property string fileSuffix
            required property bool fileIsDir

            readonly property real nonAnimHeight: icon.implicitHeight + name.anchors.topMargin + name.implicitHeight + Appearance.padding.normal * 2

            implicitWidth: Sizes.itemWidth
            implicitHeight: nonAnimHeight

            radius: Appearance.rounding.normal
            color: Qt.alpha(Colours.tPalette.m3surfaceContainerHighest, GridView.isCurrentItem ? Colours.tPalette.m3surfaceContainerHighest.a : 0)
            z: GridView.isCurrentItem || implicitHeight !== nonAnimHeight ? 1 : 0
            clip: true

            StateLayer {
                onDoubleClicked: {
                    if (item.fileIsDir)
                        root.dialog.cwd.push(item.fileName);
                    else if (root.dialog.selectionValid)
                        root.dialog.accepted(item.filePath);
                }

                function onClicked(): void {
                    view.currentIndex = item.index;
                }
            }

            CachingIconImage {
                id: icon

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Appearance.padding.normal

                asynchronous: true
                implicitSize: Sizes.itemWidth - Appearance.padding.normal * 2
                source: {
                    if (!item.fileIsDir)
                        return Quickshell.iconPath("application-x-zerosize");

                    const name = item.fileName;
                    if (root.dialog.cwd.length === 1 && ["Desktop", "Documents", "Downloads", "Music", "Pictures", "Public", "Templates", "Videos"].includes(name))
                        return Quickshell.iconPath(`folder-${name.toLowerCase()}`);

                    return Quickshell.iconPath("inode-directory");
                }

                onStatusChanged: {
                    if (status === Image.Error)
                        source = Quickshell.iconPath("error");
                }

                Process {
                    running: !item.fileIsDir
                    command: ["file", "--mime", "-b", item.filePath]
                    stdout: StdioCollector {
                        onStreamFinished: {
                            const mime = text.split(";")[0].replace("/", "-");
                            icon.source = Images.validImageTypes.some(t => mime === `image-${t}`) ? item.fileUrl : Quickshell.iconPath(mime, "image-missing");
                        }
                    }
                }
            }

            StyledText {
                id: name

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: icon.bottom
                anchors.topMargin: Appearance.spacing.small
                anchors.margins: Appearance.padding.normal

                horizontalAlignment: Text.AlignHCenter
                text: item.fileName
                elide: item.GridView.isCurrentItem ? Text.ElideNone : Text.ElideRight
                wrapMode: item.GridView.isCurrentItem ? Text.WrapAtWordBoundaryOrAnywhere : Text.NoWrap
            }

            Behavior on implicitHeight {
                Anim {}
            }
        }

        populate: Transition {
            Anim {
                property: "scale"
                from: 0.7
                to: 1
                easing.bezierCurve: Appearance.anim.curves.standardDecel
            }
        }
    }

    CurrentItem {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Appearance.padding.small

        currentItem: view.currentItem
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}
