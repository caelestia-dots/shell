'use strict';
import GObject from 'gi://GObject';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import UPower from 'gi://UPowerGlib';

import {WidgetManagerUPower} from './widgetManagerUPower.js';
import * as Helper from './upowerHelper.js';

const deviceKindMapping = {
    [UPower.DeviceKind.MOUSE]: 'input-mouse',
    [UPower.DeviceKind.KEYBOARD]: 'input-keyboard',
    [UPower.DeviceKind.TOUCHPAD]: 'touchpad',
    [UPower.DeviceKind.GAMING_INPUT]: 'input-gaming',
    [UPower.DeviceKind.PEN]: 'input-tablet',
    [UPower.DeviceKind.MONITOR]: 'video-display',
    [UPower.DeviceKind.PDA]: 'pda',
    [UPower.DeviceKind.PHONE]: 'phone',
    [UPower.DeviceKind.MEDIA_PLAYER]: 'multimedia-player',
    [UPower.DeviceKind.COMPUTER]: 'computer',
    [UPower.DeviceKind.PEN]: 'input-tablet',
    [UPower.DeviceKind.MODEM]: 'modem',
    [UPower.DeviceKind.NETWORK]: 'network-wireless',
    [UPower.DeviceKind.HEADSET]: 'audio-headset',
    [UPower.DeviceKind.SPEAKERS]: 'audio-speakers',
    [UPower.DeviceKind.HEADPHONES]: 'audio-headphones',
    [UPower.DeviceKind.VIDEO]: 'camera-video',
    [UPower.DeviceKind.OTHER_AUDIO]: 'audio-card',
    [UPower.DeviceKind.PRINTER]: 'printer',
    [UPower.DeviceKind.SCANNER]: 'scanner',
    [UPower.DeviceKind.CAMERA]: 'camera-photo',
    [UPower.DeviceKind.WEARABLE]: 'wearable',
};

const UpowerDevice = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_UpowerDevice',
    Properties: {
        'batteryPercentage': GObject.ParamSpec.int(
            'batteryPercentage', '', 'Battery Percentage',
            GObject.ParamFlags.READWRITE, 0, 100, 0
        ),
    },
}, class UpowerDevice extends GObject.Object {
    _init(upowerClientObj, path) {
        super._init();
        this._toggle = upowerClientObj._toggle;
        this._upowerClientObj = upowerClientObj;
        this._settings = upowerClientObj._settings;
        this._widgetInfo = upowerClientObj._widgetInfo;
        this._path = path;
        this._initializeUPowerDevice();
    }

    async _initializeUPowerDevice() {
        this._deviceCancellable = new Gio.Cancellable();
        [this._proxy, this._proxyId] =
            await Helper.initDeviceProxy(
                this._path, this._deviceCancellable, _ => this._sync());

        if (!this._proxy || !this._proxyId || !this._deviceCancellable ||
            this._deviceCancellable.is_cancelled())
            return;
        this._sync();
    }

    _sync() {
        const isPresent = this._proxy.get_cached_property('IsPresent').unpack();
        const model = this._proxy.get_cached_property('Model').unpack();
        const percentage = this._proxy.get_cached_property('Percentage').unpack();
        const state = this._proxy.get_cached_property('State').unpack();
        const isValidBatteryState = state !== UPower.DeviceState.UNKNOWN;

        let alias, icon;
        let deviceProp = {};
        let devicePropUpdated = false;
        if (this._upowerClientObj._deviceList.has(this._path)) {
            deviceProp = this._upowerClientObj._deviceList.get(this._path);
            icon = deviceProp.icon;
            alias = deviceProp.alias;

            if (deviceProp.model !== model) {
                deviceProp.model = model;
                devicePropUpdated = true;
            }
            if (isValidBatteryState && !deviceProp.reportsState) {
                deviceProp.reportsState = true;
                devicePropUpdated = true;
            }
        } else {
            const type = this._proxy.get_cached_property('Type').unpack();
            icon = deviceKindMapping[type] || 'upower-devices';
            alias = model;
            deviceProp = {
                alias,
                icon,
                model,
                hideDevice: false,
                reportsState: isValidBatteryState,
            };
            this._upowerClientObj._deviceList.set(this._path, deviceProp);
            this._upowerClientObj._delayedUpdateDeviceGsettings();
        }
        let device;
        if (this._upowerClientObj._deviceWidgets.has(this._path))
            device = this._upowerClientObj._deviceWidgets.get(this._path);

        const showDevice =
            !deviceProp.hideDevice && isPresent && percentage > 0 &&
            (!deviceProp.reportsState || isValidBatteryState);


        if (showDevice && !device) {
            device = new WidgetManagerUPower(this._toggle, this._path, alias,
                icon, percentage);

            this._upowerClientObj._deviceWidgets.set(this._path, device);
        } else if (showDevice && device) {
            device.updatePercentage(percentage);
        } else if (!showDevice && device) {
            device?.destroy();
            device = null;
            this._upowerClientObj._deviceWidgets.delete(this._path);
        }

        if (devicePropUpdated) {
            this._upowerClientObj._deviceList.set(this._path, deviceProp);
            this._upowerClientObj._pushDevicesToGsetting();
        }
    }

    destroy() {
        if (this._proxyId && this._proxy)
            this._proxy.disconnect(this._proxyId);
        if (this._deviceCancellable) {
            this._deviceCancellable.cancel();
            this._deviceCancellable = null;
        }
        this._proxyId = null;
        this._proxy = null;
    }
});

