'use strict';
import GObject from 'gi://GObject';

import {getBluezDeviceProxy} from '../../bluezDeviceProxy.js';
import {createConfig, createProperties, DataHandler} from '../../dataHandler.js';
import {supportedCommonIcons} from './gattBasConfig.js';
import {GattBasDbus} from './gattBasDbus.js';

const GattBasUUID = '0000180f-0000-1000-8000-00805f9b34fb';

export const DeviceTypeGattBas = 'gatt-bas';

export function isGattBas(bluezDeviceProxy, uuids) {
    const bluezProps = [];
    const supported = uuids.includes(GattBasUUID) ? 'yes' : 'no';
    return {supported, bluezProps};
}


export const GattBasDevices = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_GattBasDevices',
}, class GattBasDevices extends GObject.Object {
    _init(settings, devicePath, icon, updateDeviceMapCb) {
        super._init();
        this._settings = settings;
        this._devicePath = devicePath;
        this._icon = icon;
        this._config = createConfig();
        this._props = createProperties();
        this.updateDeviceMapCb = updateDeviceMapCb;
        this._battInfoRecieved = false;
        this._callbacks = {
            updateBatteryProps: this.updateBatteryProps.bind(this),
        };

        this._bluezDeviceProxy = getBluezDeviceProxy(this._devicePath);
        const servicesResolved = this._bluezDeviceProxy.ServicesResolved;
        if (!servicesResolved) {
            this._bluezSignalId = this._bluezDeviceProxy.connect(
                'g-properties-changed', () => this._onBluezPropertiesChanged());
        } else {
            this._startGattBasDbus();
        }
    }

    _onBluezPropertiesChanged() {
        const modalias = this._bluezDeviceProxy.Modalias;
        if (modalias) {
            this._startGattBasDbus();
            if (this._bluezDeviceProxy && this._bluezSignalId)
                this._bluezDeviceProxy.disconnect(this._bluezSignalId);
            this._bluezSignalId = null;
            this._bluezDeviceProxy = null;
        }
    }

    _startGattBasDbus() {
        this._gattBasDbus = new GattBasDbus(this._devicePath, this._callbacks);
    }

    _startConfiguration(battInfo) {
        const bat1level = battInfo.battery1Level  ?? 0;
        const bat2level = battInfo.battery2Level  ?? 0;
        const bat3level = battInfo.battery3Level  ?? 0;

        if (bat1level <= 0 && bat2level <= 0 && bat3level <= 0)
            return;

        this._battInfoRecieved = true;
        this._props = {...this._props, ...battInfo};
        this._config.battery1ShowOnDisconnect = true;
        this._config.panelButtonLabelFixed = false;

        const parsedDevices = this._settings.get_strv('gattbas-list').map(JSON.parse);

        if (!parsedDevices || parsedDevices.length === 0 ||
            !parsedDevices.some(device => device.path === this._devicePath)) {
            const icons = this._validIcons(this._icon);

            this._config.commonIcon = icons.supportedicon;
            this._config.albumArtIcon = icons.albumArtIcon;
            this._config.battery1Icon = icons.supportedicon;
            this._config.battery2Icon = icons.supportedicon;
            this._config.battery3Icon = icons.supportedicon;
            this._addConfigToSettings();
        } else {
            this._loadConfigFromSettings(parsedDevices);
        }

        this._settings.connectObject(
            'changed::gattbas-list', () => {
                const parsedBasDevices = this._settings.get_strv('gattbas-list').map(JSON.parse);
                this._loadConfigFromSettings(parsedBasDevices);
            },
            this
        );

        this.dataHandler = new DataHandler(this._config, this._props);

        this.updateDeviceMapCb(this._devicePath, this.dataHandler);
    }

    _addConfigToSettings() {
        const item = {
            'path': this._devicePath,
            'alias': '',
            'icon': this._config.commonIcon,
            'icon-batt1': this._config.battery1Icon,
            'icon-batt2': this._config.battery2Icon,
            'icon-batt3': this._config.battery3Icon,
        };
        this._settings.set_strv('gattbas-list', [JSON.stringify(item)]);
    }

    _loadConfigFromSettings(parsedDevices) {
        const existingItem = parsedDevices.find(device => device.path === this._devicePath);
        if (!existingItem)
            return;
        this._config.commonIcon = existingItem['icon'];
        const albumArtIcon = this._validAlbumArtIcons(existingItem['icon']);
        this._config.albumArtIcon = albumArtIcon;
        this._config.battery1Icon = existingItem['icon-batt1'];
        this._config.battery2Icon = existingItem['icon-batt2'];
        this._config.battery3Icon = existingItem['icon-batt3'];
        this.dataHandler?.setConfig(this._config);
    }

    _validAlbumArtIcons(icon) {
        const albumArtIconMap = {
            'audio-speakers3': 'audio-speakers3',
            'headphone1': 'audio-headphones',
            'input-gaming3': 'input-gaming',
            'input-gaming2': 'input-gaming',
            'input-keyboard2': 'input-keyboard',
        };
        return albumArtIconMap[icon] || icon;
    }

    _validIcons(icon) {
        if (supportedCommonIcons.includes(icon)) {
            const iconMap = {
                'phone-apple-iphone-symbolic': 'phone',
                'phone-google-nexus-one': 'phone',
                'phone-samsung-galaxy-s': 'phone',
            };
            const supportedicon = iconMap[icon] || icon;
            const albumArtIcon = this._validAlbumArtIcons(supportedicon);
            return {supportedicon,  albumArtIcon};
        } else {
            return {supportedicon: 'audio-headphones',  albumArtIcon: 'audio-headphones'};
        }
    }

    updateBatteryProps(props) {
        this._props = {...this._props, ...props};

        const b1 = props.battery1Level;
        const b2 = props.battery2Level;

        let computed;

        if ((b1 === undefined || b1 === 0) && (b2 === undefined || b2 === 0))
            computed = undefined;
        else if (b1 === undefined || b1 === 0)
            computed = b2;
        else if (b2 === undefined || b2 === 0)
            computed = b1;
        else
            computed = Math.min(b1, b2);


        this._props.computedBatteryLevel = computed;

        if (!this._battInfoRecieved)
            this._startConfiguration(props);

        this.dataHandler?.setProps(this._props);
    }


    destroy() {
        if (this._bluezDeviceProxy && this._bluezSignalId)
            this._bluezDeviceProxy.disconnect(this._bluezSignalId);
        this._bluezSignalId = null;
        this._bluezDeviceProxy = null;
        this.dataHandler = null;
        this._battInfoRecieved = false;
    }
});
