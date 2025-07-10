pragma Singleton

import "root:/config"
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property list<int> values: Array(Config.dashboard.visualiserBars)
    property int refCount

    Connections {
        target: Config.dashboard

        function onVisualiserBarsChanged() {
            root.values = Array(Config.dashboard.visualiserBars);
            cavaProc.running = false;
            cavaProc.running = true;
        }
    }

    Process {
        id: cavaProc

        running: true
        command: ["sh", "-c", `printf '[general]\nframerate=60\nbars=${Config.dashboard.visualiserBars}\nsleep_timer=3\n[output]\nchannels=mono\nmethod=raw\nraw_target=/dev/stdout\ndata_format=ascii\nascii_max_range=100' | cava -p /dev/stdin`]
        stdout: SplitParser {
            onRead: data => {
                if (root.refCount)
                    root.values = data.slice(0, -1).split(";").map(v => parseInt(v, 10));
            }
        }
    }
}
