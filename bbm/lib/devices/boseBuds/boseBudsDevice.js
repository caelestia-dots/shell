'use strict';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';
const _ = s => s; // gettext stub for daemon context

import {createLogger, getDeviceIdentifier, hexBytes} from '../logger.js';
import {
    buds2to1BatteryLevel, validateProperties, launchConfigureWindow, isArrayEqual,
    SppUUidType, SppUUid
} from '../deviceUtils.js';
import {createConfig, createProperties, DataHandler} from '../../dataHandler.js';
import {getBluezDeviceProxy} from '../../bluezDeviceProxy.js';
import {BoseBudsSocket} from './boseBudsSocket.js';
import {BoseBudsModelList, AudioModes} from './boseBudsConfig.js';
import {BtDeviceState, DeviceManagementAction} from '../commonEmuns.js';

export const DeviceTypeBoseBuds = 'boseBuds';
const BoseBudsUUID = '00000000-deca-fade-deca-deafdecacaff';
export function isBoseBuds(bluezDeviceProxy, uuids) {
    const bluezProps = ['Modalias'];
    let supported = 'no';

    if (!uuids.includes(BoseBudsUUID) || !uuids.includes(SppUUid))
        return {supported, bluezProps};

    const modalias = bluezDeviceProxy.Modalias;
    if (!modalias) {
        supported = 'pending';
        return {supported, bluezProps};
    }

    const regex = /v009Ep([0-9A-Fa-f]{4})d/;
    const match = modalias.match(regex);
    if (!match)
        return {supported, bluezProps};

    const modelId = match[1].toUpperCase();
    if (BoseBudsModelList.some(m => m.id === modelId))
        supported = 'yes';

    return {supported, bluezProps};
}

