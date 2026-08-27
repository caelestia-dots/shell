'use strict';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';
const _ = s => s; // gettext stub for daemon context

import {createLogger, getDeviceIdentifier} from '../logger.js';
import {getBluezDeviceProxy} from '../../bluezDeviceProxy.js';
import {
    buds2to1BatteryLevel, validateProperties, launchConfigureWindow, isArrayEqual
} from '../deviceUtils.js';
import {createConfig, createProperties, DataHandler} from '../../dataHandler.js';
import {SonySocketV1} from './sonySocketV1.js';
import {SonySocketV2} from './sonySocketV2.js';
import {
    SonyConfiguration, AmbientSoundMode, AutoAsmSensitivity, ListeningMode,
    AudioCodec, DseeType
} from './sonyConfig.js';
import {BtDeviceState, DeviceManagementAction} from '../commonEmuns.js';

const SonyUUIDv1 = '96cc203e-5068-46ad-b32d-e316f5e069ba';
const SonyUUIDv2 = '956c7b26-d49a-4ba8-b03f-b17d393cb6e2';
export const DeviceTypeSonyV1 = 'sonyV1';
export const DeviceTypeSonyV2 = 'sonyV2';

function isSony(bluezDeviceProxy, uuids, uuid) {
    const bluezProps = ['Modalias'];
    let supported = 'no';

    if (!uuids.includes(uuid))
        return {supported, bluezProps};

    const modalias = bluezDeviceProxy.Modalias;
    if (!modalias) {
        supported = 'pending';
        return {supported, bluezProps};
    }

    const name = bluezDeviceProxy.Name;

    const isCompatible = SonyConfiguration.some(model =>
        model.modaliasPrefix && modalias.includes(model.modaliasPrefix) ||
        model.pattern && model.pattern.test(name)
    );
    if (isCompatible)
        supported = 'yes';

    return {supported, bluezProps};
}

export function isSonyV1(bluezDeviceProxy, uuids) {
    return isSony(bluezDeviceProxy, uuids, SonyUUIDv1);
}

export function isSonyV2(bluezDeviceProxy, uuids) {
    return isSony(bluezDeviceProxy, uuids, SonyUUIDv2);
}

