pragma ComponentBehavior: Bound

import ".."
import qs.services
import qs.config
import qs.utils
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import Qt.labs.folderlistmodel

GridView {
    id: root

    required property list<string> cwd

    property var mimes: ({})

    clip: true
    focus: true
    Keys.onEscapePressed: root.currentIndex = -1

    model: FolderListModel {
        folder: {
            let url = "file://";
            if (root.cwd[0] === "Home")
                url += `${Paths.strip(Paths.home)}/${root.cwd.slice(1).join("/")}`;
            else
                url += root.cwd.join("/");
            return url;
        }
    }

    delegate: StyledRect {
        id: item

        required property int index
        required property string fileName
        required property url fileUrl
        required property string fileSuffix
        required property bool fileIsDir

        readonly property real nonAnimHeight: icon.implicitHeight + name.anchors.topMargin + name.implicitHeight + Appearance.padding.normal * 2

        implicitWidth: Sizes.itemWidth
        implicitHeight: nonAnimHeight

        radius: Appearance.rounding.normal
        color: root.currentItem === item ? Colours.palette.m3primary : "transparent"
        z: root.currentItem === item || implicitHeight !== nonAnimHeight ? 1 : 0
        clip: true

        StateLayer {
            color: root.currentItem === item ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            onDoubleClicked: console.log("double clicked", item)

            function onClicked(): void {
                root.currentIndex = item.index;
            }
        }

        IconImage {
            id: icon

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Appearance.spacing.normal

            asynchronous: true
            implicitSize: Sizes.itemWidth - Appearance.padding.normal * 2
            source: {
                const mime = root.mimes[item.fileSuffix];

                if (mime?.startsWith("image-"))
                    return item.fileUrl;

                return Quickshell.iconPath(item.fileIsDir ? "inode-directory" : root.mimes[item.fileSuffix] ?? "application-x-zerosize", "image-missing");
            }
            onStatusChanged: {
                if (status === Image.Error)
                    source = Quickshell.iconPath("error");
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
            color: root.currentItem === item ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            elide: root.currentItem === item ? Text.ElideNone : Text.ElideRight
            wrapMode: root.currentItem === item ? Text.WrapAtWordBoundaryOrAnywhere : Text.NoWrap
        }

        Behavior on implicitHeight {
            NumberAnimation {
                duration: Appearance.anim.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.standard
            }
        }
    }

    FileView {
        path: "/etc/mime.types"
        onLoaded: {
            root.mimes = text().split("\n").filter(l => !l.startsWith("#")).reduce((mimes, line) => {
                const [type, ext] = line.split(/\s+/);
                if (ext)
                    mimes[ext] = type.replace("/", "-");
                return mimes;
            }, {});
        }
    }
}
