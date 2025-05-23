import { execAsync, GLib, GObject, monitorFile, property, readFile, readFileAsync, register } from "astal";
import Schemes from "./schemes";

export type ColourMode = "light" | "dark";

export type Hex = `#${string}`;

export interface IPalette {
    rosewater: Hex;
    flamingo: Hex;
    pink: Hex;
    mauve: Hex;
    red: Hex;
    maroon: Hex;
    peach: Hex;
    yellow: Hex;
    green: Hex;
    teal: Hex;
    sky: Hex;
    sapphire: Hex;
    blue: Hex;
    lavender: Hex;
    text: Hex;
    subtext1: Hex;
    subtext0: Hex;
    overlay2: Hex;
    overlay1: Hex;
    overlay0: Hex;
    surface2: Hex;
    surface1: Hex;
    surface0: Hex;
    base: Hex;
    mantle: Hex;
    crust: Hex;
    primary: Hex;
    secondary: Hex;
    tertiary: Hex;
}

@register({ GTypeName: "Palette" })
export default class Palette extends GObject.Object {
    static instance: Palette;
    static get_default() {
        if (!this.instance) this.instance = new Palette();

        return this.instance;
    }

    #mode: ColourMode;
    #scheme: string;
    #flavour?: string;
    #colours!: IPalette;

    @property(Boolean)
    get mode() {
        return this.#mode;
    }

    @property(String)
    get scheme() {
        return this.#scheme;
    }

    @property(String)
    get flavour() {
        return this.#flavour;
    }

    @property(Object)
    get colours() {
        return this.#colours;
    }

    @property(String)
    get rosewater() {
        return this.#colours.rosewater;
    }

    @property(String)
    get flamingo() {
        return this.#colours.flamingo;
    }

    @property(String)
    get pink() {
        return this.#colours.pink;
    }

    @property(String)
    get mauve() {
        return this.#colours.mauve;
    }

    @property(String)
    get red() {
        return this.#colours.red;
    }

    @property(String)
    get maroon() {
        return this.#colours.maroon;
    }

    @property(String)
    get peach() {
        return this.#colours.peach;
    }

    @property(String)
    get yellow() {
        return this.#colours.yellow;
    }

    @property(String)
    get green() {
        return this.#colours.green;
    }

    @property(String)
    get teal() {
        return this.#colours.teal;
    }

    @property(String)
    get sky() {
        return this.#colours.sky;
    }

    @property(String)
    get sapphire() {
        return this.#colours.sapphire;
    }

    @property(String)
    get blue() {
        return this.#colours.blue;
    }

    @property(String)
    get lavender() {
        return this.#colours.lavender;
    }

    @property(String)
    get text() {
        return this.#colours.text;
    }

    @property(String)
    get subtext1() {
        return this.#colours.subtext1;
    }

    @property(String)
    get subtext0() {
        return this.#colours.subtext0;
    }

    @property(String)
    get overlay2() {
        return this.#colours.overlay2;
    }

    @property(String)
    get overlay1() {
        return this.#colours.overlay1;
    }

    @property(String)
    get overlay0() {
        return this.#colours.overlay0;
    }

    @property(String)
    get surface2() {
        return this.#colours.surface2;
    }

    @property(String)
    get surface1() {
        return this.#colours.surface1;
    }

    @property(String)
    get surface0() {
        return this.#colours.surface0;
    }

    @property(String)
    get base() {
        return this.#colours.base;
    }

    @property(String)
    get mantle() {
        return this.#colours.mantle;
    }

    @property(String)
    get crust() {
        return this.#colours.crust;
    }

    @property(String)
    get primary() {
        return this.#colours.primary;
    }

    @property(String)
    get secondary() {
        return this.#colours.secondary;
    }

    @property(String)
    get tertiary() {
        return this.#colours.tertiary;
    }

    #notify() {
        this.notify("colours");
        this.notify("rosewater");
        this.notify("flamingo");
        this.notify("pink");
        this.notify("mauve");
        this.notify("red");
        this.notify("maroon");
        this.notify("peach");
        this.notify("yellow");
        this.notify("green");
        this.notify("teal");
        this.notify("sky");
        this.notify("sapphire");
        this.notify("blue");
        this.notify("lavender");
        this.notify("text");
        this.notify("subtext1");
        this.notify("subtext0");
        this.notify("overlay2");
        this.notify("overlay1");
        this.notify("overlay0");
        this.notify("surface2");
        this.notify("surface1");
        this.notify("surface0");
        this.notify("base");
        this.notify("mantle");
        this.notify("crust");
        this.notify("primary");
        this.notify("secondary");
        this.notify("tertiary");
    }

    update() {
        let schemeColours;
        if (GLib.file_test(`${STATE}/scheme/current.txt`, GLib.FileTest.EXISTS)) {
            const currentScheme = readFile(`${STATE}/scheme/current.txt`);
            schemeColours = currentScheme.split("\n").map(l => l.split(" "));
        } else
            schemeColours = readFile(`${SRC}/scss/scheme/_default.scss`)
                .split("\n")
                .map(l => {
                    const [name, hex] = l.split(":");
                    return [name.slice(1), hex.trim().slice(1, -1)];
                });

        this.#colours = schemeColours.reduce((acc, [name, hex]) => ({ ...acc, [name]: `#${hex}` }), {} as IPalette);
        this.#notify();
    }

    switchMode(mode: ColourMode) {
        execAsync(`caelestia scheme ${this.scheme} ${this.flavour ?? ""} ${mode}`).catch(console.error);
    }

    hasMode(mode: ColourMode) {
        const scheme = Schemes.get_default().map[this.scheme];
        if (scheme?.colours?.[mode]) return true;
        return scheme?.flavours?.[this.flavour ?? ""]?.colours?.[mode] !== undefined;
    }

    constructor() {
        super();

        this.#mode = readFile(`${STATE}/scheme/current-mode.txt`) === "light" ? "light" : "dark";
        monitorFile(`${STATE}/scheme/current-mode.txt`, async file => {
            this.#mode = (await readFileAsync(file)) === "light" ? "light" : "dark";
            this.notify("mode");
        });

        [this.#scheme, this.#flavour] = readFile(`${STATE}/scheme/current-name.txt`).split("-");
        monitorFile(`${STATE}/scheme/current-name.txt`, async file => {
            [this.#scheme, this.#flavour] = (await readFileAsync(file)).split("-");
            this.notify("scheme");
            this.notify("flavour");
        });

        this.update();
        monitorFile(`${STATE}/scheme/current.txt`, () => this.update());
    }
}
