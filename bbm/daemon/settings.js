'use strict';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';

/**
 * Tries to load the compiled org.bbm GSettings schema from schemaDir.
 * Falls back to JsonSettings backed by ~/.config/bbm/settings.json.
 */
export function createSettings(schemaDir) {
    try {
        const source = Gio.SettingsSchemaSource.new_from_directory(
            schemaDir,
            Gio.SettingsSchemaSource.get_default(),
            false
        );
        const schema = source.lookup('org.bbm', false);
        if (!schema)
            throw new Error('Schema org.bbm not found in ' + schemaDir);
        return new Gio.Settings({settings_schema: schema});
    } catch (e) {
        console.warn('BBM: falling back to JsonSettings:', e.message);
        return new JsonSettings();
    }
}

// ---------------------------------------------------------------------------
// JsonSettings — minimal Gio.Settings-compatible shim backed by a JSON file.
// Implements only the surface area that *Device.js files call.
// ---------------------------------------------------------------------------

const DEFAULTS = {
    'enable-airpods-device': true,
    'enable-sony-device': true,
    'enable-galaxy-buds-device': true,
    'enable-nothing-buds-device': true,
    'enable-google-buds-device': true,
    'enable-bose-buds-device': true,
    'enable-redmi-buds-device': true,
    'enable-senh-buds-device': true,
    'enable-gfps-device': true,
    'enable-gattbas-device': true,
    'airpods-list': [],
    'sony-list': [],
    'galaxy-buds-list': [],
    'nothing-buds-list': [],
    'google-buds-list': [],
    'bose-buds-list': [],
    'redmi-buds-list': [],
    'senh-buds-list': [],
    'gfps-list': [],
    'gattbas-list': [],
    'attenuated-on-destroy-info': [],
};

class JsonSettings {
    constructor() {
        this._path = GLib.build_filenamev([
            GLib.get_user_config_dir(), 'bbm', 'settings.json',
        ]);
        this._data = {...DEFAULTS};
        this._signals = new Map(); // key -> [{id, cb}]
        this._nextId = 1;
        this._ownerMap = new Map(); // owner -> [id]
        this._load();
    }

    _load() {
        try {
            const file = Gio.File.new_for_path(this._path);
            const [ok, contents] = file.load_contents(null);
            if (ok) {
                const parsed = JSON.parse(new TextDecoder().decode(contents));
                Object.assign(this._data, parsed);
            }
        } catch {
            // File doesn't exist yet — use defaults
        }
    }

    _save() {
        try {
            const dir = Gio.File.new_for_path(GLib.path_get_dirname(this._path));
            dir.make_directory_with_parents(null);
        } catch {
            // Already exists
        }
        try {
            const file = Gio.File.new_for_path(this._path);
            const bytes = new TextEncoder().encode(JSON.stringify(this._data, null, 2));
            file.replace_contents(bytes, null, false,
                Gio.FileCreateFlags.REPLACE_DESTINATION, null);
        } catch (e) {
            console.warn('BBM: failed to save settings:', e.message);
        }
    }

    _emit(key) {
        const listeners = this._signals.get(key) ?? [];
        for (const {cb} of listeners)
            cb(this, key);
    }

    get_boolean(key) {
        return this._data[key] ?? DEFAULTS[key] ?? false;
    }

    get_int(key) {
        return this._data[key] ?? DEFAULTS[key] ?? 0;
    }

    get_strv(key) {
        return this._data[key] ?? DEFAULTS[key] ?? [];
    }

    set_boolean(key, value) {
        this._data[key] = value;
        this._save();
        this._emit(key);
    }

    set_strv(key, value) {
        this._data[key] = value;
        this._save();
        this._emit(key);
    }

    connect(signal, cb) {
        // signal is 'changed::key-name'
        const key = signal.startsWith('changed::') ? signal.slice(9) : signal;
        if (!this._signals.has(key))
            this._signals.set(key, []);
        const id = this._nextId++;
        this._signals.get(key).push({id, cb});
        return id;
    }

    disconnect(id) {
        for (const [key, list] of this._signals) {
            const idx = list.findIndex(e => e.id === id);
            if (idx !== -1) {
                list.splice(idx, 1);
                return;
            }
        }
    }

    // connectObject(sig1, cb1, sig2, cb2, ..., owner) — GObject-style multi-connect
    connectObject(...args) {
        const owner = args[args.length - 1];
        const pairs = args.slice(0, -1);
        const ids = [];
        for (let i = 0; i < pairs.length; i += 2) {
            const id = this.connect(pairs[i], pairs[i + 1]);
            ids.push(id);
        }
        if (!this._ownerMap.has(owner))
            this._ownerMap.set(owner, []);
        this._ownerMap.get(owner).push(...ids);
    }

    disconnectObject(owner) {
        const ids = this._ownerMap.get(owner) ?? [];
        for (const id of ids)
            this.disconnect(id);
        this._ownerMap.delete(owner);
    }
}
