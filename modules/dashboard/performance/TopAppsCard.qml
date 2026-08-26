import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    readonly property color accent: Colours.palette.m3primary
    property var topAppsList: []

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.extraLarge

    implicitWidth: Tokens.sizes.dashboard.perfNetworkCardWidth
    implicitHeight: Tokens.sizes.dashboard.perfNetworkCardHeight

    Timer {
        id: refreshTimer
        interval: GlobalConfig.dashboard.resourceUpdateInterval || 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }

    Process {
        id: proc
        command: ["ps", "-eo", "comm,%cpu,%mem", "--no-headers"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.parseOutput(text);
            }
        }
    }

    function parseOutput(text) {
        if (!text) return;
        const lines = text.trim().split("\n");
        const map = {};
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            if (!line) continue;
            const parts = line.split(/\s+/);
            if (parts.length < 3) continue;

            let comm = parts[0].replace(/<defunct>/g, "").trim();
            if (!comm || comm.startsWith("[")) continue;

            const cpu = parseFloat(parts[1]) || 0;
            const mem = parseFloat(parts[2]) || 0;

            if (!map[comm]) {
                map[comm] = { name: comm, cpu: 0, mem: 0 };
            }
            map[comm].cpu += cpu;
            map[comm].mem += mem;
        }

        const list = [];
        for (const k in map) {
            list.push(map[k]);
        }
        list.sort((a, b) => b.cpu - a.cpu);
        root.topAppsList = list.slice(0, 4);
    }

    function getAppIcon(name) {
        const lower = name.toLowerCase();
        if (lower.includes("firefox") || lower.includes("chrome") || lower.includes("browser") || lower.includes("zen")) return "public";
        if (lower.includes("code") || lower.includes("antigravity") || lower.includes("nvim") || lower.includes("vim") || lower.includes("emacs") || lower.includes("kate")) return "code";
        if (lower.includes("quickshell") || lower.includes("caelestia")) return "widgets";
        if (lower.includes("hypr") || lower.includes("wayland") || lower.includes("xorg") || lower.includes("kwin")) return "desktop_windows";
        if (lower.includes("mpv") || lower.includes("vlc") || lower.includes("media") || lower.includes("player")) return "play_circle";
        if (lower.includes("spotify") || lower.includes("music") || lower.includes("cava")) return "music_note";
        if (lower.includes("discord") || lower.includes("telegram") || lower.includes("signal") || lower.includes("vesktop")) return "chat";
        if (lower.includes("steam") || lower.includes("game") || lower.includes("heroic")) return "sports_esports";
        if (lower.includes("term") || lower.includes("kitty") || lower.includes("alacritty") || lower.includes("foot") || lower.includes("bash") || lower.includes("zsh") || lower.includes("fish")) return "terminal";
        return "apps";
    }

    function getAppName(name) {
        const lower = name.toLowerCase();
        if (lower.includes("antigravity")) return "Antigravity IDE";
        if (lower.includes("quickshell")) return "QuickShell";
        if (lower.includes("hyprland")) return "Hyprland";
        if (lower.includes("firefox")) return "Firefox";
        if (lower.includes("chrome")) return "Chrome";
        if (lower.includes("code")) return "VS Code";
        if (lower.includes("kitty")) return "Kitty";
        if (lower.includes("alacritty")) return "Alacritty";
        return name;
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        anchors.bottomMargin: Tokens.padding.medium
        spacing: Tokens.spacing.small

        RowLayout {
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "analytics"
                color: root.accent
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                text: qsTr("Top Apps")
                font: Tokens.font.title.medium
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                text: qsTr("CPU / RAM")
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Tokens.spacing.extraSmall

            Repeater {
                model: root.topAppsList

                delegate: RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        text: root.getAppIcon(modelData.name)
                        color: Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.small
                    }

                    StyledText {
                        text: root.getAppName(modelData.name)
                        font: Tokens.font.body.medium
                        color: Colours.palette.m3onSurface
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    StyledText {
                        text: `${modelData.cpu.toFixed(1)}%`
                        font: Tokens.font.body.small
                        color: Colours.palette.m3tertiary
                    }

                    StyledText {
                        text: `${modelData.mem.toFixed(1)}%`
                        font: Tokens.font.body.small
                        color: Colours.palette.m3secondary
                    }
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Loading top apps...")
                font: Tokens.font.body.small
                color: Colours.palette.m3outline
                visible: root.topAppsList.length === 0
            }
        }
    }
}
