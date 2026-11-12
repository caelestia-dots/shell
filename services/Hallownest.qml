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

    readonly property string serif: cinzel.status === FontLoader.Ready ? cinzel.name : "serif"
    readonly property string mono: "JetBrainsMono Nerd Font"

    // Hover/raised tint: lighter on dark styles, slightly darker on light ones
    function raise(c: color, k: real): color {
        return light ? Qt.darker(c, 1 + (k - 1) * 0.16) : Qt.lighter(c, k);
    }

    function setStyle(name: string): void {
        setTheme(name, flavour);
    }

    function setFlavour(name: string): void {
        setTheme(style, name);
    }

    function setTheme(styleName: string, flavourName: string): void {
        if (!styles[styleName] || !flavours.includes(flavourName) || (styleName === style && flavourName === flavour))
            return;
        style = styleName;
        flavour = flavourName;
        state.setText(JSON.stringify({
            style,
            flavour
        }));
        // The icons are re-tinted before caelestia reapplies the icon theme; thunar-theme.py must
        // run after caelestia, which rewrites thunar.css
        Quickshell.execDetached(["sh", "-c", 'python3 "$2" "$0" "$1"; caelestia scheme set -n hollowknight -f "$4" -m "$5"; python3 "$3" "$0" "$1"; command -v spicetify >/dev/null && spicetify -q refresh', style, flavour, Quickshell.shellPath("assets/icon-theme.py"), Quickshell.shellPath("assets/thunar-theme.py"), schemeFlavour, light ? "light" : "dark"]);
        for (const app of ["zen", "obsidian", "apps"])
            Quickshell.execDetached(["python3", Quickshell.shellPath(`assets/${app}-theme.py`), style, flavour]);
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
            Quickshell.execDetached(["python3", Quickshell.shellPath("assets/icon-theme.py"), root.style, root.flavour]);
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
