'use strict';

import Gio from 'gi://Gio';
import GObject from 'gi://GObject';
const _ = s => s; // gettext stub for daemon context

import {createLogger, getDeviceIdentifier} from '../logger.js';
import {buds2to1BatteryLevel, validateProperties, launchConfigureWindow} from '../deviceUtils.js';
import {createConfig, createProperties, DataHandler} from '../../dataHandler.js';
import {GfpsSocket} from './gfpsSocket.js';
import {DeviceTypeGfps, GfpsUUID, ANCMode} from './gfpsConfig.js';

export {DeviceTypeGfps};

export function isGfps(bluezDeviceProxy, uuids) {
    const bluezProps = [];
    // Bypass true Google Pixel Buds so that GoogleBudsDevice (libmaestro) handles them
    if (uuids.includes('25e97ff7-24ce-4c4c-8951-f764a708f7b5'))
        return {supported: 'no', bluezProps};
    const supported = uuids.includes(GfpsUUID) ? 'yes' : 'no';
    return {supported, bluezProps};
}

export const GfpsDevice = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_GfpsDevice',
}, class GfpsDevice extends GObject.Object {
    _init(settings, devicePath, alias, extPath, profileManager, updateDeviceMapCb) {
        super._init();
        const identifier = getDeviceIdentifier(devicePath);
        const tag = `GfpsDevice-${identifier}`;
        this._log = createLogger(tag);
        this._log.info('------------------- GfpsDevice init -------------------');
        this._settings = settings;
        this._devicePath = devicePath;
        this._alias = alias;
        this._extPath = extPath;
        this.updateDeviceMapCb = updateDeviceMapCb;
        this._settableToggles = null;

        this._config = createConfig();
        this._props = createProperties();

        this._callbacks = {
            updateInitDevice: this.updateInitDevice.bind(this),
            updateBatteryProps: this.updateBatteryProps.bind(this),
            updateNoiseControl: this.updateNoiseControl.bind(this),
        };

        const profile = {type: DeviceTypeGfps, uuid: GfpsUUID};

        this._gfpsSocket = new GfpsSocket(
            this._devicePath,
            profileManager,
            profile,
            this._callbacks
        );
    }

    updateInitDevice(battType) {
        this._hasMultipleBatteries = battType !== 1;
        this._commonIcon = this._hasMultipleBatteries ? 'earbuds' : 'headphone1';
        this._config.battery1ShowOnDisconnect = true;
        this._config.battery2ShowOnDisconnect = this._hasMultipleBatteries;
        this._config.showSettingsButton = true;
        if (this._hasMultipleBatteries)
            this._caseIcon = 'case-normal';

        this._createDefaultSettings();

        const devicesList = this._settings.get_strv('gfps-list').map(JSON.parse);

        if (devicesList.length === 0 ||
                !devicesList.some(device => device.path === this._devicePath)) {
            this._addPropsToSettings(devicesList);
        } else {
            validateProperties(this._settings, 'gfps-list', devicesList,
                this._defaultsDeviceSettings, this._devicePath);
        }

        this._updateInitialValues();
        this._monitorGfpsListGsettings(true);
        this._updateIcons();
        this._addToggle1Button();
        this._startConfiguration();
    }

    _createDefaultSettings() {
        this._defaultsDeviceSettings = {
            path: this._devicePath,
            alias: this._alias,
            icon: this._commonIcon,
            'multiple-batt': this._hasMultipleBatteries,

            ...this._hasMultipleBatteries && {
                'case': this._caseIcon,
            },
        };
    }

    _addPropsToSettings(devicesList) {
        devicesList.push(this._defaultsDeviceSettings);
        this._settings.set_strv('gfps-list', devicesList.map(JSON.stringify));
    }

    _updateInitialValues() {
        const devicesList = this._settings.get_strv('gfps-list').map(JSON.parse);
        const existingPathIndex = devicesList.findIndex(item => item.path === this._devicePath);
        if (existingPathIndex === -1)
            return;

        this._settingsItems = devicesList[existingPathIndex];
        this._commonIcon = this._settingsItems['icon'];
        this._caseIcon = this._settingsItems['case'];
    }

    _updateGsettingsProps() {
        const devicesList = this._settings.get_strv('gfps-list').map(JSON.parse);
        const existingPathIndex = devicesList.findIndex(item => item.path === this._devicePath);
        if (existingPathIndex === -1)
            return;

        this._settingsItems = devicesList[existingPathIndex];

        const icon = this._settingsItems['icon'];
        if (this._commonIcon !== icon) {
            this._commonIcon = icon;
            this._updateIcons();
        }

        if (this._hasMultipleBatteries) {
            const caseIcon = this._settingsItems['case'];
            if (this._caseIcon !== caseIcon) {
                this._caseIcon = caseIcon;
                this._updateIcons();
            }
        }
    }

    _monitorGfpsListGsettings(monitor) {
        if (monitor) {
            if (this._settingsHandlerId)
                this._settings?.disconnect(this._settingsHandlerId);

            this._settingsHandlerId = this._settings?.connect('changed::gfps-list', () =>
                this._updateGsettingsProps());
        } else {
            if (this._settingsHandlerId)
                this._settings?.disconnect(this._settingsHandlerId);
            this._settingsHandlerId = null;
        }
    }

    _updateIcons() {
        this._config.commonIcon = this._commonIcon;
        this._config.albumArtIcon = this._commonIcon;
        if (this._hasMultipleBatteries) {
            this._config.battery1Icon = `${this._commonIcon}-left`;
            this._config.battery2Icon = `${this._commonIcon}-right`;
            this._config.battery3Icon = this._caseIcon;
        } else {
            this._config.battery1Icon = this._commonIcon;
        }

        this.dataHandler?.setConfig(this._config);
    }

    _addToggle1Button() {
        this._config.toggle1Title = _('Noise Control');
        this._config.toggle1Button1Icon = 'bbm-anc-off-symbolic';
        this._config.toggle1Button1Name = _('Off');
        this._config.toggle1Button2Icon = 'bbm-anc-on-symbolic';
        this._config.toggle1Button2Name = _('Noise Cancellation');
        this._props.toggle1Visible = false;
    }

    _updateAncConfig(settableToggles) {
        const modes = [
            {
                key: 'off',
                mode: ANCMode.OFF,
                icon: 'bbm-anc-off-symbolic',
                label: _('Off'),
            },
            {
                key: 'transparency',
                mode: ANCMode.TRANSPARENCY,
                icon: 'bbm-transperancy-symbolic',
                label: _('Transparency'),
            },
            {
                key: 'adaptive',
                mode: ANCMode.ADAPTIVE,
                icon: 'bbm-adaptive-symbolic',
                label: _('Adaptive'),
            },
            {
                key: 'anc',
                mode: ANCMode.ANC_ON,
                icon: 'bbm-anc-on-symbolic',
                label: _('Noise Cancellation'),
            },
        ];

        this._toggle1ButtonToAncMode = [];

        for (let i = 1; i <= 4; i++) {
            this._config[`toggle1Button${i}Icon`] = '';
            this._config[`toggle1Button${i}Name`] = '';
            this._toggle1ButtonToAncMode[i] = null;
        }

        let index = 1;

        for (const entry of modes) {
            if (!(settableToggles & entry.mode))
                continue;

            this._config[`toggle1Button${index}Icon`] = entry.icon;
            this._config[`toggle1Button${index}Name`] = entry.label;

            this._toggle1ButtonToAncMode[index] = entry.mode;

            index++;
        }

        this._props.toggle1Visible = index > 2;
    }

    _startConfiguration() {
        this.dataHandler = new DataHandler(this._config, this._props);
        this.updateDeviceMapCb(this._devicePath, this.dataHandler);

        this._dataHandlerId = this.dataHandler.connect(
            'ui-action', (o, command, value) => {
                if (command === 'toggle1State')
                    this._toggle1ButtonClicked(value);

                if (command === 'settingsButtonClicked')
                    this._settingsButtonClicked();
            }
        );
    }

    updateBatteryProps(props) {
        this._props = {...this._props, ...props};
        this._props.computedBatteryLevel = buds2to1BatteryLevel(props);
        this.dataHandler?.setProps(this._props);
    }

    updateNoiseControl(mode, settableToggles) {
        if (this._settableToggles !== settableToggles) {
            this._settableToggles = settableToggles;
            this._updateAncConfig(settableToggles);
            this.dataHandler?.setConfig(this._config);
            this.dataHandler?.setProps(this._props);
        }

        if (mode !== null)
            this._ancMode = mode;

        let toggleIndex =
        this._toggle1ButtonToAncMode?.findIndex(v => v === this._ancMode);

        if (toggleIndex < 0)
            toggleIndex = 0;

        this._props.toggle1State = toggleIndex;

        this.dataHandler?.setProps(this._props);
    }

    _toggle1ButtonClicked(index) {
        const ancMode = this._toggle1ButtonToAncMode?.[index];

        if (ancMode == null)
            return;

        this._props.toggle1State = index;
        this.dataHandler?.setProps(this._props);

        this._gfpsSocket?.sendAncState(ancMode);
    }

    _settingsButtonClicked() {
        this._configureWindowLauncherCancellable = new Gio.Cancellable();
        launchConfigureWindow(this._devicePath, DeviceTypeGfps, this._extPath,
            this._configureWindowLauncherCancellable);
        this._configureWindowLauncherCancellable = null;
    }

    destroy() {
        this._gfpsSocket?.destroy();
        this._gfpsSocket = null;

        if (this._dataHandlerId)
            this.dataHandler?.disconnect(this._dataHandlerId);
        this._dataHandlerId = null;
        this.dataHandler = null;
        this._monitorGfpsListGsettings(false);
        this._settings = null;
    }
});
