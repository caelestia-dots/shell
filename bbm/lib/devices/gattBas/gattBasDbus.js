'use strict';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';

import {createLogger, getDeviceIdentifier} from '../logger.js';
import {Bat1Group, Bat2Group, CpfNames} from './gattBasConfig.js';

/**
Credits: https://github.com/Genteure
https://github.com/maniacx/Bluetooth-Battery-Meter/issues/21#issuecomment-2267584302
**/

const BLUEZ_BUS_NAME = 'org.bluez';
const BLUEZ_ROOT_PATH = '/';
const BLUEZ_GATT_CHARACTERISTIC = 'org.bluez.GattCharacteristic1';
const BLUEZ_GATT_DESCRIPTOR = 'org.bluez.GattDescriptor1';
const UUID_CHAR_BATTERY_LEVEL = '00002a19-0000-1000-8000-00805f9b34fb';
const UUID_CHAR_PRESENTATION_FORMAT = '00002904-0000-1000-8000-00805f9b34fb';

export class GattBasDbus {
    constructor(devicePath, callbacks) {
        const identifier = getDeviceIdentifier(devicePath);
        const tag = `GattBasDevice-${identifier}`;
        this._log = createLogger(tag);
        this._log.info('GattBasDevice init');
        this._devicePath = devicePath;
        this._callbacks = callbacks;
        this._charInfo = {};
        this._battProps = {};

        this._initBatteryCharacteristics();
    }

    async _initBatteryCharacteristics() {
        this._log.info(`Scanning for battery characteristics on${this._devicePath}`);

        try {
            let objectManager;
            try {
                objectManager = await Gio.DBusProxy.new_for_bus(
                    Gio.BusType.SYSTEM,
                    Gio.DBusProxyFlags.NONE,
                    null,
                    BLUEZ_BUS_NAME,
                    BLUEZ_ROOT_PATH,
                    'org.freedesktop.DBus.ObjectManager',
                    null
                );
            } catch (e) {
                this._log.error(e, 'Failed to create Proxy objectManager');
                return;
            }
            let managed;
            try {
                const rawManaged = await objectManager.call(
                    'GetManagedObjects',
                    null,
                    Gio.DBusCallFlags.NONE,
                    -1,
                    null
                );
                managed = rawManaged.get_child_value(0).deepUnpack();
            } catch (e) {
                this._log.error(e, 'Failed during call GetManagedObjects');
                return;
            }


            for (const [path, ifaces] of Object.entries(managed)) {
                if (!path.startsWith(this._devicePath))
                    continue;

                const charProps = ifaces[BLUEZ_GATT_CHARACTERISTIC];
                if (!charProps || charProps['UUID'].deepUnpack() !== UUID_CHAR_BATTERY_LEVEL)
                    continue;

                let cpfName = null;
                try {
                    for (const [dpath, descIfaces] of Object.entries(managed)) {
                        if (!dpath.startsWith(path))
                            continue;

                        const descProps = descIfaces[BLUEZ_GATT_DESCRIPTOR];
                        if (!descProps ||
                            descProps['UUID'].deepUnpack() !== UUID_CHAR_PRESENTATION_FORMAT)
                            continue;

                        // eslint-disable-next-line no-await-in-loop
                        const descProxy = await Gio.DBusProxy.new_for_bus(
                            Gio.BusType.SYSTEM, Gio.DBusProxyFlags.NONE, null,
                            BLUEZ_BUS_NAME, dpath, BLUEZ_GATT_DESCRIPTOR, null
                        );

                        // eslint-disable-next-line no-await-in-loop
                        const descResult = await descProxy.call(
                            'ReadValue', GLib.Variant.new('(a{sv})', [{}]),
                            Gio.DBusCallFlags.NONE, -1, null
                        );

                        const arr = descResult.get_child_value(0).deepUnpack();
                        if (arr.length >= 7) {
                            cpfName = CpfNames[arr[5] | arr[6] << 8] || 'unknown';
                            this._log.info(`cpfName = ${cpfName}`);
                        }
                        break;
                    }
                } catch (e) {
                    this._log.error(e, `Failed to read CPF descriptor for ${path}`);
                }

                try {
                    // eslint-disable-next-line no-await-in-loop
                    const proxy = await Gio.DBusProxy.new_for_bus(
                        Gio.BusType.SYSTEM, Gio.DBusProxyFlags.NONE, null,
                        BLUEZ_BUS_NAME, path, BLUEZ_GATT_CHARACTERISTIC, null
                    );

                    const sigId =
                    proxy.connect('g-properties-changed', this._onPropertiesChanged.bind(this));

                    this._charInfo[path] = {proxy, sigId, cpf: cpfName};

                    this._log.info(`Starting notifications for${path}`);
                    proxy.call(
                        'StartNotify', null, Gio.DBusCallFlags.NONE,
                        -1, null,
                        this._makeStartNotifyCb(path)
                    );
                } catch (e) {
                    this._log.error(e, `Failed to initialize characteristic at ${path}`);
                }
            }
        } catch (e) {
            this._log.error(e, 'Failed to initialize battery characteristics');
        }
    }

