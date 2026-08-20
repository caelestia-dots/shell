'use strict';
import Gio from 'gi://Gio';
import GObject from 'gi://GObject';
const _ = s => s; // gettext stub for daemon context

import {createLogger, getDeviceIdentifier} from '../logger.js';
import {getBluezDeviceProxy} from '../../bluezDeviceProxy.js';
import {createConfig, createProperties, DataHandler} from '../../dataHandler.js';
import {
    buds2to1BatteryLevel, validateProperties, launchConfigureWindow,
    SppUUidType, SppUUid
} from '../deviceUtils.js';
import {GalaxyBudsSocket} from './galaxyBudsSocket.js';
import {checkForSamsungBuds} from './galaxyBudsDetector.js';
import {
    GalaxyBudsModel, GalaxyBudsModelList, GalaxyBudsAnc, BudsLegacyUUID,
    SamsungMepSppUUID, GalaxyBudsEarDetectionState
} from './galaxyBudsConfig.js';

export const DeviceTypeGalaxyBuds = 'galaxyBuds';
export const DeviceTypeGalaxyLegacy = 'galaxybudslegacy';

export function isGalaxyLegacy(bluezDeviceProxy, uuids) {
    const bluezProps = [];
    let supported = 'no';

    if (uuids.includes(SamsungMepSppUUID) && uuids.includes(BudsLegacyUUID))
        supported = 'yes';

    return {supported, bluezProps};
}

export function isGalaxyBuds(bluezDeviceProxy, uuids) {
    const bluezProps = [];
    let supported = 'no';

    if (uuids.includes(SamsungMepSppUUID) && uuids.includes(SppUUid)) {
        const name = bluezDeviceProxy.Name;
        if (checkForSamsungBuds(uuids, name))
            supported = 'yes';
    }

    return {supported, bluezProps};
}

