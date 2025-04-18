import { notify } from "@/utils/system";
import { Gio, GLib, monitorFile, readFileAsync, Variable, writeFileAsync } from "astal";
import config from ".";
import { loadStyleAsync } from "../../app";
import defaults from "./defaults";
import types from "./types";

type Settings<T> = { [P in keyof T]: T[P] extends object & { length?: never } ? Settings<T[P]> : Variable<T[P]> };

const CONFIG = `${GLib.get_user_config_dir()}/caelestia/shell.json`;

const warn = (msg: string) => {
    console.warn(`[CONFIG] ${msg}`);
    if (config.config.notifyOnError.get())
        notify({
            summary: "Invalid config",
            body: msg,
            icon: "dialog-error-symbolic",
            urgency: "critical",
        });
};

const isObject = (o: any): o is object => typeof o === "object" && o !== null && !Array.isArray(o);

const isCorrectType = (v: any, type: string | string[] | number[], path: string) => {
    if (Array.isArray(type)) {
        // type is array of valid values
        if (!type.includes(v as never)) {
            warn(`Invalid value for ${path}: ${v} != ${type.map(v => `"${v}"`).join(" | ")}`);
            return false;
        }
    } else if (type.startsWith("array of ")) {
        // Array of ...
        if (Array.isArray(v)) {
            // Remove invalid items but always return true
            const arrType = type.slice(9);
            try {
                // Recursively check type
                const type = JSON.parse(arrType);
                if (Array.isArray(type)) {
                    v.splice(0, v.length, ...v.filter((item, i) => isCorrectType(item, type, `${path}[${i}]`)));
                } else {
                    const valid = v.filter((item, i) =>
                        Object.entries(type).every(([k, t]) => {
                            if (!item.hasOwnProperty(k)) {
                                warn(`Invalid shape for ${path}[${i}]: ${JSON.stringify(item)} != ${arrType}`);
                                return false;
                            }
                            return isCorrectType(item[k], t as any, `${path}[${i}].${k}`);
                        })
                    );
                    v.splice(0, v.length, ...valid); // In-place filter
                }
            } catch {
                const valid = v.filter((item, i) => {
                    if (typeof item !== arrType) {
                        warn(`Invalid type for ${path}[${i}]: ${typeof item} != ${arrType}`);
                        return false;
                    }
                    return true;
                });
                v.splice(0, v.length, ...valid); // In-place filter
            }
        } else {
            // Type is array but value is not
            warn(`Invalid type for ${path}: ${typeof v} != ${type}`);
            return false;
        }
    } else if (typeof v !== type) {
        // Value is not correct type
        warn(`Invalid type for ${path}: ${typeof v} != ${type}`);
        return false;
    }

    return true;
};

const deepMerge = <T extends object, U extends object>(a: T, b: U, path = ""): T & U => {
    const merged: { [k: string]: any } = { ...b };
    for (const [k, v] of Object.entries(a)) {
        if (b.hasOwnProperty(k)) {
            const bv = b[k as keyof U];
            if (isObject(v) && isObject(bv)) merged[k] = deepMerge(v, bv, `${path}${k}.`);
            else if (!isCorrectType(bv, types[path + k], path + k)) merged[k] = v;
        } else merged[k] = v;
    }
    return merged as any;
};

export const convertSettings = <T extends object>(obj: T): Settings<T> =>
    Object.fromEntries(Object.entries(obj).map(([k, v]) => [k, isObject(v) ? convertSettings(v) : Variable(v)])) as any;

const updateSection = (from: { [k: string]: any }, to: { [k: string]: any }, path = "") => {
    for (const [k, v] of Object.entries(from)) {
        if (to.hasOwnProperty(k)) {
            if (isObject(v)) updateSection(v, to[k], `${path}${k}.`);
            else if (!Array.isArray(v) || JSON.stringify(to[k].get()) !== JSON.stringify(v)) to[k].set(v);
        } else warn(`Unknown config key: ${path}${k}`);
    }
};

export const updateConfig = async () => {
    if (GLib.file_test(CONFIG, GLib.FileTest.EXISTS))
        updateSection(deepMerge(defaults, JSON.parse(await readFileAsync(CONFIG))), config);
    else updateSection(defaults, config);
    await loadStyleAsync();
    console.log("[LOG] Config updated");
};

export const initConfig = async () => {
    monitorFile(CONFIG, (_, e) => {
        if (e === Gio.FileMonitorEvent.CHANGES_DONE_HINT || e === Gio.FileMonitorEvent.DELETED)
            updateConfig().catch(warn);
    });
    await updateConfig().catch(warn);
};

export const setConfig = async (path: string, value: any) => {
    const conf = JSON.parse(await readFileAsync(CONFIG));
    let obj = conf;
    for (const p of path.split(".").slice(0, -1)) obj = obj[p];
    obj[path.split(".").at(-1)!] = value;
    await writeFileAsync(CONFIG, JSON.stringify(conf, null, 4));
};
