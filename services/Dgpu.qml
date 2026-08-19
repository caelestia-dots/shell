pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

// dGPU assignments: reads the sidecar registry, probes for an NVIDIA dGPU and
// toggles apps on/off it via the generator script (gpu/dgpu_generator.py).
// The generator owns registry writes; this singleton only reads it back.
Singleton {
    id: root

    readonly property string registryPath: `${Paths.config}/dgpu.json`
    readonly property string generatorPath: `${Quickshell.shellDir}/gpu/dgpu_generator.py`

    // Desktop entry ids (with .desktop) currently assigned to the dGPU
    property var assignments: ({})

    // True when an NVIDIA GPU is present on this host (lspci probe)
    property bool nvidiaPresent: false

    function normaliseId(id: string): string {
        return id.endsWith(".desktop") ? id : `${id}.desktop`;
    }

    function isDgpu(id: string): bool {
        return root.assignments[root.normaliseId(id)] === true;
    }

    function setDgpu(id: string, on: bool): void {
        if (setProc.running)
            return;
        setProc.command = [root.generatorPath, "set", root.normaliseId(id), on ? "on" : "off"];
        setProc.running = true;
    }

    function parseRegistry(text: string): var {
        if (!text.trim())
            return {};
        try {
            const data = JSON.parse(text);
            const apps = data.apps ?? {};
            const out = {};
            for (const id of Object.keys(apps)) {
                if (apps[id] === "dGPU")
                    out[id] = true;
            }
            return out;
        } catch (e) {
            return {};
        }
    }

    FileView {
        id: registryView

        path: root.registryPath
        watchChanges: true
        printErrors: false
        onLoaded: root.assignments = root.parseRegistry(text())
        onLoadFailed: root.assignments = ({})
    }

    // Probing lspci (not the Gpu service) keeps the gate a hardware check: the
    // Services GPU monitor can be overridden by the user, the hardware cannot.
    // A dGPU means an NVIDIA card plus a second (iGPU) card on the bus.
    Process {
        id: lspciProc

        running: true
        command: ["lspci"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.nvidiaPresent = /nvidia/i.test(text) && /vga compatible controller: (intel|amd|ati)/i.test(text);
            }
        }
    }

    Process {
        id: setProc

        // Reload after every toggle: success picks up the new assignment,
        // failure reverts the optimistic UI state.
        onExited: exitCode => { // qmllint disable signal-handler-parameters
            if (exitCode !== 0)
                console.warn(`dgpu: generator 'set' failed with exit code ${exitCode}`);
            registryView.reload();
        }
    }
}
