'use strict';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';

// Properties on org.bluez.Device1 that we care about.
const DEVICE_PROPS = new Set(['Connected', 'Paired', 'Alias', 'Name', 'Icon',
    'UUIDs', 'Modalias', 'ServicesResolved']);

// Properties whose change should trigger a full sync (connect/disconnect lifecycle).
const LIFECYCLE_PROPS = new Set(['Connected']);

// Properties whose change should update DeviceRecord metadata only.
const METADATA_PROPS = new Set(['Alias', 'Name', 'Icon']);

/**
 * Watches the BlueZ ObjectManager for device add/remove/change events.
 * Replaces the GnomeBluetooth.Client dependency.
 *
 * Emits GObject signals:
 *   device-added(path: string)
 *   device-removed(path: string)
 *   device-changed(path: string)   — metadata change only (alias, icon, etc.)
 *   device-lifecycle(path: string) — Connected state changed → triggers full sync
 */
export const BluezEnumerator = GObject.registerClass({
    GTypeName: 'BBMDaemon_BluezEnumerator',
    Signals: {
        'device-added': {param_types: [GObject.TYPE_STRING]},
        'device-removed': {param_types: [GObject.TYPE_STRING]},
        'device-changed': {param_types: [GObject.TYPE_STRING]},
        'device-lifecycle': {param_types: [GObject.TYPE_STRING]},
    },
}, class BluezEnumerator extends GObject.Object {
    _init() {
        super._init();
        // Map<bluezPath, deviceInfo>
        this._devices = new Map();
        this._systemBus = null;
        this._objManagerProxy = null;
        this._ifacesAddedId = null;
        this._ifacesRemovedId = null;
        // Map<bluezPath, signalSubscriptionId>
        this._propsChangedIds = new Map();
    }

    async start() {
        this._systemBus = Gio.bus_get_sync(Gio.BusType.SYSTEM, null);

        // Connect to ObjectManager signals for device add/remove
        this._ifacesAddedId = this._systemBus.signal_subscribe(
            'org.bluez', 'org.freedesktop.DBus.ObjectManager',
            'InterfacesAdded', null, null,
            Gio.DBusSignalFlags.NONE,
            this._onInterfacesAdded.bind(this)
        );
        this._ifacesRemovedId = this._systemBus.signal_subscribe(
            'org.bluez', 'org.freedesktop.DBus.ObjectManager',
            'InterfacesRemoved', null, null,
            Gio.DBusSignalFlags.NONE,
            this._onInterfacesRemoved.bind(this)
        );

        // Initial enumeration (synchronous — called once at startup before the main loop)
        const result = this._systemBus.call_sync(
            'org.bluez', '/', 'org.freedesktop.DBus.ObjectManager',
            'GetManagedObjects', null, null,
            Gio.DBusCallFlags.NONE, -1, null
        );

        const objects = result.deepUnpack()[0];
        for (const [path, interfaces] of Object.entries(objects)) {
            if ('org.bluez.Device1' in interfaces)
                this._addDevice(path, interfaces['org.bluez.Device1']);
        }
    }

    getDevices() {
        return this._devices;
    }

    _pathToAddress(path) {
        // /org/bluez/hci0/dev_AA_BB_CC_DD_EE_FF → AA:BB:CC:DD:EE:FF
        const match = path.match(/dev_([0-9A-F_]+)$/i);
        return match ? match[1].replace(/_/g, ':') : path;
    }

    _extractDeviceInfo(path, propsVariant) {
        const p = propsVariant;
        return {
            address: this._pathToAddress(path),
            alias: p.Alias?.deepUnpack() ?? p.Name?.deepUnpack() ?? 'Unknown',
            connected: p.Connected?.deepUnpack() ?? false,
            paired: p.Paired?.deepUnpack() ?? false,
            icon: p.Icon?.deepUnpack() ?? '',
            uuids: p.UUIDs?.deepUnpack() ?? [],
            modalias: p.Modalias?.deepUnpack() ?? null,
            servicesResolved: p.ServicesResolved?.deepUnpack() ?? false,
        };
    }

    _addDevice(path, propsVariant) {
        const info = this._extractDeviceInfo(path, propsVariant);
        this._devices.set(path, info);
        this._subscribePropsChanged(path);
        this.emit('device-added', path);
    }

    _removeDevice(path) {
        if (!this._devices.has(path))
            return;
        this._unsubscribePropsChanged(path);
        this._devices.delete(path);
        this.emit('device-removed', path);
    }

    _subscribePropsChanged(path) {
        if (this._propsChangedIds.has(path))
            return;
        const id = this._systemBus.signal_subscribe(
            'org.bluez',
            'org.freedesktop.DBus.Properties',
            'PropertiesChanged',
            path,
            'org.bluez.Device1',
            Gio.DBusSignalFlags.NONE,
            (_conn, _sender, _opath, _iface, _signal, params) => {
                this._onPropsChanged(path, params);
            }
        );
        this._propsChangedIds.set(path, id);
    }

    _unsubscribePropsChanged(path) {
        const id = this._propsChangedIds.get(path);
        if (id !== undefined) {
            this._systemBus.signal_unsubscribe(id);
            this._propsChangedIds.delete(path);
        }
    }

    _onInterfacesAdded(_conn, _sender, _path, _iface, _signal, params) {
        const [objectPath, interfaces] = params.deepUnpack();
        if ('org.bluez.Device1' in interfaces)
            this._addDevice(objectPath, interfaces['org.bluez.Device1']);
    }

    _onInterfacesRemoved(_conn, _sender, _path, _iface, _signal, params) {
        const [objectPath, removedIfaces] = params.deepUnpack();
        if (removedIfaces.includes('org.bluez.Device1'))
            this._removeDevice(objectPath);
    }

    _onPropsChanged(path, params) {
        const [, changedProps] = params.deepUnpack();
        const info = this._devices.get(path);
        if (!info)
            return;

        let lifecycleChanged = false;
        let metadataChanged = false;

        for (const [key, variant] of Object.entries(changedProps)) {
            if (!DEVICE_PROPS.has(key))
                continue; // Ignore RSSI, TxPower, ManufacturerData, etc.

            const value = variant.deepUnpack();

            if (LIFECYCLE_PROPS.has(key)) {
                info[key.toLowerCase()] = value;
                lifecycleChanged = true;
            } else if (METADATA_PROPS.has(key)) {
                if (key === 'Alias' || key === 'Name')
                    info.alias = value;
                else if (key === 'Icon')
                    info.icon = value;
                metadataChanged = true;
            } else {
                // UUIDs, Modalias, ServicesResolved — update but don't emit lifecycle
                if (key === 'UUIDs') info.uuids = value;
                else if (key === 'Modalias') info.modalias = value;
                else if (key === 'ServicesResolved') info.servicesResolved = value;
                else if (key === 'Paired') info.paired = value;
            }
        }

        if (lifecycleChanged)
            this.emit('device-lifecycle', path);
        else if (metadataChanged)
            this.emit('device-changed', path);
    }

    destroy() {
        if (this._systemBus) {
            if (this._ifacesAddedId !== null)
                this._systemBus.signal_unsubscribe(this._ifacesAddedId);
            if (this._ifacesRemovedId !== null)
                this._systemBus.signal_unsubscribe(this._ifacesRemovedId);
            for (const id of this._propsChangedIds.values())
                this._systemBus.signal_unsubscribe(id);
        }
        this._propsChangedIds.clear();
        this._devices.clear();
        this._systemBus = null;
    }
});
