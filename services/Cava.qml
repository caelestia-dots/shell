pragma Singleton

import "root:/config"
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property list<int> values
    property int refCount

    Process {
        running: true
        command: ["sh", "-c", `printf '[general]\nframerate=60\nbars=${Config.dashboard.visualiserBars}\nsleep_timer = 3\n[output]\nchannels=mono\nmethod=raw\nraw_target=/dev/stdout\ndata_format=ascii\nascii_max_range=100' | cava -p /dev/stdin`]
        stdout: SplitParser {
            onRead: data => {
                if (root.refCount)
                    root.values = data.slice(0, -1).split(";").map(v => parseInt(v, 10));
            }
        }
    }
}
