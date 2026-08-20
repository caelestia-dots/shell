'use strict';
import Gio from 'gi://Gio';
import GObject from 'gi://GObject';
const _ = s => s; // gettext stub for daemon context

import {createLogger, getDeviceIdentifier} from '../logger.js';
import {getBluezDeviceProxy} from '../../bluezDeviceProxy.js';
import {buds2to1BatteryLevel, validateProperties, launchConfigureWindow} from '../deviceUtils.js';
import {createConfig, createProperties, DataHandler} from '../../dataHandler.js';
import {AirpodsSocket} from './airpodsSocket.js';
import {
    AirpodsModelList, ANCMode, AwarenessMode, EarDetection,
    PressSpeedMode, PressDurationMode, VolSwipeLength
} from './airpodsConfig.js';

export const DeviceTypeAirpods = 'airpods';

const AirpodsUUID = '74ec2172-0bad-4d01-8f77-997b2be0722a';
export function isAirpods(bluezDeviceProxy, uuids) {
    const bluezProps = ['Modalias'];
    let supported = 'no';

    if (!uuids.includes(AirpodsUUID))
        return {supported, bluezProps};

    const modalias = bluezDeviceProxy.Modalias;
    if (!modalias) {
        supported = 'pending';
        return {supported, bluezProps};
    }

    const regex = /v004Cp([0-9A-Fa-f]{4})d/;
    const match = modalias.match(regex);
    if (!match)
        return {supported, bluezProps};

    const model = match[1].toUpperCase();
    if (AirpodsModelList.some(m => m.key === model))
        supported = 'yes';

    return {supported, bluezProps};
}

