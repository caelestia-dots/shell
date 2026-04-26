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
    implicitWidth: Math.max(minWidth, content.implicitWidth)
    implicitHeight: 400

    property string sortField: "-%cpu"
    property var processData: []

    Timer {
        id: procTimer
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            processLoader.running = true;
        }
    }

    Process {
        id: processLoader
        command: ["sh", "-c", `ps axo pid,comm,%cpu,%mem --sort=${root.sortField} | head -n 16 | tail -n +2`]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                let newData = [];
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i].trim();
                    if (line.length === 0) continue;
                    
                    // Matches format from ps output
                    const parts = line.match(/^(\d+)\s+(.+?)\s+([0-9.]+)\s+([0-9.]+)$/);
                    if (parts && parts.length === 5) {
                        newData.push({
                            pid: parts[1],
                            name: parts[2],
                            cpu: parts[3],
                            mem: parts[4]
                        });
                    }
                }
                root.processData = newData;
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
                text: "CPU % " + (root.sortField === "-%cpu" ? "↓" : (root.sortField === "%cpu" ? "↑" : ""))
                Layout.preferredWidth: 60
                onClicked: {
                    root.sortField = root.sortField === "-%cpu" ? "%cpu" : "-%cpu";
                    processLoader.running = true;
                }
            }

            HeaderButton {
                text: "MEM % " + (root.sortField === "-%mem" ? "↓" : (root.sortField === "%mem" ? "↑" : ""))
                Layout.preferredWidth: 60
                onClicked: {
                    root.sortField = root.sortField === "-%mem" ? "%mem" : "-%mem";
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
            Layout.fillHeight: true
            clip: true
            model: root.processData

            delegate: Item {
                width: ListView.view.width
                height: 36

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
                            text: modelData.name
                            Layout.fillWidth: true
                            color: Colours.palette.m3onSurface
                            elide: Text.ElideRight
                        }

                        StyledText {
                            text: modelData.cpu
                            Layout.preferredWidth: 60
                            horizontalAlignment: Text.AlignRight
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        StyledText {
                            text: modelData.mem
                            Layout.preferredWidth: 60
                            horizontalAlignment: Text.AlignRight
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        Item {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: parent.height

                            CustomMouseArea {
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
                    
                    CustomMouseArea {
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