export const GalaxyBudsDevice = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_GalaxyBudsDevice',
}, class GalaxyBudsDevice extends GObject.Object {
    _init(settings, devicePath, alias, extPath, profileManager, updateDeviceMapCb) {
        super._init();
        const identifier = getDeviceIdentifier(devicePath);
        const tag = `GalaxyBudsDevice-${identifier}`;
        this._log = createLogger(tag);
        this._log.info('------------------- GalaxyBudsDevice init -------------------');
        this._settings = settings;
        this._devicePath = devicePath;
        this._alias = alias;
        this._extPath = extPath;
        this.updateDeviceMapCb = updateDeviceMapCb;
        this._battInfoRecieved = false;
        this._toggle1Enabled = false;
        this._toggle2Enabled = false;
        this._bothInEars = false;
        this._budInEar = false;
        this._ancMode = 0;
        this._ambientLevel = 0;
        this._ncLevel = 0;
        this._focusOnVoice = false;
        this._fwVersion = '';
        this._leftSerial = '';
        this._rightSerial = '';
        this._caseSerial = '';

        this._config = createConfig();
        this._props = createProperties();

        this._initialize(profileManager);
    }

    _initialize(profileManager) {
        const bluezDeviceProxy = getBluezDeviceProxy(this._devicePath);
        const uuids = bluezDeviceProxy.UUIDs;
        const name = bluezDeviceProxy.Name;

        this._modelId = checkForSamsungBuds(uuids, name);
        if (!this._modelId) {
            this._log.info('No valid modelId found');
            return;
        }
        this._log.info(`Model id: ${this._modelId}`);

        const modelData = GalaxyBudsModelList.find(m => m.modelId === this._modelId);

        if (!modelData) {
            this._log.info(`No matching modelData found for name: ${name}`);
            return;
        }

        this._log.info(`Configuration: ${JSON.stringify(modelData, null, 2)}`);

        this._features = modelData.features;
        this._touchOptions = modelData.touchOptions;


        this._callbacks = {
            updateFirmwareInfo: this.updateFirmwareInfo.bind(this),
            updateLRSerial: this.updateLRSerial.bind(this),
            updateCaseSerial: this.updateCaseSerial.bind(this),
            updateExtendedStatusStarted: this.updateExtendedStatusStarted.bind(this),
            updateExtendedStatusEnded: this.updateExtendedStatusEnded.bind(this),
            updateBatteryProps: this.updateBatteryProps.bind(this),
            updateInEarState: this.updateInEarState.bind(this),

            updateFocusOnVoice: this.updateFocusOnVoice.bind(this),
            updateAmbientVolume: this.updateAmbientVolume.bind(this),
            updateNCModes: this.updateNCModes.bind(this),

            updateEqPresets: this.updateEqPresets.bind(this),
            updateTouchpadLock: this.updateTouchpadLock.bind(this),
            updateTouchpadOptionL: this.updateTouchpadOptionL.bind(this),
            updateTouchpadOptionR: this.updateTouchpadOptionR.bind(this),
            updateAdvanceTouchpadLock: this.updateAdvanceTouchpadLock.bind(this),
            updateSideToneEnabled: this.updateSideToneEnabled.bind(this),
            updateStereoBal: this.updateStereoBal.bind(this),
            updateNoiseReductionLevel: this.updateNoiseReductionLevel.bind(this),
            updateNoiseControlCycle: this.updateNoiseControlCycle.bind(this),
            updateDetectConversations: this.updateDetectConversations.bind(this),
            updateDetectConversationsDuration: this.updateDetectConversationsDuration.bind(this),
            updateNoiseControlsWithOneEarbud: this.updateNoiseControlsWithOneEarbud.bind(this),
            updateOutsideDoubleTap: this.updateOutsideDoubleTap.bind(this),
            updateLightingMode: this.updateLightingMode.bind(this),
            updateAmbientCustomization: this.updateAmbientCustomization.bind(this),
        };

        this._commonIcon = modelData.budsIcon;
        if (this._features.caseBattery)
            this._caseIcon = `${modelData.case}`;

        this._createDefaultSettings();

        const devicesList = this._settings.get_strv('galaxy-buds-list').map(JSON.parse);

        if (devicesList.length === 0 ||
                !devicesList.some(device => device.path === this._devicePath)) {
            this._addPropsToSettings(devicesList);
        } else {
            validateProperties(this._settings, 'galaxy-buds-list', devicesList,
                this._defaultsDeviceSettings, this._devicePath);
        }

        this._updateInitialValues();
        this._monitorGalaxyBudsListGsettings(true);
        this._updateIcons();

        this._configureANC();
        this._configureDetectConversations();
        this._config.showSettingsButton = true;

        this._ringState = 'stopped';
        this._settingsItems['ring-state'] = this._ringState;
        this._updateGsettings();

        const type = this._modelId === GalaxyBudsModel.GalaxyBuds
            ? DeviceTypeGalaxyLegacy : SppUUidType;

        const uuid = type === DeviceTypeGalaxyLegacy ? BudsLegacyUUID : SppUUid;

        const profile = {type, uuid};

        this._galaxyBudsSocket = new GalaxyBudsSocket(
            this._devicePath,
            profileManager,
            profile,
            modelData,
            this._callbacks
        );
    }

    _updateIcons() {
        this._config.commonIcon = this._commonIcon;
        this._config.albumArtIcon = this._commonIcon;

        this._config.battery1Icon = `${this._commonIcon}-left`;
        this._config.battery2Icon = `${this._commonIcon}-right`;
        this._config.battery1ShowOnDisconnect = true;
        this._config.battery2ShowOnDisconnect = true;

        if (this._features.caseBattery)
            this._config.battery3Icon = this._caseIcon;

        this.dataHandler?.setConfig(this._config);
    }

    _createDefaultSettings() {
        this._defaultsDeviceSettings = {
            path: this._devicePath,
            modelId: this._modelId,
            alias: this._alias,
            icon: this._commonIcon,
            'fw-version': this._fwVersion,
            'lsn': this._leftSerial,
            'rsn': this._rightSerial,
            'csn': this._caseSerial,

            ...this._features.caseBattery && {
                'case': this._caseIcon,
            },

            'wear-detection-mode': 1,

            ...this._features.detectConversations && {
                's2c-time': 0,
            },

            'eq-preset': 0,

            ...this._features.stereoPan && {
                'stereo-bal': 0,
            },

            'tp-enabled': false,

            ...this._features.advancedTouchLock && {
                'tp-adv-single': false,
                'tp-adv-double': false,
                'tp-adv-triple': false,
                'tp-adv-hold': false,
            },

            ...this._features.advancedTouchIsPinch && {
                'tp-adv-swipe': false,
            },

            ...this._features.advancedTouchLockForCalls && {
                'tp-adv-call-double': false,
                'tp-adv-call-hold': false,
            },

            ...this._features.lightingControl && {
                'tp-lighting': 0,
            },

            'th-left': 0,
            'th-right': 0,

            ...this._features.ncCycle && {
                'nc-off': false,
                'nc-ambient': false,
                'nc-anc': false,
                ...this._features.adaptiveNoiseControl && {
                    'nc-adaptive': false,
                },

                ...this._features.noiseControlModeDualSide && {
                    'nc-left-off': false,
                    'nc-left-ambient': false,
                    'nc-left-anc': false,
                    ...this._features.adaptiveNoiseControl && {
                        'nc-left-adaptive': false,
                    },
                },
            },

            ...this._features.ambientSidetone && {
                'sidetone': false,
            },

            ...this._features.noiseControlsWithOneEarbud && {
                'nc-one': false,
            },

            ...this._features.doubleTapVolume && {
                '2tap-vol': false,
            },

            ...this._features.ambientCustomize && {
                'amb-enable': false,
                'amb-left': 0,
                'amb-right': 0,
                'amb-tone': 0,
            },

            'ring-state': 'stopped',
        };
    }

    _addPropsToSettings(devicesList) {
        devicesList.push(this._defaultsDeviceSettings);
        this._settings.set_strv('galaxy-buds-list', devicesList.map(JSON.stringify));
    }

    _updateInitialValues() {
        const devicesList = this._settings.get_strv('galaxy-buds-list').map(JSON.parse);
        const existingPathIndex = devicesList.findIndex(item => item.path === this._devicePath);
        if (existingPathIndex === -1)
            return;

        this._settingsItems = devicesList[existingPathIndex];

        this._commonIcon = this._settingsItems['icon'];

        if (this._features.caseBattery)
            this._caseIcon = this._settingsItems['case'];

        if (this._features.detectConversations)
            this._s2cTime = this._settingsItems['s2c-time'];

        this._eqPreset = this._settingsItems['eq-preset'];

        if (this._features.stereoPan)
            this._stereoBal = this._settingsItems['stereo-bal'];

        this._touchEnabled = this._settingsItems['tp-enabled'];

        if (this._features.advancedTouchLock) {
            this._tpAdvLock = this._settingsItems['tp-adv-lock'];
            this._tpAdvSingle = this._settingsItems['tp-adv-single'];
            this._tpAdvDouble = this._settingsItems['tp-adv-double'];
            this._tpAdvTriple = this._settingsItems['tp-adv-triple'];
            this._tpAdvHold = this._settingsItems['tp-adv-hold'];
        }

        if (this._features.advancedTouchLockForCalls) {
            this._tpAdvCallDouble = this._settingsItems['tp-adv-call-double'];
            this._tpAdvCallHold = this._settingsItems['tp-adv-call-hold'];
        }

        if (this._features.lightingControl)
            this._tpLighting = this._settingsItems['tp-lighting'];

        this._thLeft = this._settingsItems['th-left'];
        this._thRight = this._settingsItems['th-right'];

        if (this._features.noiseControl) {
            this._ncCycleRight = this._settingsItems['nc-cycle-right'];

            if (this._features.noiseControlModeDualSide)
                this._ncCycleLeft = this._settingsItems['nc-cycle-left'];
        }

        if (this._features.ambientSidetone)
            this._sidetone = this._settingsItems['sidetone'];


        if (this._features.noiseControlsWithOneEarbud)
            this._ncOne = this._settingsItems['nc-one'];


        if (this._features.doubleTapVolume)
            this._twoTapVol = this._settingsItems['2tap-vol'];

        if (this._features.ambientCustomize) {
            this._ambEnable = this._settingsItems['amb-enable'];
            this._ambLeft = this._settingsItems['amb-left'];
            this._ambRight = this._settingsItems['amb-right'];
            this._ambTone = this._settingsItems['amb-tone'];
        }

        this._wearDetectionMode = this._settingsItems['wear-detection-mode'];
        this._ringState = 'stopped';
    }

    _updateGsettingsProps() {
        const devicesList = this._settings.get_strv('galaxy-buds-list').map(JSON.parse);
        const existingPathIndex = devicesList.findIndex(item => item.path === this._devicePath);
        if (existingPathIndex === -1)
            return;

        this._settingsItems = devicesList[existingPathIndex];

        const icon = this._settingsItems['icon'];
        if (this._commonIcon !== icon) {
            this._commonIcon = icon;
            this._updateIcons();
        }

        if (this._features.caseBattery) {
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

        if (this._features.detectConversations) {
            const s2cTime = this._settingsItems['s2c-time'];
            if (this._s2cTime !== s2cTime) {
                this._s2cTime = s2cTime;
                this._setDetectConversationConfig();
            }
        }

        const eqPreset = this._settingsItems['eq-preset'];
        if (this._eqPreset !== eqPreset) {
            this._eqPreset = eqPreset;
            this._setEqPreset();
        }

        if (this._features.stereoPan) {
            const stereoBal = this._settingsItems['stereo-bal'];
            if (this._stereoBal !== stereoBal) {
                this._stereoBal = stereoBal;
                this._setStereoBalance();
            }
        }

        const tpLock = this._settingsItems['tp-enabled'];
        if (this._touchEnabled !== tpLock) {
            this._touchEnabled = tpLock;
            if (this._features.advancedTouchLock || this._features.advancedTouchIsPinch)
                this._setAdvancedTouchConfig();
            else
                this._setTouchpadLock();
        }

        if (this._features.advancedTouchLock) {
            const tpAdvSingle = this._settingsItems['tp-adv-single'];
            if (this._tpAdvSingle !== tpAdvSingle) {
                this._tpAdvSingle = tpAdvSingle;
                this._setAdvancedTouchConfig();
            }

            const tpAdvDouble = this._settingsItems['tp-adv-double'];
            if (this._tpAdvDouble !== tpAdvDouble) {
                this._tpAdvDouble = tpAdvDouble;
                this._setAdvancedTouchConfig();
            }

            const tpAdvTriple = this._settingsItems['tp-adv-triple'];
            if (this._tpAdvTriple !== tpAdvTriple) {
                this._tpAdvTriple = tpAdvTriple;
                this._setAdvancedTouchConfig();
            }

            const tpAdvHold = this._settingsItems['tp-adv-hold'];
            if (this._tpAdvHold !== tpAdvHold) {
                this._tpAdvHold = tpAdvHold;
                this._setAdvancedTouchConfig();
            }
        }

        if (this._features.advancedTouchLockForCalls) {
            const tpAdvCallDouble = this._settingsItems['tp-adv-call-double'];
            if (this._tpAdvCallDouble !== tpAdvCallDouble) {
                this._tpAdvCallDouble = tpAdvCallDouble;
                this._setAdvancedTouchConfig();
            }

            const tpAdvCallHold = this._settingsItems['tp-adv-call-hold'];
            if (this._tpAdvCallHold !== tpAdvCallHold) {
                this._tpAdvCallHold = tpAdvCallHold;
                this._setAdvancedTouchConfig();
            }
        }

        if (this._features.lightingControl) {
            const tpLighting = this._settingsItems['tp-lighting'];
            if (this._tpLighting !== tpLighting) {
                this._tpLighting = tpLighting;
                this._setAdvancedTouchConfig();
            }
        }

        const thLeft = this._settingsItems['th-left'];
        if (this._thLeft !== thLeft) {
            this._thLeft = thLeft;
            this._setTouchAndHold();
        }

        const thRight = this._settingsItems['th-right'];
        if (this._thRight !== thRight) {
            this._thRight = thRight;
            this._setTouchAndHold();
        }

        if (this._features.noiseControl) {
            const ncCycleRight = this._settingsItems['nc-cycle-right'];
            if (this._ncCycleRight !== ncCycleRight) {
                this._ncCycleRight = ncCycleRight;
                this._setNoiseControlConfig();
            }

            if (this._features.noiseControlModeDualSide) {
                const ncCycleLeft = this._settingsItems['nc-cycle-left'];
                if (this._ncCycleLeft !== ncCycleLeft) {
                    this._ncCycleLeft = ncCycleLeft;
                    this._setNoiseControlConfig();
                }
            }
        }

        if (this._features.ambientSidetone) {
            const sidetone = this._settingsItems['sidetone'];
            if (this._sidetone !== sidetone) {
                this._sidetone = sidetone;
                this._setAmbientSidetone();
            }
        }

        if (this._features.noiseControlsWithOneEarbud) {
            const ncOne = this._settingsItems['nc-one'];
            if (this._ncOne !== ncOne) {
                this._ncOne = ncOne;
                this._configureANC();
                this._setNcOneEarbud();
            }
        }

        if (this._features.doubleTapVolume) {
            const twoTapVol = this._settingsItems['2tap-vol'];
            if (this._twoTapVol !== twoTapVol) {
                this._twoTapVol = twoTapVol;
                this._setDoubleTapVolume();
            }
        }

        if (this._features.ambientCustomize) {
            const ambEnable = this._settingsItems['amb-enable'];
            if (this._ambEnable !== ambEnable) {
                this._ambEnable = ambEnable;
                this._setAmbientCustomize();
            }

            const ambLeft = this._settingsItems['amb-left'];
            if (this._ambLeft !== ambLeft) {
                this._ambLeft = ambLeft;
                this._setAmbientCustomize();
            }

            const ambRight = this._settingsItems['amb-right'];
            if (this._ambRight !== ambRight) {
                this._ambRight = ambRight;
                this._setAmbientCustomize();
            }

            const ambTone = this._settingsItems['amb-tone'];
            if (this._ambTone !== ambTone) {
                this._ambTone = ambTone;
                this._setAmbientCustomize();
            }
        }

        const state = this._settingsItems['ring-state'];

        if (this._ringState !== state) {
            this._ringState = state;
            this._setRingMyBuds(state);
        }
    }

    _monitorGalaxyBudsListGsettings(monitor) {
        if (monitor) {
            if (this._settingsHandlerId)
                this._settings?.disconnect(this._settingsHandlerId);

            this._settingsHandlerId = this._settings?.connect('changed::galaxy-buds-list', () =>
                this._updateGsettingsProps());
        } else {
            if (this._settingsHandlerId)
                this._settings?.disconnect(this._settingsHandlerId);
            this._settingsHandlerId = null;
        }
    }

    _updateGsettings() {
        this._monitorGalaxyBudsListGsettings(false);

        const currentList = this._settings.get_strv('galaxy-buds-list').map(JSON.parse);
        const index = currentList.findIndex(d => d.path === this._devicePath);

        if (index !== -1) {
            currentList[index] = this._settingsItems;
            this._settings.set_strv('galaxy-buds-list', currentList.map(JSON.stringify));
        }

        this._monitorGalaxyBudsListGsettings(true);
    }

    _configureANC() {
        if (!this._features.ambientSound && !this._features.noiseCancellation)
            return;

        this._toggle1Enabled = true;

        this._config.toggle1Title = _('Noise Control');

        let showAnc = false;
        if (this._features.noiseCancellation) {
            showAnc = this._features.noiseControlsWithOneEarbud
                ? this._ncOne || this._bothInEars : true;
        }

        let showAdaptive = false;
        if (this._features.adaptiveNoiseControl) {
            showAdaptive = this._features.noiseControlsWithOneEarbud
                ? this._ncOne || this._bothInEars : true;
        }

        const modes = ['off'];

        if (this._features.ambientSound)
            modes.push('transparency');

        if (showAdaptive)
            modes.push('adaptive');

        if (showAnc)
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
            off: GalaxyBudsAnc.Off,
            transparency: GalaxyBudsAnc.AmbientSound,
            adaptive: GalaxyBudsAnc.Adaptive,
            anc: GalaxyBudsAnc.NoiseReduction,
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

        this._featuresAmbientVolume = this._features.ambientSoundVolume &&
            this._features.ambientVolumeMax;

        this._featuresNCVolume = this._features.noiseReductionAdjustments &&
            this._features.noiseReductionLevels;

        if (this._featuresAmbientVolume && this._featuresNCVolume) {
            this._config.optionsBox1 = ['slider'];
            this._config.box1SliderTitle = _('Ambient Level');
            this._config.optionsBox2 = ['slider'];
            this._config.box2SliderTitle = _('Noise Cancellation Level');
        } else if (this._featuresAmbientVolume) {
            if (this._features.ambientVoiceFocus) {
                this._config.optionsBox1 = ['check-button', 'slider'];
                this._config.box1CheckButton = [_('Focus on Voice')];
            } else {
                this._config.optionsBox1 = ['slider'];
            }
            this._config.box1SliderTitle = _('Ambient Level');
        } else if (this._featuresNCVolume) {
            this._config.optionsBox1 = ['slider'];
            this._config.box1SliderTitle = _('Noise Cancellation Level');
        }

        this.dataHandler?.setConfig(this._config);
    }

    _configureDetectConversations() {
        if (!this._features.detectConversations)
            return;

        this._toggle2Enabled = true;
        this._config.toggle2Title = _('Conversation Awareness');
        this._config.toggle2Button1Icon = 'bbm-ca-on-symbolic';
        this._config.toggle2Button1Name = _('On');
        this._config.toggle2Button2Icon = 'bbm-ca-off-symbolic';
        this._config.toggle2Button2Name = _('Off');
    }

    updateExtendedStatusStarted() {
        this._monitorGalaxyBudsListGsettings(false);
    }

    updateExtendedStatusEnded() {
        this._monitorGalaxyBudsListGsettings(true);
        this._updateGsettings();
    }

    _startConfiguration(battInfo) {
        const bat1level = battInfo.battery1Level  ?? 0;
        const bat2level = battInfo.battery2Level  ?? 0;
        const bat3level = battInfo.battery3Level  ?? 0;

        if (bat1level <= 0 && bat2level <= 0 && bat3level <= 0)
            return;

        this._battInfoRecieved = true;

        this._configureMediaController();

        this.dataHandler = new DataHandler(this._config, this._props);

        this.updateDeviceMapCb(this._devicePath, this.dataHandler);

        this._dataHandlerId = this.dataHandler.connect(
            'ui-action', (o, command, value) => {
                if (command === 'toggle1State')
                    this._toggle1ButtonClicked(value);

                if (command === 'toggle2State')
                    this._toggle2ButtonClicked(value);

                if (command === 'box1SliderValue')
                    this._box1SliderValueChanged(value);

                if (command === 'box2SliderValue')
                    this._box2SliderValueChanged(value);

                if (command === 'box1CheckButton1State')
                    this._box1CheckButton1StateChanged(value);

                if (command === 'settingsButtonClicked')
                    this._settingsButtonClicked();
            }
        );
    }

    _configureMediaController() {
        // MediaController not available in daemon context
    }

    updateFirmwareInfo(fwVersion) {
        this._fwVersion = fwVersion;
        if (this._settingsItems) {
            this._settingsItems['fw-version'] = fwVersion;
            this._updateGsettings();
        }
    }

    updateLRSerial(left, right) {
        this._leftSerial = left;
        this._rightSerial = right;
        if (this._settingsItems) {
            this._settingsItems['lsn'] = left;
            this._settingsItems['rsn'] = right;
            this._updateGsettings();
        }
    }

    updateCaseSerial(caseSn) {
        this._caseSerial = caseSn;
        if (this._settingsItems) {
            this._settingsItems['csn'] = caseSn;
            this._updateGsettings();
        }
    }

    updateBatteryProps(props) {
        this._props = {...this._props, ...props};
        if (!this._battInfoRecieved)
            this._startConfiguration(props);

        this._props.computedBatteryLevel = buds2to1BatteryLevel(props);
        this.dataHandler?.setProps(this._props);
    }

    updateInEarState(left, right) {
        let bothInEarChanged = false;
        let budsInEarChanged = false;
        const bothInEars = left === GalaxyBudsEarDetectionState.Wearing &&
            right === GalaxyBudsEarDetectionState.Wearing;

        const budInEar = left === GalaxyBudsEarDetectionState.Wearing ||
            right === GalaxyBudsEarDetectionState.Wearing;

        if (this._bothInEars !== bothInEars) {
            this._bothInEars = bothInEars;
            bothInEarChanged = true;
        }

        if (this._budInEar !== budInEar) {
            this._budInEar = budInEar;
            budsInEarChanged = true;
        }

        if (budsInEarChanged || bothInEarChanged) {
            let toggle1Visible = false;
            if (this._features.noiseControlsWithOneEarbud)
                toggle1Visible = this._budInEar;
            else
                toggle1Visible = this._bothInEars;


            this._props.toggle1Visible = this._toggle1Enabled && toggle1Visible;
            this._props.toggle2Visible = this._toggle2Enabled && this._bothInEars;
            this.dataHandler?.setProps(this._props);

            if (this._features.noiseControlsWithOneEarbud && !this._ncOne && bothInEarChanged)
                this._configureANC();
        }

        if (this._wearDetectionMode !== 0) {
            let playbackMode = null;

            if (this._wearDetectionMode === 1)
                playbackMode = bothInEars ? 'play' : 'pause';
            else if (this._wearDetectionMode === 2)
                playbackMode = budInEar ? 'play' : 'pause';

            if (playbackMode)
                this._mediaController?.changeActivePlayerState(playbackMode);
        }
    }

    _updateOptionBox(mode) {
        if (mode === GalaxyBudsAnc.Off) {
            this._props.optionsBoxVisible = 0;
        } else if (mode === GalaxyBudsAnc.AmbientSound) {
            if (this._featuresAmbientVolume)
                this._props.optionsBoxVisible = 1;
        } else if (mode === GalaxyBudsAnc.NoiseReduction) {
            if (this._featuresNCVolume)
                this._props.optionsBoxVisible = this._featuresAmbientVolume ? 2 : 1;
        } else if (mode === GalaxyBudsAnc.Adaptive) {
            this._props.optionsBoxVisible = 0;
        }
    }

    updateNCModes(mode) {
        this._ancMode = mode;

        let index = this._toggle1ButtonToAncMode?.findIndex(v => v === mode);

        if (index < 0)
            index = 0;

        this._props.toggle1State = index;
        this._updateOptionBox(mode);
        this.dataHandler?.setProps(this._props);
    }

    _toggle1ButtonClicked(index) {
        const ancMode = this._toggle1ButtonToAncMode?.[index];
        if (ancMode == null)
            return;

        this._updateOptionBox(ancMode);

        this._props.toggle1State = index;
        this.dataHandler?.setProps(this._props);

        if (this._features.noiseControl)
            this._galaxyBudsSocket.setNCModes(ancMode);
        else if (this._features.ambientSound)
            this._galaxyBudsSocket.setAmbientSoundOnOff(ancMode);
        else if (this._features.noiseCancellation)
            this._galaxyBudsSocket.setNCOnOff(ancMode);
    }

    updateFocusOnVoice(enabled) {
        if (!this._features.ambientVoiceFocus)
            return;

        if (this._focusOnVoice !== enabled) {
            this._focusOnVoice = enabled;
            const value = enabled ? 1 : 0;
            this._props.box1CheckButton1State = value;
            this.dataHandler?.setProps(this._props);
        }
    }

    _box1CheckButton1StateChanged(value) {
        if (!this._features.ambientVoiceFocus)
            return;

        const enabled = value === 1;

        if (this._focusOnVoice !== enabled) {
            this._focusOnVoice = enabled;
            this._galaxyBudsSocket.setFocusOnVoice(enabled);
        };
    }

    updateAmbientVolume(level) {
        if (!this._featuresAmbientVolume)
            return;

        if (this._ambientLevel !== level) {
            this._ambientLevel = level;
            const maxVolume = this._features.ambientVolumeMax;
            this._props.box1SliderValue = Math.round(level * 100 / maxVolume);
            this.dataHandler?.setProps(this._props);
        }
    }

    updateNoiseReductionLevel(level) {
        if (!this._featuresNCVolume)
            return;

        if (this._ncLevel !== level) {
            this._ncLevel = level;
            const maxVolume = this._features.noiseReductionLevels;
            const value = Math.round(level * 100 / maxVolume);
            if (this._featuresAmbientVolume)
                this._props.box2SliderValue = value;
            else
                this._props.box1SliderValue = value;
            this.dataHandler?.setProps(this._props);
        }
    }

    _box1SliderValueChanged(value) {
        if (this._featuresAmbientVolume) {
            const maxVolume = this._features.ambientVolumeMax;
            const level = Math.round(value * maxVolume / 100);
            if (this._ambientLevel !== level) {
                this._ambientLevel = level;
                this._galaxyBudsSocket.setAmbientVolume(level);
            }
        } else if (this._featuresNCVolume) {
            const maxVolume = this._features.noiseReductionLevels;
            const level = Math.round(value * maxVolume / 100);
            if (this._ncLevel !== level) {
                this._ncLevel = level;
                this._galaxyBudsSocket.setNoiseCancellationLevel(level);
            }
        }
    }

    _box2SliderValueChanged(value) {
        if (this._featuresNCVolume && this._featuresAmbientVolume) {
            const maxVolume = this._features.noiseReductionLevels;
            const level = Math.round(value * maxVolume / 100);
            if (this._ncLevel !== level) {
                this._ncLevel = level;
                this._galaxyBudsSocket.setNoiseCancellationLevel(level);
            }
        }
    }

    updateDetectConversations(enabled) {
        if (!this._features.detectConversations)
            return;

        if (this._s2cenable !== enabled) {
            this._s2cenable = enabled;
            this._props.toggle1State = enabled ? 1 : 2;
            this.dataHandler?.setProps(this._props);
        }
    }

    _toggle2ButtonClicked(value) {
        if (!this._features.detectConversations)
            return;

        const enabled = value === 1;
        if (this._s2cenable !== enabled) {
            this._s2cenable = enabled;
            this._galaxyBudsSocket.setDetectConversations(enabled);
        }
        this._props.toggle2State = value;
        this.dataHandler?.setProps(this._props);
    }

    updateDetectConversationsDuration(duration) {
        if (!this._features.detectConversations)
            return;

        if (this._s2cTime !== duration) {
            this._s2cTime = duration;
            this._settingsItems['s2c-time'] = duration;
            this._updateGsettings();
        }
    }

    _setDetectConversationConfig() {
        if (!this._features.detectConversations)
            return;

        this._galaxyBudsSocket.setDetectConversationsDuration(this._s2cTime);
    }

    updateEqPresets(presetCode) {
        if (this._eqPreset !== presetCode) {
            this._eqPreset = presetCode;
            this._settingsItems['eq-preset'] = presetCode;
            this._updateGsettings();
        }
    }

    _setEqPreset() {
        this._galaxyBudsSocket.setEqPresets(this._eqPreset);
    }

    updateStereoBal(level) {
        if (!this._features.stereoPan)
            return;

        if (this._stereoBal !== level) {
            this._stereoBal = level;
            this._settingsItems['stereo-bal'] = level;
            this._updateGsettings();
        }
    }

    _setStereoBalance() {
        if (!this._features.stereoPan)
            return;

        this._galaxyBudsSocket.setStereoBalance(this._stereoBal);
    }

    updateTouchpadLock(lockEnabled) {
        const touchEnabled = !lockEnabled;
        if (this._touchEnabled !== touchEnabled) {
            this._touchEnabled = touchEnabled;
            this._settingsItems['tp-enabled'] = touchEnabled;
            this._updateGsettings();
        }
    }

    _setTouchpadLock() {
        const lockEnabled = !this._touchEnabled;
        this._galaxyBudsSocket.setTouchPadLock(lockEnabled);
    }

    updateAdvanceTouchpadLock(touchProps) {
        if (!this._features.advancedTouchLock && !this._features.advancedTouchIsPinch)
            return;

        let update = false;

        if (this._features.advancedTouchLock) {
            const touchEnabled = !touchProps.touchpadLock;
            const single = touchProps.singleTapOn;
            const dbl = touchProps.doubleTapOn;
            const triple = touchProps.tripleTapOn;
            const hold = touchProps.touchHoldOn;

            if (this._touchEnabled !== touchEnabled) {
                this._touchEnabled = touchEnabled;
                this._settingsItems['tp-enabled'] = touchEnabled;
                update = true;
            }

            if (this._tpAdvSingle !== single) {
                this._tpAdvSingle = single;
                this._settingsItems['tp-adv-single'] = single;
                update = true;
            }

            if (this._tpAdvDouble !== dbl) {
                this._tpAdvDouble = dbl;
                this._settingsItems['tp-adv-double'] = dbl;
                update = true;
            }

            if (this._tpAdvTriple !== triple) {
                this._tpAdvTriple = triple;
                this._settingsItems['tp-adv-triple'] = triple;
                update = true;
            }

            if (this._tpAdvHold !== hold) {
                this._tpAdvHold = hold;
                this._settingsItems['tp-adv-hold'] = hold;
                update = true;
            }
        } else {
            const single = touchProps.singleTapOn;
            const dbl = touchProps.doubleTapOn;
            const triple = touchProps.tripleTapOn;

            const mediaEnabled = single && dbl && triple;
            if (this._touchEnabled !== mediaEnabled) {
                this._touchEnabled = mediaEnabled;
                this._settingsItems['tp-enabled'] = mediaEnabled;
                update = true;
            }
        }

        if (this._features.advancedTouchLockForCalls) {
            const callDouble = touchProps.doubleTapForCallOn;
            const callHold = touchProps.touchHoldOnForCallOff;

            if (this._tpAdvCallDouble !== callDouble) {
                this._tpAdvCallDouble = callDouble;
                this._settingsItems['tp-adv-call-double'] = callDouble;
                update = true;
            }

            if (this._tpAdvCallHold !== callHold) {
                this._tpAdvCallHold = callHold;
                this._settingsItems['tp-adv-call-hold'] = callHold;
                update = true;
            }
        }

        if (this._features.lightingControl && touchProps.lightingMode) {
            const lighting = touchProps.lightingMode;

            if (this._tpLighting !== lighting) {
                this._tpLighting = lighting;
                this._settingsItems['tp-lighting'] = lighting;
                update = true;
            }
        }

        if (update)
            this._updateGsettings();
    }

    updateLightingMode(lighting) {
        if (this._features.lightingControl) {
            if (this._tpLighting !== lighting) {
                this._tpLighting = lighting;
                this._settingsItems['tp-lighting'] = lighting;
            }
        }
    }

    _setAdvancedTouchConfig() {
        if (!this._features.advancedTouchLock && !this._features.advancedTouchIsPinch)
            return;

        const props = {};
        if (this._features.advancedTouchLock) {
            props.touchpadLock = !this._touchEnabled;
            props.singleTapOn = this._tpAdvSingle;
            props.doubleTapOn = this._tpAdvDouble;
            props.tripleTapOn = this._tpAdvTriple;
            props.touchHoldOn = this._tpAdvHold;
        } else {
            props.touchpadLock = true;
            props.singleTapOn = this._touchEnabled;
            props.doubleTapOn = this._touchEnabled;
            props.tripleTapOn = this._touchEnabled;
            props.touchHoldOn = true;
        }

        if (this._features.advancedTouchLockForCalls) {
            props.doubleTapForCallOn = this._tpAdvCallDouble;
            props.touchHoldOnForCallOff = this._tpAdvCallHold;
        }

        if (this._features.lightingControl)
            props.lightingMode = this._tpLighting;

        this._galaxyBudsSocket.setTouchPadAdvance(props);
    }

    updateTouchpadOptionL(leftMode) {
        if (!this._features.touchAndHold)
            return;

        if (this._thLeft !== leftMode) {
            this._thLeft = leftMode;
            this._settingsItems['th-left'] = leftMode;
            this._updateGsettings();
        }
    }

    updateTouchpadOptionR(rightMode) {
        if (!this._features.touchAndHold)
            return;

        if (this._thRight !== rightMode) {
            this._thRight = rightMode;
            this._settingsItems['th-right'] = rightMode;
            this._updateGsettings();
        }
    }

    _setTouchAndHold() {
        const props = {left: this._thLeft, right: this._thRight};
        this._galaxyBudsSocket.setTouchAndHoldLRModes(props);
    }

    updateNoiseControlCycle(props) {
        if (!this._features.noiseControl)
            return;

        const rightVal =
        (props.off ? 1 : 0) << 0 |
        (props.ambient ? 1 : 0) << 1 |
        (props.anc ? 1 : 0) << 2 |
        (this._features.adaptiveNoiseControl ? (props.adaptive ? 1 : 0) << 3 : 0);

        const leftVal =
        !this._features.noiseControlModeDualSide ? rightVal
            : (props.leftOff ? 1 : 0) << 0 |
             (props.leftAmbient ? 1 : 0) << 1 |
             (props.leftAnc ? 1 : 0) << 2 |
             (this._features.adaptiveNoiseControl ? (props.leftAdaptive ? 1 : 0) << 3 : 0);

        let update = false;

        if (this._ncCycleRight !== rightVal) {
            this._ncCycleRight = rightVal;
            this._settingsItems['nc-cycle-right'] = rightVal;
            update = true;
        }

        if (this._ncCycleLeft !== leftVal) {
            this._ncCycleLeft = leftVal;
            this._settingsItems['nc-cycle-left'] = leftVal;
            update = true;
        }

        if (update)
            this._updateGsettings();
    }


    _setNoiseControlConfig() {
        if (!this._features.noiseControl)
            return;

        const right = this._ncCycleRight;
        const left = this._features.noiseControlModeDualSide ? this._ncCycleLeft : null;

        const payload = {right, left};

        if (this._features.noiseTouchAndHoldNewVersion)
            this._galaxyBudsSocket.setNcCycle(payload);
        else
            this._galaxyBudsSocket.setNcCycleLegacy(payload);
    }


    updateSideToneEnabled(level) {
        if (!this._features.ambientSidetone)
            return;

        if (this._sidetone !== level) {
            this._sidetone = level;
            this._settingsItems['sidetone'] = level;
            this._updateGsettings();
        }
    }

    _setAmbientSidetone() {
        if (!this._features.ambientSidetone)
            return;

        this._galaxyBudsSocket.setSideTone(this._sidetone);
    }

    updateNoiseControlsWithOneEarbud(enabled) {
        if (!this._features.noiseControlsWithOneEarbud)
            return;

        if (this._ncOne !== enabled) {
            this._ncOne = enabled;
            this._settingsItems['nc-one'] = enabled;
            this._updateGsettings();
        }
    }

    _setNcOneEarbud() {
        if (!this._features.noiseControlsWithOneEarbud)
            return;

        this._galaxyBudsSocket.setNoiseControlsWithOneEarbud(!!this._ncOne);
    }



    updateOutsideDoubleTap(enabled) {
        if (!this._features.doubleTapVolume)
            return;

        if (this._twoTapVol !== enabled) {
            this._twoTapVol = enabled;
            this._settingsItems['2tap-vol'] = enabled;
            this._updateGsettings();
        }
    }

    _setDoubleTapVolume() {
        if (!this._features.doubleTapVolume)
            return;

        this._galaxyBudsSocket.setOutsideDoubleTap(!!this._twoTapVol);
    }

    updateAmbientCustomization(props) {
        if (!this._features.ambientCustomize)
            return;

        let update = false;

        if (this._ambEnable !== props.enable) {
            this._ambEnable = props.enable;
            this._settingsItems['amb-enable'] = props.enable;
            update = true;
        }

        if (this._ambLeft !== props.leftVolume) {
            this._ambLeft = props.leftVolume;
            this._settingsItems['amb-left'] = props.leftVolume;
            update = true;
        }

        if (this._ambRight !== props.rightVolume) {
            this._ambRight = props.rightVolume;
            this._settingsItems['amb-right'] = props.rightVolume;
            update = true;
        }

        if (this._ambTone !== props.soundtone) {
            this._ambTone = props.soundtone;
            this._settingsItems['amb-tone'] = props.soundtone;
            update = true;
        }

        if (update)
            this._updateGsettings();
    }

    _setAmbientCustomize() {
        if (!this._features.ambientCustomize)
            return;

        const props = {
            enable: this._ambEnable,
            leftVolume: this._ambLeft,
            rightVolume: this._ambRight,
            soundtone: this._ambTone,
        };

        this._galaxyBudsSocket.setCustomizeAmbientSound(props);
    }

    _setRingMyBuds(state) {
        this._galaxyBudsSocket?.setRingMyBuds(state);
    }

    _settingsButtonClicked() {
        this._configureWindowLauncherCancellable = new Gio.Cancellable();
        launchConfigureWindow(this._devicePath, 'galaxyBuds', this._extPath,
            this._configureWindowLauncherCancellable);
        this._configureWindowLauncherCancellable = null;
    }

    destroy() {
        this._galaxyBudsSocket?.destroy();
        this._galaxyBudsSocket = null;
        this._bluezDeviceProxy = null;
        if (this._dataHandlerId)
            this.dataHandler?.disconnect(this._dataHandlerId);
        this._dataHandlerId = null;
        this.dataHandler = null;
        if (this._settingsHandlerId)
            this._settings?.disconnect(this._settingsHandlerId);
        this._settingsHandlerId = null;
        this._mediaController?.destroy();
        this._mediaController = null;
        this._settings = null;
        this._battInfoRecieved = false;
    }
});