export const AirpodsDevice = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_AirpodsDevice',
}, class AirpodsDevice extends GObject.Object {
    _init(settings, devicePath, alias, extPath, profileManager, updateDeviceMapCb) {
        super._init();
        const identifier = getDeviceIdentifier(devicePath);
        const tag = `AirpodsDevice-${identifier}`;
        this._log = createLogger(tag);
        this._log.info('------------------- AirpodsDevice init -------------------');
        const now = Date.now();
        this._settings = settings;
        this._devicePath = devicePath;
        this._alias = alias;
        this._extPath = extPath;
        this.updateDeviceMapCb = updateDeviceMapCb;

        this._config = createConfig();
        this._props = createProperties();
        this._model = null;
        this._budInEar = false;
        this._bothBudsInEar = false;
        this._battInfoRecieved = false;
        this._previousOnDestroyVolume = -1;
        this._ignoreGsettingsChange = false;

        const attStrings = this._settings.get_strv('attenuated-on-destroy-info');
        if (attStrings.length > 0) {
            const {path, timestamp, volume} = JSON.parse(attStrings[0]);
            if (path === this._devicePath && now - timestamp <= 500)
                this._previousOnDestroyVolume = volume;
        }

        this._callbacks = {
            updateBatteryProps: this.updateBatteryProps.bind(this),
            updateAncMode: this.updateAncMode.bind(this),
            updateAdaptiveLevel: this.updateAdaptiveLevel.bind(this),
            updateAwarenessMode: this.updateAwarenessMode.bind(this),
            updateAwarenessData: this.updateAwarenessData.bind(this),
            updateInEarStatus: this.updateInEarStatus.bind(this),

            updatePressSpeed: this.updatePressSpeed.bind(this),
            updatePressDuration: this.updatePressDuration.bind(this),
            updateVolSwipeLength: this.updateVolSwipeLength.bind(this),
            updateVolSwipeMode: this.updateVolSwipeMode.bind(this),
            updateNotificationToneMode: this.updateNotificationToneMode.bind(this),
        };
        this._initialize(profileManager);
    }

    _initialize(profileManager) {
        this._bluezDeviceProxy = getBluezDeviceProxy(this._devicePath);
        const modalias = this._bluezDeviceProxy.Modalias;
        const regex = /v004Cp([0-9A-Fa-f]{4})d/;
        const match = modalias.match(regex);
        if (!match)
            return;

        this._model = match[1].toUpperCase();
        this._modelData = AirpodsModelList.find(m => m.key === this._model);
        this._log.info(`Configuration: ${JSON.stringify(this._modelData, null, 2)}`);

        this._batteryType = this._modelData.batteryType;
        this._ancSupported = this._modelData.ancSupported ?? false;
        this._adaptiveSupported = this._modelData.adaptiveSupported ?? false;
        this._awarenessSupported = this._modelData.awarenessSupported ?? false;
        this._pressSpeedDurationSupported =
                        this._modelData.pressSpeedDurationSupported ?? false;
        this._volumeSwipeSupported = this._modelData.volumeSwipeSupported ?? false;
        this._longPressCycleSupported = this._modelData.longPressCycleSupported ?? false;
        this._toneVolumeSupported = this._modelData.toneVolumeSupported ?? false;
        this._enableTurnOffListeningMode = this._modelData.enableTurnOffListeningMode ?? false;

        this._commonIcon = this._modelData.budsIcon;
        this._config.battery1ShowOnDisconnect = true;
        this._config.showSettingsButton = true;

        if (this._batteryType !== 1)
            this._caseIcon = `${this._modelData.case}`;

        this._createDefaultSettings();

        const devicesList = this._settings.get_strv('airpods-list').map(JSON.parse);

        if (devicesList.length === 0 ||
                !devicesList.some(device => device.path === this._devicePath)) {
            this._addPropsToSettings(devicesList);
        } else {
            validateProperties(this._settings, 'airpods-list', devicesList,
                this._defaultsDeviceSettings, this._devicePath);
        }

        this._updateInitialValues();
        this._monitorAirpodsListGsettings();
        this._updateIcons();
        this._updateAncConfig();
        this._updateAwarnessConfig();

        const profile = {type: DeviceTypeAirpods, uuid: AirpodsUUID};

        this._airpodsSocket = new AirpodsSocket(
            this._devicePath,
            profileManager,
            profile,
            this._modelData,
            this._callbacks
        );
    }

    _updateIcons() {
        this._config.commonIcon = this._commonIcon;
        this._config.albumArtIcon = this._commonIcon;

        this._config.battery1ShowOnDisconnect = true;
        if (this._batteryType !== 1) {
            this._config.battery1Icon = `${this._commonIcon}-left`;
            this._config.battery2Icon = `${this._commonIcon}-right`;
            this._config.battery2ShowOnDisconnect = true;
            this._config.battery3Icon = this._caseIcon;
        } else {
            this._config.battery1Icon = this._commonIcon;
        }

        this.dataHandler?.setConfig(this._config);
    }

    _updateAncConfig() {
        if (!this._ancSupported)
            return;

        this._config.toggle1Title = _('Noise Control');

        const allowOff = !this._enableTurnOffListeningMode ||
                this._enableTurnOffListeningMode && this._lisMode;

        const modes = [];

        if (allowOff)
            modes.push('off');

        modes.push('transparency');

        if (this._adaptiveSupported)
            modes.push('adaptive');

        modes.push('anc');

        this._toggle1Modes = modes;

        const icons = {
            off: 'bbm-anc-off-symbolic',
            transparency: 'bbm-transperancy-symbolic',
            adaptive: 'bbm-adaptive-symbolic',
            anc: 'bbm-anc-on-symbolic',
        };

        const labels = {
            off: _('Off'),
            transparency: _('Transparency'),
            adaptive: _('Adaptive'),
            anc: _('Noise Cancellation'),
        };

        const ncModes = {
            off: ANCMode.ANC_OFF,
            transparency: ANCMode.TRANSPARENCY,
            adaptive: ANCMode.ADAPTIVE,
            anc: ANCMode.ANC_ON,
        };

        this._toggle1ButtonToAncMode = [];

        for (let i = 1; i <= 4; i++) {
            this._config[`toggle1Button${i}Icon`] = '';
            this._config[`toggle1Button${i}Name`] = '';
            this._toggle1ButtonToAncMode[i] = null;
        }

        modes.forEach((mode, index) => {
            const button = index + 1;

            this._config[`toggle1Button${button}Icon`] = icons[mode];
            this._config[`toggle1Button${button}Name`] = labels[mode];

            this._toggle1ButtonToAncMode[button] = ncModes[mode];
        });

        if (this._adaptiveSupported) {
            this._config.optionsBox1 = ['slider'];
            this._config.box1SliderTitle = _('Ambient Level');
        }
    }

    _updateAwarnessConfig() {
        if (this._awarenessSupported) {
            this._config.toggle2Title = _('Conversation Awareness');
            this._config.toggle2Button1Icon = 'bbm-ca-on-symbolic';
            this._config.toggle2Button1Name = _('On');
            this._config.toggle2Button2Icon = 'bbm-ca-off-symbolic';
            this._config.toggle2Button2Name = _('Off');
        }
    }

    _createDefaultSettings() {
        this._defaultsDeviceSettings = {
            path: this._devicePath,
            model: this._model,
            alias: this._alias,
            icon: this._commonIcon,

            ...this._batteryType !== 1 && {
                'case': this._caseIcon,
            },

            'wear-detection-mode': 1,

            ...this._enableTurnOffListeningMode && {
                'listening-mode': true,
            },

            ...this._awarenessSupported && {
                'ca-volume-enabled': true,
                'ca-volume': 20,
            },

            ...this._longPressCycleSupported && {
                'lp-value': 6,
            },

            ...this._toneVolumeSupported && {
                'noti-vol': 77,
            },

            ...this._volumeSwipeSupported && {
                'swipe-mode': true,
                'swipe-len': 0,
            },

            ...this._pressSpeedDurationSupported && {
                'press-speed': 0,
                'press-dur': 0,
            },
        };
    }

    _addPropsToSettings(devicesList) {
        devicesList.push(this._defaultsDeviceSettings);
        this._settings.set_strv('airpods-list', devicesList.map(JSON.stringify));
    }

    _updateInitialValues() {
        const devicesList = this._settings.get_strv('airpods-list').map(JSON.parse);
        const existingPathIndex = devicesList.findIndex(item => item.path === this._devicePath);
        if (existingPathIndex === -1)
            return;

        this._settingsItems = devicesList[existingPathIndex];

        this._commonIcon = this._settingsItems['icon'];

        if (this._batteryType !== 1)
            this._caseIcon = this._settingsItems['case'];

        if (this._awarenessSupported) {
            this._caVolEnabled = this._settingsItems['ca-volume-enabled'];
            this._caVolume = this._settingsItems['ca-volume'];
        }

        if (this._enableTurnOffListeningMode)
            this._lisMode = this._settingsItems['listening-mode'];

        if (this._longPressCycleSupported)
            this._lpValue = this._settingsItems['lp-value'];

        if (this._toneVolumeSupported)
            this._notiVolume = this._settingsItems['noti-vol'];

        if (this._volumeSwipeSupported) {
            this._swipeMode = this._settingsItems['swipe-mode'];
            this._swipeLength = this._settingsItems['swipe-len'];
        }

        if (this._pressSpeedDurationSupported) {
            this._pressSpeed = this._settingsItems['press-speed'];
            this._pressDur = this._settingsItems['press-dur'];
        }

        this._wearDetectionMode = this._settingsItems['wear-detection-mode'];
    }

    _updateGsettingsProps() {
        const devicesList = this._settings.get_strv('airpods-list').map(JSON.parse);
        const existingPathIndex = devicesList.findIndex(item => item.path === this._devicePath);
        if (existingPathIndex === -1)
            return;

        this._settingsItems = devicesList[existingPathIndex];

        const icon = this._settingsItems['icon'];
        if (this._commonIcon !== icon) {
            this._commonIcon = icon;
            this._updateIcons();
        }

        if (this._batteryType !== 1) {
            const caseIcon = this._settingsItems['case'];
            if (this._caseIcon !== caseIcon) {
                this._caseIcon = caseIcon;
                this._updateIcons();
            }
        }

        const wearDetectionMode = this._settingsItems['wear-detection-mode'];
        if (this._wearDetectionMode !== wearDetectionMode) {
            this._wearDetectionMode = wearDetectionMode;
            this._configureMediaController();
        }

        if (this._awarenessSupported) {
            this._caVolume = this._settingsItems['ca-volume'];
            if (this._caVolEnabled && !this._settingsItems['ca-volume-enabled'])
                this._mediaController?.setConversationAwarenessVolume(false, this._caVolume);

            this._caVolEnabled = this._settingsItems['ca-volume-enabled'];
        }

        if (this._enableTurnOffListeningMode) {
            const lisMode = this._settingsItems['listening-mode'];
            if (this._lisMode !== lisMode) {
                this._lisMode = lisMode;
                this._setListMode(lisMode);
            }
        }

        if (this._longPressCycleSupported) {
            const lpValue = this._settingsItems['lp-value'];
            if (this._lpValue !== lpValue) {
                this._lpValue = lpValue;
                this._setLongpressCycle(lpValue);
            }
        }

        if (this._toneVolumeSupported) {
            const notiVol = this._settingsItems['noti-vol'];
            if (this._notiVolume !== notiVol) {
                this._notiVolume = notiVol;
                this._setNotiVolume(notiVol);
            }
        }

        if (this._volumeSwipeSupported) {
            const swipeMode = this._settingsItems['swipe-mode'];
            if (this._swipeMode !== swipeMode) {
                this._swipeMode = swipeMode;
                this._setSwipeMode(swipeMode);
            }

            const swipeLen = this._settingsItems['swipe-len'];
            if (this._swipeLength !== swipeLen) {
                this._swipeLength = swipeLen;
                this._setSwipeLength(swipeLen);
            }
        }

        if (this._pressSpeedDurationSupported) {
            const pressSpeed = this._settingsItems['press-speed'];
            if (this._pressSpeed !== pressSpeed) {
                this._pressSpeed = pressSpeed;
                this._setPressSpeed(pressSpeed);
            }

            const pressDur = this._settingsItems['press-dur'];
            if (this._pressDur !== pressDur) {
                this._pressDur = pressDur;
                this._setPressDur(pressDur);
            }
        }
    }

    _monitorAirpodsListGsettings() {
        this._settingsHandlerId = this._settings?.connect('changed::airpods-list', () => {
            if (this._ignoreGsettingsChange)
                return;

            this._updateGsettingsProps();
        });
    }

    _updateGsettings() {
        this._ignoreGsettingsChange = true;

        const currentList = this._settings.get_strv('airpods-list').map(JSON.parse);
        const index = currentList.findIndex(d => d.path === this._devicePath);

        if (index !== -1) {
            currentList[index] = this._settingsItems;
            this._settings.set_strv('airpods-list', currentList.map(JSON.stringify));
        }

        this._ignoreGsettingsChange = false;
    }

    _startConfiguration(battInfo) {
        const bat1level = battInfo.battery1Level  ?? 0;
        const bat2level = battInfo.battery2Level  ?? 0;
        const bat3level = battInfo.battery3Level  ?? 0;

        if (bat1level <= 0 && bat2level <= 0 && bat3level <= 0)
            return;

        this._battInfoRecieved = true;

        this._configureMediaController();

        if (this._enableTurnOffListeningMode)
            this._setListMode(this._lisMode, true);

        this.dataHandler = new DataHandler(this._config, this._props);

        this.updateDeviceMapCb(this._devicePath, this.dataHandler);

        this._dataHandlerId = this.dataHandler.connect(
            'ui-action', (o, command, value) => {
                if (command === 'toggle1State')
                    this._toggle1ButtonClicked(value);

                if (command === 'toggle2State')
                    this._toggle2ButtonClicked(value);

                if (command === 'box1SliderValue')
                    this._setSliderChanged(value);

                if (command === 'settingsButtonClicked')
                    this._settingsButtonClicked();
            }
        );
    }

    _configureMediaController() {
        // MediaController not available in daemon context
    }

    updateBatteryProps(props) {
        this._props = {...this._props, ...props};

        if (this._batteryType === 1)
            this._props.computedBatteryLevel = props.battery1Level;
        else
            this._props.computedBatteryLevel = buds2to1BatteryLevel(props);

        if (!this._battInfoRecieved)
            this._startConfiguration(props);

        this.dataHandler?.setProps(this._props);
    }

    updateAncMode(ancMode) {
        if (!this._ancSupported)
            return;

        if (ancMode !== null)
            this._ancMode = ancMode;

        let index = this._toggle1ButtonToAncMode?.findIndex(v => v === this._ancMode);

        if (index < 0)
            index = 0;

        this._props.toggle1State = index;

        this._props.optionsBoxVisible =
            this._adaptiveSupported && ancMode === ANCMode.ADAPTIVE ? 1 : 0;

        this.dataHandler?.setProps(this._props);
    }

    updateAdaptiveLevel(level) {
        const inverseLevel = 100 - level;
        this._inverseLevel = inverseLevel;
        this._props.box1SliderValue = inverseLevel;
        this.dataHandler?.setProps(this._props);
    }

    updateAwarenessMode(mode) {
        if (!this._awarenessSupported)
            return;

        if (mode === AwarenessMode.ON)
            this._props.toggle2State = 1;
        else if (mode === AwarenessMode.OFF)
            this._props.toggle2State = 2;

        this.dataHandler?.setProps(this._props);
    }

    _updatetoggleVisibility() {
        const toggle1Visible = this._budInEar && this._ancSupported;
        const toggle2Visible =
            this._bothBudsInEar  && this._awarenessSupported && this._outputIsA2dp;

        this._props.toggle1Visible = toggle1Visible;
        this._props.toggle2Visible = toggle2Visible;
        this.dataHandler?.setProps(this._props);
    }

    updateInEarStatus(bud1Status, bud2Status) {
        this._bothBudsInEar =
            bud1Status === EarDetection.IN_EAR && bud2Status === EarDetection.IN_EAR;

        this._budInEar =
            bud1Status === EarDetection.IN_EAR || bud2Status === EarDetection.IN_EAR;

        this._updatetoggleVisibility();

        if (this._wearDetectionMode !== 0) {
            let playbackMode = null;

            if (this._wearDetectionMode === 1)
                playbackMode = this._bothBudsInEar ? 'play' : 'pause';
            else if (this._wearDetectionMode === 2)
                playbackMode = this._budInEar ? 'play' : 'pause';

            if (playbackMode)
                this._mediaController?.changeActivePlayerState(playbackMode);
        }
    }

    updateAwarenessData(attenuated) {
        if (this._awarenessSupported && this._caVolEnabled)
            this._mediaController?.setConversationAwarenessVolume(attenuated, this._caVolume);
    }

    updateNotificationToneMode(level) {
        if (!this._toneVolumeSupported)
            return;

        this._notiVolume = level;

        if (this._settingsItems) {
            this._settingsItems['noti-vol'] = level;
            this._updateGsettings();
        }
    }

    updateVolSwipeMode(state) {
        if (!this._volumeSwipeSupported)
            return;

        this._swipeMode = state;

        if (this._settingsItems) {
            this._settingsItems['swipe-mode'] = state;
            this._updateGsettings();
        }
    }

    updateVolSwipeLength(duration) {
        if (!this._volumeSwipeSupported)
            return;

        let index;
        if (duration === VolSwipeLength.DEFAULT)
            index = 0;
        else if (duration === VolSwipeLength.LONGER)
            index = 1;
        else
            index = 2;

        this._swipeLength = index;

        if (this._settingsItems) {
            this._settingsItems['swipe-len'] = index;
            this._updateGsettings();
        }
    }

    updatePressSpeed(speed) {
        if (!this._pressSpeedDurationSupported)
            return;

        let index;
        if (speed === PressSpeedMode.DEFAULT)
            index = 0;
        else if (speed === PressSpeedMode.SLOWER)
            index = 1;
        else
            index = 2;

        this._pressSpeed = index;

        if (this._settingsItems) {
            this._settingsItems['press-speed'] = index;
            this._updateGsettings();
        }
    }

    updatePressDuration(duration) {
        let index;
        if (duration === PressDurationMode.DEFAULT)
            index = 0;
        else if (duration === PressDurationMode.SLOWER)
            index = 1;
        else
            index = 2;

        this._pressDur = index;

        if (this._settingsItems) {
            this._settingsItems['press-dur'] = index;
            this._updateGsettings();
        }
    }

    _toggle1ButtonClicked(index) {
        const ancMode = this._toggle1ButtonToAncMode?.[index];
        if (ancMode == null)
            return;

        this._props.toggle1State = index;
        this._props.optionsBoxVisible =
            this._adaptiveSupported && ancMode === ANCMode.ADAPTIVE ? 1 : 0;
        this.dataHandler?.setProps(this._props);
        this._airpodsSocket?.setAncMode(ancMode);
    }

    _toggle2ButtonClicked(index) {
        this._props.toggle2State = index;
        this.dataHandler?.setProps(this._props);
        if (index === 1)
            this._airpodsSocket?.setAwarenessMode(AwarenessMode.ON);
        else if (index === 2)
            this._airpodsSocket?.setAwarenessMode(AwarenessMode.OFF);
    }

    _setSliderChanged(level) {
        const inverseLevel = 100 - level;
        if (this._inverseLevel !== inverseLevel) {
            this._inverseLevel = inverseLevel;
            this._airpodsSocket?.setAdaptiveLevel(inverseLevel);
        }
    }

    _setListMode(lisMode, atInit = false) {
        if (!this._enableTurnOffListeningMode)
            return;

        this._airpodsSocket?.setListMode(lisMode);
        if (!atInit) {
            this._updateAncConfig();
            this.dataHandler?.setConfig(this._config);
            this.updateAncMode(this._ancMode);
        }
    }

    _setLongpressCycle(cyclicValue) {
        if (!this._longPressCycleSupported)
            return;

        this._airpodsSocket?.setLongpressCycle(cyclicValue);
    }

    _setNotiVolume(volume) {
        if (!this._toneVolumeSupported)
            return;

        this._airpodsSocket?.setNotiVolume(volume);
    }

    _setSwipeMode(state) {
        if (!this._volumeSwipeSupported)
            return;

        this._airpodsSocket?.setSwipeMode(state);
    }

    _setSwipeLength(index) {
        if (!this._volumeSwipeSupported)
            return;

        if (index === 0)
            this._airpodsSocket?.setSwipeLength(VolSwipeLength.DEFAULT);
        else if (index === 1)
            this._airpodsSocket?.setSwipeLength(VolSwipeLength.LONGER);
        else if (index === 2)
            this._airpodsSocket?.setSwipeLength(VolSwipeLength.LONGEST);
    }

    _setPressSpeed(index) {
        if (!this._pressSpeedDurationSupported)
            return;

        if (index === 0)
            this._airpodsSocket?.setPressSpeed(PressSpeedMode.DEFAULT);
        else if (index === 1)
            this._airpodsSocket?.setPressSpeed(PressSpeedMode.SLOWER);
        else if (index === 2)
            this._airpodsSocket?.setPressSpeed(PressSpeedMode.SLOWEST);
    }

    _setPressDur(index) {
        if (!this._pressSpeedDurationSupported)
            return;

        if (index === 0)
            this._airpodsSocket?.setPressDur(PressDurationMode.DEFAULT);
        else if (index === 1)
            this._airpodsSocket?.setPressDur(PressDurationMode.SHORTER);
        else if (index === 2)
            this._airpodsSocket?.setPressDur(PressDurationMode.SHORTEST);
    }

    _settingsButtonClicked() {
        this._configureWindowLauncherCancellable = new Gio.Cancellable();
        launchConfigureWindow(this._devicePath, 'airpods', this._extPath,
            this._configureWindowLauncherCancellable);
        this._configureWindowLauncherCancellable = null;
    }

    destroy() {
        this._configureWindowLauncherCancellable?.cancel();
        this._configureWindowLauncherCancellable = null;

        this._airpodsSocket?.destroy();
        this._airpodsSocket = null;
        this._bluezDeviceProxy = null;
        if (this._dataHandlerId)
            this.dataHandler?.disconnect(this._dataHandlerId);
        this._dataHandlerId = null;
        this.dataHandler = null;
        if (this._settingsHandlerId)
            this._settings?.disconnect(this._settingsHandlerId);
        this._settingsHandlerId = null;
        if (this._mediaHandlerId)
            this._mediaController?.disconnect(this._mediaHandlerId);
        this._mediaHandlerId = null;
        this._mediaController?.destroy();
        this._mediaController = null;
        this._settings = null;
        this._battInfoRecieved = false;
    }
});