export const UpowerClient = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_UpowerClient',
}, class UpowerClient extends GObject.Object {
    constructor(toggle) {
        super();
        this._toggle = toggle;
        this._settings = toggle.settings;
        this._widgetInfo = toggle.widgetInfo;
        this._requestedProps = ['PowerSupply', 'NativePath'];
        this._deviceItems = new Map();
        this._deviceWidgets = new Map();
        this._deviceList = new Map();
        this._pullDevicesFromGsetting();
        this._connectSettingsSignal(true);
        this._initializeUpower();
    }

    async _initializeUpower() {
        this._cancellable = new Gio.Cancellable();
        this._dbusProxy = await Helper.initProxy(this._cancellable);
        if (!this._dbusProxy)
            return;

        const devices =
            await Helper.getDevices(this._dbusProxy, this._cancellable, this._requestedProps);
        if (!this._cancellable || this._cancellable.is_cancelled())
            return;
        this._dbusSignalId = Helper.watchDevices(this._dbusProxy, this._refreshDevices.bind(this));
        for (const dev of devices)
            this._createDevice(dev);
    }

    _createDevice(dev) {
        const path = dev.path;
        const isPowerSupply = dev.properties['PowerSupply'];
        const nativePath = dev.properties['NativePath'];
        if (!isPowerSupply && !nativePath.startsWith('/org/bluez/')) {
            if (this._deviceItems.has(path)) {
                this._deviceItems.get(path)._sync();
            } else {
                const device = new UpowerDevice(this, path);
                this._deviceItems.set(path, device);
            }
        }
    }

    _removeDevice(path) {
        if (this._deviceWidgets.has(path)) {
            this._deviceWidgets.get(path)?.destroy();
            this._deviceWidgets.delete(path);
        }
        if (this._deviceItems.has(path)) {
            this._deviceItems.get(path)?.destroy();
            this._deviceItems.delete(path);
        }
    }

    async _refreshDevices(path, action) {
        if (action === 'add') {
            const device = await Helper.getDeviceProps(path, null, this._requestedProps);
            this._createDevice(device);
        } else if (action === 'remove') {
            this._removeDevice(path);
        }
    }

    _connectSettingsSignal(connect) {
        if (connect) {
            this._settingSignalId = this._settings.connect('changed::upower-device-list', () => {
                this._pullDevicesFromGsetting();
                this._deviceWidgets.forEach(device => device?.destroy());
                this._deviceWidgets.clear();
                this._deviceItems.forEach(device => device?._sync());
            });
        } else if (this._settingSignalId) {
            this._settings.disconnect(this._settingSignalId);
            this._settingSignalId = null;
        }
    }

    _pullDevicesFromGsetting() {
        this._deviceList.clear();
        const deviceList = this._settings.get_strv('upower-device-list');
        if (deviceList.length !== 0) {
            for (const jsonString of deviceList) {
                const item = JSON.parse(jsonString);
                const path = item.path;
                const deviceProps = {
                    'alias': item['alias'],
                    'icon': item['icon'],
                    'model': item['model'],
                    'hideDevice': item['hide-device'],
                    'reportsState': item['reports-state'],
                };
                if (!deviceProps.alias)
                    deviceProps.alias = deviceProps.model;
                this._deviceList.set(path, deviceProps);
            }
        }
    }

    _pushDevicesToGsetting() {
        const deviceList = [];
        for (const [path, deviceProps] of this._deviceList) {
            const item = {
                path,
                'alias': deviceProps.alias,
                'icon': deviceProps.icon,
                'model': deviceProps.model,
                'hide-device': deviceProps.hideDevice,
                'reports-state': deviceProps.reportsState,
            };
            deviceList.push(JSON.stringify(item));
        }
        this._connectSettingsSignal(false);
        this._settings.set_strv('upower-device-list', deviceList);
        this._connectSettingsSignal(true);
    }

    _delayedUpdateDeviceGsettings() {
        if (this._delayedTimerId)
            GLib.source_remove(this._delayedTimerId);
        this._delayedTimerId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 300, () => {
            this._pushDevicesToGsetting();
            this._delayedTimerId = null;
            return GLib.SOURCE_REMOVE;
        });
    }

    destroy() {
        if (this._delayedTimerId)
            GLib.source_remove(this._delayedTimerId);
        this._delayedTimerId = null;
        if (this._cancellable) {
            this._cancellable.cancel();
            this._cancellable = null;
        }
        if (this._dbusSignalId && this._dbusProxy)
            this._dbusProxy.disconnect(this._dbusSignalId);
        this._dbusSignalId = null;
        this._dbusProxy = null;
        this._connectSettingsSignal(false);
        if (this._deviceWidgets) {
            this._deviceWidgets.forEach(device => device?.destroy());
            this._deviceWidgets.clear();
        }
        this._deviceWidgets = null;
        if (this._deviceItems) {
            this._deviceItems.forEach(item => item?.destroy());
            this._deviceItems.clear();
        }
        this._deviceItems = null;
    }
});
