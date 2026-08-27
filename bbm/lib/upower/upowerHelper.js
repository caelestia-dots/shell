'use strict';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';

const BUS = 'org.freedesktop.UPower';
const U_PATH = '/org/freedesktop/UPower';
const U_IFACE = 'org.freedesktop.UPower';
const U_PROPS = 'org.freedesktop.DBus.Properties';
const UD_IFACE = 'org.freedesktop.UPower.Device';

export async function initProxy(cancellable) {
    try {
        return await Gio.DBusProxy.new_for_bus(
            Gio.BusType.SYSTEM, Gio.DBusProxyFlags.NONE, null, BUS, U_PATH, U_IFACE, cancellable);
    } catch  {
        console.log('Bluetooth-Battery-Meter: Failed to create DBus proxy');
        return null;
    }
}

export async function initDeviceProxy(path, cancellable, onPropertiesChangedCallback) {
    try {
        const proxy = await Gio.DBusProxy.new_for_bus(
            Gio.BusType.SYSTEM, Gio.DBusProxyFlags.NONE, null, BUS, path, UD_IFACE, cancellable);
        const proxyId = proxy.connect('g-properties-changed', () => {
            onPropertiesChangedCallback(proxy);
        });
        return [proxy, proxyId];
    } catch  {
        console.log(`Bluetooth-Battery-Meter: Failed to create DBus proxy for ${path}`);
        return [null, null];
    }
}

export async function getDeviceProps(path, cancellable, requestedProps) {
    try {
        const response = await Gio.DBus.system.call(
            BUS, path, U_PROPS, 'GetAll',
            new GLib.Variant('(s)', [UD_IFACE]), GLib.VariantType.new('(a{sv})'),
            Gio.DBusCallFlags.NONE, -1, cancellable
        );
        const [deviceProps] = response.deep_unpack();
        const filteredProps = {};
        requestedProps.forEach(prop => {
            if (deviceProps[prop] !== undefined)
                filteredProps[prop] = deviceProps[prop]?.unpack();
        });
        return {path, properties: filteredProps};
    } catch {
        console.log(`Bluetooth-Battery-Meter: Could not get properties for ${path}`);
        return null;
    }
}

export async function getDevices(dbusProxy, cancellable, requestedProps) {
    try {
        const response =
        await dbusProxy.call('EnumerateDevices', null, Gio.DBusCallFlags.NONE, -1, cancellable);
        if (cancellable.is_cancelled())
            return [];

        if (response?.deep_unpack) {
            const devices = response.deep_unpack()[0];
            if (Array.isArray(devices) && devices.length > 0) {
                const deviceList =
                    await Promise.all(devices.map(
                        path => getDeviceProps(path, cancellable, requestedProps)));
                return deviceList.filter(device => device !== null);
            }
        }
    } catch {
        console.log('Bluetooth-Battery-Meter: Could not EnumerateDevices');
    }
    return [];
}

export function watchDevices(dbusProxy, createDevicesCallback) {
    const dbusConnectId =
        dbusProxy.connect('g-signal', (proxy, senderName, signalName, parameters) => {
            if (signalName === 'DeviceAdded') {
                const path = parameters.deep_unpack()[0];
                createDevicesCallback(path, 'add');
            } else if (signalName === 'DeviceRemoved') {
                const path = parameters.deep_unpack()[0];
                createDevicesCallback(path, 'remove');
            }
        });
    return dbusConnectId;
}



