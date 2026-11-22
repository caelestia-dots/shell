pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root

    readonly property var styles: JSON.parse(stylesFile.text())
    readonly property var styleData: styles[style] ?? styles.hallownest
    readonly property var tone: styleData.flavours[flavour] ?? styleData.flavours.vessel
    // Light styles keep the same order: every level steps away from void_, which here is the lightest
    readonly property bool light: styleData.light ?? false
    readonly property bool isMono: styleData.mono ?? false
    readonly property color void_: styleData.base.void
    readonly property color shell: styleData.base.shell
    readonly property color card: styleData.base.card
    readonly property color button: styleData.base.button
    readonly property color steel: tone.steel
    readonly property color border: Qt.alpha(steel, 0.15)
    readonly property color soul: tone.accent
    readonly property color text: styleData.base.text
    readonly property color subtext: styleData.base.subtext
    readonly property color faint: styleData.base.faint
    readonly property color lifeblood: styleData.charms.lifeblood
    readonly property color lifebloodDeep: styleData.charms.lifebloodDeep
    readonly property color lifebloodSoft: styleData.charms.lifebloodSoft
    readonly property color glowBlue: styleData.charms.glowBlue
    readonly property color hotSpring: styleData.charms.hotSpring
    readonly property color infection: styleData.charms.infection
    readonly property color grimm: styleData.charms.grimm
    readonly property color gold: styleData.charms.gold
    readonly property color unn: styleData.charms.unn
    readonly property color crystal: styleData.charms.crystal
    readonly property var charms: [grimm, gold, unn, crystal]

    readonly property var flavours: ["vessel", "lifeblood", "infection", "greenpath"]
    readonly property var styleNames: Object.keys(styles)
    property string style: "hallownest"
    property string flavour: "vessel"
    // Folder in assets/schemes/hollowknight, also the caelestia flavour
    readonly property string schemeFlavour: style === "hallownest" ? flavour : `${style}-${flavour}`
    property bool loaded
    property var pending: null
    readonly property bool transitioning: applyDelay.running

    readonly property string serif: cinzel.status === FontLoader.Ready ? cinzel.name : "serif"
    readonly property string bodySerif: "Noto Serif"
    readonly property string mono: "JetBrainsMono Nerd Font"

    // Hover/raised tint: shifts perceptually toward `text` so all dark and light styles stay hue-consistent
    function raise(c: color, k: real): color {
        const strength = Math.max(0, Math.min(0.24, (k - 1) * (light ? 0.12 : 0.18)));
        return Qt.tint(c, Qt.alpha(text, strength));
    }

    // The icon theme is rebuilt by these scripts; Icons rescans it once they finish
    function runThemeScripts(command: var): void {
        if (themeScripts.running) {
            themeScripts.next = command;
        } else {
            themeScripts.command = command;
            themeScripts.running = true;
        }
    }

    function setStyle(name: string): void {
        setTheme(name, flavour);
    }

    function setFlavour(name: string): void {
        setTheme(style, name);
    }

    // Applied after a short delay so StyleTransition can veil the screen in the old colours first
    function setTheme(styleName: string, flavourName: string): void {
        if (!styles[styleName] || !flavours.includes(flavourName))
            return;
        if (styleName === style && flavourName === flavour) {
            pending = null;
            applyDelay.stop();
            return;
        }
        pending = {
            style: styleName,
            flavour: flavourName
        };
        // Only a new style gets the veil; a flavour change within the same style applies at once
        if (styleName === style) {
            applyDelay.stop();
            applyTheme();
        } else {
            applyDelay.restart();
        }
    }

    function applyTheme(): void {
        if (!pending)
            return;
        style = pending.style;
        flavour = pending.flavour;
        pending = null;
        state.setText(JSON.stringify({
            style,
            flavour
        }));
        // The icons are re-tinted before caelestia reapplies the icon theme; thunar-theme.py must
        // run after caelestia, which rewrites thunar.css
        runThemeScripts(["sh", "-c", 'python3 "$2" "$0" "$1"; caelestia scheme set -n hollowknight -f "$4" -m "$5"; python3 "$3" "$0" "$1"; command -v spicetify >/dev/null && spicetify -q refresh', style, flavour, Quickshell.shellPath("assets/icon-theme.py"), Quickshell.shellPath("assets/thunar-theme.py"), schemeFlavour, light ? "light" : "dark"]);
        for (const app of ["zen", "obsidian", "apps"])
            Quickshell.execDetached(["python3", Quickshell.shellPath(`assets/${app}-theme.py`), style, flavour]);
    }

    Timer {
        id: applyDelay

        interval: 300
        onTriggered: root.applyTheme()
    }

    Process {
        id: themeScripts

        property var next: null

        onExited: {
            Icons.reloadTinted();
            if (next) {
                command = next;
                next = null;
                running = true;
            }
        }
    }

    FileView {
        id: stylesFile

        path: Quickshell.shellPath("assets/styles.json")
        blockLoading: true
    }

    FileView {
        id: state

        path: `${Paths.state}/hallownest.json`
        printErrors: false

        onLoaded: {
            try {
                const saved = JSON.parse(text());
                if (root.styles[saved.style])
                    root.style = saved.style;
                if (root.flavours.includes(saved.flavour))
                    root.flavour = saved.flavour;
            } catch (e) {}
            root.loaded = true;
            Quickshell.execDetached(["python3", Quickshell.shellPath("assets/thunar-theme.py"), root.style, root.flavour]);
            root.runThemeScripts(["python3", Quickshell.shellPath("assets/icon-theme.py"), root.style, root.flavour]);
        }
        onLoadFailed: root.loaded = true
    }

    IpcHandler {
        function flavour(name: string): void {
            root.setFlavour(name);
        }

        function style(name: string): void {
            root.setStyle(name);
        }

        function list(): string {
            return root.flavours.join("\n");
        }

        function styles(): string {
            return root.styleNames.join("\n");
        }

        target: "hallownest"
    }

    FontLoader {
        id: cinzel

        source: Quickshell.shellPath("assets/fonts/cinzel/Cinzel.ttf")
    }
}
