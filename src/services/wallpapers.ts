import { basename } from "@/utils/strings";
import { monitorDirectory } from "@/utils/system";
import { execAsync, GLib, GObject, property, register } from "astal";
import { wallpapers as config } from "config";

export interface Wallpaper {
    path: string;
    thumbnail?: string;
}

@register({ GTypeName: "Wallpapers" })
export default class Wallpapers extends GObject.Object {
    static instance: Wallpapers;
    static get_default() {
        if (!this.instance) this.instance = new Wallpapers();

        return this.instance;
    }

    #thumbnailDir = `${CACHE}/thumbnails`;

    #list: Wallpaper[] = [];

    @property(Object)
    get list() {
        return this.#list;
    }

    async #thumbnail(path: string) {
        const dir = path.slice(1, path.lastIndexOf("/")).replaceAll("/", "-");
        const thumbPath = `${this.#thumbnailDir}/${dir}-${basename(path)}.jpg`;
        await execAsync(`magick -define jpeg:size=1000x500 ${path} -thumbnail 500x250 -unsharp 0x.5 ${thumbPath}`);
        return thumbPath;
    }

    async update() {
        const results = await Promise.allSettled(
            config.paths
                .get()
                .map(p => execAsync(`find ${p.path.replace("~", HOME)}/ ${p.recursive ? "" : "-maxdepth 1"} -type f`))
        );
        const files = results
            .filter(r => r.status === "fulfilled")
            .map(r => r.value.replaceAll("\n", " "))
            .join(" ");
        const list = (await execAsync(["fish", "-c", `identify -ping -format '%i\n' ${files} ; true`])).split("\n");

        this.#list = await Promise.all(list.map(async p => ({ path: p, thumbnail: await this.#thumbnail(p) })));
        this.notify("list");
    }

    constructor() {
        super();

        GLib.mkdir_with_parents(this.#thumbnailDir, 0o755);

        this.update().catch(console.error);

        let monitors = config.paths
            .get()
            .flatMap(p => monitorDirectory(p.path, () => this.update().catch(console.error), p.recursive));
        config.paths.subscribe(v => {
            for (const m of monitors) m.cancel();
            monitors = v.flatMap(p => monitorDirectory(p.path, () => this.update().catch(console.error), p.recursive));
        });
    }
}
