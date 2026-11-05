pragma ComponentBehavior: Bound

import QtQuick
import QtCore
import Quickshell
import Caelestia.Blobs
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Scheme
import qs.components
import qs.utils

LazyLoader {
    id: loader

    property string title: Tr.tr("Select a file")
    property list<string> initialDir: Paths.toLocalFile(StandardPaths.writableLocation(StandardPaths.HomeLocation)).split("/")
    property list<string> nameFilters
    property int filters
    property bool save
    property string confirmLabel: Tr.trCtx("Select", "button")

    signal accepted(path: string)
    signal rejected

    function open(): void {
        activeAsync = true;
    }

    function close(): void {
        rejected();
    }

    onAccepted: activeAsync = false
    onRejected: activeAsync = false

    FloatingWindow {
        id: root

        property DialogState dState: DialogState {
            cwd: loader.initialDir
            nameFilters: loader.nameFilters
            filters: loader.filters
            save: loader.save
            confirmLabel: loader.confirmLabel

            onAccepted: path => loader.accepted(path)
            onRejected: loader.rejected()
        }

        contentItem.Config.screen: screen.name
        contentItem.Tokens.screen: screen.name

        implicitWidth: contentItem.Tokens.sizes.fileDialog.initialWidth
        implicitHeight: contentItem.Tokens.sizes.fileDialog.initialHeight
        minimumSize.width: contentItem.Tokens.sizes.fileDialog.minWidth
        minimumSize.height: contentItem.Tokens.sizes.fileDialog.minHeight

        color: Colours.tPalette.surface
        surfaceFormat.opaque: false
        title: loader.title

        onVisibleChanged: {
            if (!visible)
                dState.rejected();
        }

        Item {
            anchors.fill: parent
            opacity: blobGroup.color.a
            layer.enabled: true

            BlobGroup {
                id: blobGroup

                smoothing: root.contentItem.Tokens.rounding.largeIncreased
                color: Colours.tPalette.surfaceContainer

                Behavior on color {
                    CAnim {}
                }
            }

            BlobInvertedRect {
                anchors.fill: parent
                group: blobGroup
                radius: Tokens.rounding.largeIncreased

                borderLeft: sidebar.width
                borderRight: Tokens.padding.small
                borderTop: header.height
                borderBottom: buttons.height
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.contentItem.focus = true
        }

        Sidebar {
            id: sidebar

            anchors.top: parent.top
            anchors.bottom: parent.bottom
            dState: root.dState
        }

        HeaderBar {
            id: header

            anchors.left: sidebar.right
            anchors.right: parent.right
            dState: root.dState
        }

        FolderContents {
            id: folderContents

            anchors.left: sidebar.right
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: buttons.top
            dState: root.dState
        }

        DialogButtons {
            id: buttons

            anchors.left: sidebar.right
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            dState: root.dState
        }

        Behavior on color {
            CAnim {}
        }
    }
}