export const BoseBudsDevice = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_BoseBudsDevice',
}, class BoseBudsDevice extends GObject.Object {
    _init(settings, devicePath, alias, extPath, profileManager, updateDeviceMapCb) {
        super._init();

        const identifier = getDeviceIdentifier(devicePath);
        const tag = `BoseBudsDevice-${identifier}`;
        this._log = createLogger(tag);
        this._log.info('------------------- BoseBudsDevice init -------------------');
        this._settings = settings;
        this._devicePath = devicePath;
        this._alias = alias;
        this._extPath = extPath;
        this.updateDeviceMapCb = updateDeviceMapCb;
        this._ignoreGsettingsChange = false;
        this._inEarSettings = false;

        this._config = createConfig();
        this._props = createProperties();
        this._modelData = null;
        this._fwVersion = '';
        this._serialNo = '';
        this._deviceInfo = [];
        this._pendingBTOperations = new Map();
        this._modeCount = 10;

        this._callbacks = {
            updateFirmware: this.updateFirmware.bind(this),
            updateSerial: this.updateSerial.bind(this),
            updateBatteryProps: this.updateBatteryProps.bind(this),
            updateInEarState: this.updateInEarState.bind(this),
            updateEq: this.updateEq.bind(this),
            updateAnr: this.updateAnr.bind(this),
            updateAudioModeCurrent: this.updateAudioModeCurrent.bind(this),
            updateAudioModeRestore: this.updateAudioModeRestore.bind(this),
            updateAudioModeFavorites: this.updateAudioModeFavorites.bind(this),
            updateCnc: this.updateCnc.bind(this),
            updateSpatialAudio: this.updateSpatialAudio.bind(this),
            updateDualConnection: this.updateDualConnection.bind(this),
            updateSideTone: this.updateSideTone.bind(this),
            updateInEarSettings: this.updateInEarSettings.bind(this),
            updateAutoAnswer: this.updateAutoAnswer.bind(this),
            updateAutoPause: this.updateAutoPause.bind(this),
            updateAutoTransparency: this.updateAutoTransparency.bind(this),
            updateAutoPowerOffTimer: this.updateAutoPowerOffTimer.bind(this),
            updateVoicePrompt: this.updateVoicePrompt.bind(this),
            updateActionButton: this.updateActionButton.bind(this),
            updateBTDeviceList: this.updateBTDeviceList.bind(this),
            updateBTDeviceInfo: this.updateBTDeviceInfo.bind(this),
            updatePairingMode: this.updatePairingMode.bind(this),
            updateConnectError: this.updateConnectError.bind(this),
            updateConnectStatus: this.updateConnectStatus.bind(this),
            updateDisconnectError: this.updateDisconnectError.bind(this),
            updateDisconnectStatus: this.updateDisconnectStatus.bind(this),
            updateRemoveBTDeviceError: this.updateRemoveBTDeviceError.bind(this),
            updateRemoveBTDeviceStatus: this.updateRemoveBTDeviceStatus.bind(this),
            updateRoutingStatus: this.updateRoutingStatus.bind(this),
            updateOwnDeviceId: this.updateOwnDeviceId.bind(this),
        };

        const bluezDeviceProxy = getBluezDeviceProxy(this._devicePath);
        const modalias = bluezDeviceProxy.Modalias;

        const regex = /v009Ep([0-9A-Fa-f]{4})d/;
        const match = modalias.match(regex);
        if (!match) {
            this._log.info(`No device configuration found for modalias: ${modalias}`);
            return;
        }

        const modelId = match[1].toUpperCase();
        this._modelData = BoseBudsModelList.find(m => m.id === modelId);
        if (!this._modelData) {
            this._log.info(`No device configuration found for modalias: ${modalias}`);
            return;
        }

        this._log.info(`Configuration: ${JSON.stringify(this._modelData, null, 2)}`);

        this._commonIcon = this._modelData.budsIcon;
        this._config.battery1ShowOnDisconnect = true;
        this._config.showSettingsButton = true;

        if (!this._modelData.batterySingle)
            this._caseIcon = `${this._modelData.case}`;

        this._createDefaultSettings();

        const devicesList = this._settings.get_strv('bose-buds-list').map(JSON.parse);

        if (devicesList.length === 0 ||
                !devicesList.some(device => device.path === this._devicePath)) {
            this._addPropsToSettings(devicesList);
        } else {
            validateProperties(this._settings, 'bose-buds-list', devicesList,
                this._defaultsDeviceSettings, this._devicePath);
        }

        this._updateInitialValues();
        this._monitorBoseBudsListGsettings();
        this._updateDeviceInfo();
        this._updateIcons();
        if (this._modelData.audioModes)
            this._setupAudioModeToggle();
        else if (this._modelData.anr)
            this._setupAnrToggle();

        if (this._modelData.audioModes?.showNCInterface)
            this._addCNC();

        if (this._modelData.audioModes?.spatialMode)
            this._addSpatialMode();

        const profile = {type: SppUUidType, uuid: SppUUid};

        this._boseBudsSocket = new BoseBudsSocket(
            this._devicePath,
            profileManager,
            profile,
            this._modelData,
            this._callbacks
        );
    }

    _createModesArray() {
        const audioModes = this._modelData.audioModes;
        const modes = [];

        for (const preset of Object.values(audioModes.presets)) {
            modes[preset.index] = {
                ...audioModes.defaultConfig,
                ...preset,
            };
        }

        for (let index = 0; index < audioModes.totalModes; index++) {
            if (!modes[index]) {
                modes[index] = {
                    ...audioModes.defaultConfig,
                    index,
                };
            }
        }

        return modes;
    }

    _createDefaultGestureSettings() {
        const gestures = [];

        for (const button of Object.values(this._modelData.gestureOptions.buttons)) {
            for (const gesture of Object.values(button.gestures)) {
                const [, actionByte] = Object.entries(gesture.actions)[0];

                gestures.push({
                    id: button.id,
                    gesture: gesture.byte,
                    action: actionByte,
                });
            }
        }

        return gestures;
    }

    _createDefaultSettings() {
        this._defaultsDeviceSettings = {
            path: this._devicePath,
            id: this._modelData.id,
            alias: this._alias,
            icon: this._commonIcon,
            'fw-version': this._fwVersion,
            'serial': this._serialNo,

            ...!this._modelData.batterySingle && {
                'case': this._caseIcon,
            },

            ...this._modelData.audioModes && {
                'modes': this._createModesArray(),
                'current-mode': 0,
                'restore-mode': false,
            },

            ...this._modelData.eq && {
                'eq-preset': 'flat',
            },

            ...this._modelData.eq?.bands !== undefined && {
                'eq-custom': new Array(this._modelData.eq.bands.length).fill(0),
            },

            ...this._modelData.dualConnection && {
                'multipoint': false,
                'dev-mgmt': [],
                'pairing-mode': false,
                'dev-mgmt-action': {seq: 0, action: 0, id: ''},
                'active-dev': '',
                'own-dev': '',
            },

            ...this._modelData.sideTone && {
                'side-tone': 0,
            },

            ...this._modelData.inEarSettings && {
                'in-ear': false,
                'wear-detection-mode': 1,
            },

            ...this._modelData.autoAnswer && {
                'auto-answer': false,
            },

            ...this._modelData.autoPause && {
                'auto-pause': false,
            },

            ...this._modelData.autoTransparency && {
                'auto-transp': false,
            },

            ...this._modelData.automaticPowerOffTimer && {
                'auto-power': this._modelData.automaticPowerOffTimer[0],
            },

            ...this._modelData.voicePrompt && {
                'voice-enabled': false,
                'voice-prompt': 0xFF,
                'supported-voice': 0xFFFFFFFF,
                'batt-voice': 0,
                'vobat-sup': false,
                'vobat-en': false,
            },

            ...this._modelData.gestureOptions && {
                'gestures': this._createDefaultGestureSettings(),
            },
        };
    }

    _addPropsToSettings(devicesList) {
        devicesList.push(this._defaultsDeviceSettings);
        this._settings.set_strv('bose-buds-list', devicesList.map(JSON.stringify));
    }

    _updateInitialValues() {
        const devicesList = this._settings.get_strv('bose-buds-list').map(JSON.parse);
        const existingPathIndex = devicesList.findIndex(item => item.path === this._devicePath);
        if (existingPathIndex === -1)
            return;

        this._settingsItems = devicesList[existingPathIndex];

        this._commonIcon = this._settingsItems['icon'];

        if (!this._modelData.batterySingle)
            this._caseIcon = this._settingsItems['case'];

        if (this._modelData.audioModes) {
            this._audioModes = this._settingsItems['modes'];
            this._currentAudioMode = this._settingsItems['current-mode'];
            this._restoreAudioMode = this._settingsItems['restore-mode'];
        }

        if (this._modelData.eq)
            this._presetEq = this._settingsItems['eq-preset'];

        if (this._modelData.eq?.bands !== undefined)
            this._customEq = this._settingsItems['eq-custom'];

        if (this._modelData.dualConnection) {
            this._multipoint = this._settingsItems['multipoint'];
            this._pairingMode = this._settingsItems['pairing-mode'];
            this._devMgmtAction = this._settingsItems['dev-mgmt-action'];
            this._activeDevice = this._settingsItems['active-dev'];
            this._ownDevice = this._settingsItems['own-dev'];
        }

        if (this._modelData.sideTone)
            this._sideTone = this._settingsItems['side-tone'];

        if (this._modelData.inEarSettings) {
            this._inEarSettings = this._settingsItems['in-ear'];
            this._wearDetectionMode = this._settingsItems['wear-detection-mode'];
        }

        if (this._modelData.autoAnswer)
            this._autoAnswer = this._settingsItems['auto-answer'];

        if (this._modelData.autoPause)
            this._autoPause = this._settingsItems['auto-pause'];

        if (this._modelData.autoTransparency)
            this._autoTransparency = this._settingsItems['auto-transp'];

        if (this._modelData.automaticPowerOffTimer)
            this._autoPowerOffTimer = this._settingsItems['auto-power'];

        if (this._modelData.voicePrompt) {
            this._voiceEnabled = this._settingsItems['voice-enabled'];
            this._voicePrompt = this._settingsItems['voice-prompt'];
            this._supportedVoice = this._settingsItems['supported-voice'];
            this._voiceBatSupported = this._settingsItems['vobat-sup'];
            this._voiceBatEnabled = this._settingsItems['vobat-en'];
        }

        if (this._modelData.gestureOptions)
            this._gestures = this._settingsItems['gestures'];
    }

    _updateGsettingsProps() {
        const devicesList = this._settings.get_strv('bose-buds-list').map(JSON.parse);
        const existingPathIndex = devicesList.findIndex(item => item.path === this._devicePath);
        if (existingPathIndex === -1)
            return;

        this._settingsItems = devicesList[existingPathIndex];

        const icon = this._settingsItems['icon'];
        if (this._commonIcon !== icon) {
            this._commonIcon = icon;
            this._updateIcons();
        }

        if (!this._modelData.batterySingle) {
            const caseIcon = this._settingsItems['case'];
            if (this._caseIcon !== caseIcon) {
                this._caseIcon = caseIcon;
                this._updateIcons();
            }
        }

        if (this._modelData.audioModes) {
            const modes = this._settingsItems['modes'];
            let favoritesChanged = false;
            let uiModesChanged = false;
            const favorites = [];

            for (const mode of modes) {
                const isModeEqual = (a, b) => Object.keys(a).every(key => {
                    if (key === 'ui' || key === 'fav')
                        return true;

                    return a[key] === b[key];
                });

                const isFavoriteEqual = (a, b) => a.added === b.added && a.fav === b.fav;
                const isUiEqual = (a, b) => a.added === b.added && a.ui === b.ui;


                const current = this._audioModes.find(m => m.index === mode.index);

                if (!current || !isModeEqual(current, mode))
                    this._setAudioMode(mode);

                if (current && !isFavoriteEqual(current, mode))
                    favoritesChanged = true;

                if (current && !isUiEqual(current, mode))
                    uiModesChanged = true;

                if (mode.added && mode.fav)
                    favorites.push(mode.index);
            }

            if (favoritesChanged)
                this._setAudioModeFavorites(favorites);

            this._audioModes = modes.map(mode => ({...mode}));

            if (uiModesChanged)
                this._setupAudioModeToggle();

            const currentAudioMode = this._settingsItems['current-mode'];
            if (this._currentAudioMode !== currentAudioMode) {
                this._currentAudioMode = currentAudioMode;
                this._setCurrentAudioMode(currentAudioMode);
                this.updateAudioModeCurrent(currentAudioMode, true);
            }

            const restoreAudioMode = this._settingsItems['restore-mode'];
            if (this._restoreAudioMode !== restoreAudioMode) {
                this._restoreAudioMode = restoreAudioMode;
                this._setRestoreAudioMode(restoreAudioMode);
            }
        }

        if (this._modelData.eq?.bands !== undefined) {
            const eqCustom = this._settingsItems['eq-custom'];
            if (!this._customEq || !isArrayEqual(eqCustom, this._customEq)) {
                const oldGains = this._customEq;
                const newGains = eqCustom;

                this._customEq = eqCustom;
                this._setCustomEq(oldGains, newGains);
            }
        }

        if (this._modelData.dualConnection) {
            const multipoint = this._settingsItems['multipoint'];
            if (this._multipoint !== multipoint) {
                this._multipoint = multipoint;
                this._setMultipoint(multipoint);
            }

            const pairingMode = this._settingsItems['pairing-mode'];
            if (this._pairingMode !== pairingMode) {
                this._pairingMode = pairingMode;
                this._setPairingMode(pairingMode);
            }

            const devMgmtAction = this._settingsItems['dev-mgmt-action'];
            if (this._devMgmtAction.seq !== devMgmtAction.seq) {
                this._devMgmtAction = devMgmtAction;

                switch (devMgmtAction.action) {
                    case DeviceManagementAction.Connect:
                        this._connectBTDevice(devMgmtAction.id);
                        break;

                    case DeviceManagementAction.Disconnect:
                        this._disconnectBTDevice(devMgmtAction.id);
                        break;

                    case DeviceManagementAction.Remove:
                        this._removeBTDevice(devMgmtAction.id);
                        break;

                    case DeviceManagementAction.Routing:
                        this._setRoutingBTDevice(devMgmtAction.id);
                        break;
                }
            }
        }

        if (this._modelData.sideTone) {
            const sideTone = this._settingsItems['side-tone'];
            if (this._sideTone !== sideTone) {
                this._sideTone = sideTone;
                this._setSideTone(sideTone);
            }
        }

        if (this._modelData.inEarSettings) {
            const inEarSettings = this._settingsItems['in-ear'];
            if (this._inEarSettings !== inEarSettings) {
                this._inEarSettings = inEarSettings;
                this._setInEarSettings(inEarSettings);
            }

            const wearDetectionMode = this._settingsItems['wear-detection-mode'];
            if (this._wearDetectionMode !== wearDetectionMode) {
                this._wearDetectionMode = wearDetectionMode;
                this._configureMediaController();
            }
        }

        if (this._modelData.autoAnswer) {
            const autoAnswer = this._settingsItems['auto-answer'];
            if (this._autoAnswer !== autoAnswer) {
                this._autoAnswer = autoAnswer;
                this._setAutoAnswer(autoAnswer);
            }
        }

        if (this._modelData.autoPause) {
            const autoPause = this._settingsItems['auto-pause'];
            if (this._autoPause !== autoPause) {
                this._autoPause = autoPause;
                this._setAutoPause(autoPause);
            }
        }

        if (this._modelData.autoTransparency) {
            const autoTransparency = this._settingsItems['auto-transp'];
            if (this._autoTransparency !== autoTransparency) {
                this._autoTransparency = autoTransparency;
                this._setAutoTransparency(autoTransparency);
            }
        }

        if (this._modelData.automaticPowerOffTimer) {
            const minutes = this._settingsItems['auto-power'];
            if (this._autoPowerOffTimer !== minutes) {
                this._autoPowerOffTimer = minutes;
                this._setAutoPowerOffTimer(minutes);
            }
        }

        if (this._modelData.voicePrompt) {
            let update = false;
            const voiceEnabled = this._settingsItems['voice-enabled'];
            if (this._voiceEnabled !== voiceEnabled) {
                this._voiceEnabled = voiceEnabled;
                update = true;
            }

            const voicePrompt = this._settingsItems['voice-prompt'];
            if (this._voicePrompt !== voicePrompt) {
                this._voicePrompt = voicePrompt;
                update = true;
            }

            const batEnabled = this._settingsItems['vobat-en'];
            if (this._voiceBatEnabled !== batEnabled) {
                this._voiceBatEnabled = batEnabled;
                update = true;
            }

            if (update)
                this._setVoicePrompt();
        }

        if (this._modelData.gestureOptions) {
            const gestures = this._settingsItems['gestures'] ?? [];

            const getGestureKey = g => g.id << 8 | g.gesture;

            const oldGestures = new Map(
                (this._gestures ?? []).map(g => [getGestureKey(g), g])
            );

            for (const gesture of gestures) {
                const old = oldGestures.get(getGestureKey(gesture));

                if (!old || old.action !== gesture.action)
                    this._setGesture(gesture);
            }

            this._gestures = gestures;
        }
    }

    _monitorBoseBudsListGsettings() {
        this._settingsHandlerId = this._settings?.connect('changed::bose-buds-list', () => {
            if (this._ignoreGsettingsChange)
                return;

            this._updateGsettingsProps();
        });
    }

    _updateGsettings() {
        this._ignoreGsettingsChange = true;

        const currentList = this._settings.get_strv('bose-buds-list').map(JSON.parse);
        const index = currentList.findIndex(d => d.path === this._devicePath);

        if (index !== -1) {
            currentList[index] = this._settingsItems;
            this._settings.set_strv('bose-buds-list', currentList.map(JSON.stringify));
        }

        this._ignoreGsettingsChange = false;
    }

    _configureMediaController() {
        // MediaController not available in daemon context
    }

    _updateIcons() {
        this._config.commonIcon = this._commonIcon;
        this._config.albumArtIcon = this._commonIcon;
        this._config.battery1ShowOnDisconnect = true;

        if (this._modelData.batterySingle) {
            this._config.battery1Icon = this._commonIcon;
        } else {
            this._config.battery1Icon = `${this._commonIcon}-left`;
            this._config.battery2Icon = `${this._commonIcon}-right`;
            this._config.battery2ShowOnDisconnect = true;
            this._config.battery3Icon = this._caseIcon;
        }

        this.dataHandler?.setConfig(this._config);
    }

    _updateDeviceInfo() {
        this._settingsItems['id'] = this._modelData.id;
        this._settingsItems['alias'] = this._alias;
        this._updateGsettings();
    }

    updateFirmware(fwVersion) {
        this._fwVersion = fwVersion;
        if (this._settingsItems) {
            this._settingsItems['fw-version'] = fwVersion;
            this._updateGsettings();
        }
    }

    updateSerial(serial) {
        this._serialNo = serial;
        if (this._settingsItems) {
            this._settingsItems['serial'] = serial;
            this._updateGsettings();
        }
    }

    _setupAnrToggle() {
        const anr = this._modelData.anr;
        if (!anr)
            return;

        this._config.toggle1Title = _('Noise Control');
        this._props.toggle1Visible = true;

        const labels = {
            off: _('Off'),
            low: _('Low'),
            high: _('High'),
            wind: _('Wind'),
        };

        const icons = {
            off: 'bbm-anc-off-symbolic',
            low: 'bbm-transperancy-symbolic',
            high: 'bbm-anc-on-symbolic',
            wind: 'bbm-anc-wind-symbolic',
        };

        this._toggle1Modes = Object.keys(anr);

        for (let i = 1; i <= 4; i++) {
            this._config[`toggle1Button${i}Name`] = '';
            this._config[`toggle1Button${i}Icon`] = null;
        }

        this._toggle1Modes.forEach((mode, index) => {
            const button = index + 1;

            this._config[`toggle1Button${button}Name`] = labels[mode] ?? mode;
            this._config[`toggle1Button${button}Icon`] = icons[mode] ?? null;
        });
    }

    _setupAudioModeToggle() {
        this._log.info('Setup Audio mode toggle');

        this._config.toggle1Title = _('Modes');
        this._props.toggle1Visible = true;

        this._toggle1AudioModes = [];

        for (let i = 1; i <= 4; i++) {
            this._config[`toggle1Button${i}Name`] = '';
            this._config[`toggle1Button${i}Icon`] = null;
        }

        for (const mode of this._audioModes) {
            if (!mode.ui)
                continue;

            this._toggle1AudioModes.push(mode);
        }

        this._toggle1AudioModes.forEach((mode, index) => {
            const button = index + 1;
            const iconMode = AudioModes[mode.id];

            this._config[`toggle1Button${button}Name`] = mode.name;
            this._config[`toggle1Button${button}Icon`] = `bbm-mode-${iconMode}-symbolic`;
        });

        const entries = this._toggle1AudioModes.map((mode, index) => [mode.index, index + 1]);
        this._toggle1AudioModeMap = new Map(entries);
        this._config.labelIndicatorEnabled = 1;


        this.dataHandler?.setConfig(this._config);

        this.updateAudioModeCurrent(this._currentAudioMode, true);
    }

    _addCNC() {
        this._log.info('Add CNC UI');
        this._cncLevel = this._modelData.audioModes.nc.level / 2;
        this._cncEnabled = false;
        this._config.optionsBox1 = ['check-button'];
        this._config.box1CheckButton = [_('Noise Control')];
        this._config.optionsBox2 = ['check-button', 'slider'];
        this._config.box2CheckButton = [_('Noise Control')];
        this._config.box2SliderTitle = _('Noise Cancellation');
        this._props.optionsBoxVisible = 1;
        this.dataHandler?.setConfig(this._config);
    }

    _addSpatialMode() {
        this._log.info('Add Spatial Audio');
        this._config.toggle2Title = _('Spatial Audio');
        this._props.toggle2Visible = true;
        this._config.toggle2Button1Name = _('Off');
        this._config.toggle2Button1Icon = 'bbm-spatial-off-symbolic';
        this._config.toggle2Button2Name = _('Still');
        this._config.toggle2Button2Icon = 'bbm-spatial-still-symbolic';
        this._config.toggle2Button3Name = _('Motion');
        this._config.toggle2Button3Icon = 'bbm-spatial-motion-symbolic';
        this.dataHandler?.setConfig(this._config);
    }

    _startConfiguration(battInfo) {
        const bat1level = battInfo.battery1Level  ?? 0;
        const bat2level = battInfo.battery2Level  ?? 0;
        const bat3level = battInfo.battery3Level  ?? 0;

        if (bat1level <= 0 && bat2level <= 0 && bat3level <= 0)
            return;

        this._battInfoRecieved = true;

        this.dataHandler = new DataHandler(this._config, this._props);

        this.updateDeviceMapCb(this._devicePath, this.dataHandler);

        this._dataHandlerId = this.dataHandler.connect(
            'ui-action', (o, command, value) => {
                if (command === 'toggle1State')
                    this._toggle1ButtonClicked(value);

                if (command === 'toggle2State')
                    this._toggle2ButtonClicked(value);

                if (command === 'box1CheckButton1State')
                    this._box1CheckButton1StateChanged(value);

                if (command === 'box2SliderValue')
                    this._box2SliderValueChanged(value);

                if (command === 'box2SliderIsDragging')
                    this._box2SliderIsDragging(value);

                if (command === 'box2CheckButton1State')
                    this._box2CheckButton1StateChanged(value);

                if (command === 'settingsButtonClicked')
                    this._settingsButtonClicked();
            }
        );
    }

    updateBatteryProps(props) {
        this._props = {...this._props, ...props};

        if (!this._modelData)
            return;

        if (!this._modelData?.batteryMultiple)
            this._props.computedBatteryLevel = props.battery1Level;
        else
            this._props.computedBatteryLevel = buds2to1BatteryLevel(props);

        const isBatteryValid =
                props.battery1Level > 0 && props.battery1Status !== 'disconnected' ||
                props.battery2Level > 0 && props.battery2Status !== 'disconnected';

        if (!this._battInfoRecieved && isBatteryValid)
            this._startConfiguration(props);

        this.dataHandler?.setProps(this._props);
    }

    updateInEarState(bud1Status, bud2Status) {
        this._bothBudsInEar = bud1Status && bud2Status;
        this._budInEar = bud1Status || bud2Status;

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

    updateAnr(mode) {
        this._log.info(`updateAnr mode: ${hexBytes(mode)}`);
        const anr = this._modelData.anr;
        for (const [index, modeKey] of this._toggle1Modes.entries()) {
            if (anr[modeKey] === mode) {
                if (this._props.toggle1State !== index + 1) {
                    this._props.toggle1State = index + 1;
                    this.dataHandler?.setProps(this._props);
                }
                return;
            }
        }
    }

    _toggle1ButtonClicked(index) {
        if (this._modelData.audioModes)
            this._toggle1ButtonClickedAudioMode(index);
        else if (this._modelData.anr)
            this._toggle1ButtonClickedAnr(index);
    }

    _toggle1ButtonClickedAnr(index) {
        const mode = this._toggle1Modes[index - 1];
        if (!mode)
            return;

        const value = this._modelData.anr[mode];
        this._props.toggle1State = index;
        this.dataHandler?.setProps(this._props);
        this._boseBudsSocket?.setAnr(value);
    }

    _toggle1ButtonClickedAudioMode(index) {
        const mode = this._toggle1AudioModes[index - 1];

        if (!mode)
            return;

        this._props.toggle1State = index;
        this.dataHandler?.setProps(this._props);

        this._currentAudioMode = mode.index;
        this._settingsItems['current-mode'] = mode.index;
        this._updateGsettings();

        this._setCurrentAudioMode(mode.index);
    }

    updateAudioMode(mode) {
        this._log.info(`updateAudioMode id: ${mode.id}`);

        const index = this._audioModes.findIndex(m => m.id === mode.id);

        if (index === -1) {
            this._audioModes.push({...mode});
            this._settingsItems['modes'] = this._audioModes;
            this._updateGsettings();
            return;
        }

        const current = this._audioModes[index];
        const areModesEqual = (a, b) => {
            const areEqual = a.id === b.id &&
                a.editable === b.editable &&
                a.added === b.added &&
                a.fav === b.fav &&
                a.name === b.name &&
                a.flag === b.flag &&
                a.cnc === b.cnc &&
                a.autoCnc === b.autoCnc &&
                a.spatial === b.spatial &&
                a.wind === b.wind &&
                a.anc === b.anc;
            return areEqual;
        };

        if (!areModesEqual(current, mode)) {
            this._audioModes[index] = {...mode};
            this._settingsItems['modes'] = this._audioModes;
            this._updateGsettings();
        }
    }

    _setAudioMode(mode) {
        this._boseBudsSocket?.setAudioMode(mode);
    }

    updateAudioModeCurrent(index, uiUpdate = false) {
        this._log.info(`updateAudioModeCurrent index: ${index}`);

        const mode = this._audioModes.find(m => m.index === index);
        const text = mode?.name ?? '';

        if (!uiUpdate && this._currentAudioMode !== index) {
            this._currentAudioMode = index;
            this._settingsItems['current-mode'] = index;
            this._updateGsettings();
        }

        const toggleIndex = this._toggle1AudioModeMap?.get(index) ?? 0;

        let propsChanged = false;

        if (this._props.toggle1State !== toggleIndex) {
            this._props.toggle1State = toggleIndex;
            propsChanged = true;
        }

        if (this._props.labelIndicator1 !== text) {
            this._props.labelIndicator1 = text;
            propsChanged = true;
        }

        if (propsChanged)
            this.dataHandler?.setProps(this._props);
    }

    _setCurrentAudioMode(index) {
        const mode = this._audioModes.find(m => m.index === index);
        const toggleIndex = this._toggle1AudioModeMap?.get(index) ?? 0;

        let propsChanged = false;

        if (this._props.toggle1State !== toggleIndex) {
            this._props.toggle1State = toggleIndex;
            propsChanged = true;
        }

        const text = mode?.name ?? '';
        if (this._props.labelIndicator1 !== text) {
            this._props.labelIndicator1 = text;
            propsChanged = true;
        }

        if (propsChanged)
            this.dataHandler?.setProps(this._props);

        this._boseBudsSocket?.setCurrentAudioMode(index);
    }

    updateAudioModeFavorites(modeCount, favorites) {
        this._log.info(`updateAudioModeFavorites favorites: ${JSON.stringify(favorites)}`);
        this._modeCount = modeCount;
    }

    _setAudioModeFavorites(favorites) {
        this._boseBudsSocket?.setAudioModeFavorites(this._modeCount, favorites);
    }

    updateAudioModeRestore(enabled) {
        this._log.info(`updateAudioModeRestore enabled: ${enabled}`);
        if (this._restoreAudioMode !== enabled) {
            this._restoreAudioMode = enabled;
            this._settingsItems['restore-mode'] = enabled;
            this._updateGsettings();
        }
    }

    _setRestoreAudioMode(enable) {
        this._boseBudsSocket?.setRestoreAudioMode(enable);
    }

    updateCnc(level, enabled) {
        this._log.info(`updateCnc level: ${level} enabled: ${enabled}`);
        const nc = this._modelData.audioModes?.nc;
        if (!nc)
            return;

        const maxLevel = nc.level;
        const step = nc.steps;
        level = Math.max(0, Math.min(maxLevel, level));
        level = Math.round(level / step) * step;
        if (this._cncLevel === level && this._cncEnabled === enabled)
            return;

        this._cncLevel = level;
        this._cncEnabled = enabled;
        this._props.box1CheckButton1State = enabled;
        this._props.box2CheckButton1State = enabled;
        this._props.optionsBoxVisible = enabled ? 2 : 1;
        this._props.box2SliderValue = level * 100 / maxLevel;
        this.dataHandler?.setProps(this._props);
    }

    _box1CheckButton1StateChanged(value) {
        const enabled = value === 1;
        if (this._cncEnabled === enabled)
            return;

        this._cncEnabled = enabled;
        this._boseBudsSocket?.setCnc(this._cncLevel, this._cncEnabled);
        this._props.box1CheckButton1State = value;
        this._props.box2CheckButton1State = value;
        this._props.optionsBoxVisible = enabled ? 2 : 1;
        this.dataHandler?.setProps(this._props);
    }

    _box2CheckButton1StateChanged(value) {
        const enabled = value === 1;
        if (this._cncEnabled === enabled)
            return;

        this._cncEnabled = enabled;
        this._boseBudsSocket?.setCnc(this._cncLevel, this._cncEnabled);
        this._props.box1CheckButton1State = value;
        this._props.box2CheckButton1State = value;
        this._props.optionsBoxVisible = enabled ? 2 : 1;
        this.dataHandler?.setProps(this._props);
    }

    _box2SliderValueChanged(value) {
        const nc = this._modelData.audioModes?.nc;
        const maxLevel = nc.level;
        const step = nc.steps;

        let level = Math.round(value * maxLevel / 100);
        level = Math.max(0, Math.min(maxLevel, level));
        level = Math.round(level / step) * step;

        if (this._cncLevel === level)
            return;

        this._cncLevel = level;
        this._props.box2SliderValue = this._cncLevel * 100 / maxLevel;
        this._boseBudsSocket?.setCnc(level, this._cncEnabled);
    }

    _box2SliderIsDragging(value) {
        if (value === 0) {
            const maxLevel = this._modelData.audioModes.nc.level;
            this._props.box2SliderValue = this._cncLevel * 100 / maxLevel;
            this.dataHandler?.setProps(this._props);
        }
    }

    updateSpatialAudio(mode) {
        if (mode < 0 || mode > 2)
            return;

        this._props.toggle2State = mode + 1;
        this.dataHandler?.setProps(this._props);
    }

    _toggle2ButtonClicked(index) {
        const mode = index - 1;
        this._props.toggle2State = index;
        this.dataHandler?.setProps(this._props);
        this._boseBudsSocket?.setSpatialAudio(mode);
    }

    updateEq(arr) {
        let preset = 'custom';

        for (const [name, values] of Object.entries(this._modelData.eq.presets ?? {})) {
            if (isArrayEqual(arr, values)) {
                preset = name;
                break;
            }
        }

        let settingsChanged = false;

        if (this._settingsItems['eq-preset'] !== preset) {
            this._settingsItems['eq-preset'] = preset;
            settingsChanged = true;
        }

        if (!isArrayEqual(arr, this._customEq)) {
            this._customEq = arr;
            this._settingsItems['eq-custom'] = arr;
            settingsChanged = true;
        }

        if (settingsChanged)
            this._updateGsettings();
    }

    _setCustomEq(oldGains, newGains) {
        for (let i = 0; i < oldGains.length; i++) {
            if (oldGains[i] !== newGains[i])
                this._boseBudsSocket?.setEq(newGains[i], i);
        }
    }

    updateSideTone(level) {
        this._log.info(`updateSideTone level: ${level}`);
        if (this._sideTone !== level) {
            this._sideTone = level;
            this._settingsItems['side-tone'] = level;
            this._updateGsettings();
        }
    }

    _setSideTone(level) {
        this._boseBudsSocket?.setSideTone(level);
    }

    updateDualConnection(enabled) {
        this._log.info(`updateDualConnection enabled: ${enabled}`);
        if (this._multipoint !== enabled) {
            this._multipoint = enabled;
            this._settingsItems['multipoint'] = enabled;
            this._updateGsettings();
        }
    }

    _setMultipoint(enabled) {
        this._boseBudsSocket?.setDualConnection(enabled);
    }

    updateInEarSettings(enabled, autoPause, autoAnswer, autoTransparency) {
        this._log.info(`updateInEarSettings enabled: ${enabled}, ` +
            `autoPause: ${autoPause}, autoAnswer: ${autoAnswer}, ` +
            `autoTransparency: ${autoTransparency}`);

        let update = false;

        if (this._inEarSettings !== enabled) {
            this._inEarSettings = enabled;
            this._settingsItems['in-ear'] = enabled;
            update = true;
        }

        if (this._modelData.autoPause && this._autoPause !== autoPause) {
            this._autoPause = autoPause;
            this._settingsItems['auto-pause'] = autoPause;
            update = true;
        }

        if (this._modelData.autoAnswer && this._autoAnswer !== autoAnswer) {
            this._autoAnswer = autoAnswer;
            this._settingsItems['auto-answer'] = autoAnswer;
            update = true;
        }

        if (this._modelData.autoTransparency && this._autoTransparency !== autoTransparency) {
            this._autoTransparency = autoTransparency;
            this._settingsItems['auto-transp'] = autoTransparency;
            update = true;
        }

        if (update)
            this._updateGsettings();
    }

    _setInEarSettings(enabled) {
        const autoPause = this._autoPause ?? false;
        const autoAnswer = this._autoAnswer ?? false;
        const autoTransparency = this._autoTransparency ?? false;
        this._boseBudsSocket?.setInEarSettings(enabled, autoPause, autoAnswer, autoTransparency);
    }

    updateAutoAnswer(enabled) {
        this._log.info(`updateAutoAnswer enabled: ${enabled}`);
        if (this._autoAnswer !== enabled) {
            this._autoAnswer = enabled;
            this._settingsItems['auto-answer'] = enabled;
            this._updateGsettings();
        }
    }

    _setAutoAnswer(enabled) {
        if (this._modelData.inEarSettings)
            this._setInEarSettings(this._inEarSettings);
        else
            this._boseBudsSocket?.setAutoAnswer(enabled);
    }

    updateAutoPause(enabled) {
        this._log.info(`updateAutoPause enabled: ${enabled}`);
        if (this._autoPause !== enabled) {
            this._autoPause = enabled;
            this._settingsItems['auto-pause'] = enabled;
            this._updateGsettings();
        }
    }

    _setAutoPause(enabled) {
        if (this._modelData.inEarSettings)
            this._setInEarSettings(this._inEarSettings);
        else
            this._boseBudsSocket?.setAutoPause(enabled);
    }

    updateAutoTransparency(enabled) {
        this._log.info(`updateAutoTransparency enabled: ${enabled}`);
        if (this._autoTransparency !== enabled) {
            this._autoTransparency = enabled;
            this._settingsItems['auto-transp'] = enabled;
            this._updateGsettings();
        }
    }

    _setAutoTransparency(enabled) {
        if (this._modelData.inEarSettings)
            this._setInEarSettings(this._inEarSettings);
        else
            this._boseBudsSocket?.setAutoTransparency(enabled);
    }

    updateAutoPowerOffTimer(minutes) {
        this._log.info(`updateAutoPowerOffTimer minutes: ${minutes}`);
        if (this._autoPowerOffTimer !== minutes) {
            this._autoPowerOffTimer = minutes;
            this._settingsItems['auto-power'] = minutes;
            this._updateGsettings();
        }
    }

    _setAutoPowerOffTimer(minutes) {
        this._boseBudsSocket?.setAutoPowerOffTimer(minutes);
    }

    updateVoicePrompt(enabled, language, supported, batSupported, batEnabled) {
        let update = false;

        if (this._voiceEnabled !== enabled) {
            this._voiceEnabled = enabled;
            this._settingsItems['voice-enabled'] = enabled;
            update = true;
        }

        if (this._voicePrompt !== language) {
            this._voicePrompt = language;
            this._settingsItems['voice-prompt'] = language;
            update = true;
        }

        if (this._supportedVoice !== supported) {
            this._supportedVoice = supported;
            this._settingsItems['supported-voice'] = supported;
            update = true;
        }

        if (this._voiceBatSupported !== batSupported) {
            this._voiceBatSupported = batSupported;
            this._settingsItems['vobat-sup'] = batSupported;
            update = true;
        }

        if (this._voiceBatEnabled !== batEnabled) {
            this._voiceBatEnabled = batEnabled;
            this._settingsItems['vobat-en'] = batEnabled;
            update = true;
        }

        if (update)
            this._updateGsettings();
    }

    _setVoicePrompt() {
        if (this._voicePrompt === 0xFF)
            return;

        this._boseBudsSocket?.setVoicePrompt(this._voiceEnabled, this._voicePrompt,
            this._voiceBatSupported, this._voiceBatEnabled);
    }

    updateActionButton(buttonId, eventType, action) {
        this._log.info(`updateActionButton buttonId: ${hexBytes(buttonId)}, ` +
                `eventType: ${hexBytes(eventType)}, action: ${hexBytes(action)}`);

        const index = this._gestures.findIndex(g => g.id === buttonId && g.gesture === eventType);

        if (index === -1)
            return;

        if (this._gestures[index].action === action)
            return;

        this._gestures[index] = {...this._gestures[index], action};
        this._settingsItems['gestures'] = this._gestures;
        this._updateGsettings();
    }

    _setGesture(gesture) {
        this._boseBudsSocket?.setActionButton(gesture.id, gesture.gesture, gesture.action);
    }

    updateBTDeviceList(devices) {
        this._log.info('updateBTDeviceList');
        const deviceSet = new Set(devices);
        this._deviceInfo = this._deviceInfo.filter(info => deviceSet.has(info.id));

        for (const id of devices) {
            if (!this._deviceInfo.some(info => info.id === id)) {
                this._deviceInfo.push({
                    id,
                    name: '',
                    connected: false,
                    state: BtDeviceState.NotInitialized,
                });
            }
        }

        this._settingsItems['dev-mgmt'] = this._deviceInfo;
        this._updateGsettings();
    }

    updateBTDeviceInfo(mac, name, connected) {
        this._log.info(`updateBTDeviceInfo connected: ${connected}`);

        const device = this._deviceInfo.find(info => info.id === mac);
        if (!device)
            return;

        let changed = false;

        if (device.name !== name) {
            device.name = name;
            changed = true;
        }

        if (device.connected !== connected) {
            device.connected = connected;
            changed = true;
        }

        if (device.state !== BtDeviceState.Ready) {
            device.state = BtDeviceState.Ready;
            changed = true;
        }

        if (changed) {
            this._settingsItems['dev-mgmt'] = this._deviceInfo;
            this._updateGsettings();
        }
    }

    updatePairingMode(enabled) {
        this._log.info(`updatePairingMode enabled: ${enabled}`);
        if (this._pairingMode !== enabled) {
            this._pairingMode = enabled;
            this._settingsItems['pairing-mode'] = enabled;
            this._updateGsettings();
        }
    }

    _setPairingMode(enabled) {
        this._boseBudsSocket?.setPairingMode(enabled);
    }

    _startBTTimeout(id, operation) {
        const timeoutId = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 10, () => {
            const pending = this._pendingBTOperations.get(id);

            if (!pending)
                return GLib.SOURCE_REMOVE;

            const device = this._deviceInfo.find(info => info.id === id);

            if (device) {
                device.state = BtDeviceState.Ready;
                this._settingsItems['dev-mgmt'] = this._deviceInfo;
                this._updateGsettings();
            }

            this._pendingBTOperations.delete(id);

            return GLib.SOURCE_REMOVE;
        });

        this._pendingBTOperations.set(id, {operation, timeoutId});
    }


    _stopBTTimeout(id) {
        const pending = this._pendingBTOperations.get(id);
        if (!pending)
            return;

        if (pending.timeoutId)
            GLib.Source.remove(pending.timeoutId);

        this._pendingBTOperations.delete(id);
    }

    updateConnectError() {
        const pending = [...this._pendingBTOperations.entries()]
                .find(([, pending]) => pending.operation === 'connect');

        if (!pending)
            return;

        const [id] = pending;
        const device = this._deviceInfo.find(device => device.id === id);

        if (device) {
            device.state = BtDeviceState.Ready;
            this._settingsItems['dev-mgmt'] = this._deviceInfo;
            this._updateGsettings();
        }

        this._stopBTTimeout(id);
    }

    updateConnectStatus(id, connected) {
        const device = this._deviceInfo.find(info => info.id === id);

        if (!device)
            return;

        this._stopBTTimeout(id);
        device.connected = connected;
        device.state = BtDeviceState.Ready;
        this._settingsItems['dev-mgmt'] = this._deviceInfo;
        this._updateGsettings();
    }

    _connectBTDevice(id) {
        const device = this._deviceInfo.find(info => info.id === id);
        if (!device)
            return;

        if (this._pendingBTOperations.has(id))
            return;

        device.state = BtDeviceState.Processing;
        this._settingsItems['dev-mgmt'] = this._deviceInfo;
        this._updateGsettings();
        this._startBTTimeout(id, 'connect');
        this._boseBudsSocket?.connectBTDevice(id);
    }

    updateDisconnectError() {
        const pending = [...this._pendingBTOperations.entries()]
        .find(([, pending]) => pending.operation === 'disconnect');

        if (!pending)
            return;

        const [id] = pending;
        const device = this._deviceInfo.find(device => device.id === id);

        if (device) {
            device.state = BtDeviceState.Ready;
            this._settingsItems['dev-mgmt'] = this._deviceInfo;
            this._updateGsettings();
        }

        this._stopBTTimeout(id);
    }

    updateDisconnectStatus(id) {
        const device = this._deviceInfo.find(device => device.id === id);

        if (!device)
            return;

        device.connected = false;
        device.state = BtDeviceState.Ready;
        this._settingsItems['dev-mgmt'] = this._deviceInfo;
        this._updateGsettings();
        this._stopBTTimeout(id);
    }

    _disconnectBTDevice(id) {
        const device = this._deviceInfo.find(info => info.id === id);
        if (!device)
            return;

        if (this._pendingBTOperations.has(id))
            return;

        device.state = BtDeviceState.Processing;
        this._settingsItems['dev-mgmt'] = this._deviceInfo;
        this._updateGsettings();
        this._startBTTimeout(id, 'disconnect');
        this._boseBudsSocket?.disconnectBTDevice(id);
    }

    updateRemoveBTDeviceError() {
        const pending = [...this._pendingBTOperations.entries()]
                .find(([, pending]) => pending.operation === 'remove');

        if (!pending)
            return;

        const [id] = pending;
        const device = this._deviceInfo.find(device => device.id === id);

        if (device) {
            device.state = BtDeviceState.Ready;
            this._settingsItems['dev-mgmt'] = this._deviceInfo;
            this._updateGsettings();
        }

        this._stopBTTimeout(id);
    }

    updateRemoveBTDeviceStatus(id) {
        this._deviceInfo = this._deviceInfo.filter(device => device.id !== id);
        this._settingsItems['dev-mgmt'] = this._deviceInfo;
        this._updateGsettings();
        this._stopBTTimeout(id);
    }

    _removeBTDevice(id) {
        const device = this._deviceInfo.find(info => info.id === id);
        if (!device)
            return;

        if (this._pendingBTOperations.has(id))
            return;

        device.state = BtDeviceState.Processing;
        this._settingsItems['dev-mgmt'] = this._deviceInfo;
        this._updateGsettings();
        this._startBTTimeout(id, 'remove');
        this._boseBudsSocket?.removeBTDevice(id);
    }

    updateRoutingStatus(id) {
        if (this._activeDevice !== id) {
            this._activeDevice = id;
            this._settingsItems['active-dev'] = id;
            this._updateGsettings();
        }
    }

    _setRoutingBTDevice(id) {
        this._boseBudsSocket?.setRoutingBTDevice(id);
    }

    updateOwnDeviceId(id) {
        if (this._ownDevice !== id) {
            this._ownDevice = id;
            this._settingsItems['own-dev'] = id;
            this._updateGsettings();
        }
    }

    _settingsButtonClicked() {
        this._configureWindowLauncherCancellable = new Gio.Cancellable();
        launchConfigureWindow(this._devicePath, 'boseBuds', this._extPath,
            this._configureWindowLauncherCancellable);
        this._configureWindowLauncherCancellable = null;
    }

    destroy() {
        this._configureWindowLauncherCancellable?.cancel();
        this._configureWindowLauncherCancellable = null;

        this._boseBudsSocket?.destroy();
        this._boseBudsSocket = null;

        for (const {timeoutId} of this._pendingBTOperations.values())
            GLib.Source.remove(timeoutId);

        this._pendingBTOperations.clear();

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

