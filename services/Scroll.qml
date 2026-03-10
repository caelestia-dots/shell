pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // ── Public properties (mirror Hypr.* interface) ──────────────────────────

    property var workspaces:     ({ values: [] })
    property var toplevels:      ({ values: [] })
    property var activeToplevel: null
    property var focusedMonitor: null
    property var focusedWorkspace: null
    property int activeWsId:      0

    // Keyboard
    property string kbLayoutFull:    ""
    property string kbLayout:        ""
    property string defaultKbLayout: ""

    // Hardcoded — no clean IPC equivalent in sway/scroll
    property bool capsLock: false
    property bool numLock:  false

    // ── dispatch(cmd: string) ─────────────────────────────────────────────────
    // Accepts a space-separated command string, e.g. "workspace 3"
    // NOTE: will break for args that contain spaces — fine for current usage
    function dispatch(cmd) {
        var parts = cmd.trim().split(/\s+/)
        Quickshell.execDetached(["scrollmsg"].concat(parts))
    }

    // ── monitorFor(screen) ────────────────────────────────────────────────────
    // Matches a Quickshell ShellScreen to our monitor objects by geometry origin
    function monitorFor(screen) {
        if (!screen) return null
        var arr = root.workspaces.values  // unused — iterate monitors instead
        for (var i = 0; i < _monitors.length; i++) {
            var m = _monitors[i]
            if (m.rect.x === screen.x && m.rect.y === screen.y)
                return m
        }
        return null
    }

    // ── Internal state ────────────────────────────────────────────────────────

    property var _monitors: []    // raw monitor array (also exposed via focusedMonitor)
    property var _windowCounts: ({})  // wsId -> window count from last tree walk
    property bool _available: false

    // ── Availability check ────────────────────────────────────────────────────

    Process {
        id: checkProc
        command: ["which", "scrollmsg"]
        onExited: (code) => {
            if (code === 0) {
                root._available = true
                outputsProc.running = true
            } else {
                console.warn("Scroll: scrollmsg not found — service disabled")
            }
        }
    }

    // ── get_outputs ───────────────────────────────────────────────────────────

    Process {
        id: outputsProc
        command: ["scrollmsg", "-t", "get_outputs"]
        stdout: SplitParser {
            onRead: (line) => {
                if (!line.trim()) return
                try {
                    var outputs = JSON.parse(line)
                    root._monitors = outputs.map(function(o) {
                        return {
                            name: o.name,
                            focused: o.focused,
                            current_workspace: String(o.current_workspace),
                            rect: o.rect,
                            activeWorkspace: { id: parseInt(o.current_workspace) || 0 }
                        }
                    })
                    // Now we have outputs — start the rest
                    if (!treeProc.running)   treeProc.running = true
                    if (!wsProc.running)     wsProc.running = true
                    if (!inputsProc.running) inputsProc.running = true
                    if (!eventProc.running)  eventProc.running = true
                    root._updateFocusedMonitor()
                } catch(e) {
                    console.error("Scroll: get_outputs parse error:", e)
                }
            }
        }
    }

    // ── get_tree ──────────────────────────────────────────────────────────────

    Process {
        id: treeProc
        command: ["scrollmsg", "-t", "get_tree"]
        stdout: SplitParser {
            onRead: (line) => {
                if (!line.trim()) return
                try {
                    var tree = JSON.parse(line)
                    var windows = []
                    var counts  = {}
                    root._walkTree(tree, null, windows, counts)
                    root._windowCounts = counts
                    root.toplevels = { values: windows }
                    // Update active toplevel
                    var active = windows.find(function(w) { return w.focused }) || null
                    root.activeToplevel = active
                    // Patch window counts into workspaces
                    root._patchWindowCounts()
                } catch(e) {
                    console.error("Scroll: get_tree parse error:", e)
                }
            }
        }
    }

    // ── get_workspaces ────────────────────────────────────────────────────────

    Process {
        id: wsProc
        command: ["scrollmsg", "-t", "get_workspaces"]
        stdout: SplitParser {
            onRead: (line) => {
                if (!line.trim()) return
                try {
                    var wsList = JSON.parse(line)
                    var ws = wsList.map(function(w) {
                        return {
                            id:      w.num,
                            name:    w.name,
                            output:  w.output,
                            focused: w.focused,
                            lastIpcObject: {
                                windows: root._windowCounts[w.num] || 0
                            }
                        }
                    })
                    root.workspaces = { values: ws }
                    var focused = ws.find(function(w) { return w.focused }) || null
                    root.focusedWorkspace = focused
                    root.activeWsId = focused ? focused.id : 0
                } catch(e) {
                    console.error("Scroll: get_workspaces parse error:", e)
                }
            }
        }
    }

    // ── get_inputs ────────────────────────────────────────────────────────────

    Process {
        id: inputsProc
        command: ["scrollmsg", "-t", "get_inputs"]
        stdout: SplitParser {
            onRead: (line) => {
                if (!line.trim()) return
                try {
                    var inputs = JSON.parse(line)
                    var kb = inputs.find(function(i) {
                        return i.type === "keyboard"
                            && i.xkb_layout_names
                            && i.xkb_layout_names.length > 0
                    })
                    if (kb) {
                        root.kbLayoutFull    = kb.xkb_active_layout_name || ""
                        root.defaultKbLayout = kb.xkb_layout_names[0]   || ""
                        root.kbLayout        = root.kbLayoutFull.substring(0, 2)
                    }
                } catch(e) {
                    console.error("Scroll: get_inputs parse error:", e)
                }
            }
        }
    }

    // ── Event subscription ────────────────────────────────────────────────────
    // scrollmsg emits newline-delimited JSON objects on the subscribe stream

    Process {
        id: eventProc
        command: ["scrollmsg", "-t", "subscribe", '["workspace","window","input"]']
        stdout: SplitParser {
            onRead: (line) => {
                if (!line.trim()) return
                try {
                    var ev = JSON.parse(line)
                    root._handleEvent(ev)
                } catch(e) {
                    // Partial line or non-JSON — ignore
                }
            }
        }
        onExited: (code) => {
            // Restart subscription if it dies unexpectedly
            if (root._available)
                Qt.callLater(function() { eventProc.running = true })
        }
    }

    // ── Internal helpers ──────────────────────────────────────────────────────

    function _handleEvent(ev) {
        var type   = ev.type   || ""
        var change = ev.change || ""

        if (type === "workspace") {
            if (["focus","init","empty","rename"].indexOf(change) !== -1) {
                outputsProc.running = false
                outputsProc.running = true
                wsProc.running = false
                wsProc.running = true
            }
        } else if (type === "window") {
            if (["new","close","focus","move","title"].indexOf(change) !== -1) {
                treeProc.running = false
                treeProc.running = true
                wsProc.running = false
                wsProc.running = true
            }
        } else if (type === "input") {
            if (change === "xkb_layout" && ev.input) {
                root.kbLayoutFull = ev.input.xkb_active_layout_name || root.kbLayoutFull
                root.kbLayout     = root.kbLayoutFull.substring(0, 2)
            }
        }
    }

    // Recursive tree walker — fills `windows` array and `counts` map
    function _walkTree(node, currentWsId, windows, counts) {
        if (!node) return

        var wsId = currentWsId

        // Track workspace context
        if (node.type === "workspace") {
            wsId = node.num
        }

        // Is this node a real window?
        var isWindow = (node.type === "con" || node.type === "floating_con")
                    && (node.app_id || (node.window_properties && node.window_properties.class))

        if (isWindow) {
            var appClass = node.app_id
                        || (node.window_properties && node.window_properties.class)
                        || ""
            windows.push({
                id:        node.id,
                title:     node.name || "",
                focused:   !!node.focused,
                workspace: { id: wsId },
                lastIpcObject: { class: appClass }
            })
            // Count windows per workspace
            if (wsId !== null) {
                counts[wsId] = (counts[wsId] || 0) + 1
            }
        }

        // Recurse into children
        var children = (node.nodes || []).concat(node.floating_nodes || [])
        for (var i = 0; i < children.length; i++) {
            _walkTree(children[i], wsId, windows, counts)
        }
    }

    // After a tree refresh, backfill window counts into workspace objects
    function _patchWindowCounts() {
        var ws = root.workspaces.values
        if (!ws || ws.length === 0) return
        var patched = ws.map(function(w) {
            return Object.assign({}, w, {
                lastIpcObject: { windows: root._windowCounts[w.id] || 0 }
            })
        })
        root.workspaces = { values: patched }
    }

    function _updateFocusedMonitor() {
        for (var i = 0; i < root._monitors.length; i++) {
            if (root._monitors[i].focused) {
                root.focusedMonitor = root._monitors[i]
                return
            }
        }
    }

    // ── Bootstrap ─────────────────────────────────────────────────────────────
    Component.onCompleted: {
        checkProc.running = true
    }
}
