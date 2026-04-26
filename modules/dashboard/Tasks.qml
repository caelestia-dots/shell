import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.misc
import qs.services
import qs.components.controls

Item {
    id: root

    readonly property int minWidth: 400 + 400 + Tokens.spacing.normal + 120 + Tokens.padding.large * 2
    readonly property int listRowHeight: 36
    readonly property int sectionRowHeight: 30
    readonly property int visibleRows: 10
    readonly property int headerRowHeight: 24
    implicitWidth: Math.max(minWidth, content.implicitWidth)
    implicitHeight: Tokens.padding.large * 2
                  + headerRowHeight
                  + Tokens.spacing.normal
                  + 1
                  + Tokens.spacing.normal
                  + (listRowHeight * visibleRows)
                  + sectionRowHeight

    property string sortField: "-%cpu"
    property var processData: []
    property var pendingProcessData: null
    property bool updatesPaused: false

    function isUserScrolling() {
        return updatesPaused || listView.moving || listView.flicking || vScrollBar.pressed;
    }

    function pauseUpdates() {
        updatesPaused = true;
        resumeUpdatesTimer.restart();
    }

    function applyProcessData(newData) {
        if (isUserScrolling()) {
            pendingProcessData = newData;
            return;
        }

        const previousY = listView.contentY;
        const previousRange = Math.max(0, listView.contentHeight - listView.height);

        root.processData = newData;

        Qt.callLater(() => {
            const newRange = Math.max(0, listView.contentHeight - listView.height);
            listView.contentY = Math.max(0, Math.min(newRange, previousY));
        });
    }

    function flushPendingProcessData() {
        if (pendingProcessData === null || isUserScrolling()) return;
        const data = pendingProcessData;
        pendingProcessData = null;
        applyProcessData(data);
    }

    Timer {
        id: resumeUpdatesTimer
        interval: 450
        repeat: false
        onTriggered: {
            updatesPaused = false;
            root.flushPendingProcessData();
        }
    }

    Timer {
        id: procTimer
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (root.isUserScrolling()) return;
            processLoader.running = true;
        }
    }

    function formatBytes(bytes) {
        if (bytes === 0) return '0 B';
        const k = 1024;
        const sizes = ['B', 'KiB', 'MiB', 'GiB', 'TiB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(i === 0 ? 0 : 2)) + ' ' + sizes[i];
    }

    Process {
        id: processLoader
        command: ["sh", "-c", "python3 ~/.config/quickshell/caelestia/utils/scripts/tasks.py " + root.sortField]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "") return;
                try {
                    let parsed = JSON.parse(text);
                    let apps = parsed.apps || [];
                    let procs = parsed.processes || [];
                    
                    let newData = [];
                    for (let app of apps) { app.section = "Apps"; newData.push(app); }
                    for (let p of procs) { p.section = "Processes"; newData.push(p); }

                    root.applyProcessData(newData);
                } catch (e) {
                    console.error("Tasks parse error:", e);
                }
            }
        }
    }

    Process {
        id: killTask
        property string pidToKill: ""
        command: ["kill", "-9", pidToKill]
        onExited: processLoader.running = true
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.normal

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small  
            StyledText {
                text: qsTr("Process Name")
                Layout.fillWidth: true
                font.bold: true
                color: Colours.palette.m3onSurface
            }
            
            HeaderButton {
                text: "CPU " + (root.sortField === "-%cpu" ? "↓" : (root.sortField === "%cpu" ? "↑" : ""))
                Layout.preferredWidth: 100
                onClicked: {
                    root.sortField = root.sortField === "-%cpu" ? "%cpu" : "-%cpu";
                    processLoader.running = true;
                }
            }

            HeaderButton {
                text: "RAM " + (root.sortField === "-%mem" ? "↓" : (root.sortField === "%mem" ? "↑" : ""))
                Layout.preferredWidth: 140
                onClicked: {
                    root.sortField = root.sortField === "-%mem" ? "%mem" : "-%mem";
                    processLoader.running = true;
                }
            }

            HeaderButton {
                text: "DISK " + (root.sortField === "-%io" ? "↓" : (root.sortField === "%io" ? "↑" : ""))
                Layout.preferredWidth: 100
                onClicked: {
                    root.sortField = root.sortField === "-%io" ? "%io" : "-%io";
                    processLoader.running = true;
                }
            }

            HeaderButton {
                text: "GPU " + (root.sortField === "-%gpu" ? "↓" : (root.sortField === "%gpu" ? "↑" : ""))
                Layout.preferredWidth: 100
                onClicked: {
                    root.sortField = root.sortField === "-%gpu" ? "%gpu" : "-%gpu";
                    processLoader.running = true;
                }
            }
            
            Item { Layout.preferredWidth: 40 /* Actions col space */ }
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Colours.palette.m3outlineVariant
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.preferredHeight: root.listRowHeight * root.visibleRows + root.sectionRowHeight
            clip: true
            interactive: true
            model: root.processData
            QQC.ScrollBar.vertical: QQC.ScrollBar {
                id: vScrollBar
                policy: QQC.ScrollBar.AsNeeded
            }

            section.property: "section"
            section.delegate: Item {
                width: ListView.view.width
                height: 30
                StyledText {
                    anchors.fill: parent
                    anchors.leftMargin: Tokens.padding.small
                    verticalAlignment: Text.AlignVCenter
                    text: section
                    font.bold: true
                    color: Colours.palette.m3primary
                }
            }

            delegate: Item {
                width: ListView.view.width
                height: root.listRowHeight

                StyledRect {
                    anchors.fill: parent
                    color: itemMouseArea.containsMouse ? Colours.layer(Colours.tPalette.m3surfaceContainer, 1) : "transparent"
                    radius: Tokens.rounding.small
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Tokens.padding.small
                        anchors.rightMargin: Tokens.padding.small
                        spacing: Tokens.spacing.small

                        StyledText {
                            text: modelData.name + (modelData.count > 1 ? (" (" + modelData.count + ")") : "")
                            Layout.fillWidth: true
                            color: Colours.palette.m3onSurface
                            elide: Text.ElideRight
                        }

                        StyledText {
                            text: modelData.cpu.toFixed(1) + "%"
                            Layout.preferredWidth: 100
                            horizontalAlignment: Text.AlignHCenter
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        StyledText {
                            text: root.formatBytes(modelData.rss)
                            Layout.preferredWidth: 140
                            horizontalAlignment: Text.AlignHCenter
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        StyledText {
                            text: modelData.io > 0 ? root.formatBytes(modelData.io) + "/s" : "0 B/s"
                            Layout.preferredWidth: 100
                            horizontalAlignment: Text.AlignHCenter
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        StyledText {
                            text: modelData.gpu > 0 ? root.formatBytes(modelData.gpu) : "-"
                            Layout.preferredWidth: 100
                            horizontalAlignment: Text.AlignHCenter
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        Item {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: parent.height

                            MouseArea {
                                anchors.centerIn: parent
                                width: 24
                                height: 24
                                cursorShape: Qt.PointingHandCursor

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    text: "close"
                                    color: Colours.palette.m3error
                                    font.pixelSize: 18
                                }

                                onClicked: {
                                    killTask.pidToKill = modelData.pid;
                                    killTask.running = true;
                                }
                            }
                        }
                    }
                    
                    MouseArea {
                        id: itemMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.RightButton

                        onClicked: (mouse) => {
                            if (mouse.button === Qt.RightButton) {
                                taskMenu.pid = modelData.pid;
                                taskMenu.popup();
                            }
                        }
                    }
                }
            }

            onMovementStarted: root.pauseUpdates()
            onMovingChanged: root.flushPendingProcessData()
            onFlickingChanged: root.flushPendingProcessData()
        }
    }

    Connections {
        target: vScrollBar
        function onPressedChanged() {
            if (vScrollBar.pressed) {
                root.pauseUpdates();
            }
            root.flushPendingProcessData();
        }
    }

    QQC.Menu {
        id: taskMenu
        property string pid: ""

        QQC.MenuItem {
            text: qsTr("Kill Process (SIGKILL)")
            onTriggered: {
                killTask.pidToKill = taskMenu.pid;
                killTask.command = ["kill", "-9", killTask.pidToKill];
                killTask.running = true;
            }
        }
        QQC.MenuItem {
            text: qsTr("Terminate Process (SIGTERM)")
            onTriggered: {
                killTask.pidToKill = taskMenu.pid;
                killTask.command = ["kill", "-15", killTask.pidToKill];
                killTask.running = true;
            }
        }
    }

    component HeaderButton: CustomMouseArea {
        id: headerBtn
        property alias text: label.text
        
        implicitHeight: 24
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        StyledRect {
            anchors.fill: parent
            color: headerBtn.containsMouse ? Colours.layer(Colours.tPalette.m3surfaceContainer, 1) : "transparent"
            radius: Tokens.rounding.small
        }

        StyledText {
            id: label
            anchors.centerIn: parent
            font.bold: true
            color: Colours.palette.m3onSurfaceVariant
        }
    }
}