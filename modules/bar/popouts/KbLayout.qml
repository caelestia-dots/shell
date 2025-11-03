pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.components
import qs.components.controls
import qs.services
import qs.config

ColumnLayout {
    id: root
    spacing: Appearance.spacing.normal

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    ListModel { id: layoutsModel }   // roles: layoutIndex(int), token(string), label(string)
    property int activeIndex: -1
    property string activeLabel: ""
    property int maxListHeight: 320

    property color accentColor: (Appearance && Appearance.accent) ? Appearance.accent : "#5B9EFF"

    Process {
        id: getKbLayoutOpt
        command: ["hyprctl", "-j", "getoption", "input:kb_layout"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text)
                    const raw = (j && (j.str || j.value) || "").toString().trim()
                    if (raw.length) {
                        setLayoutsFromString(raw)
                        fetchActiveLayouts.running = true
                        return
                    }
                } catch (e) { /* fall through */ }
                fetchLayoutsFromDevices.running = true
            }
        }
    }

    Process {
        id: fetchLayoutsFromDevices
        command: ["hyprctl", "-j", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const dev = JSON.parse(text)
                    const kb = (dev && dev.keyboards) ? (dev.keyboards.find(k => k.main) || dev.keyboards[0]) : null
                    const raw = (kb && kb.layout ? kb.layout : "").toString().trim()
                    if (raw.length) {
                        setLayoutsFromString(raw)
                    }
                } catch (e) { /* no-op */ }
                fetchActiveLayouts.running = true
            }
        }
    }

    Process {
        id: fetchActiveLayouts
        command: ["hyprctl", "-j", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const dev = JSON.parse(text)
                    const kb = (dev && dev.keyboards) ? (dev.keyboards.find(k => k.main) || dev.keyboards[0]) : null

                    let idx = -1
                    if (kb && typeof kb.active_layout_index === "number") {
                        idx = kb.active_layout_index
                    } else if (kb && typeof kb.active_keymap === "string") {
                        const keymap = kb.active_keymap.toLowerCase()
                        for (let i = 0; i < layoutsModel.count; i++) {
                            const tok = layoutsModel.get(i).token.toLowerCase()
                            if (keymap.includes(tok)) { idx = i; break }
                        }
                    }

                    root.activeIndex = (typeof idx === "number" && idx >= 0) ? idx : -1
                    root.activeLabel = (root.activeIndex >= 0 && root.activeIndex < layoutsModel.count)
                        ? layoutsModel.get(root.activeIndex).label
                        : ""
                } catch (e) {
                    root.activeIndex = -1
                    root.activeLabel = ""
                }
            }
        }
    }

    Process {
        id: switchProc
        onRunningChanged: {
            if (!running) {
                fetchActiveLayouts.running = true
            }
        }
    }

    function setLayoutsFromString(raw) {
        const parts = raw.split(",")
            .map(s => s.trim())
            .filter(s => s.length > 0)

        layoutsModel.clear()
        const seen = new Set()
        let idx = 0
        for (const p of parts) {
            if (seen.has(p)) continue
            seen.add(p)
            const base = p.replace(/\(.*\)$/,"") // strip variant for pretty name lookup
            const pretty = prettyNameFor(base) || p
            layoutsModel.append({
                layoutIndex: idx,
                token: p,
                label: pretty
            })
            idx++
        }
    }

    function prettyNameFor(code) {
        const map = {
            "us": "English (US)",
            "gb": "English (UK)",
            "ee": "Estonian",
            "ru": "Russian",
            "de": "German",
            "fr": "French",
            "es": "Spanish",
            "it": "Italian",
            "pt": "Portuguese",
            "br": "Portuguese (BR)",
            "se": "Swedish",
            "no": "Norwegian",
            "fi": "Finnish",
            "dk": "Danish",
            "pl": "Polish",
            "cz": "Czech",
            "sk": "Slovak",
            "hu": "Hungarian",
            "tr": "Turkish",
            "gr": "Greek",
            "il": "Hebrew",
            "ua": "Ukrainian",
            "ro": "Romanian",
            "bg": "Bulgarian",
            "lv": "Latvian",
            "lt": "Lithuanian",
            "jp": "Japanese",
            "kr": "Korean",
            "cn": "Chinese",
            "tw": "Chinese (Taiwan)"
        }
        return map[code] || null
    }

    Component.onCompleted: getKbLayoutOpt.running = true

    Column {
        id: content
        spacing: Appearance.spacing.normal
        Layout.fillWidth: true

        StyledText {
            text: qsTr("Keyboard Layouts")
            font.weight: 600
            padding: 2
        }

        ListView {
            id: list
            model: layoutsModel
            clip: true
            interactive: true
            implicitWidth: Math.max(220, contentWidth)
            implicitHeight: Math.min(contentHeight, root.maxListHeight)

            delegate: Item {
                required property int layoutIndex
                required property string token
                required property string label

                width: list.width
                height: Math.max(28, rowText.implicitHeight + 10)

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: 8
                    visible: (layoutIndex === root.activeIndex)
                    color: root.accentColor
                    opacity: 0.20
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        switchProc.command = ["hyprctl", "switchxkblayout", "all", String(layoutIndex)]
                        switchProc.running = true
                        root.activeIndex = layoutIndex
                        root.activeLabel = label
                    }
                }

                StyledText {
                    id: rowText
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    text: label
                    font.weight: (layoutIndex === root.activeIndex ? 700 : 500)
                    opacity: (layoutIndex === root.activeIndex ? 1.0 : 0.95)
                }
            }
        }
    }
}