export const SonyDevice = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_SonyDevice',
}, class SonyDevice extends GObject.Object {
    _init(settings, devicePath, alias, extPath, profileManager, updateDeviceMapCb) {
        super._init();
        const identifier = getDeviceIdentifier(devicePath);
        const tag = `SonyDevice-${identifier}`;
        this._log = createLogger(tag);
        this._log.info('------------------- SonyDevice init -------------------');
        this._settings = settings;
        this._devicePath = devicePath;
        this._alias = alias;
        this._extPath = extPath;
        this._profileManager = profileManager;
        this.updateDeviceMapCb = updateDeviceMapCb;
        this._usesProtocolV2 = false;
        this._ignoreGsettingsChange = false;
        this._deviceInfo = [];
        this._pendingBTOperations = new Map();

        this._initialize(profileManager);
    }

    _initialize(profileManager) {
        this._bluezDeviceProxy = getBluezDeviceProxy(this._devicePath);
        const uuids = this._bluezDeviceProxy.UUIDs;
        const name = this._bluezDeviceProxy.Name;
        const modalias = this._bluezDeviceProxy.Modalias;

        if (uuids.includes(SonyUUIDv2))
            this._usesProtocolV2 = true;

        const modelData = SonyConfiguration.find(model =>
            model.modaliasPrefix && modalias.includes(model.modaliasPrefix) ||
            model.pattern && model.pattern.test(name)
        );

        if (!modelData)
            return;

        this._log.info(`Configuration: ${JSON.stringify(modelData, null, 2)}`);

        this._config = createConfig();
        this._props = createProperties();
        this._ambientMode = AmbientSoundMode.ANC_OFF;
        this._focusOnVoiceState = false;
        this._ambientLevel = 10;
        this._naMode = true;
        this._naSensitivity = AutoAsmSensitivity.STANDARD;

        this._callbacks = {
            updateFirmwareVersion: this.updateFirmwareVersion.bind(this),
            updateCapabilities: this.updateCapabilities.bind(this),
            updateBatteryProps: this.updateBatteryProps.bind(this),
            updateCodecIndicator: this.updateCodecIndicator.bind(this),
            updateUpscalingIndicator: this.updateUpscalingIndicator.bind(this),
            updateAmbientSoundControl: this.updateAmbientSoundControl.bind(this),
            updateSpeakToChatEnable: this.updateSpeakToChatEnable.bind(this),
            updateSpeakToChatConfig: this.updateSpeakToChatConfig.bind(this),
            updateEqualizer: this.updateEqualizer.bind(this),
            updateBgmMode: this.updateBgmMode.bind(this),
            updateCinemaMode: this.updateCinemaMode.bind(this),
            updateAudioSampling: this.updateAudioSampling.bind(this),
            updateButtonModesLeftRight: this.updateButtonModesLeftRight.bind(this),
            updateAmbientSoundButton: this.updateAmbientSoundButton.bind(this),
            updateVoiceNotifications: this.updateVoiceNotifications.bind(this),
            updateVoiceNotificationsVolume: this.updateVoiceNotificationsVolume.bind(this),
            updatePauseWhenTakenOff: this.updatePauseWhenTakenOff.bind(this),
            updateAutomaticPowerOff: this.updateAutomaticPowerOff.bind(this),
            updatePairingMode: this.updatePairingMode.bind(this),
            updateDeviceList: this.updateDeviceList.bind(this),
            updatePlaybackDevice: this.updatePlaybackDevice.bind(this),
            updateDeviceActionStatus: this.updateDeviceActionStatus.bind(this),
            updateSourceSwitchFixed: this.updateSourceSwitchFixed.bind(this),
        };

        this._batteryDualSupported = modelData.batteryDual ?? false;
        this._batteryCaseSupported = modelData.batteryCase ?? false;
        this._batterySingleSupported = modelData.batterySingle ?? false;

        this._noNoiseCancellingSupported = modelData.noNoiseCancelling ?? false;
        this._ambientSoundControlSupported = modelData.ambientSoundControl ?? false;
        this._windNoiseReductionSupported = modelData.windNoiseReduction ?? false;
        this._ambientSoundControlNASupported = modelData.ambientSoundControlNA ?? false;

        this._speakToChatEnabledSupported = modelData.speakToChatEnabled ?? false;
        this._speakToChatConfigSupported = modelData.speakToChatConfig ?? false;

        this._equalizerSixBandsSupported = modelData.equalizerSixBands ?? false;
        this._equalizerTenBandsSupported = modelData.equalizerTenBands ?? false;
        this._listeningModeSupported = modelData.listeningMode ?? false;
        this._audioUpsamplingSupported = modelData.audioUpsampling ?? false;

        this._buttonModesLeftRight = modelData.buttonModesLeftRight ?? false;
        this._ambientSoundControlButtonMode = modelData.ambientSoundControlButtonMode ?? false;

        this._voiceNotificationsSupported = modelData.voiceNotifications ?? false;
        this._voiceNotificationsVolumeSupported = modelData.voiceNotificationsVolume ?? false;

        this._pauseWhenTakenOffSupported = modelData.pauseWhenTakenOff ?? false;
        this._automaticPowerOffWhenTakenOffSupported =
            modelData.automaticPowerOffWhenTakenOff ?? false;

        this._automaticPowerOffByTimeSupported =
            modelData.automaticPowerOffByTime ?? false;

        this._dualConnection = modelData.dualConnection ?? false;
        this._hasRoutingIndicator = modelData.dualConnection?.hasRoutingIndicator ?? false;
        this._hasRoutingControl = modelData.dualConnection?.hasRoutingControl ?? false;
        this._hasActiveFix = modelData.dualConnection?.hasActiveFix ?? false;

        this._config.commonIcon = modelData.budsIcon;
        this._config.albumArtIcon = modelData.albumArtIcon;
        this._config.showSettingsButton = true;

        this._commonIcon = modelData.budsIcon;

        if (this._batteryCaseSupported)
            this._caseIcon = `${modelData.case}`;

        if (this._ambientSoundControlSupported) {
            this._config.toggle1Title = _('Noise Control');
            this._config.toggle1Button1Icon = 'bbm-anc-off-symbolic';
            this._config.toggle1Button1Name = _('Off');
            this._config.toggle1Button2Icon = 'bbm-transperancy-symbolic';
            this._config.toggle1Button2Name = _('Ambient');
            if (!this._noNoiseCancellingSupported) {
                this._config.toggle1Button3Icon = 'bbm-anc-on-symbolic';
                this._config.toggle1Button3Name = _('Noise Cancellation');
            }
            this._config.optionsBox1 = ['check-button', 'slider'];
            this._config.box1SliderTitle = _('Ambient Level');

            if (this._ambientSoundControlNASupported) {
                this._config.box1CheckButton = [_('Auto Ambient'), _('Focus on Voice')];
                this._config.optionsBox2 = ['check-button', 'radio-button'];
                this._config.box2CheckButton = [_('Auto Ambient'), _('Focus on Voice')];
                this._config.box2RadioTitle = _('Auto Ambient Sensitivity');
                this._config.box2RadioButton = [_('Standard'), _('High'), _('Low')];
            } else {
                this._config.box1CheckButton = [_('Focus on Voice')];
            }

            /*
            if (this._windNoiseReductionSupported) {
                this._config.optionsBox3 = ['check-button'];
                this._config.box3CheckButton = [_('Wind Noise Reduction')];
            }
*/
        }

        if (this._speakToChatEnabledSupported) {
            this._config.toggle2Title = _('Conversation Awareness');
            this._config.toggle2Button1Icon = 'bbm-ca-on-symbolic';
            this._config.toggle2Button1Name = _('On');
            this._config.toggle2Button2Icon = 'bbm-ca-off-symbolic';
            this._config.toggle2Button2Name = _('Off');
        }

        const bandCount = this._equalizerTenBandsSupported ? 10 : 6;
        const initialCustomEqValues = Array(bandCount).fill(0);

        this._createDefaultSettings(modelData.name, initialCustomEqValues);

        const devicesList = this._settings.get_strv('sony-list').map(JSON.parse);

        if (devicesList.length === 0 ||
                !devicesList.some(device => device.path === this._devicePath)) {
            this._addPropsToSettings(devicesList);
        } else {
            validateProperties(this._settings, 'sony-list', devicesList,
                this._defaultsDeviceSettings, this._devicePath);
        }

        this._updateInitialValues();
        this._monitorSonyListGsettings();
        this._updateIcons();

        const type = this._usesProtocolV2 ? DeviceTypeSonyV2 : DeviceTypeSonyV1;
        const uuid = this._usesProtocolV2 ? SonyUUIDv2 : SonyUUIDv1;
        const SocketClass = this._usesProtocolV2 ? SonySocketV2 : SonySocketV1;
        const profile = {type, uuid};

        this._sonySocket = new SocketClass(
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

        this._config.battery1ShowOnDisconnect = true;
        if (this._batteryDualSupported) {
            this._config.battery2ShowOnDisconnect = true;
            this._config.battery1Icon = `${this._commonIcon}-left`;
            this._config.battery2Icon = `${this._commonIcon}-right`;
        } else {
            this._config.battery1Icon = this._commonIcon;
        }

        if (this._batteryCaseSupported)
            this._config.battery3Icon = this._caseIcon;

        this.dataHandler?.setConfig(this._config);
    }

    _createDefaultSettings(name, initialCustomEqValues) {
        this._defaultsDeviceSettings = {
            path: this._devicePath,
            name,
            alias: this._alias,
            icon: this._commonIcon,
            'fw-version': '',

            ...this._batteryCaseSupported && {
                'case': this._caseIcon,
            },

            ...this._speakToChatConfigSupported && {
                's2c-sensitivity': 0,
                's2c-duration': 0,
            },

            ...this._listeningModeSupported && {
                'bgm-mode': 1,
                'bgm-distance': 0,
            },

            ...(this._equalizerSixBandsSupported || this._equalizerTenBandsSupported) && {
                'eq-preset': 0,
                'eq-custom': initialCustomEqValues,
            },

            ...this._audioUpsamplingSupported && {
                'dsee': 0,
            },

            ...this._buttonModesLeftRight && {
                'btn-left': 0,
                'btn-right': 0,
            },

            ...this._ambientSoundControlButtonMode && {
                'amb-btn-mode': 1,
            },

            ...this._voiceNotificationsSupported && {
                'voice-noti': true,
            },

            ...this._voiceNotificationsVolumeSupported && {
                'voice-vol': 0,
            },

            ...this._pauseWhenTakenOffSupported && {
                'pause-takeoff': true,
            },

            ...this._automaticPowerOffWhenTakenOffSupported && {
                'auto-power': true,
            },

            ...this._automaticPowerOffByTimeSupported && {
                'auto-power-time': 0,
            },

            ...this._dualConnection && {
                'dev-mgmt': [],
                'pairing-mode': false,
                'dev-mgmt-action': {seq: 0, action: 0, id: ''},
            },

            ...(this._hasRoutingIndicator || this._hasRoutingControl) && {
                'active-dev': '',
            },

            ...this._hasActiveFix && {
                'active-fix': false,
            },
        };
    }

    _addPropsToSettings(devicesList) {
        devicesList.push(this._defaultsDeviceSettings);
        this._settings.set_strv('sony-list', devicesList.map(JSON.stringify));
    }

    _updateInitialValues() {
        const devicesList = this._settings.get_strv('sony-list').map(JSON.parse);
        const existingPathIndex = devicesList.findIndex(item => item.path === this._devicePath);
        if (existingPathIndex === -1)
            return;

        this._settingsItems = devicesList[existingPathIndex];

        this._commonIcon = this._settingsItems['icon'];

        if (this._batteryCaseSupported)
            this._caseIcon = this._settingsItems['case'];

        if (this._speakToChatConfigSupported) {
            this._speak2ChatSensitivity = this._settingsItems['s2c-sensitivity'];
            this._speak2ChatTimeout = this._settingsItems['s2c-duration'];
        }

        if (this._listeningModeSupported) {
            this._bgmMode = this._settingsItems['bgm-mode'];
            this._bgmDistance = this._settingsItems['bgm-distance'];
        }

        if (this._equalizerSixBandsSupported || this._equalizerTenBandsSupported) {
            this._eqPreset = this._settingsItems['eq-preset'];
            this._eqCustom = this._settingsItems['eq-custom'];
        }

        if (this._audioUpsamplingSupported)
            this._audioUpsampling = this._settingsItems['dsee'];


        if (this._buttonModesLeftRight) {
            this._btnLeft = this._settingsItems['btn-left'];
            this._btnRight = this._settingsItems['btn-right'];
        }

        if (this._ambientSoundControlButtonMode)
            this._ambientButtonMode = this._settingsItems['amb-btn-mode'];


        if (this._voiceNotificationsSupported)
            this._voiceNoti = this._settingsItems['voice-noti'];


        if (this._voiceNotificationsVolumeSupported)
            this._voiceVolume = this._settingsItems['voice-vol'];


        if (this._pauseWhenTakenOffSupported)
            this._pauseWhenTakenOff = this._settingsItems['pause-takeoff'];


        if (this._automaticPowerOffWhenTakenOffSupported)
            this._autoPowerOff = this._settingsItems['auto-power'];


        if (this._automaticPowerOffByTimeSupported)
            this._autoPowerOffTime = this._settingsItems['auto-power-time'];

        if (this._dualConnection) {
            this._pairingMode = this._settingsItems['pairing-mode'];
            this._devMgmtAction = this._settingsItems['dev-mgmt-action'];

            if (this._hasRoutingIndicator || this._hasRoutingControl) {
                this._activeDevice = this._settingsItems['active-dev'];
                if (this._hasActiveFix)
                    this._activeDeviceFixed = this._settingsItems['active-fix'];
            }
        }
    }

    _updateGsettingsProps() {
        const devicesList = this._settings.get_strv('sony-list').map(JSON.parse);
        const existingPathIndex = devicesList.findIndex(item => item.path === this._devicePath);
        if (existingPathIndex === -1)
            return;

        this._settingsItems = devicesList[existingPathIndex];

        const icon = this._settingsItems['icon'];
        if (this._commonIcon !== icon) {
            this._commonIcon = icon;
            this._updateIcons();
        }

        if (this._batteryCaseSupported) {
            const caseIcon = this._settingsItems['case'];
            if (this._caseIcon !== caseIcon) {
                this._caseIcon = caseIcon;
                this._updateIcons();
            }
        }

        if (this._speakToChatConfigSupported) {
            const sensitivity = this._settingsItems['s2c-sensitivity'];
            if (this._speak2ChatSensitivity !== sensitivity) {
                this._speak2ChatSensitivity = sensitivity;
                this._setSpeakToChatConfig();
            }
        }

        if (this._speakToChatConfigSupported) {
            const timeout = this._settingsItems['s2c-duration'];
            if (this._speak2ChatTimeout !== timeout) {
                this._speak2ChatTimeout = timeout;
                this._setSpeakToChatConfig();
            }
        }

        if (this._listeningModeSupported) {
            const bgmMode = this._settingsItems['bgm-mode'];
            if (this._bgmMode !== bgmMode) {
                this._bgmMode = bgmMode;
                this._setBgmMode();
            }

            const bgmDistance = this._settingsItems['bgm-distance'];
            if (this._bgmDistance !== bgmDistance) {
                this._bgmDistance = bgmDistance;
                this._setBgmMode();
            }
        }

        if (this._equalizerSixBandsSupported || this._equalizerTenBandsSupported) {
            const preset = this._settingsItems['eq-preset'];
            if (this._eqPreset !== preset) {
                this._eqPreset = preset;
                this._setEqualizerPreset();
            }

            const customBands = this._settingsItems['eq-custom'];
            if (!this._eqCustom || !isArrayEqual(customBands, this._eqCustom)) {
                this._eqCustom = customBands;
                this._setEqualizerCustomBands();
            }
        }

        if (this._audioUpsamplingSupported) {
            const dsee = this._settingsItems['dsee'];
            if (this._audioUpsampling !== dsee) {
                this._audioUpsampling = dsee;
                this._setAudioUpsampling();
            }
        }

        if (this._buttonModesLeftRight) {
            const btnLeft = this._settingsItems['btn-left'];
            const btnRight = this._settingsItems['btn-right'];
            if (this._btnLeft !== btnLeft || this._btnRight !== btnRight) {
                this._btnLeft = btnLeft;
                this._btnRight = btnRight;
                this._setButtonModes();
            }
        }

        if (this._ambientSoundControlButtonMode) {
            const ambBtnMode = this._settingsItems['amb-btn-mode'];
            if (this._ambientButtonMode !== ambBtnMode) {
                this._ambientButtonMode = ambBtnMode;
                this._setAmbientButtonMode();
            }
        }

        if (this._voiceNotificationsSupported) {
            const noti = this._settingsItems['voice-noti'];
            if (this._voiceNoti !== noti) {
                this._voiceNoti = noti;
                this._setVoiceNotifications();
            }
        }

        if (this._voiceNotificationsVolumeSupported) {
            const notiVol = this._settingsItems['voice-vol'];
            if (this._voiceVolume !== notiVol) {
                this._voiceVolume = notiVol;
                this._setVoiceNotificationsVolume();
            }
        }


        if (this._pauseWhenTakenOffSupported) {
            const pause = this._settingsItems['pause-takeoff'];
            if (this._pauseWhenTakenOff !== pause) {
                this._pauseWhenTakenOff = pause;
                this._setPauseWhenTakenOff();
            }
        }

        if (this._automaticPowerOffWhenTakenOffSupported) {
            const autoPower = this._settingsItems['auto-power'];
            if (this._autoPowerOff !== autoPower) {
                this._autoPowerOff = autoPower;
                this._setAutoPowerOff();
            }
        }

        if (this._automaticPowerOffByTimeSupported) {
            const autoPowerTime = this._settingsItems['auto-power-time'];
            if (this._autoPowerOffTime !== autoPowerTime) {
                this._autoPowerOffTime = autoPowerTime;
                this._setAutoPowerOff();
            }
        }

        if (this._dualConnection) {
            const pairingMode = this._settingsItems['pairing-mode'];
            if (this._pairingMode !== pairingMode) {
                this._pairingMode = pairingMode;
                this._setPairingMode(pairingMode);
            }

            if (this._hasActiveFix) {
                const activeFixed = this._settingsItems['active-fix'];
                if (this._activeDeviceFixed !== activeFixed) {
                    this._activeDeviceFixed = activeFixed;
                    this._setSourceSwitchFixed(activeFixed);
                }
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
                        if (this._hasRoutingControl)
                            this._setRoutingBTDevice(devMgmtAction.id);
                        break;
                }
            }
        }
    }

    _monitorSonyListGsettings() {
        this._settingsHandlerId = this._settings?.connect('changed::sony-list', () => {
            if (this._ignoreGsettingsChange)
                return;

            this._updateGsettingsProps();
        });
    }

    _updateGsettings() {
        this._ignoreGsettingsChange = true;

        const currentList = this._settings.get_strv('sony-list').map(JSON.parse);
        const index = currentList.findIndex(d => d.path === this._devicePath);

        if (index !== -1) {
            currentList[index] = this._settingsItems;
            this._settings.set_strv('sony-list', currentList.map(JSON.stringify));
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

        this.dataHandler = new DataHandler(this._config, this._props);

        this.updateDeviceMapCb(this._devicePath, this.dataHandler);

        this._props.toggle1Visible = this._ambientSoundControlSupported;
        this._props.toggle2Visible = this._speakToChatEnabledSupported;

        this._dataHandlerId = this.dataHandler.connect(
            'ui-action', (o, command, value) => {
                if (command === 'toggle1State')
                    this._toggle1ButtonClicked(value);

                if (command === 'toggle2State')
                    this._toggle2ButtonClicked(value);

                if (command === 'box1SliderValue')
                    this._box1SliderValueChanged(value);

                if (command === 'box1CheckButton1State')
                    this._box1CheckButton1StateChanged(value);

                if (command === 'box2CheckButton1State')
                    this._box2CheckButton1StateChanged(value);

                if (command === 'box1CheckButton2State')
                    this._box1CheckButton2StateChanged(value);

                if (command === 'box2CheckButton2State')
                    this._box2CheckButton2StateChanged(value);

                if (command === 'box2RadioButtonState')
                    this._box2RadioButtonStateChanged(value);

                if (command === 'settingsButtonClicked')
                    this._settingsButtonClicked();
            }
        );
    }

    updateFirmwareVersion(fwVersion) {
        this._settingsItems['fw-version'] = fwVersion;
        this._updateGsettings();
    }

    updateCapabilities(supportsCodecIndicator, supportsUpscalingIndicator) {
        this._supportsCodecIndicator = supportsCodecIndicator;
        this._supportsUpscalingIndicator =
                supportsUpscalingIndicator && this._audioUpsamplingSupported;

        this._label1IsUpscaling = false;

        if (supportsCodecIndicator && this._supportsUpscalingIndicator) {
            this._config.labelIndicatorEnabled = 2;
            this._label1IsUpscaling = false;
        } else if (supportsCodecIndicator || this._supportsUpscalingIndicator) {
            this._config.labelIndicatorEnabled = 1;
            this._label1IsUpscaling = !supportsCodecIndicator;
        } else {
            this._config.labelIndicatorEnabled = 0;
        }
        this.dataHandler?.setConfig(this._config);
    }

    updateCodecIndicator(codec) {
        if (!this._supportsCodecIndicator)
            return;

        let text = '';

        switch (codec) {
            case AudioCodec.SBC:
                text = 'SBC';
                break;
            case AudioCodec.AAC:
                text = 'AAC';
                break;
            case AudioCodec.LDAC:
                text = 'LDAC';
                break;
            case AudioCodec.APT_X:
                text = 'aptX';
                break;
            case AudioCodec.APT_X_HD:
                text = 'aptX HD';
                break;
            case AudioCodec.LC3:
                text = 'LC3';
                break;
            default:
                text = '';
                break;
        }

        if (!this._label1IsUpscaling)
            this._props.labelIndicator1 = text;

        this.dataHandler?.setProps(this._props);
    }

    updateUpscalingIndicator(type) {
        if (!this._supportsUpscalingIndicator)
            return;

        let text = '';

        switch (type) {
            case DseeType.DSEE_HX:
                text = 'DSEE HX';
                break;
            case DseeType.DSEE:
                text = 'DSEE';
                break;
            case DseeType.DSEE_HX_AI:
                text = 'DSEE EX';
                break;
            case DseeType.DSEE_ULTIMATE:
                text = 'DSEE EX';
                break;
            default:
                text = '';
                break;
        }

        if (!this._audioUpsampling)
            text = '';

        if (this._label1IsUpscaling)
            this._props.labelIndicator1 = text;
        else
            this._props.labelIndicator2 = text;

        this.dataHandler?.setProps(this._props);
    }

    updateBatteryProps(props) {
        this._props = {...this._props, ...props};
        if (!this._battInfoRecieved)
            this._startConfiguration(props);

        if (this._batteryDualSupported)
            this._props.computedBatteryLevel = buds2to1BatteryLevel(props);
        else
            this._props.computedBatteryLevel = props.battery1Level;


        this.dataHandler?.setProps(this._props);
    }

    updateAmbientSoundControl(mode, focusOnVoiceState, level, naMode, naSensitivity) {
        if (!this._ambientSoundControlSupported)
            return;

        this._ambientMode = mode;
        this._focusOnVoiceState = focusOnVoiceState;
        this._ambientLevel = level;
        this._naMode = naMode;
        this._naSensitivity = naSensitivity;

        if (mode === AmbientSoundMode.ANC_OFF) {
            this._props.toggle1State = 1;
            this._props.optionsBoxVisible = 0;
        } else if (mode === AmbientSoundMode.AMBIENT) {
            this._props.toggle1State = 2;
            this._props.optionsBoxVisible = this._ambientSoundControlNASupported && naMode ? 2 : 1;
        } else if (mode === AmbientSoundMode.ANC_ON && !this._noNoiseCancellingSupported) {
            this._props.toggle1State = 3;
            this._props.optionsBoxVisible = 0;
        }

        if (this._ambientSoundControlNASupported) {
            this._props.box1CheckButton1State = naMode ? 1 : 0;
            this._props.box1CheckButton2State = focusOnVoiceState ? 1 : 0;
            this._props.box2CheckButton1State = naMode ? 1 : 0;
            this._props.box2CheckButton2State = focusOnVoiceState ? 1 : 0;
            this._props.box2RadioButtonState = naSensitivity + 1;
        } else {
            this._props.box1CheckButton1State = focusOnVoiceState ? 1 : 0;
        }

        this._props.box1SliderValue = level * 100 / 20;

        this.dataHandler?.setProps(this._props);
    }

    _toggle1ButtonClicked(index) {
        if (!this._ambientSoundControlSupported)
            return;

        if (index === 1) {
            this._ambientMode = AmbientSoundMode.ANC_OFF;
            this._props.optionsBoxVisible = 0;
            this._props.toggle1State = 1;
        } else if (index === 2) {
            this._ambientMode = AmbientSoundMode.AMBIENT;
            this._props.optionsBoxVisible = this._ambientSoundControlNASupported &&
                this._naMode ? 2 : 1;
            this._props.toggle1State = 2;
        } else if (index === 3) {
            this._ambientMode = AmbientSoundMode.ANC_ON;
            this._props.optionsBoxVisible = 0;
            this._props.toggle1State = 3;
        }
        this.dataHandler?.setProps(this._props);
        this._sonySocket.setAmbientSoundControl(this._ambientMode, this._focusOnVoiceState,
            this._ambientLevel, this._naMode, this._naSensitivity);
    }

    _box1SliderValueChanged(value) {
        if (!this._ambientSoundControlSupported)
            return;

        const ambientLevel = Math.round(value / 100 * 20);
        if (this._ambientLevel !== ambientLevel) {
            this._ambientLevel = ambientLevel;
            this._sonySocket.setAmbientSoundControl(this._ambientMode, this._focusOnVoiceState,
                this._ambientLevel, this._naMode, this._naSensitivity);
        }
    }

    _box1CheckButton1StateChanged(value) {
        if (!this._ambientSoundControlSupported)
            return;

        let sendPacket = false;
        if (this._ambientSoundControlNASupported) {
            this._props.optionsBoxVisible = value === 1 ? 2 : 1;
            this._props.box1CheckButton1State  = value;
            this._props.box2CheckButton1State  = value;
            this.dataHandler?.setProps(this._props);

            const naMode = value === 1;
            if (naMode !== this._naMode) {
                this._naMode = naMode;
                sendPacket = true;
            }
        } else {
            const focusOnVoice = value === 1;
            if (focusOnVoice !== this._focusOnVoiceState) {
                this._focusOnVoiceState = focusOnVoice;
                sendPacket = true;
            }
        }

        if (sendPacket) {
            this._sonySocket.setAmbientSoundControl(this._ambientMode, this._focusOnVoiceState,
                this._ambientLevel, this._naMode, this._naSensitivity);
        }
    }

    _box2CheckButton1StateChanged(value) {
        if (!this._ambientSoundControlSupported)
            return;

        let sendPacket = false;
        this._props.optionsBoxVisible = value === 1 ? 2 : 1;
        this._props.box1CheckButton1State  = value;
        this._props.box2CheckButton1State  = value;
        this.dataHandler?.setProps(this._props);

        const naMode = value === 1;
        if (naMode !== this._naMode) {
            this._naMode = naMode;
            sendPacket = true;
        }

        if (sendPacket) {
            this._sonySocket.setAmbientSoundControl(this._ambientMode, this._focusOnVoiceState,
                this._ambientLevel, this._naMode, this._naSensitivity);
        }
    }

    _box1CheckButton2StateChanged(value) {
        if (!this._ambientSoundControlSupported)
            return;

        let sendPacket = false;
        this._props.box1CheckButton2State  = value;
        this._props.box2CheckButton2State  = value;
        this.dataHandler?.setProps(this._props);

        const focusOnVoice = value === 1;
        if (focusOnVoice !== this._focusOnVoiceState) {
            this._focusOnVoiceState = focusOnVoice;
            sendPacket = true;
        }

        if (sendPacket) {
            this._sonySocket.setAmbientSoundControl(this._ambientMode, this._focusOnVoiceState,
                this._ambientLevel, this._naMode, this._naSensitivity);
        }
    }

    _box2CheckButton2StateChanged(value) {
        if (!this._ambientSoundControlSupported)
            return;

        let sendPacket = false;
        this._props.box1CheckButton2State  = value;
        this._props.box2CheckButton2State  = value;
        this.dataHandler?.setProps(this._props);

        const focusOnVoice = value === 1;
        if (focusOnVoice !== this._focusOnVoiceState) {
            this._focusOnVoiceState = focusOnVoice;
            sendPacket = true;
        }

        if (sendPacket) {
            this._sonySocket.setAmbientSoundControl(this._ambientMode, this._focusOnVoiceState,
                this._ambientLevel, this._naMode, this._naSensitivity);
        }
    }

    _box2RadioButtonStateChanged(value) {
        if (!this._ambientSoundControlSupported)
            return;

        const naSensitivity = value - 1;

        if (naSensitivity !== this._naSensitivity) {
            this._naSensitivity = naSensitivity;
            this._sonySocket.setAmbientSoundControl(this._ambientMode, this._focusOnVoiceState,
                this._ambientLevel, this._naMode, this._naSensitivity);
        }
    }

    updateSpeakToChatEnable(enabled) {
        if (!this._speakToChatEnabledSupported)
            return;

        this._props.toggle2State = enabled ? 1 : 2;
        this.dataHandler?.setProps(this._props);
    }

    _toggle2ButtonClicked(index) {
        if (!this._speakToChatEnabledSupported)
            return;

        if (index === 1)
            this._sonySocket.setSpeakToChatEnabled(true);
        else if (index === 2)
            this._sonySocket.setSpeakToChatEnabled(false);
    }

    updateSpeakToChatConfig(speak2ChatSensitivity, speak2ChatTimeout) {
        if (!this._speakToChatConfigSupported)
            return;

        if (this._speak2ChatSensitivity !== speak2ChatSensitivity ||
                this._speak2ChatTimeout !== speak2ChatTimeout) {
            this._speak2ChatSensitivity = speak2ChatSensitivity;
            this._speak2ChatTimeout = speak2ChatTimeout;
            this._settingsItems['s2c-sensitivity'] = speak2ChatSensitivity;
            this._settingsItems['s2c-duration'] = speak2ChatTimeout;
            this._updateGsettings();
        }
    }

    _setSpeakToChatConfig() {
        if (!this._speakToChatConfigSupported)
            return;

        this._sonySocket.setSpeakToChatConfig(this._speak2ChatSensitivity,
            this._speak2ChatTimeout);
    }

    updateBgmMode(enable, distance) {
        if (!this._listeningModeSupported)
            return;

        const mode = enable ? ListeningMode.BGM : ListeningMode.STANDARD;

        if (this._bgmMode !== mode || this._bgmDistance !== distance) {
            this._bgmMode = mode;
            this._bgmDistance = distance;

            this._settingsItems['bgm-mode'] = mode;
            this._settingsItems['bgm-distance'] = distance;
            this._updateGsettings();
        }
    }

    updateCinemaMode(enable) {
        if (!this._listeningModeSupported && !enable)
            return;

        const mode = ListeningMode.CINEMA;
        if (this._bgmMode !== mode) {
            this._bgmMode = mode;
            this._settingsItems['bgm-mode'] = mode;
            this._updateGsettings();
        }
    }

    _setBgmMode() {
        if (!this._listeningModeSupported)
            return;

        this._sonySocket.setListeningMode(this._bgmMode, this._bgmDistance);
    }

    updateEqualizer(presetCode, customBands) {
        if (!this._equalizerSixBandsSupported && !this._equalizerTenBandsSupported)
            return;

        if (this._eqPreset !== presetCode || !isArrayEqual(this._eqCustom, customBands)) {
            this._eqPreset = presetCode;
            this._eqCustom = customBands;
            this._settingsItems['eq-preset'] = presetCode;
            this._settingsItems['eq-custom'] = customBands;
            this._updateGsettings();
        }
    }

    _setEqualizerPreset() {
        if (!this._equalizerSixBandsSupported && !this._equalizerTenBandsSupported)
            return;

        if (this._eqPreset === undefined)
            return;

        this._sonySocket.setEqualizerPreset(this._eqPreset);
    }

    _setEqualizerCustomBands() {
        if (this._eqPreset === undefined || this._eqCustom === undefined)
            return;

        if (this._equalizerSixBandsSupported && this._eqCustom.length === 6 ||
            this._equalizerTenBandsSupported && this._eqCustom.length === 10)
            this._sonySocket.setEqualizer(this._eqPreset, this._eqCustom);
    }

    updateAudioSampling(enabled) {
        if (!this._audioUpsamplingSupported)
            return;

        this._audioUpsampling = enabled ? 1 : 0;

        if (this._settingsItems) {
            this._settingsItems['dsee'] = this._audioUpsampling;
            this._updateGsettings();
        }
    }

    _setAudioUpsampling() {
        if (!this._audioUpsamplingSupported)
            return;

        if (this._audioUpsampling !== undefined) {
            const enabled = this._audioUpsampling === 1;
            this._sonySocket.setAudioUpsampling(enabled);
        }
    }

    updateButtonModesLeftRight(leftMode, rightMode) {
        if (!this._buttonModesLeftRight)
            return;

        if (this._btnLeft !== leftMode || this._btnRight !== rightMode) {
            this._btnLeft = leftMode;
            this._btnRight = rightMode;
            this._settingsItems['btn-left'] = leftMode;
            this._settingsItems['btn-right'] = rightMode;
            this._updateGsettings();
        }
    }

    _setButtonModes() {
        if (!this._buttonModesLeftRight)
            return;

        this._sonySocket.setButtonModesLeftRight(this._btnLeft, this._btnRight);
    }

    updateAmbientSoundButton(mode) {
        if (!this._ambientSoundControlButtonMode)
            return;

        if (this._ambientButtonMode !== mode) {
            this._ambientButtonMode = mode;
            this._settingsItems['amb-btn-mode'] = this._ambientButtonMode;
            this._updateGsettings();
        }
    }

    _setAmbientButtonMode() {
        if (!this._ambientSoundControlButtonMode)
            return;

        this._sonySocket.setAmbientSoundButton(this._ambientButtonMode);
    }

    updateVoiceNotifications(enabled) {
        if (!this._voiceNotificationsSupported)
            return;

        if (this._voiceNoti !== enabled) {
            this._voiceNoti = enabled;
            this._settingsItems['voice-noti'] = enabled;
            this._updateGsettings();
        }
    }

    _setVoiceNotifications() {
        if (!this._voiceNotificationsSupported)
            return;

        this._sonySocket.setVoiceNotifications(this._voiceNoti);
    }


    updateVoiceNotificationsVolume(vol) {
        if (!this._voiceNotificationsVolumeSupported)
            return;

        if (this._voiceVolume !== vol) {
            this._voiceVolume = vol;
            this._settingsItems['voice-vol'] = vol;
            this._updateGsettings();
        }
    }

    _setVoiceNotificationsVolume() {
        if (!this._voiceNotificationsVolumeSupported)
            return;

        this._sonySocket.setVoiceNotificationsVolume(this._voiceVolume);
    }

    updatePauseWhenTakenOff(enabled) {
        if (!this._pauseWhenTakenOffSupported)
            return;

        if (this._pauseWhenTakenOff !== enabled) {
            this._pauseWhenTakenOff = enabled;
            this._settingsItems['pause-takeoff'] = enabled;
            this._updateGsettings();
        }
    }

    _setPauseWhenTakenOff() {
        if (!this._pauseWhenTakenOffSupported)
            return;

        this._sonySocket.setPauseWhenTakenOff(this._pauseWhenTakenOff);
    }

    updateAutomaticPowerOff(enabled, time) {
        if (!this._automaticPowerOffWhenTakenOffSupported)
            return;

        if (this._autoPowerOff !== enabled ||
                this._automaticPowerOffByTimeSupported && this._autoPowerOffTime !== time) {
            this._autoPowerOff = enabled;

            if (this._automaticPowerOffByTimeSupported)
                this._autoPowerOffTime = time;

            this._settingsItems['auto-power'] = enabled;

            if (this._automaticPowerOffByTimeSupported)
                this._settingsItems['auto-power-time'] = time;

            this._updateGsettings();
        }
    }

    _setAutoPowerOff() {
        if (!this._automaticPowerOffWhenTakenOffSupported)
            return;

        const time = this._automaticPowerOffByTimeSupported ? this._autoPowerOffTime : 0;

        this._sonySocket.setAutomaticPowerOff(this._autoPowerOff, time);
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
        this._sonySocket?.setPairingMode(enabled);
    }

    updateDeviceList(devices, routingMac) {
        this._deviceInfo = devices.map(device => ({
            id: device.mac,
            name: device.name,
            connected: device.connected,
            state: BtDeviceState.Ready,
        }));

        this._settingsItems['dev-mgmt'] = this._deviceInfo;
        this._activeDevice = routingMac;
        this._settingsItems['active-dev'] = routingMac;
        this._updateGsettings();
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

    updateDeviceActionStatus(action, result, mac) {
        const device = this._deviceInfo.find(info => info.id === mac);
        if (!device)
            return;

        let inProgress = false;
        let isReady = false;
        if (result === 0x02 || result === 0x12 || result === 0x22 ||
                result === 0x03 || result === 0x13 || result === 0x23)
            inProgress = true;

        if (result === 0x00 || result === 0x10 || result === 0x20)
            isReady = true;

        if (inProgress || isReady) {
            if (action === 0x01) {
                device.connected = true;
                device.state = inProgress ? BtDeviceState.Processing : BtDeviceState.Ready;
            } else if (action === 0x00) {
                device.connected = false;
                device.state = BtDeviceState.Ready;
            } else if (action === 0x02) {
                this._deviceInfo = this._deviceInfo.filter(info => info.id !== mac);
            }

            this._settingsItems['dev-mgmt'] = this._deviceInfo;
            this._updateGsettings();
            this._stopBTTimeout(mac);
            return;
        }

        if (result === 0x01 || result === 0x03 || result === 0x11 || result === 0x13 ||
                    result === 0x21 || result === 0x23) {
            device.state = BtDeviceState.Ready;
            this._settingsItems['dev-mgmt'] = this._deviceInfo;
            this._updateGsettings();
            this._stopBTTimeout(mac);
        }
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
        this._sonySocket?.connectDevice(id);
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
        this._sonySocket?.disconnectDevice(id);
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
        this._sonySocket?.unpairDevice(id);
    }

    updatePlaybackDevice(id) {
        if (this._activeDevice !== id) {
            this._activeDevice = id;
            this._settingsItems['active-dev'] = id;
            this._updateGsettings();
        }
    }

    _setRoutingBTDevice(id) {
        this._sonySocket?.setSourceSwitch(id);
    }

    updateSourceSwitchFixed(enabled) {
        if (this._activeDeviceFixed !== enabled) {
            this._activeDeviceFixed = enabled;
            this._settingsItems['active-fix'] = enabled;
            this._updateGsettings();
        }
    }

    _setSourceSwitchFixed(enabled) {
        this._sonySocket?.setSourceSwitchFixed(enabled);
    }

    _settingsButtonClicked() {
        this._configureWindowLauncherCancellable = new Gio.Cancellable();
        launchConfigureWindow(this._devicePath, 'sony', this._extPath,
            this._configureWindowLauncherCancellable);
        this._configureWindowLauncherCancellable = null;
    }

    destroy() {
        this._configureWindowLauncherCancellable?.cancel();
        this._configureWindowLauncherCancellable = null;
        this._bluezDeviceProxy = null;
        this._sonySocket?.destroy();
        this._sonySocket = null;

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
        this._settings = null;
        this._battInfoRecieved = false;
    }
});