    _makeStartNotifyCb(path) {
        return (proxy, result) => {
            try {
                proxy.call_finish(result);
            } catch (e) {
                this._log.error(e, `StartNotify failed for ${path}`);
                return;
            }

            this._log.info(`StartNotify successful for ${path} reading initial value`);
            proxy.call(
                'ReadValue', GLib.Variant.new('(a{sv})', [{}]),
                Gio.DBusCallFlags.NONE, -1, null,
                this._makeReadCb(path)
            );
        };
    }

    _makeReadCb(path) {
        return (proxy, result) => {
            try {
                const res = proxy.call_finish(result);
                const byteArray = res.get_child_value(0).deepUnpack();
                const level = byteArray.length > 0 ? byteArray[0] : null;
                this._updateLevel(path, level);
            } catch (e) {
                this._log.error(e, `ReadValue failed for ${path}`);
            }
        };
    }

    _onPropertiesChanged(proxy, changed, _invalidated) {
        try {
            const props = changed.deepUnpack();
            const value = props['Value'];
            if (!value)
                return;

            const arr = value.deepUnpack();
            const level = arr.length > 0 ? arr[0] : null;
            const path = proxy.get_object_path();
            this._log.info(`Battery level changed for${path} : ${level}`);
            this._updateLevel(path, level);
        } catch (e) {
            this._log.error(e, 'Error onPropertiesChanged');
        }
    }

    _updateLevel(path, level) {
        this._battProps[path] = level;

        const entries = Object.entries(this._charInfo).map(([p, info]) => ({
            path: p,
            cpf: info.cpf ?? 'unknown',
            level: this._battProps[p],
            index: Object.keys(this._charInfo).indexOf(p),
        }));

        let battery1 = null;
        let battery2 = null;
        const battery3 = [];

        battery1 = entries.find(entry => Bat1Group.has(entry.cpf));
        battery2 = entries.find(entry => Bat2Group.has(entry.cpf));

        for (const entry of entries) {
            if (battery1 && battery1.path === entry.path ||
            battery2 && battery2.path === entry.path)
                continue;
            battery3.push(entry);
        }

        if (!battery1 && battery3.length > 0)
            battery1 = battery3.shift();

        if (!battery2 && battery3.length > 0)
            battery2 = battery3.shift();

        const props = {};
        if (battery1)
            props.battery1Level = battery1.level;
        if (battery2)
            props.battery2Level = battery2.level;
        if (battery3.length > 0)
            props.battery3Level = battery3[0].level;

        for (const [key, val] of Object.entries(props)) {
            const slot = parseInt(key.match(/\d+/)[0]) - 1;
            const batteryPath = [battery1, battery2, ...battery3][slot]?.path;
            const cpf = this._charInfo[batteryPath]?.cpf ?? 'Unknown';
            this._log.info(`${cpf} Battery level: ${val}%`);
        }

        if (this._callbacks.updateBatteryProps)
            this._callbacks.updateBatteryProps(props);
    }

    destroy() {
        this._log.info(`Destroying GattBasDevice for${this._devicePath}`);
        for (const info of Object.values(this._charInfo)) {
            if (info.sigId)
                info.proxy.disconnect(info.sigId);
        }
        this._charInfo = {};
        this._battProps = {};
        this._callbacks = {};
    }
}

