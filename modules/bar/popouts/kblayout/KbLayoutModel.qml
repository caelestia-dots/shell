pragma ComponentBehavior: Bound

import QtQuick

import Quickshell
import Quickshell.Io

import qs.config
import Caelestia

Item {
    id: model
    visible: false

    ListModel {
        id: _visibleModel
    }
    property alias visibleModel: _visibleModel

    property string activeLabel: ""
    property int activeIndex: -1

    function start() {
        _xkbXmlBase.running = true;
        _getKbLayoutOpt.running = true;
    }

    function refresh() {
        _notifiedLimit = false;
        _getKbLayoutOpt.running = true;
    }

    function switchTo(idx) {
        _switchProc.command = ["hyprctl", "switchxkblayout", "all", String(idx)];
        _switchProc.running = true;
    }

    ListModel {
        id: _layoutsModel
    }

    property var _xkbMap: ({})
    property bool _notifiedLimit: false

    Process {
        id: _xkbXmlBase
        command: ["xmllint", "--xpath", "//layout/configItem[name and description]", "/usr/share/X11/xkb/rules/base.xml"]
        stdout: StdioCollector {
            onStreamFinished: _buildXmlMap(text)
        }
        onRunningChanged: if (!running && (typeof exitCode !== "undefined") && exitCode !== 0)
            _xkbXmlEvdev.running = true
    }

    Process {
        id: _xkbXmlEvdev
        command: ["xmllint", "--xpath", "//layout/configItem[name and description]", "/usr/share/X11/xkb/rules/evdev.xml"]
        stdout: StdioCollector {
            onStreamFinished: _buildXmlMap(text)
        }
    }

    function _buildXmlMap(xml) {
        const map = {};

        const re = /<name>\s*([^<]+?)\s*<\/name>[\s\S]*?<description>\s*([^<]+?)\s*<\/description>/g;

        let m;
        while ((m = re.exec(xml)) !== null) {
            const code = (m[1] || "").trim();
            const desc = (m[2] || "").trim();
            if (!code || !desc)
                continue;
            map[code] = _short(desc);
        }

        if (Object.keys(map).length === 0)
            return;

        _xkbMap = map;

        if (_layoutsModel.count > 0) {
            const tmp = [];
            for (let i = 0; i < _layoutsModel.count; i++) {
                const it = _layoutsModel.get(i);
                tmp.push({
                    layoutIndex: it.layoutIndex,
                    token: it.token,
                    label: _pretty(it.token)
                });
            }
            _layoutsModel.clear();
            tmp.forEach(t => _layoutsModel.append(t));
            _fetchActiveLayouts.running = true;
        }
    }

    function _short(desc) {
        const m = desc.match(/^(.*)\((.*)\)$/);
        if (!m)
            return desc;
        const lang = m[1].trim();
        const region = m[2].trim();
        const code = (region.split(/[,\s-]/)[0] || region).slice(0, 2).toUpperCase();
        return `${lang} (${code})`;
    }

    Process {
        id: _getKbLayoutOpt
        command: ["hyprctl", "-j", "getoption", "input:kb_layout"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text);
                    const raw = (j?.str || j?.value || "").toString().trim();
                    if (raw.length) {
                        _setLayouts(raw);
                        _fetchActiveLayouts.running = true;
                        return;
                    }
                } catch (e) {}
                _fetchLayoutsFromDevices.running = true;
            }
        }
    }

    Process {
        id: _fetchLayoutsFromDevices
        command: ["hyprctl", "-j", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const dev = JSON.parse(text);
                    const kb = dev?.keyboards?.find(k => k.main) || dev?.keyboards?.[0];
                    const raw = (kb?.layout || "").trim();
                    if (raw.length)
                        _setLayouts(raw);
                } catch (e) {}
                _fetchActiveLayouts.running = true;
            }
        }
    }

    Process {
        id: _fetchActiveLayouts
        command: ["hyprctl", "-j", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const dev = JSON.parse(text);
                    const kb = dev?.keyboards?.find(k => k.main) || dev?.keyboards?.[0];
                    const idx = kb?.active_layout_index ?? -1;

                    activeIndex = idx >= 0 ? idx : -1;
                    activeLabel = (idx >= 0 && idx < _layoutsModel.count) ? _layoutsModel.get(idx).label : "";
                } catch (e) {
                    activeIndex = -1;
                    activeLabel = "";
                }

                _rebuildVisible();
            }
        }
    }

    Process {
        id: _switchProc
        onRunningChanged: if (!running)
            _fetchActiveLayouts.running = true
    }

    function _setLayouts(raw) {
        const parts = raw.split(",").map(s => s.trim()).filter(Boolean);
        _layoutsModel.clear();

        const seen = new Set();
        let idx = 0;

        for (const p of parts) {
            if (seen.has(p))
                continue;
            seen.add(p);
            _layoutsModel.append({
                layoutIndex: idx,
                token: p,
                label: _pretty(p)
            });
            idx++;
        }
    }

    function _rebuildVisible() {
        _visibleModel.clear();

        let arr = [];
        for (let i = 0; i < _layoutsModel.count; i++)
            arr.push(_layoutsModel.get(i));

        arr = arr.filter(i => i.layoutIndex !== activeIndex);
        arr.forEach(i => _visibleModel.append(i));

        if (!Config.utilities.toasts.kbLimit)
            return;

        if (_layoutsModel.count > 4) {
            Toaster.toast(qsTr("Keyboard layout limit"), qsTr("XKB supports only 4 layouts at a time"), "warning");
        }
    }

    function _pretty(token) {
        const code = token.replace(/\(.*\)$/, "").trim();
        if (_xkbMap[code])
            return code.toUpperCase() + " - " + _xkbMap[code];
        return code.toUpperCase() + " - " + code;
    }
}
