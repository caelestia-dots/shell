pragma ComponentBehavior: Bound

import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

LazyLoader {
    id: loader

    property list<string> cwd: ["Home"]
    property string filterLabel: "All files"
    property list<string> filters: ["*"]
    property string title: qsTr("Select a file")

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

        property list<string> cwd: loader.cwd
        property string filterLabel: loader.filterLabel
        property list<string> filters: loader.filters

        readonly property bool selectionValid: {
            const item = folderContents.currentItem;
            return item && !item.fileIsDir && (filters.includes("*") || filters.includes(item.fileSuffix));
        }

        function accepted(path: string): void {
            loader.accepted(path);
        }

        function rejected(): void {
            loader.rejected();
        }

        implicitWidth: 1000
        implicitHeight: 600
        color: Colours.palette.m3surface
        title: loader.title

        onVisibleChanged: {
            if (!visible)
                rejected();
        }

        RowLayout {
            anchors.fill: parent

            spacing: 0

            Sidebar {
                Layout.fillHeight: true
                dialog: root
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true

                spacing: 0

                HeaderBar {
                    Layout.fillWidth: true
                    dialog: root
                }

                FolderContents {
                    id: folderContents

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    dialog: root
                }

                DialogButtons {
                    Layout.fillWidth: true
                    dialog: root
                    folder: folderContents
                }
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: Appearance.anim.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.standard
            }
        }
    }
}
