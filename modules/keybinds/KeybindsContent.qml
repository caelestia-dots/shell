pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.hallownest
import qs.services

Item {
    id: root

    // [{ name, binds: [{ description, combos: [string] }] }]
    property var sections: []
    readonly property string query: normalise(search.text.trim())
    readonly property var filtered: {
        if (!query)
            return sections;

        return sections.map(s => {
            if (normalise(s.name).includes(query))
                return s;
            return {
                name: s.name,
                binds: s.binds.filter(b => normalise(b.description).includes(query) || b.combos.some(c => normalise(c).includes(query)))
            };
        }).filter(s => s.binds.length > 0);
    }

    signal close

    function normalise(text: string): string {
        return text.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();
    }

    function modifiers(mask: int): var {
        const mods = [];
        if (mask & 64)
            mods.push(Tr.trCtx("Super", "key"));
        if (mask & 4)
            mods.push(Tr.trCtx("Ctrl", "key"));
        if (mask & 8)
            mods.push(Tr.trCtx("Alt", "key"));
        if (mask & 128)
            mods.push(Tr.trCtx("AltGr", "key"));
        if (mask & 1)
            mods.push(Tr.trCtx("Shift", "key"));
        return mods;
    }

    function keyName(key: string): string {
        const names = {
            "SUPER_L": "",
            "mouse:272": Tr.trCtx("Left click", "key"),
            "mouse:273": Tr.trCtx("Right click", "key"),
            "mouse:274": Tr.trCtx("Middle click", "key"),
            "mouse_up": Tr.trCtx("Scroll up", "key"),
            "mouse_down": Tr.trCtx("Scroll down", "key"),
            "left": "←",
            "right": "→",
            "up": "↑",
            "down": "↓",
            "Page_Up": Tr.trCtx("PgUp", "key"),
            "Page_Down": Tr.trCtx("PgDn", "key"),
            "Print": Tr.trCtx("Print", "key"),
            "Equal": "=",
            "Minus": "-",
            "Comma": ",",
            "Period": ".",
            "Backslash": "\\",
            "Slash": "/",
            "Space": Tr.trCtx("Space", "key"),
            "Delete": Tr.trCtx("Del", "key"),
            "Escape": Tr.trCtx("Esc", "key"),
            "TAB": "Tab",
            "Backspace": Tr.trCtx("Backspace", "key"),
            "Return": Tr.trCtx("Enter", "key"),
            "XF86AudioRaiseVolume": Tr.trCtx("Volume up", "key"),
            "XF86AudioLowerVolume": Tr.trCtx("Volume down", "key"),
            "XF86AudioMute": Tr.trCtx("Mute", "key"),
            "XF86AudioMicMute": Tr.trCtx("Mic mute", "key"),
            "XF86AudioPlay": Tr.trCtx("Play", "key"),
            "XF86AudioPause": Tr.trCtx("Pause", "key"),
            "XF86AudioNext": Tr.trCtx("Next", "key"),
            "XF86AudioPrev": Tr.trCtx("Previous", "key"),
            "XF86AudioStop": Tr.trCtx("Stop", "key"),
            "XF86MonBrightnessUp": Tr.trCtx("Brightness up", "key"),
            "XF86MonBrightnessDown": Tr.trCtx("Brightness down", "key"),
            "XF86PowerOff": Tr.trCtx("Power", "key")
        };
        if (key in names)
            return names[key];
        return key.length === 1 ? key.toUpperCase() : key;
    }

    function parse(binds: var): var {
        const sectionList = [];
        const byName = {};

        for (const b of binds) {
            if (!b.has_description || !b.description)
                continue;

            const sep = b.description.indexOf("|");
            const sectionName = sep === -1 ? Tr.tr("Other") : b.description.slice(0, sep);
            const description = sep === -1 ? b.description : b.description.slice(sep + 1);

            if (!byName[sectionName]) {
                byName[sectionName] = {
                    name: sectionName,
                    binds: [],
                    byDesc: {}
                };
                sectionList.push(byName[sectionName]);
            }
            const section = byName[sectionName];

            if (!section.byDesc[description]) {
                section.byDesc[description] = {
                    description,
                    keys: []
                };
                section.binds.push(section.byDesc[description]);
            }

            section.byDesc[description].keys.push({
                mods: modifiers(b.modmask),
                key: keyName(b.key)
            });
        }

        return sectionList.map(s => ({
                    name: s.name,
                    binds: s.binds.map(b => ({
                                description: b.description,
                                combos: combos(b.keys)
                            }))
                }));
    }

    // Formats key combos, collapsing runs like Super + 1 ... Super + 0 into "Super + 1…0"
    function combos(keys: var): var {
        const byMods = {};
        const order = [];
        for (const k of keys) {
            const mods = k.mods.join(" + ");
            if (!byMods[mods]) {
                byMods[mods] = [];
                order.push(mods);
            }
            if (!byMods[mods].includes(k.key))
                byMods[mods].push(k.key);
        }

        const out = [];
        for (const mods of order) {
            const ks = byMods[mods];
            const join = key => [mods, key].filter(Boolean).join(" + ");
            if (ks.length >= 5 && ks.every(k => /^\d$/.test(k)))
                out.push(join(`${ks[0]}…${ks[ks.length - 1]}`));
            else if (ks.length === 4 && ["←", "→", "↑", "↓"].every(k => ks.includes(k)))
                out.push(join(Tr.trCtx("Arrows", "key")));
            else
                for (const k of ks)
                    out.push(join(k));
        }
        return out;
    }

    Component.onCompleted: bindsProc.running = true

    Keys.onEscapePressed: close()

    Process {
        id: bindsProc

        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.sections = root.parse(JSON.parse(text));
                } catch (e) {
                    console.warn("[Keybinds] Failed to parse hyprctl binds:", e);
                }
            }
        }
    }

    // Backdrop, click to close
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha("black", 0.45)

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    HkCard {
        id: card

        property real enter

        anchors.centerIn: parent
        width: Math.min(parent.width - Tokens.padding.extraLarge * 4, 1200)
        height: Math.min(parent.height - Tokens.padding.extraLarge * 4, 860)
        ornate: true
        scale: 0.96 + enter * 0.04
        filigreeDrawn: 0

        transform: Translate {
            y: (1 - card.enter) * 10
        }

        Component.onCompleted: enterAnim.start()

        ParallelAnimation {
            id: enterAnim

            Anim {
                target: card
                property: "enter"
                from: 0
                to: 1
                type: Anim.FastSpatial
            }
            NumberAnimation {
                target: card
                property: "filigreeDrawn"
                from: 0
                to: 1
                duration: 460
                easing.type: Easing.InOutQuad
            }
        }

        // Swallow clicks so they don't reach the backdrop
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Tokens.padding.extraLarge
            spacing: Tokens.spacing.large

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.large

                MaterialIcon {
                    text: "keyboard"
                    color: Hallownest.soul
                    fontStyle: Tokens.font.icon.builders.large.build()
                }

                HkTitle {
                    Layout.fillWidth: true
                    text: Tr.tr("Keyboard shortcuts")
                    size: 16
                }

                SearchBar {
                    id: search

                    Layout.preferredWidth: 320
                    topPadding: Tokens.padding.medium
                    bottomPadding: Tokens.padding.medium
                    placeholderText: Tr.tr("Search shortcuts")
                    focus: true

                    Keys.onEscapePressed: {
                        if (text)
                            text = "";
                        else
                            root.close();
                    }
                }

                HkButton {
                    icon: "close"
                    onClicked: root.close()
                }
            }

            HkDivider {
                Layout.fillWidth: true
            }

            StyledFlickable {
                id: view

                Layout.fillWidth: true
                Layout.fillHeight: true

                clip: true
                flickableDirection: Flickable.VerticalFlick
                contentWidth: width
                contentHeight: columns.implicitHeight

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: view
                }

                // Masonry-style columns: each section goes into the currently shortest column
                RowLayout {
                    id: columns

                    readonly property int count: Math.max(1, Math.floor(view.width / 340))
                    readonly property var split: {
                        const cols = Array.from({
                            length: count
                        }, () => []);
                        const heights = new Array(count).fill(0);
                        for (const s of root.filtered) {
                            const i = heights.indexOf(Math.min(...heights));
                            cols[i].push(s);
                            heights[i] += 2 + s.binds.reduce((n, b) => n + Math.max(1, b.combos.length * 0.6), 0);
                        }
                        return cols;
                    }

                    width: view.width
                    spacing: Tokens.spacing.large

                    Repeater {
                        model: columns.split

                        ColumnLayout {
                            id: column

                            required property var modelData

                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.alignment: Qt.AlignTop
                            spacing: Tokens.spacing.large

                            Repeater {
                                model: column.modelData

                                Section {}
                            }
                        }
                    }
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                visible: root.filtered.length === 0
                text: root.sections.length ? Tr.tr("No shortcuts match \"%1\"").arg(search.text) : Tr.tr("No shortcuts with a description found")
                color: Hallownest.faint
                font: Tokens.font.body.medium
            }
        }
    }

    component Section: ColumnLayout {
        id: section

        required property var modelData

        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        HkSection {
            Layout.topMargin: 0
            Layout.leftMargin: 0
            Layout.bottomMargin: Tokens.spacing.extraSmall
            text: section.modelData.name
        }

        Repeater {
            model: section.modelData.binds

            RowLayout {
                id: bindRow

                required property var modelData

                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                StyledText {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 2
                    text: bindRow.modelData.description
                    color: Hallownest.text
                    font: Tokens.font.body.small
                    wrapMode: Text.WordWrap
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignTop | Qt.AlignRight
                    spacing: 2

                    Repeater {
                        model: bindRow.modelData.combos

                        StyledRect {
                            id: keycap

                            required property string modelData

                            Layout.alignment: Qt.AlignRight
                            implicitWidth: keyText.implicitWidth + Tokens.padding.medium * 2
                            implicitHeight: keyText.implicitHeight + Tokens.padding.extraSmall * 2
                            radius: Tokens.rounding.small
                            color: Hallownest.button
                            border.width: 1
                            border.color: Hallownest.border

                            StyledText {
                                id: keyText

                                anchors.centerIn: parent
                                text: keycap.modelData
                                color: Hallownest.soul
                                font.family: Hallownest.mono
                                font.pointSize: 8.5
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }
            }
        }
    }
}
