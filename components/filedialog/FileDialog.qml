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
    property string initialName
    property list<string> nameFilters
    property int filters
    property bool save
    property string confirmLabel: save ? Tr.trCtx("Save", "button") : Tr.trCtx("Select", "button")

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

        function handleEnter(): void {
            if (dState.save) {
                if (!dState.search)
                    return;

                dState.accepted(dState.cwd.join("/") + "/" + dState.search);
                return;
            }

            if (dState.selectedPath?.isDir)
                dState.cdInto(dState.selectedPath.name);
            else if (dState.selectionValid)
                dState.accepted(dState.selectedPath.path);
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

        Component.onCompleted: {
            if (dState.save) {
                if (loader.initialName)
                    search.selectName(loader.initialName);
                search.focus = true;
            }
        }

        onVisibleChanged: {
            if (!visible)
                dState.rejected();
        }

        contentItem.focus: true
        contentItem.Keys.onEscapePressed: {
            if (dState.selectedPath)
                dState.select(null);
            else
                dState.rejected();
        }
        contentItem.Keys.onReturnPressed: handleEnter()
        contentItem.Keys.onEnterPressed: handleEnter()
        contentItem.Keys.onPressed: event => {
            if (event.modifiers & Qt.ControlModifier) {
                if (event.key === Qt.Key_H)
                    dState.showHidden = !dState.showHidden;
                return;
            }

            if (/^[^\x00-\x1F\x7F-\x9F]+$/.test(event.text)) {
                search.text += event.text;
                search.focus = true;
            }
        }

        contentItem.Keys.onLeftPressed: folderContents.navLeft()
        contentItem.Keys.onRightPressed: folderContents.navRight()
        contentItem.Keys.onUpPressed: folderContents.navUp()
        contentItem.Keys.onDownPressed: folderContents.navDown()

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

            BlobRect {
                id: searchBg

                x: searchWrapper.x + search.x - Tokens.padding.large
                anchors.bottom: parent.bottom
                anchors.bottomMargin: buttons.height - (searchWrapper.open ? 0 : searchWrapper.realHeight + 5)

                implicitWidth: search.width + Tokens.padding.large * 2
                implicitHeight: searchWrapper.realHeight
                group: blobGroup
                radius: Tokens.rounding.largeIncreased
                deformScale: 0.00003 * Config.appearance.deformScale

                Behavior on anchors.bottomMargin {
                    Anim {}
                }
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
            anchors.bottom: searchWrapper.top
            dState: root.dState
        }

        Item {
            id: searchWrapper

            readonly property bool open: root.dState.save || root.dState.search
            readonly property int realHeight: search.implicitHeight + search.anchors.topMargin + Tokens.padding.extraSmall

            anchors.left: sidebar.right
            anchors.right: parent.right
            anchors.bottom: buttons.top

            clip: true
            implicitHeight: open ? realHeight : 0
            opacity: open ? 1 : 0

            FooterSearch {
                id: search

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Tokens.padding.medium
                dState: root.dState

                transform: Matrix4x4 {
                    matrix: searchBg.deformMatrix
                }

                Keys.onReturnPressed: root.handleEnter()
                Keys.onEnterPressed: root.handleEnter()

                Keys.onEscapePressed: {
                    if (text || !root.dState.save)
                        clear();
                    else
                        root.dState.rejected();
                }
                onFocusChanged: {
                    if (!focus && text && !root.dState.save)
                        clear();
                }
                onTextChanged: {
                    if (!text && !root.dState.save)
                        root.contentItem.focus = true;
                }
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
