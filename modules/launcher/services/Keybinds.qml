pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

QtObject {
    id: root

    readonly property string hyprConfPath: Paths.home + "/.config/hypr/hyprland.conf"
    property var keybinds: []
    property bool initialized: false

    signal loaded()

    property Process reader: Process {
        running: false
        command: ["sh", "-c", "grep -rhE '^bind\\s*=' " + hyprConfPath.substring(0, hyprConfPath.lastIndexOf('/')) + "/ 2>/dev/null; grep -rhE '^\\$[a-zA-Z_][a-zA-Z0-9_]*\\s*=' " + hyprConfPath.substring(0, hyprConfPath.lastIndexOf('/')) + "/ 2>/dev/null | sort"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split('\n').map(l => l.trim()).filter(l => l);
                const bindLines = lines.filter(l => l.startsWith('bind'));
                const varLines = lines.filter(l => l.startsWith('$'));

                const vars = extractVariables(varLines);
                keybinds = bindLines.map(l => parseBindLine(l, vars)).filter(b => b);
                initialized = true;
                root.loaded();
            }
        }
    }

    function extractVariables(lines) {
        const vars = {};
        for (const line of lines) {
            const trimmed = line.trim();
            if (trimmed.startsWith('$')) {
                const idx = trimmed.indexOf('=');
                if (idx > 0) {
                    const name = trimmed.substring(1, idx).trim();
                    const value = trimmed.substring(idx + 1).trim();
                    if (!vars[name]) {
                        vars[name] = value;
                    }
                }
            }
        }
        return vars;
    }

    function expandVars(text, vars) {
        let result = text;
        for (const [name, value] of Object.entries(vars)) {
            const regex = new RegExp('\\$' + name + '(?=\\W|$)', 'g');
            result = result.replace(regex, value || '');
        }
        return result;
    }

    function loadKeybinds() {
        if (initialized && keybinds.length > 0) {
            return;
        }
        keybinds = [];
        initialized = false;
        reader.running = true;
    }

    function formatBind(bind: string): string {
        if (!bind) return "";
        const modifiers = ["SUPER", "SHIFT", "CTRL", "ALT", "CONTROL", "SHIFTCTRL", "SUPERALT", "CTRLSHIFT", "SUPERSHIFT"];
        let result = bind;
        for (const mod of modifiers) {
            const regex = new RegExp(mod, 'gi');
            result = result.replace(regex, (match) => match.charAt(0).toUpperCase() + match.slice(1).toLowerCase());
        }
        const parts = result.split(',').map(p => p.trim());
        const formattedParts = parts.map(p => {
            let part = p;
            const plusRegex = /\+([^+\s]+)/g;
            part = part.replace(plusRegex, (match, key) => " + " + key);
            return part;
        });
        return formattedParts.join(" + ");
    }

    function parseBindLine(line, vars) {
        const bindMatch = line.match(/^bind[aeilmnr]?\s*=\s*(.+)$/);
        if (!bindMatch)
            return null;

        const expanded = expandVars(bindMatch[1], vars);
        const parts = expanded.split(',').map(p => p.trim());

        if (parts.length < 3)
            return null;

        const modifiers = parts[0];
        const key = parts[1];
        const action = parts.slice(2).join(', ');

        let bindText = modifiers;
        if (key && key !== '')
            bindText += "," + key;

        return {
            bind: formatBind(bindText),
            action: action
        };
    }

    function query(searchText) {
        if (!searchText)
            return keybinds;

        const query = searchText.toLowerCase();
        return keybinds.filter(k =>
            k.bind.toLowerCase().includes(query) ||
            k.action.toLowerCase().includes(query)
        );
    }

    Component.onCompleted: loadKeybinds()
}