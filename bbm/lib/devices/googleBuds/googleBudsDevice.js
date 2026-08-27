'use strict';
import Gio from 'gi://Gio';
import GObject from 'gi://GObject';
const _ = s => s; // gettext stub for daemon context

import {createLogger, getDeviceIdentifier} from '../logger.js';
import {
    buds2to1BatteryLevel, launchConfigureWindow, validateProperties
} from '../deviceUtils.js';
import {createConfig, createProperties, DataHandler} from '../../dataHandler.js';
import {GoogleBudsSocket} from './googleBudsSocket.js';
import {
    AncState, DeviceTypeGoogleBuds, EqPreset, MaestroUUID, eqPresetForBands
} from './googleBudsConfig.js';

export {DeviceTypeGoogleBuds};

export function isGoogleBuds(bluezDeviceProxy, uuids) {
    const bluezProps = [];
    let supported = 'no';

    if (uuids.includes(MaestroUUID))
        supported = 'yes';

    return {supported, bluezProps};
}

export const GoogleBudsDevice = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_GoogleBudsDevice',
}, class GoogleBudsDevice extends GObject.Object {
    _init(settings, devicePath, alias, extPath, profileManager, updateDeviceMapCb) {
        super._init();
        const identifier = getDeviceIdentifier(devicePath);
        const tag = `GoogleBudsDevice-${identifier}`;
        this._log = createLogger(tag);
        this._log.info('------------------- GoogleBudsDevice init -------------------');
        this._settings = settings;
        this._devicePath = devicePath;
        this._alias = alias;
        this._extPath = extPath;
        this.updateDeviceMapCb = updateDeviceMapCb;
        this._ignoreGsettingsChange = false;

        this._battInfoRecieved = false;
        this._config = createConfig();
        this._props = createProperties();

        this._callbacks = {
            updateFirmwareInfo: this.updateFirmwareInfo.bind(this),
            updateBatteryProps: this.updateBatteryProps.bind(this),
            updateAncState: this.updateAncState.bind(this),
            updateAncGestureLoop: this.updateAncGestureLoop.bind(this),
            updateVolumeEqEnable: this.updateVolumeEqEnable.bind(this),
            updateEq: this.updateEq.bind(this),
            updateLastSavedEq: this.updateLastSavedEq.bind(this),
        };

        this._initialize(profileManager);
    }

    _initialize(profileManager) {
        this._commonIcon = 'earbuds';
        this._caseIcon = 'case-oval';

        this._config.commonIcon = this._commonIcon;
        this._config.albumArtIcon = this._commonIcon;
        this._config.battery1Icon = `${this._commonIcon}-left`;
        this._config.battery2Icon = `${this._commonIcon}-right`;
        this._config.battery3Icon = this._caseIcon;
        this._config.battery1ShowOnDisconnect = true;
        this._config.battery2ShowOnDisconnect = true;
        this._config.showSettingsButton = true;
        this._updateAncConfig();
        this._createDefaultSettings();
        this._ensureSettings();
        this._updateInitialValues();
        this._monitorGoogleBudsListGsettings();

        const profile = {type: DeviceTypeGoogleBuds, uuid: MaestroUUID};

        this._googleBudsSocket = new GoogleBudsSocket(
            this._devicePath,
            profileManager,
            profile,
            this._callbacks
        );
    }

    _createDefaultSettings() {
        this._defaultsDeviceSettings = {
            path: this._devicePath,
            name: 'Pixel Buds',
            alias: this._alias,
            icon: this._commonIcon,
            'fw-version': '',
            'volume-eq': false,
            'eq-preset': EqPreset.CUSTOM,
            'eq-custom': [0, 0, 0, 0, 0],
            'eq-last-saved': [0, 0, 0, 0, 0],
        };
    }

    _ensureSettings() {
        const devicesList = this._settings.get_strv('google-buds-list').map(JSON.parse);

        if (devicesList.length === 0 ||
                !devicesList.some(device => device.path === this._devicePath)) {
            devicesList.push(this._defaultsDeviceSettings);
            this._settings.set_strv('google-buds-list', devicesList.map(JSON.stringify));
            return;
        }

        validateProperties(this._settings, 'google-buds-list', devicesList,
            this._defaultsDeviceSettings, this._devicePath);
    }

    _updateInitialValues() {
        const devicesList = this._settings.get_strv('google-buds-list').map(JSON.parse);
        const existingPathIndex = devicesList.findIndex(item => item.path === this._devicePath);
        if (existingPathIndex === -1)
            return;

        this._settingsItems = devicesList[existingPathIndex];
        this._commonIcon = this._settingsItems.icon;
        this._volumeEq = this._settingsItems['volume-eq'];
        this._eqPreset = this._settingsItems['eq-preset'];
        this._eqCustom = this._settingsItems['eq-custom'];
        this._eqLastSaved = this._settingsItems['eq-last-saved'];
        this._updateIcons();
    }

    _updateIcons() {
        this._config.commonIcon = this._commonIcon;
        this._config.albumArtIcon = this._commonIcon;
        this._config.battery1Icon = `${this._commonIcon}-left`;
        this._config.battery2Icon = `${this._commonIcon}-right`;
        this._config.battery3Icon = this._caseIcon;
        this.dataHandler?.setConfig(this._config);
    }

    _monitorGoogleBudsListGsettings() {
        this._settingsHandlerId = this._settings?.connect('changed::google-buds-list', () => {
            if (this._ignoreGsettingsChange)
                return;

            this._updateGsettingsProps();
        });
    }

    _updateGsettingsProps() {
        const devicesList = this._settings.get_strv('google-buds-list').map(JSON.parse);
        const existingPathIndex = devicesList.findIndex(item => item.path === this._devicePath);
        if (existingPathIndex === -1)
            return;

        this._settingsItems = devicesList[existingPathIndex];

        const icon = this._settingsItems.icon;
        if (this._commonIcon !== icon) {
            this._commonIcon = icon;
            this._updateIcons();
        }

        const volumeEq = this._settingsItems['volume-eq'];
        if (this._volumeEq !== volumeEq) {
            this._volumeEq = volumeEq;
            this._googleBudsSocket?.setVolumeEqEnable(volumeEq);
        }

        this._eqPreset = this._settingsItems['eq-preset'];
        this._eqLastSaved = this._settingsItems['eq-last-saved'];

        const eqCustom = this._settingsItems['eq-custom'];
        if (JSON.stringify(this._eqCustom) !== JSON.stringify(eqCustom)) {
            this._eqCustom = eqCustom;
            this._googleBudsSocket?.setEq(eqCustom);
        }
    }

    _updateGsettings() {
        if (!this._settingsItems)
            return;

        this._ignoreGsettingsChange = true;

        const currentList = this._settings.get_strv('google-buds-list').map(JSON.parse);
        const index = currentList.findIndex(d => d.path === this._devicePath);

        if (index !== -1) {
            currentList[index] = this._settingsItems;
            this._settings.set_strv('google-buds-list', currentList.map(JSON.stringify));
        }

        this._ignoreGsettingsChange = false;
    }

    _updateAncConfig(enabledModes = {off: true, aware: true, active: true, adaptive: false}) {
        this._ancEnabledModes = {...enabledModes};
        this._config.toggle1Title = _('Noise Control');

        for (let i = 1; i <= 4; i++) {
            this._config[`toggle1Button${i}Icon`] = null;
            this._config[`toggle1Button${i}Name`] = '';
        }

        const modes = [
            {
                enabled: enabledModes.off,
                state: AncState.OFF,
                icon: 'bbm-anc-off-symbolic',
                name: _('Off'),
            },
            {
                enabled: enabledModes.aware,
                state: AncState.AWARE,
                icon: 'bbm-transperancy-symbolic',
                name: _('Transparency'),
            },
            {
                enabled: enabledModes.active,
                state: AncState.ACTIVE,
                icon: 'bbm-anc-on-symbolic',
                name: _('Noise Cancellation'),
            },
            {
                enabled: enabledModes.adaptive,
                state: AncState.ADAPTIVE,
                icon: 'bbm-adaptive-symbolic',
                name: _('Adaptive'),
            },
        ];

        this._toggle1ButtonToAncState = {};
        let button = 1;

        for (const mode of modes) {
            if (!mode.enabled)
                continue;

            this._config[`toggle1Button${button}Icon`] = mode.icon;
            this._config[`toggle1Button${button}Name`] = mode.name;
            this._toggle1ButtonToAncState[button] = mode.state;
            button++;
        }

        this._ancStateToToggle1Button = Object.fromEntries(
            Object.entries(this._toggle1ButtonToAncState)
                .map(([button, state]) => [state, Number(button)])
        );

        if (this._props.toggle1State &&
                !this._toggle1ButtonToAncState[this._props.toggle1State])
            this._props.toggle1State = 0;

        this.dataHandler?.setConfig(this._config);
    }

    updateAncGestureLoop(gestureLoop) {
        const enabledModes = {
            off: true,
            aware: true,
            active: true,
            adaptive: gestureLoop.adaptive || this._ancState === AncState.ADAPTIVE,
        };
        this._updateAncConfig(enabledModes);
    }

    _startConfiguration(battInfo) {
        const bat1level = battInfo.battery1Level  ?? 0;
        const bat2level = battInfo.battery2Level  ?? 0;
        const bat3level = battInfo.battery3Level  ?? 0;

        if (bat1level <= 0 && bat2level <= 0 && bat3level <= 0)
            return;

        this._battInfoRecieved = true;
        this._props.toggle1Visible = true;
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

    updateFirmwareInfo(fwVersions) {
        const arr = fwVersions ?? [];

        if (arr.length === 0) {
            this._settingsItems['fw-version'] = '';
            this._updateGsettings();
            return;
        }

        let best = arr[0];
        let bestCount = 0;

        for (const v of arr) {
            const count = arr.filter(x => x === v).length;

            if (count > bestCount) {
                best = v;
                bestCount = count;
            }
        }

        const allSame = arr.every(v => v === arr[0]);

        this._settingsItems['fw-version'] = best;
        this._updateGsettings();

        if (allSame)
            this._log.info(`Firmware: ${best}`);
        else
            this._log.info(`Firmware mismatch: ${arr.join(', ')} -> using ${best}`);
    }

    updateBatteryProps(props) {
        this._props = {...this._props, ...props};
        this._props.computedBatteryLevel = buds2to1BatteryLevel(this._props);

        if (!this._battInfoRecieved)
            this._startConfiguration(this._props);

        this.dataHandler?.setProps(this._props);
    }

    updateAncState(ancState) {
        this._ancState = ancState;
        if (ancState === AncState.ADAPTIVE && !this._ancStateToToggle1Button?.[ancState])
            this._updateAncConfig({...this._ancEnabledModes, adaptive: true});

        const toggleState = this._ancStateToToggle1Button?.[ancState] ?? 0;
        this._props.toggle1State = toggleState;
        this.dataHandler?.setProps(this._props);
    }

    updateVolumeEqEnable(enabled) {
        if (this._volumeEq === enabled)
            return;

        this._volumeEq = enabled;

        if (this._settingsItems) {
            this._settingsItems['volume-eq'] = enabled;
            this._updateGsettings();
        }
    }

    updateEq(eqBands) {
        const roundedBands = eqBands.map(value => Math.round(value));
        const preset = this._eqPresetForBands(roundedBands);
        if (this._eqPreset === preset &&
                JSON.stringify(this._eqCustom) === JSON.stringify(roundedBands))
            return;

        this._eqPreset = preset;
        this._eqCustom = roundedBands;

        if (this._settingsItems) {
            this._settingsItems['eq-preset'] = preset;
            this._settingsItems['eq-custom'] = roundedBands;
            this._updateGsettings();
        }
    }

    updateLastSavedEq(eqBands) {
        const roundedBands = eqBands.map(value => Math.round(value));
        const lastSavedChanged =
            JSON.stringify(this._eqLastSaved) !== JSON.stringify(roundedBands);

        this._eqLastSaved = roundedBands;
        const preset = this._eqPresetForBands(this._eqCustom);

        if (!lastSavedChanged && this._eqPreset === preset)
            return;

        this._eqPreset = preset;

        if (this._settingsItems) {
            this._settingsItems['eq-last-saved'] = roundedBands;
            this._settingsItems['eq-preset'] = preset;
            this._updateGsettings();
        }
    }

    _eqPresetForBands(eqBands) {
        const staticPreset = eqPresetForBands(eqBands);
        if (staticPreset !== EqPreset.CUSTOM)
            return staticPreset;

        if (JSON.stringify(eqBands) === JSON.stringify(this._eqLastSaved))
            return EqPreset.LAST_SAVED;

        return EqPreset.CUSTOM;
    }

    _toggle1ButtonClicked(index) {
        const ancState = this._toggle1ButtonToAncState?.[index];
        if (!ancState)
            return;

        this._props.toggle1State = index;
        this.dataHandler?.setProps(this._props);
        this._googleBudsSocket?.setAncState(ancState);
    }

    _settingsButtonClicked() {
        this._configureWindowLauncherCancellable = new Gio.Cancellable();
        launchConfigureWindow(this._devicePath, DeviceTypeGoogleBuds, this._extPath,
            this._configureWindowLauncherCancellable);
        this._configureWindowLauncherCancellable = null;
    }

    destroy() {
        this._configureWindowLauncherCancellable?.cancel();
        this._configureWindowLauncherCancellable = null;

        if (this._dataHandlerId && this.dataHandler)
            this.dataHandler.disconnect(this._dataHandlerId);
        this._dataHandlerId = null;
        if (this._settingsHandlerId)
            this._settings?.disconnect(this._settingsHandlerId);
        this._settingsHandlerId = null;
        this._googleBudsSocket?.destroy();
        this._googleBudsSocket = null;
        this.dataHandler = null;
        this._settings = null;
    }
});
