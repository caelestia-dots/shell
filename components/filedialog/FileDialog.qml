pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtCore
import Quickshell
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
    property string confirmLabel: Tr.tr("Select")

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

        readonly property bool selectionValid: {
            const file = folderContents.currentItem?.modelData;
            return (file && !file.isDir && (filters.includes("*") || filters.some(filter => filter.toLowerCase() === file.suffix.toLowerCase()))) ?? false;
        }

        property DialogState dState: DialogState {
            cwd: loader.initialDir
            nameFilters: loader.nameFilters
            filters: loader.filters
            save: loader.save
            confirmLabel: loader.confirmLabel

            onAccepted: path => loader.accepted(path)
            onRejected: loader.rejected()
        }

        implicitWidth: 1000
        implicitHeight: 600
        minimumSize.width: 400
        minimumSize.height: 300
        color: Colours.tPalette.surface
        surfaceFormat.opaque: false
        title: loader.title

        onVisibleChanged: {
            if (!visible)
                dState.rejected();
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
            folder: folderContents
        }

        Behavior on color {
            CAnim {}
        }
    }
}
