'use strict';
import Gio from 'gi://Gio';
import GObject from 'gi://GObject';
const _ = s => s; // gettext stub for daemon context

import {createLogger, getDeviceIdentifier} from '../logger.js';
import {
    buds2to1BatteryLevel, validateProperties, launchConfigureWindow, isArrayEqual
} from '../deviceUtils.js';
import {createConfig, createProperties, DataHandler} from '../../dataHandler.js';
import {NothingBudsSocket} from './nothingBudsSocket.js';

export const DeviceTypeNothingBuds = 'nothingBuds';

const NothingBudsUUID = 'aeac4a03-dff5-498f-843a-34487cf133eb';
export function isNothingBuds(bluezDeviceProxy, uuids) {
    const bluezProps = [];
    const supported = uuids.includes(NothingBudsUUID) ? 'yes' : 'no';
    return {supported, bluezProps};
}

export const NothingBudsDevice = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_NothingBudsDevice',
}, class NothingBudsDevice extends GObject.Object {
    _init(settings, devicePath, alias, extPath, profileManager, updateDeviceMapCb) {
        super._init();
        const identifier = getDeviceIdentifier(devicePath);
        const tag = `NothingBudsDevice-${identifier}`;
        this._log = createLogger(tag);
        this._log.info('------------------- NothingBudsDevice init -------------------');
        this._settings = settings;
        this._devicePath = devicePath;
        this._alias = alias;
        this._extPath = extPath;
        this.updateDeviceMapCb = updateDeviceMapCb;
        this._ignoreGsettingsChange = false;
        this._fwVersion = '';
        this._serialNo = '';

        this._config = createConfig();
        this._props = createProperties();
        this._modelData = null;

        this._callbacks = {
            modelIntialized: this.modelIntialized.bind(this),
            updateFirmwareInfo: this.updateFirmwareInfo.bind(this),
            updateSerial: this.updateSerial.bind(this),
            updateBatteryProps: this.updateBatteryProps.bind(this),
            updateNoiseControl: this.updateNoiseControl.bind(this),
            updatePersonalizedAnc: this.updatePersonalizedAnc.bind(this),
            updateEqPreset: this.updateEqPreset.bind(this),
            updateCustomEq: this.updateCustomEq.bind(this),
            updateEnhancedBass: this.updateEnhancedBass.bind(this),
            updateLatency: this.updateLatency.bind(this),
            updateInEar: this.updateInEar.bind(this),
            updateSpatialAudio: this.updateSpatialAudio.bind(this),
            updateGestures: this.updateGestures.bind(this),
        };

        const profile = {type: DeviceTypeNothingBuds, uuid: NothingBudsUUID};

        this._nothingBudsSocket = new NothingBudsSocket(
            this._devicePath,
            profileManager,
            profile,
            this._callbacks
        );
    }

    modelIntialized(modelData) {
        this._modelData = modelData;

        this._log.info(`Configuration: ${JSON.stringify(this._modelData, null, 2)}`);

        this._commonIcon = this._modelData.budsIcon;
        this._config.battery1ShowOnDisconnect = true;
        this._config.showSettingsButton = true;

        if (this._modelData.batteryCase)
            this._caseIcon = `${this._modelData.case}`;

        this._createDefaultSettings();

        const devicesList = this._settings.get_strv('nothing-buds-list').map(JSON.parse);

        if (devicesList.length === 0 ||
                !devicesList.some(device => device.path === this._devicePath)) {
            this._addPropsToSettings(devicesList);
        } else {
            validateProperties(this._settings, 'nothing-buds-list', devicesList,
                this._defaultsDeviceSettings, this._devicePath);
        }

        this._updateInitialValues();
        this._monitorNothingBudsListGsettings();
        this._updateIcons();
        this._updateAncConfig();

        if (this._modelData.ring) {
            this._ringState = 'stopped';
            this._settingsItems['ring-state'] = this._ringState;
            if (!this._modelData.ringLegacy && !this._modelData.batterySingle) {
                this._ringStateLeft = 'stopped';
                this._settingsItems['ring-state-left'] = this._ringStateLeft;
            }
            this._updateGsettings();
        }
    }

    _createDefaultSettings() {
        this._defaultsDeviceSettings = {
            path: this._devicePath,
            modelid: this._modelData.modelId,
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
                'eq-custom': [0, 0, 0],
            },

            ...this._modelData.bassEnhanceLevel && {
                'bass-enable': false,
                'bass-level': 1,
            },

            ...this._modelData.lowLatencyMode && {
                'lowlatency': false,
            },

            ...this._modelData.inEarDetection && {
                'inear-enable': false,
            },

            ...this._modelData.spatialAudioSwitch && {
                'spatial': false,
            },

            ...this._modelData.ring && {
                'ring-state': 'stopped',
                ...!this._modelData.ringLegacy && !this._modelData.batterySingle && {
                    'ring-state-left': 'stopped',
                },
            },

            ...this._modelData.gestureOptions && {
                'gestures': this._createDefaultGestures(),
            },
        };
    }

    _addPropsToSettings(devicesList) {
        devicesList.push(this._defaultsDeviceSettings);
        this._settings.set_strv('nothing-buds-list', devicesList.map(JSON.stringify));
    }

    _updateInitialValues() {
        const devicesList = this._settings.get_strv('nothing-buds-list').map(JSON.parse);
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

        if (this._modelData.bassEnhanceLevel) {
            this._bassEnabled = this._settingsItems['bass-enable'];
            this._bassLevel = this._settingsItems['bass-level'];
        }

        if (this._modelData.lowLatencyMode)
            this._lowlatency = this._settingsItems['lowlatency'];

        if (this._modelData.inEarDetection)
            this._inEar = this._settingsItems['inear-enable'];

        if (this._modelData.spatialAudioSwitch)
            this._spatialAudio = this._settingsItems['spatial'];

        if (this._modelData.ring) {
            this._ringState = 'stopped';
            if (!this._modelData.ringLegacy && !this._modelData.batterySingle)
                this._ringStateLeft = 'stopped';
        }

        if (this._modelData.gestureOptions)
            this._gestures = this._settingsItems['gestures'];
    }

    _updateGsettingsProps() {
        const devicesList = this._settings.get_strv('nothing-buds-list').map(JSON.parse);
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

        if (this._modelData.bassEnhanceLevel) {
            const bassEnabled = this._settingsItems['bass-enable'];
            const bassLevel = this._settingsItems['bass-level'];

            if (this._bassEnabled !== bassEnabled || this._bassLevel !== bassLevel) {
                this._bassEnabled = bassEnabled;
                this._bassLevel = bassLevel;
                this._setEnhancedBass(bassEnabled, bassLevel);
            }
        }

        if (this._modelData.lowLatencyMode) {
            const enable = this._settingsItems['lowlatency'];

            if (this._lowlatency !== enable) {
                this._lowlatency = enable;
                this._setLatency(enable);
            }
        }

        if (this._modelData.inEarDetection) {
            const enable = this._settingsItems['inear-enable'];

            if (this._inEar !== enable) {
                this._inEar = enable;
                this._setInEar(enable);
            }
        }

        if (this._modelData.spatialAudioSwitch) {
            const enable = this._settingsItems['spatial'];

            if (this._spatialAudio !== enable) {
                this._spatialAudio = enable;
                this._setSpatialAudio(enable);
            }
        }

        if (this._modelData.ring) {
            const state = this._settingsItems['ring-state'];
            if (this._ringState !== state) {
                this._ringState = state;
                this._setRingMyBuds(state);
            }

            if (!this._modelData.ringLegacy && !this._modelData.batterySingle) {
                const stateLeft = this._settingsItems['ring-state-left'];
                if (this._ringStateLeft !== stateLeft) {
                    this._ringStateLeft = stateLeft;
                    this._setRingMyBuds(stateLeft, true);
                }
            }
        }

        if (this._modelData.gestureOptions) {
            const newGestures = this._settingsItems['gestures'];

            if (!this._gestureSlotsEqual(this._gestures, newGestures)) {
                const oldGestures = this._gestures;
                this._gestures = newGestures;

                const diff = this._findGestureDiff(newGestures, oldGestures);
                if (diff)
                    this._setGesture(diff);
            }
        }
    }

    _monitorNothingBudsListGsettings() {
        this._settingsHandlerId = this._settings?.connect('changed::nothing-buds-list', () => {
            if (this._ignoreGsettingsChange)
                return;

            this._updateGsettingsProps();
        });
    }

    _updateGsettings() {
        this._ignoreGsettingsChange = true;

        const currentList = this._settings.get_strv('nothing-buds-list').map(JSON.parse);
        const index = currentList.findIndex(d => d.path === this._devicePath);

        if (index !== -1) {
            currentList[index] = this._settingsItems;
            this._settings.set_strv('nothing-buds-list', currentList.map(JSON.stringify));
        }

        this._ignoreGsettingsChange = false;
    }

    _updateIcons() {
        this._config.commonIcon = this._commonIcon;
        this._config.albumArtIcon = this._commonIcon;

        this._config.battery1ShowOnDisconnect = true;
        if (this._modelData.batteryLR) {
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
        const nc = this._modelData.noiseControl;
        if (!nc)
            return;

        let buttonIndex = 1;
        this._ancToggleMap = {};
        this._config.toggle1Title = _('Noise Control');

        const addToggle = (type, bytes, icon, name) => {
            this._config[`toggle1Button${buttonIndex}Icon`] = icon;
            this._config[`toggle1Button${buttonIndex}Name`] = name;
            this._ancToggleMap[buttonIndex] = {type, bytes};
            buttonIndex++;
        };

        if (nc.off)
            addToggle('off', [nc.off.byte], 'bbm-anc-off-symbolic', _('Off'));

        if (nc.transparency) {
            addToggle('transparency', [nc.transparency.byte],
                'bbm-transperancy-symbolic', _('Transparency'));
        }

        let hasNcLevel = false;
        if (nc.noiseCancellation) {
            let bytes = [];
            this._ancRadioMap = {};
            this._ancRadioReverse = {};

            if (nc.noiseCancellation.levels) {
                hasNcLevel = true;
                const levelOrder = ['low', 'mid', 'high', 'adaptive'];
                const levelsObj = nc.noiseCancellation.levels;
                const validLevels = levelOrder.filter(l => l in levelsObj);
                const labels = [];

                this._config.box1RadioTitle = _('Noise Cancellation Level');

                const levelNames = {
                    low: _('Low'),
                    mid: _('Mid'),
                    high: _('High'),
                    adaptive: _('Adaptive'),
                };

                validLevels.forEach((level, i) => {
                    const index = i + 1;
                    labels.push(levelNames[level]);
                    const byte = levelsObj[level];
                    bytes.push(byte);
                    this._ancRadioMap[index] = byte;
                    this._ancRadioReverse[byte] = index;
                });

                this._log.info(`ANC level labels: ${JSON.stringify(labels)}`);
                this._log.info(`ANC level bytes: ${JSON.stringify(bytes)}`);


                this._config.box1RadioButton = validLevels.map(l => levelNames[l]);
            } else if (nc.noiseCancellation.byte != null) {
                bytes = [nc.noiseCancellation.byte];
            }

            addToggle('noiseCancellation', bytes,
                'bbm-anc-on-symbolic', _('Noise Cancellation'));
        }

        if (hasNcLevel)
            this._config.optionsBox1.push('radio-button');

        if (this._modelData.personalizeAnc) {
            this._config.optionsBox1.push('check-button');
            this._config.box1CheckButton = [_('Personalised ANC')];
        }
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

                if (command === 'box1RadioButtonState')
                    this._box1RadioButtonStateChanged(value);

                if (command === 'settingsButtonClicked')
                    this._settingsButtonClicked();
            }
        );
    }

    updateFirmwareInfo(fwVersion) {
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


    updateBatteryProps(props) {
        this._props = {...this._props, ...props};

        if (!this._modelData.batteryLR)
            this._props.computedBatteryLevel = props.battery1Level;
        else
            this._props.computedBatteryLevel = buds2to1BatteryLevel(props);

        if (!this._battInfoRecieved)
            this._startConfiguration(props);

        this.dataHandler?.setProps(this._props);
    }

    updateNoiseControl(mode) {
        if (!this._ancToggleMap)
            return;

        const nc = this._modelData.noiseControl;
        let toggleIndex = 0;
        let isNcMode = false;

        for (const [index, {bytes}] of Object.entries(this._ancToggleMap)) {
            if (bytes.includes(mode)) {
                toggleIndex = Number(index);
                if (this._ancToggleMap[toggleIndex]?.type === 'noiseCancellation')
                    isNcMode = true;
                break;
            }
        }

        this._props.toggle1State = toggleIndex;

        if (isNcMode && this._ancRadioReverse && this._ancRadioReverse[mode])
            this._props.box1RadioButtonState = this._ancRadioReverse[mode];

        if (isNcMode && (nc?.noiseCancellation?.levels || this._modelData.personalizeAnc))
            this._props.optionsBoxVisible = 1;
        else
            this._props.optionsBoxVisible = 0;

        this.dataHandler?.setProps(this._props);
    }

    _toggle1ButtonClicked(index) {
        if (!this._ancToggleMap)
            return;

        let ancMode = null;
        const toggle = this._ancToggleMap[index];
        if (!toggle)
            return;

        this._props.toggle1State = index;

        if (toggle.type === 'noiseCancellation') {
            const boxVisible = toggle.bytes.length > 1 || this._modelData.personalizeAnc;
            this._props.optionsBoxVisible = boxVisible ? 1 : 0;

            if (toggle.bytes.length > 1) {
                const radioIndex = this._props.box1RadioButtonState;
                let byte = this._ancRadioMap[radioIndex];
                if (byte == null) {
                    const levels = this._modelData.noiseControl.noiseCancellation.levels;
                    const lastLevelKey = Object.keys(levels).pop();
                    byte = levels[lastLevelKey];
                    this._props.box1RadioButtonState = this._ancRadioReverse[byte];
                }
                ancMode = byte;
            } else {
                ancMode = toggle.bytes[0];
            }
        } else {
            this._props.optionsBoxVisible = 0;
            ancMode = toggle.bytes[0];
        }

        this.dataHandler?.setProps(this._props);

        if (ancMode != null)
            this._nothingBudsSocket?.setNoiseControl(ancMode);
    }

    _box1RadioButtonStateChanged(index) {
        if (!this._ancRadioMap)
            return;

        this._props.box1RadioButtonState = index;
        this.dataHandler?.setProps(this._props);

        const byte = this._ancRadioMap[index];
        if (byte != null)
            this._nothingBudsSocket?.setNoiseControl(byte);
    }

    _box1CheckButton1StateChanged(state) {
        if (!this._modelData.personalizeAnc)
            return;

        this._nothingBudsSocket?.setPersonalizedAnc(state);
    }

    updatePersonalizedAnc(state) {
        if (this._props.box1CheckButton1State === state)
            return;

        this._props.box1CheckButton1State = state;
        this.dataHandler?.setProps(this._props);
    }

    updateEqPreset(mode) {
        if (this._eqPreset === mode)
            return;

        this._eqPreset = mode;

        if (this._settingsItems) {
            this._settingsItems['eq-preset'] = mode;
            this._updateGsettings();
        }
    }

    _setEqPreset(mode) {
        if (!this._modelData.eqPreset)
            return;

        this._nothingBudsSocket?.setEqPreset(mode);
    }

    updateCustomEq(eqArray) {
        if (isArrayEqual(this._customEq, eqArray))
            return;

        this._customEq = eqArray;

        if (this._settingsItems) {
            this._settingsItems['eq-custom'] = eqArray;
            this._updateGsettings();
        }
    }

    _setCustomEq(eqArray) {
        this._nothingBudsSocket?.setCustomEq(eqArray);
    }

    updateEnhancedBass(enable, level) {
        const enableChanged = this._bassEnabled !== enable;
        const levelChanged  = this._bassLevel !== level;

        if (!enableChanged && !levelChanged)
            return;

        this._bassEnabled = enable;
        this._bassLevel = level;

        if (this._settingsItems) {
            if (enableChanged)
                this._settingsItems['bass-enable'] = enable;

            if (levelChanged)
                this._settingsItems['bass-level'] = level;

            this._updateGsettings();
        }
    }

    _setEnhancedBass(enable, level) {
        this._nothingBudsSocket?.setEnhancedBass(enable, level);
    }

    updateLatency(enable) {
        this._lowlatency = enable;

        if (this._settingsItems) {
            this._settingsItems['lowlatency'] = enable;
            this._updateGsettings();
        }
    }

    _setLatency(enable) {
        this._nothingBudsSocket?.setLatency(enable);
    }

    updateInEar(enable) {
        if (this._inEar === enable)
            return;

        this._inEar = enable;

        if (this._settingsItems) {
            this._settingsItems['inear-enable'] = enable;
            this._updateGsettings();
        }
    }

    _setInEar(enable) {
        this._nothingBudsSocket?.setInEar(enable);
    }

    updateSpatialAudio(enable) {
        if (this._spatialAudio === enable)
            return;

        this._spatialAudio = enable;

        if (this._settingsItems) {
            this._settingsItems['spatial'] = enable;
            this._updateGsettings();
        }
    }

    _setSpatialAudio(enable) {
        this._nothingBudsSocket?.setSpatialAudio(enable);
    }

    _createDefaultGestures() {
        const opts = this._modelData.gestureOptions;
        const hex = opts?.default;
        if (!hex)
            return [];

        const bytes = [];

        for (let i = 0; i < hex.length; i += 2)
            bytes.push(parseInt(hex.substr(i, 2), 16));

        const count = bytes[0];
        const slots = [];

        let offset = 1;
        for (let i = 0; i < count; i++) {
            if (offset + 4 > bytes.length)
                break;

            slots.push({
                device: bytes[offset],
                buttonId: bytes[offset + 1],
                type: bytes[offset + 2],
                action: bytes[offset + 3],
            });

            offset += 4;
        }

        return slots;
    }

    _isValidGestureSlot(slot) {
        const opts = this._modelData.gestureOptions;
        if (!opts)
            return false;

        const {slots, mapping, gestures} = opts;

        const slotDef = slots.find(s =>
            s.device === slot.device &&
            s.buttonId === slot.buttonId &&
            mapping.gestureTypes[s.type] === slot.type
        );

        if (!slotDef) {
            this._log.info(
                `Unsupported slot device=${slot.device} button=${slot.buttonId} type=${slot.type}`
            );
            return false;
        }

        const gestureKey = Object.entries(mapping.gestureTypes)
            .find(([, v]) => v === slot.type)?.[0];

        if (!gestureKey || !gestures[gestureKey]) {
            this._log.info(`Unsupported gesture type byte: ${slot.type}`);
            return false;
        }

        const actionKey = Object.entries(mapping.actions)
            .find(([, values]) => values.includes(slot.action))?.[0];

        if (!actionKey) {
            this._log.info(`Unsupported action byte: ${slot.action}`);
            return false;
        }

        if (!gestures[gestureKey].actions.includes(actionKey)) {
            this._log.info(
                `Action '${actionKey}' not allowed for gesture '${gestureKey}'`
            );
            return false;
        }

        return true;
    }

    _gestureSlotsEqual(a = [], b = []) {
        if (a.length !== b.length)
            return false;

        const areEqual = a.every((slot, index) => {
            const other = b[index];

            const sameDevice = slot.device === other.device;
            const sameButton = slot.buttonId === other.buttonId;
            const sameType   = slot.type === other.type;
            const sameAction = slot.action === other.action;

            return sameDevice && sameButton && sameType && sameAction;
        });

        return areEqual;
    }

    _findGestureDiff(newSlots, oldSlots) {
        for (let i = 0; i < newSlots.length; i++) {
            const old = oldSlots[i];
            const cur = newSlots[i];

            if (!old || old.device !== cur.device || old.buttonId !== cur.buttonId ||
                    old.type !== cur.type || old.action !== cur.action)
                return cur;
        }
        return null;
    }

    updateGestures(slots) {
        const validSlots = [];

        for (const slot of slots) {
            if (this._isValidGestureSlot(slot))
                validSlots.push(slot);
        }

        this._gestures = validSlots;

        if (this._settingsItems) {
            this._settingsItems['gestures'] = validSlots;
            this._updateGsettings();
        }
    }

    _setGesture(slot) {
        this._nothingBudsSocket?.setGesture(slot);
    }

    _setRingMyBuds(state, isLeft = false) {
        this._nothingBudsSocket?.setRingMyBuds(state, isLeft);
    }

    _settingsButtonClicked() {
        this._configureWindowLauncherCancellable = new Gio.Cancellable();
        launchConfigureWindow(this._devicePath, 'nothingBuds', this._extPath,
            this._configureWindowLauncherCancellable);
        this._configureWindowLauncherCancellable = null;
    }

    destroy() {
        this._configureWindowLauncherCancellable?.cancel();
        this._configureWindowLauncherCancellable = null;

        this._nothingBudsSocket?.destroy();
        this._nothingBudsSocket = null;

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

