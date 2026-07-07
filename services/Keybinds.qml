pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string hyprDir: Quickshell.env("CAELESTIA_HYPR_CONFIG_DIR") || `${Quickshell.env("XDG_CONFIG_HOME") || `${Quickshell.env("HOME")}/.config`}/hypr`

    property var groups: []
    property bool ready: false

    property string _varsText: ""
    property string _kbText: ""

    function _rebuild(): void {
        if (!_varsText || !_kbText)
            return;
        groups = _parse(_varsText, _kbText);
        ready = true;
    }

    function _parse(varsText, kbText) {
        const vars = {};
        for (const line of varsText.split("\n")) {
            const m = line.match(/^\s*([A-Za-z_]\w*)\s*=\s*"([^"]*)"/);
            if (m)
                vars[m[1]] = m[2];
        }

        const resolveVar = name => {
            const v = vars[name.replace(/^vars\./, "")];
            return v === undefined ? null : v;
        };

        function prettify(token) {
            const t = token.replace(/^caelestia:/, "");
            const spaced = t.replace(/([a-z0-9])([A-Z])/g, "$1 $2").replace(/[_-]+/g, " ");
            return spaced.charAt(0).toUpperCase() + spaced.slice(1);
        }

        function resolveExpr(expr) {
            expr = expr.trim();
            const parts = expr.split(/\s*\.\.\s*/);
            const out = parts.map(p => {
                p = p.trim();
                const str = p.match(/^"([^"]*)"$/) || p.match(/^\[\[([\s\S]*?)\]\]$/);
                if (str)
                    return str[1];
                const v = resolveVar(p);
                if (v !== null)
                    return v;
                return null;
            });
            if (out.some(x => x === null))
                return null;
            return out.join("");
        }

        function tableField(tbl, key) {
            const m = tbl.match(new RegExp(key + "\\s*=\\s*\"([^\"]*)\""));
            return m ? m[1] : null;
        }

        function deriveAction(dispatch, comment) {
            const d = dispatch.trim();
            let m;

            if ((m = d.match(/hl\.dsp\.global\(\s*"([^"]+)"/)))
                return prettify(m[1]);

            if ((m = d.match(/hl\.dsp\.exec_cmd\(([\s\S]*)\)\s*$/))) {
                const cmd = resolveExpr(m[1]);
                return cmd ? cmd.split("\n")[0] : (comment || "Run command");
            }

            if ((m = d.match(/hl\.dsp\.focus\(\{([\s\S]*)\}/))) {
                const ws = tableField(m[1], "workspace");
                if (ws !== null)
                    return "Focus workspace " + ws;
                const dir = tableField(m[1], "direction");
                if (dir !== null)
                    return "Focus window " + dir;
                return "Focus";
            }

            if ((m = d.match(/hl\.dsp\.window\.move\(\{([\s\S]*)\}/))) {
                const ws = tableField(m[1], "workspace");
                if (ws !== null)
                    return "Move window to workspace " + ws;
                const dir = tableField(m[1], "direction");
                if (dir !== null)
                    return "Move window " + dir;
                if (/out_of_group/.test(m[1]))
                    return "Move window out of group";
                return "Move window";
            }

            if ((m = d.match(/hl\.dsp\.window\.(\w+)/))) {
                const map = {
                    resize: "Resize window",
                    close: "Close window",
                    float: "Toggle floating",
                    fullscreen: /maximized/.test(d) ? "Maximise window" : "Fullscreen window",
                    pin: "Pin window",
                    center: "Centre window",
                    drag: "Drag window",
                    cycle_next: /next\s*=\s*false/.test(d) ? "Cycle group previous" : "Cycle group next"
                };
                return map[m[1]] || prettify(m[1]);
            }

            if ((m = d.match(/hl\.dsp\.group\.(\w+)/))) {
                const map = {
                    next: "Next in group",
                    prev: "Previous in group",
                    toggle: "Toggle group",
                    lock_active: "Lock group"
                };
                return map[m[1]] || prettify(m[1]);
            }

            return comment || "Custom action";
        }

        function splitArgs(s) {
            const args = [];
            let depth = 0, buf = "", inStr = null;
            for (let i = 0; i < s.length; i++) {
                const c = s[i];
                if (inStr) {
                    buf += c;
                    if (c === inStr)
                        inStr = null;
                    continue;
                }
                if (c === '"' || c === "'") {
                    inStr = c;
                    buf += c;
                    continue;
                }
                if (c === "(" || c === "{" || c === "[")
                    depth++;
                else if (c === ")" || c === "}" || c === "]")
                    depth--;
                if (c === "," && depth === 0) {
                    args.push(buf);
                    buf = "";
                    continue;
                }
                buf += c;
            }
            if (buf.trim())
                args.push(buf);
            return args;
        }

        const groups = [];
        const groupOf = name => {
            let g = groups.find(g => g.category === name);
            if (!g) {
                g = {
                    category: name,
                    binds: []
                };
                groups.push(g);
            }
            return g;
        };

        let curComment = "General";
        const lines = kbText.split("\n");
        let li = 0;
        while (li < lines.length) {
            const raw = lines[li];
            const trimmed = raw.trim();

            const cm = trimmed.match(/^--\s*(.*)$/);
            if (cm && cm[1] && !/maps to key/.test(cm[1])) {
                curComment = cm[1].trim();
                li++;
                continue;
            }

            const bidx = raw.indexOf("hl.bind(");
            if (bidx === -1) {
                li++;
                continue;
            }

            let acc = "";
            let depth = 0;
            let started = false;
            let j = li;
            const startCol = bidx + "hl.bind".length;
            let done = false;
            for (; j < lines.length && !done; j++) {
                const l = lines[j];
                const from = j === li ? startCol : 0;
                for (let k = from; k < l.length; k++) {
                    const c = l[k];
                    if (c === "(") {
                        depth++;
                        started = true;
                        if (depth === 1)
                            continue;
                    } else if (c === ")") {
                        depth--;
                        if (depth === 0) {
                            done = true;
                            break;
                        }
                    }
                    if (started)
                        acc += c;
                }
                if (started && !done)
                    acc += "\n";
            }
            li = j;

            const args = splitArgs(acc);
            if (args.length < 2)
                continue;

            const keys = resolveExpr(args[0].trim());
            if (keys === null)
                continue;

            groupOf(curComment).binds.push({
                keys: normalizeKeys(keys),
                action: deriveAction(args[1].trim(), curComment)
            });
        }

        const loop = kbText.match(/for\s+i\s*=\s*1,\s*10\s+do([\s\S]*?)end/);
        if (loop) {
            const body = loop[1];
            const bindRe = /hl\.bind\(\s*([A-Za-z_.]+)\s*\.\.\s*"\s*\+\s*"\s*\.\.\s*key\s*,\s*fn\.wsaction\(\s*"(\w+)"\s*,\s*"(\w*)"/g;
            let lm;
            const wsGroup = groupOf("Workspaces");
            while ((lm = bindRe.exec(body))) {
                const base = resolveVar(lm[1]);
                if (base === null)
                    continue;
                const move = lm[2] === "move";
                const grp = lm[3] === "group";
                const action = (move ? "Move window to " : "Focus ") + (grp ? "workspace group " : "workspace ") + "1–10";
                wsGroup.binds.unshift({
                    keys: normalizeKeys(base) + " + 1…0",
                    action
                });
            }
        }

        return groups.filter(g => g.binds.length > 0);
    }

    function normalizeKeys(keys) {
        const order = ["SUPER", "CTRL", "ALT", "SHIFT"];
        const modName = {
            SUPER: "Super",
            CTRL: "Ctrl",
            ALT: "Alt",
            SHIFT: "Shift"
        };
        const special = {
            SUPER_L: "Super",
            SUPER_R: "Super",
            LEFT: "←",
            RIGHT: "→",
            UP: "↑",
            DOWN: "↓",
            "MOUSE_DOWN": "Scroll ↓",
            "MOUSE_UP": "Scroll ↑",
            "MOUSE:272": "LMB",
            "MOUSE:273": "RMB",
            PAGE_UP: "Page Up",
            PAGE_DOWN: "Page Down",
            BACKSLASH: "\\",
            MINUS: "−",
            EQUAL: "=",
            COMMA: ",",
            PERIOD: ".",
            SPACE: "Space",
            ESCAPE: "Esc",
            DELETE: "Del",
            TAB: "Tab",
            PRINT: "Print",
            XF86MONBRIGHTNESSUP: "Brightness +",
            XF86MONBRIGHTNESSDOWN: "Brightness −",
            XF86AUDIOPLAY: "Play",
            XF86AUDIOPAUSE: "Pause",
            XF86AUDIONEXT: "Next",
            XF86AUDIOPREV: "Prev",
            XF86AUDIOSTOP: "Stop",
            XF86AUDIORAISEVOLUME: "Vol +",
            XF86AUDIOLOWERVOLUME: "Vol −",
            XF86AUDIOMUTE: "Mute",
            XF86AUDIOMICMUTE: "Mic mute"
        };

        const tokens = keys.split("+").map(t => t.trim()).filter(Boolean);
        const mods = [];
        const rest = [];
        for (const t of tokens) {
            const up = t.toUpperCase();
            if (order.includes(up)) {
                if (!mods.includes(up))
                    mods.push(up);
            } else {
                rest.push(t);
            }
        }
        mods.sort((a, b) => order.indexOf(a) - order.indexOf(b));

        const pretty = k => {
            const up = k.toUpperCase();
            if (special[up])
                return special[up];
            if (/^F\d{1,2}$/i.test(k))
                return k.toUpperCase();
            if (k.length === 1)
                return k.toUpperCase();
            return k.replace(/^XF86/, "").replace(/([a-z])([A-Z])/g, "$1 $2").replace(/_+/g, " ").replace(/\b\w/g, c => c.toUpperCase());
        };

        const restPretty = rest.filter(k => !(mods.includes("SUPER") && /^SUPER_[LR]$/i.test(k))).map(pretty);
        return [...mods.map(m => modName[m]), ...restPretty].join(" + ");
    }

    FileView {
        path: `${root.hyprDir}/variables.lua`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            root._varsText = text();
            root._rebuild();
        }
    }

    FileView {
        path: `${root.hyprDir}/hyprland/keybinds.lua`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            root._kbText = text();
            root._rebuild();
        }
    }
}
