'use strict';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';

import {DeviceTypeAirpods} from '../lib/devices/airpods/airpodsDevice.js';
import {DeviceTypeSonyV1, DeviceTypeSonyV2} from '../lib/devices/sony/sonyDevice.js';
import {
    DeviceTypeGalaxyLegacy, DeviceTypeGalaxyBuds,
} from '../lib/devices/galaxyBuds/galaxyBudsDevice.js';
import {DeviceTypeNothingBuds} from '../lib/devices/nothingBuds/nothingBudsDevice.js';
import {DeviceTypeGoogleBuds} from '../lib/devices/googleBuds/googleBudsDevice.js';
import {DeviceTypeRedmiBuds} from '../lib/devices/redmiBuds/redmiBudsDevice.js';
import {DeviceTypeSenhBuds} from '../lib/devices/senhBuds/senhBudsDevice.js';
import {DeviceTypeBoseBuds} from '../lib/devices/boseBuds/boseBudsDevice.js';
import {DeviceTypeGfps} from '../lib/devices/gfps/gfpsDevice.js';

const TYPE_LABELS = {
    [DeviceTypeAirpods]: 'AirPods / Beats Bluetooth audio devices',
    [DeviceTypeSonyV1]: 'Sony Bluetooth audio devices',
    [DeviceTypeSonyV2]: 'Sony Bluetooth audio devices',
    [DeviceTypeGalaxyLegacy]: 'Samsung Galaxy Bluetooth audio devices',
    [DeviceTypeGalaxyBuds]: 'Samsung Galaxy Bluetooth audio devices',
    [DeviceTypeNothingBuds]: 'Nothing / CMF Bluetooth audio devices',
    [DeviceTypeGoogleBuds]: 'Google Pixel Buds Bluetooth audio devices',
    [DeviceTypeRedmiBuds]: 'Redmi / Xiaomi Bluetooth audio devices',
    [DeviceTypeSenhBuds]: 'Sennheiser Bluetooth audio devices',
    [DeviceTypeBoseBuds]: 'Bose Bluetooth audio devices',
    [DeviceTypeGfps]: 'Google Fast Pair Bluetooth audio devices',
};

export function notifyProfileRegisteredError(type) {
    const label = TYPE_LABELS[type] ?? type;
    const title = `Could not access advanced features for ${label}.`;
    const body =
        `Another app or session is already using the Bluetooth socket/profile on ${label}. ` +
        'Close any other apps using this device, ' +
        'then disable and re-enable it in BBM settings.';

    try {
        Gio.DBus.session.call(
            'org.freedesktop.Notifications',
            '/org/freedesktop/Notifications',
            'org.freedesktop.Notifications',
            'Notify',
            new GLib.Variant('(susssasa{sv}i)', [
                'bbm-daemon',   // app_name
                0,              // replaces_id
                'bluetooth',    // app_icon
                title,          // summary
                body,           // body
                [],             // actions
                {},             // hints
                8000,           // expire_timeout ms
            ]),
            null,
            Gio.DBusCallFlags.NONE,
            -1,
            null,
            null
        );
    } catch (e) {
        console.warn('BBM: failed to send notification:', e.message);
    }
}
