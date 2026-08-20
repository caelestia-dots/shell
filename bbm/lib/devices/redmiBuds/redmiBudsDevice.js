'use strict';
import Gio from 'gi://Gio';
import GObject from 'gi://GObject';
const _ = s => s; // gettext stub for daemon context

import {createLogger, getDeviceIdentifier, hexBytes} from '../logger.js';
import {
    buds2to1BatteryLevel, validateProperties, launchConfigureWindow, isArrayEqual
} from '../deviceUtils.js';
import {createConfig, createProperties, DataHandler} from '../../dataHandler.js';
import {RedmiBudsSocket} from './redmiBudsSocket.js';

export const DeviceTypeRedmiBuds = 'redmiBuds';

const RedmiBudsUUID = '0000fd2d-0000-1000-8000-00805f9b34fb';
export function isRedmiBuds(bluezDeviceProxy, uuids) {
    const bluezProps = [];
    const supported = uuids.includes(RedmiBudsUUID) ? 'yes' : 'no';
    return {supported, bluezProps};
}

export const RedmiBudsDevice = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_RedmiBudsDevice',
}, class RedmiBudsDevice extends GObject.Object {
    _init(settings, devicePath, alias, extPath, profileManager, updateDeviceMapCb) {
        super._init();
        const identifier = getDeviceIdentifier(devicePath);
        const tag = `RedmiBudsDevice-${identifier}`;
        this._log = createLogger(tag);
        this._log.info('------------------- RedmiBudsDevice init -------------------');
        this._settings = settings;
        this._devicePath = devicePath;
        this._alias = alias;
        this._extPath = extPath;
        this.updateDeviceMapCb = updateDeviceMapCb;
        this._ignoreGsettingsChange = false;

        this._config = createConfig();
        this._props = createProperties();
        this._modelData = null;
        this._fwVersion = '';
        this._serialNo = '';

        this._callbacks = {
            modelIntialized: this.modelIntialized.bind(this),
            updateFirmware: this.updateFirmware.bind(this),
            updateSerial: this.updateSerial.bind(this),
            updateBatteryProps: this.updateBatteryProps.bind(this),
            updateInEarState: this.updateInEarState.bind(this),
            updateNoiseControl: this.updateNoiseControl.bind(this),
            updateAdaptiveNC: this.updateAdaptiveNC.bind(this),
            updateAncStrength: this.updateAncStrength.bind(this),
            updateAmbientStrength: this.updateAmbientStrength.bind(this),

            updateGestureSingle: this.updateGestureSingle.bind(this),
            updateGestureDouble: this.updateGestureDouble.bind(this),
            updateGestureTriple: this.updateGestureTriple.bind(this),
            updateGestureLong: this.updateGestureLong.bind(this),
            updateGestureSwipe: this.updateGestureSwipe.bind(this),

            updateAutoAnswer: this.updateAutoAnswer.bind(this),
            updateDualConnection: this.updateDualConnection.bind(this),
            updateEqPreset: this.updateEqPreset.bind(this),
            updateLongGestures: this.updateLongGestures.bind(this),
            updateAdaptiveSound: this.updateAdaptiveSound.bind(this),
            updateLowLatency: this.updateLowLatency.bind(this),
            updateCustomEq: this.updateCustomEq.bind(this),
        };

        const profile = {type: DeviceTypeRedmiBuds, uuid: RedmiBudsUUID};

        this._redmiBudsSocket = new RedmiBudsSocket(
            this._devicePath,
            profileManager,
            profile,
            this._callbacks
        );
    }

    modelIntialized(modelData, vid, pid) {
        this._modelData = modelData;

        this._log.info(`Configuration: ${JSON.stringify(this._modelData, null, 2)}`);

        this._commonIcon = this._modelData.budsIcon;
        this._config.battery1ShowOnDisconnect = true;
        this._config.showSettingsButton = true;

        if (this._modelData.batteryCase)
            this._caseIcon = `${this._modelData.case}`;

        this._createDefaultSettings(vid, pid);

        const devicesList = this._settings.get_strv('redmi-buds-list').map(JSON.parse);

        if (devicesList.length === 0 ||
                !devicesList.some(device => device.path === this._devicePath)) {
            this._addPropsToSettings(devicesList);
        } else {
            validateProperties(this._settings, 'redmi-buds-list', devicesList,
                this._defaultsDeviceSettings, this._devicePath);
        }

        this._updateInitialValues();
        this._monitorRedmiBudsListGsettings();
        this._updateIcons();
        this._setupAncConfig();

        if (this._modelData.ring) {
            this._ringState = 'stopped';
            this._settingsItems['ring-state'] = this._ringState;
            this._ringStateLeft = 'stopped';
            this._settingsItems['ring-state-left'] = this._ringStateLeft;
            this._updateGsettings();
        }
    }

    _createDefaultSettings(vid, pid) {
        const getDefaultAction = gestureType => {
            const actions = this._modelData.gestureOptions.gestures?.[gestureType].actions ?? {};
            const values = Object.values(actions);
            return values[0] ?? 0;
        };

        this._defaultsDeviceSettings = {
            path: this._devicePath,
            vid,
            pid,
            alias: this._alias,
            icon: this._commonIcon,
            'fw-version': this._fwVersion,
            'serial': this._serialNo,

            ...this._modelData.batteryCase && {
                'case': this._caseIcon,
            },

            ...this._modelData.eqPreset && {
                'eq-preset': Object.values(this._modelData.eqPreset)[0],
            },

            ...this._modelData.eqPreset?.custom !== undefined && {
                'eq-custom': [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            },

            ...this._modelData.adaptiveSound && {
                'adapt-sound': false,
            },

            ...this._modelData.dualConnection && {
                'dual-conn': false,
            },

            ...this._modelData.autoAnswer && {
                'auto-answer': false,
            },

            ...this._modelData.lowLatencyMode && {
                'low-latency': false,
            },

            ...this._modelData.gestureOptions?.gestureTypes?.single !== undefined && {
                'single-left': getDefaultAction('single'),
                'single-right': getDefaultAction('single'),
            },

            ...this._modelData.gestureOptions?.gestureTypes?.double !== undefined && {
                'double-left': getDefaultAction('double'),
                'double-right': getDefaultAction('double'),
            },

            ...this._modelData.gestureOptions?.gestureTypes?.triple !== undefined && {
                'triple-left': getDefaultAction('triple'),
                'triple-right': getDefaultAction('triple'),
            },

            ...this._modelData.gestureOptions?.gestureTypes?.['action-hold'] !== undefined && {
                'action-hold-left': getDefaultAction('action-hold'),
                'action-hold-right': getDefaultAction('action-hold'),
            },

            ...this._modelData.gestureOptions?.gestureTypes?.['swipe'] !== undefined && {
                'swipe-left': getDefaultAction('swipe'),
                'swipe-right': getDefaultAction('swipe'),
            },

            ...this._modelData.gestureOptions?.noiseControlModes && {
                'left-longpress': 7,
                'right-longpress': 7,
            },

            ...this._modelData.ring && {
                'ring-state': 'stopped',
                'ring-state-left': 'stopped',
            },
        };
    }

    _addPropsToSettings(devicesList) {
        devicesList.push(this._defaultsDeviceSettings);
        this._settings.set_strv('redmi-buds-list', devicesList.map(JSON.stringify));
    }

    _updateInitialValues() {
        const devicesList = this._settings.get_strv('redmi-buds-list').map(JSON.parse);
        const existingPathIndex = devicesList.findIndex(item => item.path === this._devicePath);
        if (existingPathIndex === -1)
            return;

        this._settingsItems = devicesList[existingPathIndex];

        this._commonIcon = this._settingsItems['icon'];

        if (this._modelData.batteryCase)
            this._caseIcon = this._settingsItems['case'];

        if (this._modelData.eqPreset)
            this._eqPreset = this._settingsItems['eq-preset'];

        if (this._modelData.eqPreset?.custom !== undefined)
            this._customEq = this._settingsItems['eq-custom'];

        if (this._modelData.adaptiveSound)
            this._adaptiveSound = this._settingsItems['adapt-sound'];

        if (this._modelData.dualConnection)
            this._dualConn = this._settingsItems['dual-conn'];

        if (this._modelData.autoAnswer)
            this._autoAnswer = this._settingsItems['auto-answer'];

        if (this._modelData.lowLatencyMode)
            this._lowLatency = this._settingsItems['low-latency'];

        const gestureTypes = this._modelData.gestureOptions?.gestureTypes;

        if (gestureTypes?.single !== undefined) {
            this._gestureSingleLeft = this._settingsItems['single-left'];
            this._gestureSingleRight = this._settingsItems['single-right'];
        }

        if (gestureTypes?.double !== undefined) {
            this._gestureDoubleLeft = this._settingsItems['double-left'];
            this._gestureDoubleRight = this._settingsItems['double-right'];
        }

        if (gestureTypes?.triple !== undefined) {
            this._gestureTripleLeft = this._settingsItems['triple-left'];
            this._gestureTripleRight = this._settingsItems['triple-right'];
        }

        if (gestureTypes?.['action-hold'] !== undefined) {
            this._gestureLongLeft = this._settingsItems['action-hold-left'];
            this._gestureLongRight = this._settingsItems['action-hold-right'];
        }

        if (gestureTypes?.['swipe'] !== undefined) {
            this._gestureSwipeLeft = this._settingsItems['swipe-left'];
            this._gestureSwipeRight = this._settingsItems['swipe-right'];
        }

        if (this._modelData.gestureOptions?.noiseControlModes) {
            this._leftLongpressMode = this._settingsItems['left-longpress'];
            this._rightLongpressMode = this._settingsItems['right-longpress'];
        }

        if (this._modelData.ring) {
            this._ringState = 'stopped';
            this._ringStateLeft = 'stopped';
        }
    }

    _updateGsettingsProps() {
        const devicesList = this._settings.get_strv('redmi-buds-list').map(JSON.parse);
        const existingPathIndex = devicesList.findIndex(item => item.path === this._devicePath);
        if (existingPathIndex === -1)
            return;

        this._settingsItems = devicesList[existingPathIndex];

        const icon = this._settingsItems['icon'];
        if (this._commonIcon !== icon) {
            this._commonIcon = icon;
            this._updateIcons();
        }

        if (this._modelData.batteryCase) {
            const caseIcon = this._settingsItems['case'];
            if (this._caseIcon !== caseIcon) {
                this._caseIcon = caseIcon;
                this._updateIcons();
            }
        }

        if (this._modelData.eqPreset) {
            const eqPreset = this._settingsItems['eq-preset'];
            if (this._eqPreset !== eqPreset) {
                this._eqPreset = eqPreset;
                this._setEqPreset(eqPreset);
            }
        }

        if (this._modelData.eqPreset?.custom !== undefined) {
            const eqCustom = this._settingsItems['eq-custom'];
            if (!this._customEq || !isArrayEqual(eqCustom, this._customEq)) {
                this._customEq = eqCustom;
                this._setCustomEq(eqCustom);
            }
        }

        if (this._modelData.adaptiveSound) {
            const enable = this._settingsItems['adapt-sound'];

            if (this._adaptiveSound !== enable) {
                this._adaptiveSound = enable;
                this._setAdaptiveSound(enable);
            }
        }

        if (this._modelData.lowLatencyMode) {
            const enable = this._settingsItems['low-latency'];

            if (this._lowLatency !== enable) {
                this._lowLatency = enable;
                this._setLowLatency(enable);
            }
        }

        if (this._modelData.dualConnection) {
            const enable = this._settingsItems['dual-conn'];

            if (this._dualConn !== enable) {
                this._dualConn = enable;
                this._setDualConn(enable);
            }
        }

        if (this._modelData.autoAnswer) {
            const enable = this._settingsItems['auto-answer'];

            if (this._autoAnswer !== enable) {
                this._autoAnswer = enable;
                this._setAutoAnswer(enable);
            }
        }

        const gestureTypes = this._modelData.gestureOptions?.gestureTypes;

        if (gestureTypes.single !== undefined) {
            const left = this._settingsItems['single-left'];
            const right = this._settingsItems['single-right'];

            if (this._gestureSingleLeft !== left) {
                this._gestureSingleLeft = left;
                this._setGesture('single', 'left', left);
            }

            if (this._gestureSingleRight !== right) {
                this._gestureSingleRight = right;
                this._setGesture('single', 'right', right);
            }
        }

        if (gestureTypes.double !== undefined) {
            const left = this._settingsItems['double-left'];
            const right = this._settingsItems['double-right'];

            if (this._gestureDoubleLeft !== left) {
                this._gestureDoubleLeft = left;
                this._setGesture('double', 'left', left);
            }

            if (this._gestureDoubleRight !== right) {
                this._gestureDoubleRight = right;
                this._setGesture('double', 'right', right);
            }
        }

        if (gestureTypes.triple !== undefined) {
            const left = this._settingsItems['triple-left'];
            const right = this._settingsItems['triple-right'];

            if (this._gestureTripleLeft !== left) {
                this._gestureTripleLeft = left;
                this._setGesture('triple', 'left', left);
            }

            if (this._gestureTripleRight !== right) {
                this._gestureTripleRight = right;
                this._setGesture('triple', 'right', right);
            }
        }

        if (gestureTypes['action-hold'] !== undefined) {
            const left = this._settingsItems['action-hold-left'];
            const right = this._settingsItems['action-hold-right'];

            if (this._gestureLongLeft !== left) {
                this._gestureLongLeft = left;
                this._setGesture('action-hold', 'left', left);
            }

            if (this._gestureLongRight !== right) {
                this._gestureLongRight = right;
                this._setGesture('action-hold', 'right', right);
            }
        }

        if (gestureTypes.swipe !== undefined) {
            const left = this._settingsItems['swipe-left'];
            const right = this._settingsItems['swipe-right'];

            if (this._gestureSwipeLeft !== left) {
                this._gestureSwipeLeft = left;
                this._setGesture('swipe', 'left', left);
            }

            if (this._gestureSwipeRight !== right) {
                this._gestureSwipeRight = right;
                this._setGesture('swipe', 'right', right);
            }
        }

        if (this._modelData.gestureOptions?.noiseControlModes) {
            const leftLongPress = this._settingsItems['left-longpress'];
            if (leftLongPress !== this._leftLongpressMode) {
                this._leftLongpressMode = leftLongPress;
                this._setLongPressMode(true, leftLongPress);
            }

            const rightLongPress = this._settingsItems['right-longpress'];
            if (rightLongPress !== this._rightLongpressMode) {
                this._rightLongpressMode = rightLongPress;
                this._setLongPressMode(false, rightLongPress);
            }
        }

        if (this._modelData.ring) {
            const state = this._settingsItems['ring-state'];
            if (this._ringState !== state) {
                this._ringState = state;
                this._setRingMyBuds(state);
            }

            const stateLeft = this._settingsItems['ring-state-left'];
            if (this._ringStateLeft !== stateLeft) {
                this._ringStateLeft = stateLeft;
                this._setRingMyBuds(stateLeft, true);
            }
        }
    }

    _monitorRedmiBudsListGsettings() {
        this._settingsHandlerId = this._settings?.connect('changed::redmi-buds-list', () => {
            if (this._ignoreGsettingsChange)
                return;

            this._updateGsettingsProps();
        });
    }

    _updateGsettings() {
        this._ignoreGsettingsChange = true;

        const currentList = this._settings.get_strv('redmi-buds-list').map(JSON.parse);
        const index = currentList.findIndex(d => d.path === this._devicePath);

        if (index !== -1) {
            currentList[index] = this._settingsItems;
            this._settings.set_strv('redmi-buds-list', currentList.map(JSON.stringify));
        }

        this._ignoreGsettingsChange = false;
    }

    _updateIcons() {
        this._config.commonIcon = this._commonIcon;
        this._config.albumArtIcon = this._commonIcon;

        this._config.battery1ShowOnDisconnect = true;
        if (this._modelData.batteryMutiple) {
            this._config.battery1Icon = `${this._commonIcon}-left`;
            this._config.battery2Icon = `${this._commonIcon}-right`;
            this._config.battery2ShowOnDisconnect = true;
            this._config.battery3Icon = this._caseIcon;
        } else {
            this._config.battery1Icon = this._commonIcon;
        }

        this.dataHandler?.setConfig(this._config);
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

    _setupAncConfig() {
        const nc = this._modelData.noiseControl;
        if (!nc)
            return;

        this._strengthMap = {
            'off': 0x00,
            'noiseCancellation': 0x00,
            'transparency': 0x00,
        };

        let buttonIndex = 1;
        this._ancToggleMap = {};
        this._config.toggle1Title = _('Noise Control');

        const addToggle = (type, byte, icon, name) => {
            if (byte == null)
                return;

            this._config[`toggle1Button${buttonIndex}Icon`] = icon;
            this._config[`toggle1Button${buttonIndex}Name`] = name;

            this._ancToggleMap[buttonIndex] = {type, byte};

            buttonIndex++;
        };

        if (nc.off != null) {
            addToggle(
                'off',
                nc.off,
                'bbm-anc-off-symbolic',
                _('Off')
            );
        }

        if (nc.transparency != null) {
            addToggle(
                'transparency',
                nc.transparency,
                'bbm-transperancy-symbolic',
                _('Transparency')
            );
        }

        if (nc.noiseCancellation != null) {
            addToggle(
                'noiseCancellation',
                nc.noiseCancellation,
                'bbm-anc-on-symbolic',
                _('Noise Cancellation')
            );
        }

        this._setupAdaptiveSwitch();
        this._setupNCStrength();
        this._setupNcLevel();
        this._setupTransparencyStrength();
    }

    _setupAdaptiveSwitch() {
        if (!this._modelData.adaptiveNcSwitch)
            return;

        this._config.optionsBox1.push('check-button');
        this._config.box1CheckButton = [_('Adaptive')];

        if (this._modelData.noiseCancellationStrength || this._modelData.ancLevel) {
            this._config.optionsBox2.push('check-button');
            this._config.box2CheckButton = [_('Adaptive')];
        }
    }

    _setupNCStrength() {
        const data = this._modelData.noiseCancellationStrength;
        if (!data)
            return;

        const levelNames = {
            low: _('Low'),
            mid: _('Mid'),
            high: _('High'),
            adaptive: _('Adaptive'),
        };

        const keys = Object.keys(data);
        if (keys.length < 2)
            return;

        const labels = [];
        const map = {};
        const reverse = {};

        keys.forEach((k, i) => {
            const index = i + 1;
            const byte = data[k];

            labels.push(levelNames[k] ?? k);
            map[index] = byte;
            reverse[byte] = index;
        });

        this._config.box1RadioTitle = _('Noise Cancellation Strength');
        this._config.box1RadioButton = labels;

        this._noiseCancellationStrengthMap = map;
        this._noiseCancellationStrengthReverse = reverse;
        this._config.optionsBox1.push('radio-button');
    }

    _setupNcLevel() {
        if (!this._modelData.ancLevel)
            return;

        this._config.optionsBox1.push('slider');
        this._config.box1SliderTitle = _('Noise Level');
    }

    _setupTransparencyStrength() {
        const data = this._modelData.transparencyStrength;
        if (!data)
            return;

        const transNames = {
            regular: _('Regular'),
            voice: _('Voice'),
            ambient: _('Ambient'),
        };

        const keys = Object.keys(data);
        if (keys.length < 2)
            return;

        const labels = [];
        const map = {};
        const reverse = {};

        keys.forEach((k, i) => {
            const index = i + 1;
            const byte = data[k];

            labels.push(transNames[k] ?? k);
            map[index] = byte;
            reverse[byte] = index;
        });

        this._config.box3RadioTitle = _('Transparency Strength');
        this._config.box3RadioButton = labels;

        this._transparencyStrengthMap = map;
        this._transparencyStrengthReverse = reverse;

        this._config.optionsBox3.push('radio-button');
    }

    _startConfiguration(battInfo) {
        const bat1level = battInfo.battery1Level  ?? 0;
        const bat2level = battInfo.battery2Level  ?? 0;
        const bat3level = battInfo.battery3Level  ?? 0;

        if (bat1level <= 0 && bat2level <= 0 && bat3level <= 0)
            return;

        this._battInfoRecieved = true;

        if (this._modelData.noiseControl)
            this._props.toggle1Visible = true;

        this.dataHandler = new DataHandler(this._config, this._props);

        this.updateDeviceMapCb(this._devicePath, this.dataHandler);

        this._dataHandlerId = this.dataHandler.connect(
            'ui-action', (o, command, value) => {
                if (command === 'toggle1State')
                    this._toggle1ButtonClicked(value);

                if (command === 'box1CheckButton1State')
                    this._box1CheckButton1StateChanged(value);

                if (command === 'box2CheckButton1State')
                    this._box2CheckButton1StateChanged(value);

                if (command === 'box1RadioButtonState')
                    this._box1RadioButtonStateChanged(value);

                if (command === 'box3RadioButtonState')
                    this._box3RadioButtonStateChanged(value);

                if (command === 'box1SliderValue')
                    this._box1SliderValueChanged(value);

                if (command === 'settingsButtonClicked')
                    this._settingsButtonClicked();
            }
        );
    }

    updateFirmwareInfo(fwVersion) {
        this._settingsItems['fw-version'] = fwVersion ?? '';
        this._updateGsettings();
    }

    updateBatteryProps(props) {
        this._props = {...this._props, ...props};

        if (!this._modelData.batteryMutiple)
            this._props.computedBatteryLevel = props.battery1Level;
        else
            this._props.computedBatteryLevel = buds2to1BatteryLevel(props);

        if (!this._battInfoRecieved)
            this._startConfiguration(props);

        this.dataHandler?.setProps(this._props);
    }

    updateNoiseControl(mode) {
        this._log.info(`UpdateNoiseControl mode: ${hexBytes(mode)}`);
        if (!this._ancToggleMap)
            return;

        let toggleIndex = 0;
        let modeType = null;

        for (const [index, data] of Object.entries(this._ancToggleMap)) {
            if (data.byte === mode) {
                toggleIndex = Number(index);
                modeType = data.type;
                break;
            }
        }

        this._props.toggle1State = toggleIndex;
        const hasNCOptions = this._modelData.adaptiveANCSwitch || this._modelData.ancLevel ||
            this._modelData.noiseCancellationStrength;

        if (hasNCOptions && modeType === 'noiseCancellation') {
            const adaptiveEnabled = this._modelData.adaptiveNcSwitch &&
                this._props.box1CheckButton1State;

            this._props.optionsBoxVisible = adaptiveEnabled ? 2 : 1;
        } else if (this._modelData.transparencyStrength && modeType === 'transparency') {
            this._props.optionsBoxVisible = 3;
        } else {
            this._props.optionsBoxVisible = 0;
        }

        this.dataHandler?.setProps(this._props);
    }

    updateAdaptiveNC(enabled) {
        this._log.info(`updateAdaptiveNC enabled: ${enabled}`);
        if (!this._modelData.adaptiveNcSwitch)
            return;

        const state = enabled ? 1 : 0;
        this._props.box1CheckButton1State = state;
        this._props.box2CheckButton1State = state;
        const modeIndex = this._props.toggle1State;
        const toggle = this._ancToggleMap?.[modeIndex];
        if (toggle?.type === 'noiseCancellation')
            this._props.optionsBoxVisible = enabled ? 2 : 1;

        this.dataHandler?.setProps(this._props);
    }

    updateAncStrength(strength) {
        this._log.info(`updateAncStrength strength: ${hexBytes(strength)}`);

        this._strengthMap['noiseCancellation'] = strength;

        if (this._modelData.noiseCancellationStrength) {
            const index = this._noiseCancellationStrengthReverse?.[strength];
            if (index == null)
                return;

            this._props.box1RadioButtonState = index;
            this.dataHandler?.setProps(this._props);
        } else if (this._modelData.ancLevel) {
            if (this._ancLevel !== strength) {
                this._ancLevel = strength;

                const level = this._modelData.ancLevel;
                this._props.box1SliderValue = Math.round(strength * 100 / level);

                this.dataHandler?.setProps(this._props);
            }
        }
    }

    updateAmbientStrength(strength) {
        this._log.info(`updateAmbientStrength strength: ${hexBytes(strength)}`);

        this._strengthMap['transparency'] = strength;
        const index = this._transparencyStrengthReverse?.[strength];

        if (index == null)
            return;

        this._props.box3RadioButtonState = index;
        this.dataHandler?.setProps(this._props);
    }

    _toggle1ButtonClicked(index) {
        const toggle = this._ancToggleMap?.[index];
        if (!toggle)
            return;

        this._props.toggle1State = index;

        const hasNCOptions = this._modelData.adaptiveANCSwitch || this._modelData.ancLevel ||
            this._modelData.noiseCancellationStrength;

        if (hasNCOptions && toggle.type === 'noiseCancellation') {
            const adaptiveEnabled = this._modelData.adaptiveNcSwitch &&
                this._props.box1CheckButton1State;

            this._props.optionsBoxVisible = adaptiveEnabled ? 2 : 1;
        } else if (this._modelData.transparencyStrength && toggle.type === 'transparency') {
            this._props.optionsBoxVisible = 3;
        } else {
            this._props.optionsBoxVisible = 0;
        }

        this.dataHandler?.setProps(this._props);
        this._redmiBudsSocket?.setNoiseControl(toggle.byte, this._strengthMap[toggle.type]);
    }

    _box1CheckButton1StateChanged(state) {
        this.updateAdaptiveNC(state);
        this._redmiBudsSocket?.setAdaptiveNC(state);
    }

    _box2CheckButton1StateChanged(state) {
        this.updateAdaptiveNC(state);
        this._redmiBudsSocket?.setAdaptiveNC(state);
    }

    _box1RadioButtonStateChanged(index) {
        const strength = this._noiseCancellationStrengthMap?.[index];
        if (strength == null)
            return;

        const ncByte = this._modelData.noiseControl.noiseCancellation;
        this._strengthMap['noiseCancellation'] = strength;
        this._redmiBudsSocket?.setNoiseControl(ncByte, strength);
    }

    _box3RadioButtonStateChanged(index) {
        const strength = this._transparencyStrengthMap?.[index];
        if (strength == null)
            return;

        const transparencyByte = this._modelData.noiseControl.transparency;
        this._strengthMap['transparency'] = strength;
        this._redmiBudsSocket?.setNoiseControl(transparencyByte, strength);
    }

    _box1SliderValueChanged(value) {
        const ncByte = this._modelData.noiseControl.noiseCancellation;
        const level = this._modelData.ancLevel;
        const strength = Math.round(value * level / 100);
        this._strengthMap['noiseCancellation'] = strength;
        this._redmiBudsSocket?.setNoiseControl(ncByte, strength);
    }

    updateInEarState(left, right) {
        this._log.info(`Inear status left: ${left} Right: ${right}`);
    }

    updateEqPreset(mode) {
        this._log.info(`updateEqPreset : ${hexBytes(mode)}`);
        if (!this._modelData.eqPreset)
            return;

        if (this._eqPreset === mode)
            return;

        this._eqPreset = mode;

        if (this._settingsItems) {
            this._settingsItems['eq-preset'] = mode;
            this._updateGsettings();
        }
    }

    _setEqPreset(mode) {
        this._redmiBudsSocket?.setEqPreset(mode);
    }

    updateCustomEq(eqArray) {
        this._log.info(`updateCustomEq : ${hexBytes(eqArray)}`);
        if (this._modelData.eqPreset.custom === undefined)
            return;

        if (isArrayEqual(this._customEq, eqArray))
            return;

        this._customEq = eqArray;

        if (this._settingsItems) {
            this._settingsItems['eq-custom'] = eqArray;
            this._updateGsettings();
        }
    }

    _setCustomEq(eqArray) {
        this._redmiBudsSocket?.setCustomEq(eqArray);
    }

    updateAdaptiveSound(enable) {
        this._log.info(`updateAdaptiveSound : ${enable}`);
        if (!this._modelData.adaptiveSound)
            return;

        if (this._adaptiveSound === enable)
            return;

        this._adaptiveSound = enable;

        if (this._settingsItems) {
            this._settingsItems['adapt-sound'] = enable;
            this._updateGsettings();
        }
    }

    _setAdaptiveSound(enable) {
        this._redmiBudsSocket?.setAdaptiveSound(enable);
    }


    updateDualConnection(enable) {
        this._log.info(`updateDualConnection : ${enable}`);
        if (!this._modelData.dualConnection)
            return;

        if (this._dualConn === enable)
            return;

        this._dualConn = enable;

        if (this._settingsItems) {
            this._settingsItems['dual-conn'] = enable;
            this._updateGsettings();
        }
    }

    _setDualConn(enable) {
        this._redmiBudsSocket?.setDualConn(enable);
    }

    updateAutoAnswer(enable) {
        this._log.info(`updateAutoAnswer : ${enable}`);
        if (!this._modelData.autoAnswer)
            return;

        if (this._autoAnswer === enable)
            return;

        this._autoAnswer = enable;

        if (this._settingsItems) {
            this._settingsItems['auto-answer'] = enable;
            this._updateGsettings();
        }
    }

    _setAutoAnswer(enable) {
        this._redmiBudsSocket?.setAutoAnswer(enable);
    }

    updateLowLatency(enable) {
        this._log.info(`updateLowLatency : ${enable}`);
        if (!this._modelData.lowLatencyMode)
            return;

        if (this._lowLatency === enable)
            return;

        this._lowLatency = enable;

        if (this._settingsItems) {
            this._settingsItems['low-latency'] = enable;
            this._updateGsettings();
        }
    }

    _setLowLatency(enable) {
        this._redmiBudsSocket?.setLowLatency(enable);
    }

    updateGestureSingle(left, right) {
        this._log.info(`updateGestureSingle L : ${hexBytes(left)} R: ${hexBytes(right)}`);

        const gestureTypes = this._modelData.gestureOptions?.gestureTypes;
        if (gestureTypes.single === undefined)
            return;

        let update = false;
        if (this._gestureSingleLeft !== left) {
            update = true;
            this._gestureSingleLeft = left;
            this._settingsItems['single-left'] = left;
        }

        if (this._gestureSingleRight !== right) {
            update = true;

            this._gestureSingleRight = right;
            this._settingsItems['single-right'] = right;
        }
        if (update)
            this._updateGsettings();
    }

    updateGestureDouble(left, right) {
        this._log.info(`updateGestureDouble L : ${hexBytes(left)} R: ${hexBytes(right)}`);

        const gestureTypes = this._modelData.gestureOptions?.gestureTypes;
        if (gestureTypes.double === undefined)
            return;

        let update = false;

        if (this._gestureDoubleLeft !== left) {
            update = true;
            this._gestureDoubleLeft = left;
            this._settingsItems['double-left'] = left;
        }

        if (this._gestureDoubleRight !== right) {
            update = true;
            this._gestureDoubleRight = right;
            this._settingsItems['double-right'] = right;
        }

        if (update)
            this._updateGsettings();
    }

    updateGestureTriple(left, right) {
        this._log.info(`updateGestureTriple L : ${hexBytes(left)} R: ${hexBytes(right)}`);

        const gestureTypes = this._modelData.gestureOptions?.gestureTypes;
        if (gestureTypes.triple === undefined)
            return;

        let update = false;

        if (this._gestureTripleLeft !== left) {
            update = true;
            this._gestureTripleLeft = left;
            this._settingsItems['triple-left'] = left;
        }

        if (this._gestureTripleRight !== right) {
            update = true;
            this._gestureTripleRight = right;
            this._settingsItems['triple-right'] = right;
        }

        if (update)
            this._updateGsettings();
    }

    updateGestureLong(left, right) {
        this._log.info(`updateGestureLong L : ${hexBytes(left)} R: ${hexBytes(right)}`);

        const gestureTypes = this._modelData.gestureOptions?.gestureTypes;
        if (gestureTypes['action-hold'] === undefined)
            return;

        let update = false;

        if (this._gestureLongLeft !== left) {
            update = true;
            this._gestureLongLeft = left;
            this._settingsItems['action-hold-left'] = left;
        }

        if (this._gestureLongRight !== right) {
            update = true;
            this._gestureLongRight = right;
            this._settingsItems['action-hold-right'] = right;
        }

        if (update)
            this._updateGsettings();
    }

    updateGestureSwipe(left, right) {
        this._log.info(`updateGestureSwipe L : ${hexBytes(left)} R: ${hexBytes(right)}`);

        const gestureTypes = this._modelData.gestureOptions?.gestureTypes;
        if (gestureTypes.swipe === undefined)
            return;

        let update = false;

        if (this._gestureSwipeLeft !== left) {
            update = true;
            this._gestureSwipeLeft = left;
            this._settingsItems['swipe-left'] = left;
        }

        if (this._gestureSwipeRight !== right) {
            update = true;
            this._gestureSwipeRight = right;
            this._settingsItems['swipe-right'] = right;
        }

        if (update)
            this._updateGsettings();
    }

    _setGesture(type, position, value) {
        this._redmiBudsSocket?.setGesture(type, position, value);
    }

    updateLongGestures(leftPressMode, rightPressMode) {
        this._log.info(`updateLongGestures L: ${hexBytes(leftPressMode)}
            R: ${hexBytes(rightPressMode)}`);

        if (this._modelData.gestureOptions?.noiseControlModes === undefined)
            return;

        let update = false;

        if (this._leftLongpressMode !== leftPressMode) {
            update = true;
            this._leftLongpressMode = leftPressMode;
            this._settingsItems['left-longpress'] = leftPressMode;
        }

        if (this._rightLongpressMode !== rightPressMode) {
            update = true;
            this._rightLongpressMode = rightPressMode;
            this._settingsItems['right-longpress'] = rightPressMode;
        }

        if (update)
            this._updateGsettings();
    }

    _setLongPressMode(isleft, mode) {
        this._redmiBudsSocket?.setLongPressMode(isleft, mode);
    }

    _setRingMyBuds(state, isLeft = false) {
        this._redmiBudsSocket?.setRingMyBuds(state, isLeft);
    }

    _settingsButtonClicked() {
        this._configureWindowLauncherCancellable = new Gio.Cancellable();
        launchConfigureWindow(this._devicePath, 'redmiBuds', this._extPath,
            this._configureWindowLauncherCancellable);
        this._configureWindowLauncherCancellable = null;
    }

    destroy() {
        this._configureWindowLauncherCancellable?.cancel();
        this._configureWindowLauncherCancellable = null;

        this._redmiBudsSocket?.destroy();
        this._redmiBudsSocket = null;

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

