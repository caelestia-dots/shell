pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Caelestia
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    property ServiceRef sRef: ServiceRef {
        service: Storage
    }

    readonly property DiskInfo activeDisk: Storage.primaryDisk

    readonly property real totalBytes: (root.activeDisk?.total ?? 0) * 1024
    readonly property real usedBytes: (root.activeDisk?.used ?? 0) * 1024
    readonly property real freeBytes: (root.activeDisk?.free ?? 0) * 1024
    readonly property real usagePerc: root.activeDisk?.perc ?? 0

    property bool inExplorerView: false
    property string activeCategoryName: ""
    property string activeCategoryIcon: ""
    property var categories: []

    property var fileList: []
    property bool isScanningFiles: false

    property var selectedFilePaths: []
    property bool showDeleteConfirm: false
    property string fileToDeletePath: ""
    property string fileToDeleteName: ""

    property bool showAppInspector: false
    property var selectedAppItem: null

    property Process cleanCacheProc: Process {
        id: cleanProc

        command: ["sh", "-c", "rm -rf ~/.cache/* 2>/dev/null || true"]

        stdout: StdioCollector {
            onStreamFinished: {
                Toaster.toast("Cache Cleaned", "Temporary cache files have been cleared", "cleaning_services", Toast.Success);
                root.scanCategories();
                if (root.inExplorerView)
                    root.loadCategoryFiles();
            }
        }
    }

    property Process filesProc: Process {
        id: fProc

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.fileList = JSON.parse(text.trim());
                } catch (e) {
                    root.fileList = [];
                }
                root.isScanningFiles = false;
            }
        }
    }

    property Process deleteProc: Process {
        id: delProc

        stdout: StdioCollector {
            onStreamFinished: {
                Toaster.toast("Deleted", "Selected item(s) have been deleted", "delete", Toast.Success);
                root.loadCategoryFiles();
                root.scanCategories();
            }
        }
    }

    property Process catScanProc: Process {
        id: cScanProc

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.categories = JSON.parse(text.trim());
                } catch (e) {
                    root.categories = [];
                }
            }
        }
    }

    property Process launchProc: Process {
        id: lProc
    }

    property Process openProc: Process {
        id: oProc
    }

    title: root.inExplorerView ? root.activeCategoryName : qsTr("Storage")

    function formatBytes(bytes) {
        if (bytes <= 0 || isNaN(bytes))
            return "0 B";
        const k = 1024;
        const sizes = ["B", "KB", "MB", "GB", "TB"];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + " " + sizes[i];
    }

    function scanCategories() {
        let activeMount = root.activeDisk ? root.activeDisk.mount : "/";
        let pyCmd = `import os, json, subprocess, sys
active_mount = '${activeMount}'
def get_xdg(name, fallback):
    try:
        res = subprocess.check_output(['xdg-user-dir', name], text=True, stderr=subprocess.DEVNULL).strip()
        if res and os.path.exists(res): return res
    except: pass
    return os.path.expanduser(fallback)

def fast_calc(path):
    p = os.path.expanduser(path)
    if not os.path.exists(p): return 0
    total = 0
    try:
        if os.path.isfile(p): return os.path.getsize(p)
        count = 0
        for entry in os.scandir(p):
            count += 1
            if count > 200: break
            try:
                if entry.is_file(follow_symlinks=False):
                    total += entry.stat(follow_symlinks=False).st_size
                elif entry.is_dir(follow_symlinks=False):
                    subcount = 0
                    for sub in os.scandir(entry.path):
                        subcount += 1
                        if subcount > 40: break
                        if sub.is_file(follow_symlinks=False):
                            total += sub.stat(follow_symlinks=False).st_size
            except: pass
    except: pass
    return total

cats_def = [
    {'name': 'Programs', 'icon': 'apps', 'paths': ['/usr/share/applications', os.path.expanduser('~/.local/share/applications')]},
    {'name': 'Downloads', 'icon': 'download', 'paths': [get_xdg('DOWNLOAD', '~/Downloads')]},
    {'name': 'Videos', 'icon': 'movie', 'paths': [get_xdg('VIDEOS', '~/Videos')]},
    {'name': 'Pictures', 'icon': 'image', 'paths': [get_xdg('PICTURES', '~/Pictures')]},
    {'name': 'Music', 'icon': 'music_note', 'paths': [get_xdg('MUSIC', '~/Music')]},
    {'name': 'Documents', 'icon': 'description', 'paths': [get_xdg('DOCUMENTS', '~/Documents')]},
    {'name': 'Cache & Temp', 'icon': 'cleaning_services', 'paths': [os.path.expanduser('~/.cache')]}
]
res_cats = []
for c in cats_def:
    valid = [p for p in c['paths'] if os.path.exists(p)]
    if valid:
        sz = sum(fast_calc(p) for p in valid)
        res_cats.append({'name': c['name'], 'icon': c['icon'], 'size': sz, 'paths': valid})
print(json.dumps(res_cats))
`;

        root.catScanProc.command = ["python3", "-c", pyCmd];
        root.catScanProc.running = false;
        root.catScanProc.running = true;
    }

    function openCategoryExplorer(cat) {
        root.activeCategoryName = cat.name;
        root.activeCategoryIcon = cat.icon;
        root.selectedFilePaths = [];
        root.showDeleteConfirm = false;
        root.showAppInspector = false;
        root.inExplorerView = true;
        root.loadCategoryFiles();
    }

    function loadCategoryFiles() {
        root.isScanningFiles = true;
        root.fileList = [];

        let cat = null;
        for (let i = 0; i < root.categories.length; i++) {
            if (root.categories[i].name === root.activeCategoryName) {
                cat = root.categories[i];
                break;
            }
        }

        if (!cat) {
            root.isScanningFiles = false;
            return;
        }

        let pyCmd = `import os, json, sys
cat_name = '${cat.name}'
paths = ${JSON.stringify(cat.paths)}

def trunc(s, limit=40):
    if not s: return ""
    return (s[:37] + "...") if len(s) > limit else s

files = []
for p in paths:
    p = os.path.expanduser(p)
    if not os.path.exists(p): continue
    if cat_name == 'Programs':
        for root_d, dirs, fnames in os.walk(p):
            for f in fnames:
                if f.endswith('.desktop'):
                    fp = os.path.join(root_d, f)
                    try:
                        name = f.replace('.desktop', '')
                        exec_path = ''
                        icon_name = 'apps'
                        with open(fp, 'r', errors='ignore') as df:
                            for line in df:
                                if line.startswith('Name=') and name == f.replace('.desktop', ''):
                                    name = line.split('=', 1)[1].strip()
                                elif line.startswith('Exec='):
                                    exec_path = line.split('=', 1)[1].strip()
                                elif line.startswith('Icon='):
                                    icon_name = line.split('=', 1)[1].strip()
                        sz = os.path.getsize(fp)
                        files.append({
                            'name': trunc(name, 40),
                            'path': trunc(fp, 40),
                            'fullPath': fp,
                            'exec': exec_path,
                            'icon': icon_name,
                            'size': sz,
                            'isApp': True
                        })
                    except: pass
    else:
        try:
            count = 0
            for entry in os.scandir(p):
                count += 1
                if count > 100: break
                try:
                    st = entry.stat(follow_symlinks=False)
                    sz = st.st_size
                    is_d = entry.is_dir(follow_symlinks=False)
                    files.append({
                        'name': trunc(entry.name, 40),
                        'path': trunc(entry.path, 40),
                        'fullPath': entry.path,
                        'size': sz,
                        'isDir': is_d,
                        'mtime': st.st_mtime,
                        'isApp': False
                    })
                except: pass
        except: pass
files.sort(key=lambda x: x['size'], reverse=True)
print(json.dumps(files[:100]))
`;

        root.filesProc.command = ["python3", "-c", pyCmd];
        root.filesProc.running = false;
        root.filesProc.running = true;
    }

    function isFileSelected(path) {
        return root.selectedFilePaths.indexOf(path) !== -1;
    }

    function toggleFileSelection(path) {
        let idx = root.selectedFilePaths.indexOf(path);
        let list = root.selectedFilePaths.slice();
        if (idx !== -1)
            list.splice(idx, 1);
        else
            list.push(path);
        root.selectedFilePaths = list;
    }

    function selectAllFiles() {
        let list = [];
        for (let i = 0; i < root.fileList.length; i++) {
            list.push(root.fileList[i].fullPath || root.fileList[i].path);
        }
        root.selectedFilePaths = list;
    }

    function clearSelection() {
        root.selectedFilePaths = [];
    }

    function requestDeleteSingleFile(path, name) {
        root.fileToDeletePath = path;
        root.fileToDeleteName = name;
        root.showDeleteConfirm = true;
    }

    function requestDeleteSelectedFiles() {
        if (root.selectedFilePaths.length === 0)
            return;
        root.fileToDeletePath = "";
        root.fileToDeleteName = root.selectedFilePaths.length + " files (" + root.formatBytes(root.getSelectedTotalSize()) + ")";
        root.showDeleteConfirm = true;
    }

    function confirmDeleteFile() {
        root.showDeleteConfirm = false;

        let targets = [];
        if (root.fileToDeletePath !== "") {
            targets.push(root.fileToDeletePath);
        } else if (root.selectedFilePaths.length > 0) {
            targets = root.selectedFilePaths.slice();
        }

        if (targets.length === 0)
            return;

        root.deleteProc.command = ["rm", "-rf"].concat(targets);
        root.deleteProc.running = false;
        root.deleteProc.running = true;

        root.fileToDeletePath = "";
        root.fileToDeleteName = "";
        root.selectedFilePaths = [];
    }

    function getSelectedTotalSize() {
        let sz = 0;
        for (let i = 0; i < root.fileList.length; i++) {
            let fp = root.fileList[i].fullPath || root.fileList[i].path;
            if (root.selectedFilePaths.indexOf(fp) !== -1) {
                sz += root.fileList[i].size || 0;
            }
        }
        return sz;
    }

    function openFileParentDir(path) {
        root.openProc.command = ["sh", "-c", "xdg-open $(dirname '" + path + "') 2>/dev/null || true"];
        root.openProc.running = false;
        root.openProc.running = true;
    }

    function launchAppItem(execStr) {
        if (!execStr)
            return;
        let cleanCmd = execStr.replace(/%[fFuUniick]/g, "").trim();
        root.launchProc.command = ["sh", "-c", cleanCmd + " &"];
        root.launchProc.running = false;
        root.launchProc.running = true;
    }

    Component.onCompleted: {
        root.scanCategories();
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.large

        // MAIN OVERVIEW VIEW
        ColumnLayout {
            visible: !root.inExplorerView
            Layout.fillWidth: true
            spacing: Tokens.spacing.large

            // DRIVE SELECTOR PILL BAR (ONLY inside Main Overview view)
            ColumnLayout {
                visible: Storage.disks.length > 0
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                SectionHeader {
                    text: qsTr("Storage Devices")
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    Repeater {
                        model: Storage.disks

                        TextButton {
                            id: diskBtn

                            required property DiskInfo modelData

                            text: diskBtn.modelData.mount + " (" + root.formatBytes(diskBtn.modelData.free * 1024) + " " + qsTr("free") + ")"
                            type: Storage.manualPrimaryDisk === diskBtn.modelData || (Storage.manualPrimaryDisk === null && Storage.primaryDisk === diskBtn.modelData) ? ButtonBase.Filled : ButtonBase.Tonal
                            isRound: true
                            onClicked: {
                                Storage.manualPrimaryDisk = diskBtn.modelData;
                                root.scanCategories();
                            }
                        }
                    }
                }
            }

            // MAIN STORAGE OVERVIEW CARD
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: mainCardLayout.implicitHeight + Tokens.padding.large * 2
                radius: Tokens.rounding.large
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: mainCardLayout

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.large
                    spacing: Tokens.spacing.medium

                    RowLayout {
                        Layout.fillWidth: true

                        ColumnLayout {
                            spacing: Tokens.spacing.extraSmall / 2

                            StyledText {
                                text: root.activeDisk ? root.activeDisk.mount : qsTr("Primary Disk")
                                font: Tokens.font.title.medium
                                color: Colours.palette.m3primary
                            }

                            StyledText {
                                text: root.formatBytes(root.usedBytes) + " " + qsTr("used of") + " " + root.formatBytes(root.totalBytes)
                                font: Tokens.font.body.medium
                                color: Colours.palette.m3outline
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        ColumnLayout {
                            Layout.alignment: Qt.AlignRight

                            StyledText {
                                text: root.formatBytes(root.freeBytes)
                                font: Tokens.font.title.large
                                color: Colours.palette.m3primary
                                horizontalAlignment: Text.AlignRight
                            }

                            StyledText {
                                text: qsTr("Free Space Available")
                                font: Tokens.font.body.small
                                color: Colours.palette.m3outline
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }

                    // PROPORTIONAL STORAGE BAR
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 16
                        radius: Tokens.rounding.full
                        color: Qt.alpha(Colours.palette.m3outline, 0.2)
                        clip: true

                        RowLayout {
                            anchors.fill: parent
                            spacing: 2

                            Rectangle {
                                Layout.fillHeight: true
                                Layout.preferredWidth: root.totalBytes > 0 ? (parent.width * root.usagePerc) : 0
                                color: Colours.palette.m3primary
                                radius: Tokens.rounding.full
                            }

                            Rectangle {
                                Layout.fillHeight: true
                                Layout.fillWidth: true
                                color: Qt.alpha(Colours.palette.m3outlineVariant, 0.3)
                                radius: Tokens.rounding.full
                            }
                        }
                    }
                }
            }

            // CATEGORY BREAKDOWN GRID
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                RowLayout {
                    Layout.fillWidth: true

                    SectionHeader {
                        text: qsTr("Category Breakdown")
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    TextButton {
                        text: qsTr("Clean Cache")
                        type: ButtonBase.Tonal
                        isRound: true
                        onClicked: root.cleanCacheProc.running = true
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: Tokens.spacing.small
                    columnSpacing: Tokens.spacing.small

                    Repeater {
                        model: root.categories

                        Rectangle {
                            id: catCard

                            required property var modelData

                            Layout.fillWidth: true
                            implicitHeight: 72
                            radius: Tokens.rounding.medium
                            color: catMouseArea.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : Colours.tPalette.m3surfaceContainer

                            Behavior on color {
                                ColorAnimation {
                                    duration: Tokens.anim.durations.expressiveFastSpatial
                                }
                            }

                            MouseArea {
                                id: catMouseArea

                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.openCategoryExplorer(catCard.modelData)
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: Tokens.padding.medium
                                spacing: Tokens.spacing.medium

                                Rectangle {
                                    implicitWidth: 40
                                    implicitHeight: 40
                                    radius: Tokens.rounding.small
                                    color: Qt.alpha(Colours.palette.m3primary, 0.12)

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        text: catCard.modelData.icon
                                        color: Colours.palette.m3primary
                                        fontStyle: Tokens.font.icon.medium
                                    }
                                }

                                ColumnLayout {
                                    spacing: 1

                                    StyledText {
                                        text: catCard.modelData.name
                                        font: Tokens.font.title.small
                                        color: Colours.palette.m3primary
                                    }

                                    StyledText {
                                        text: root.formatBytes(catCard.modelData.size)
                                        font: Tokens.font.body.small
                                        color: Colours.palette.m3outline
                                    }
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                MaterialIcon {
                                    text: "chevron_right"
                                    color: Colours.palette.m3outline
                                    fontStyle: Tokens.font.icon.small
                                }
                            }
                        }
                    }
                }
            }
        }

        // EXPLORER FILE INSPECTOR VIEW
        ColumnLayout {
            visible: root.inExplorerView
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                TextButton {
                    text: qsTr("Back to Overview")
                    type: ButtonBase.Tonal
                    isRound: true
                    onClicked: {
                        root.showDeleteConfirm = false;
                        root.inExplorerView = false;
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                TextButton {
                    text: root.selectedFilePaths.length === root.fileList.length ? qsTr("Deselect All") : qsTr("Select All")
                    type: ButtonBase.Tonal
                    isRound: true
                    onClicked: {
                        if (root.selectedFilePaths.length === root.fileList.length)
                            root.clearSelection();
                        else
                            root.selectAllFiles();
                    }
                }

                TextButton {
                    visible: root.selectedFilePaths.length > 0
                    text: qsTr("Delete Selected") + " (" + root.selectedFilePaths.length + ")"
                    type: ButtonBase.Filled
                    isRound: true
                    onClicked: root.requestDeleteSelectedFiles()
                }

                IconButton {
                    icon: "refresh"
                    onClicked: root.loadCategoryFiles()
                }
            }

            // CLEAN INLINE DELETE BANNER AT TOP OF FILE EXPLORER
            Rectangle {
                visible: root.showDeleteConfirm
                Layout.fillWidth: true
                implicitHeight: 52
                radius: Tokens.rounding.medium
                color: Qt.alpha(Colours.palette.m3error, 0.15)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Tokens.padding.large
                    anchors.rightMargin: Tokens.padding.large
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        text: "warning"
                        color: Colours.palette.m3error
                        fontStyle: Tokens.font.icon.medium
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: "Delete " + (root.fileToDeleteName.length > 40 ? root.fileToDeleteName.substring(0, 37) + "..." : root.fileToDeleteName) + "?"
                        font: Tokens.font.body.medium
                        color: Colours.palette.m3error
                        elide: Text.ElideRight
                    }

                    TextButton {
                        text: "Cancel"
                        type: ButtonBase.Text
                        isRound: true
                        onClicked: root.showDeleteConfirm = false
                    }

                    TextButton {
                        text: "Delete permanently"
                        type: ButtonBase.Filled
                        isRound: true
                        onClicked: root.confirmDeleteFile()
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: root.fileList

                    Rectangle {
                        id: fileRowItem

                        required property var modelData

                        Layout.fillWidth: true
                        implicitHeight: 56
                        radius: Tokens.rounding.medium
                        color: root.isFileSelected(fileRowItem.modelData.fullPath || fileRowItem.modelData.path) ? Qt.alpha(Colours.palette.m3primary, 0.15) : (fileMouseArea.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : Colours.tPalette.m3surfaceContainer)

                        Behavior on color {
                            ColorAnimation {
                                duration: Tokens.anim.durations.expressiveFastSpatial
                            }
                        }

                        MouseArea {
                            id: fileMouseArea

                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (fileRowItem.modelData.isApp) {
                                    root.selectedAppItem = fileRowItem.modelData;
                                    root.showAppInspector = true;
                                } else {
                                    root.toggleFileSelection(fileRowItem.modelData.fullPath || fileRowItem.modelData.path);
                                }
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Tokens.padding.medium
                            anchors.rightMargin: Tokens.padding.medium
                            spacing: Tokens.spacing.medium

                            IconButton {
                                visible: !fileRowItem.modelData.isApp
                                icon: root.isFileSelected(fileRowItem.modelData.fullPath || fileRowItem.modelData.path) ? "check_box" : "check_box_outline_blank"
                                onClicked: root.toggleFileSelection(fileRowItem.modelData.fullPath || fileRowItem.modelData.path)
                            }

                            Rectangle {
                                implicitWidth: 36
                                implicitHeight: 36
                                radius: Tokens.rounding.small
                                color: Qt.alpha(Colours.palette.m3primary, 0.12)

                                IconImage {
                                    anchors.centerIn: parent
                                    visible: fileRowItem.modelData.isApp
                                    asynchronous: true
                                    implicitSize: 24
                                    source: Quickshell.iconPath(fileRowItem.modelData.icon || "apps", "apps")
                                }

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    visible: !fileRowItem.modelData.isApp
                                    text: fileRowItem.modelData.isDir ? "folder" : "description"
                                    color: Colours.palette.m3primary
                                    fontStyle: Tokens.font.icon.medium
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Tokens.spacing.small

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: fileRowItem.modelData.name
                                        font: Tokens.font.body.medium
                                        color: Colours.palette.m3primary
                                        elide: Text.ElideRight
                                    }

                                    StyledText {
                                        text: "(" + root.formatBytes(fileRowItem.modelData.size) + ")"
                                        font: Tokens.font.label.medium
                                        color: Colours.palette.m3outline
                                    }
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: fileRowItem.modelData.path
                                    font: Tokens.font.label.small
                                    color: Colours.palette.m3outline
                                    elide: Text.ElideRight
                                }
                            }

                            IconButton {
                                icon: "delete"
                                onClicked: root.requestDeleteSingleFile(fileRowItem.modelData.fullPath || fileRowItem.modelData.path, fileRowItem.modelData.name)
                            }
                        }
                    }
                }
            }
        }
    }
}
