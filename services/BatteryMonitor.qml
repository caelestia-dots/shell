import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property real percent
    property bool plugged
    property string state

    Process {
        running: true
        command: [`${Quickshell.shellRoot}/assets/battery-monitor.py`]
        stdout: SplitParser {
            onRead: data => {
                try {
                    const json = JSON.parse(data)
                    root.percent = json.percent
                    root.plugged = json.plugged
                    root.state = json.state
                } catch (e) {
                    console.warn("Battery parse error:", data)
                }
            }
        }
    }
}
