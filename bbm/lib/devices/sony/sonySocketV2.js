'use strict';
import GObject from 'gi://GObject';

import {createLogger, getDeviceIdentifier} from '../logger.js';
import {SonySocketBase} from './sonySocketBase.js';
import {isValidByte, booleanFromByte} from '../deviceUtils.js';

import {
    MessageType, PayloadTypeV2T1 as PTV2T1, FunctionTypeV2T1, PayloadTypeV2T2 as PTV2T2,
    ValueType, BatteryType, AudioCodec, DseeType, BatteryStatus, AmbientSoundMode,
    AutoAsmSensitivity, AsmType, Speak2ChatSensitivity, Speak2ChatTimeout, EqualizerPreset,
    ListeningMode, BgmDistance, AutoPowerOffState, AutoPowerOffTime, AmbientButtonMode,
    ButtonModes, EqInquiryType, FunctionTypeV2T2, ConnectionType
} from './sonyConfig.js';

/**
Sony module for Bluetooth battery meter service to provide,
battery information, ANC and Convesational awareness on device that support it.

Reference and Credits: for V1
https://codeberg.org/Freeyourgadget/Gadgetbridge

https://github.com/mos9527/SonyHeadphonesClient

https://github.com/andreasolofsson/MDR-protocol
**/
export const SonySocketV2 = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_SonySocketV2',
}, class SonySocketV2 extends SonySocketBase {
    _init(devicePath, profileManager, profile, modelData, callbacks) {
        super._init(devicePath, profileManager, profile);
        const identifier = getDeviceIdentifier(devicePath);
        const tag = `SonySocketV2-${identifier}`;
        this._log = createLogger(tag);
        this._log.info('SonySocketV2 init');
        this._supportedFunction = [];
        this._callbacks = callbacks;

        this._asmType = null;
        this._connectionType = null;
        this._battProps = {
            battery1Level: 0,
            battery1Status: '',
            battery2Level: 0,
            battery2Status: '',
            battery3Level: 0,
            battery3Status: '',
        };

        this._batteryDualSupported = modelData.batteryDual ?? false;
        this._batteryDual2Supported = modelData.batteryDual2 ?? false;
        this._batteryCaseSupported = modelData.batteryCase ?? false;
        this._batterySingleSupported = modelData.batterySingle ?? false;
        this._noNoiseCancellingSupported = modelData.noNoiseCancelling ?? false;
        this._ambientSoundControlSupported = modelData.ambientSoundControl ?? false;
        this._ambientSoundControlNASupported = modelData.ambientSoundControlNA ?? false;
        this._windNoiseReductionSupported = modelData.windNoiseReduction ?? false;
        this._ambientSoundControlButtonMode = modelData.ambientSoundControlButtonMode ?? false;
        this._speakToChatEnabledSupported = modelData.speakToChatEnabled ?? false;
        this._speakToChatConfigSupported = modelData.speakToChatConfig ?? false;
        this._speakToChatFocusOnVoiceSupported = modelData.speakToChatFocusOnVoice ?? false;
        this._pauseWhenTakenOffSupported = modelData.pauseWhenTakenOff ?? false;
        this._listeningModeSupported = modelData.listeningMode ?? false;
        this._equalizerSixBands = modelData.equalizerSixBands ?? false;
        this._equalizerTenBands = modelData.equalizerTenBands ?? false;
        this._voiceNotifications = modelData.voiceNotifications ?? false;
        this._voiceNotificationsVolume = modelData.voiceNotificationsVolume ?? false;
        this._audioUpsamplingSupported = modelData.audioUpsampling ?? false;
        this._automaticPowerOffWhenTakenOff = modelData.automaticPowerOffWhenTakenOff ?? false;
        this._automaticPowerOffByTime = modelData.automaticPowerOffByTime ?? false;
        this._buttonModesLeftRight = modelData.buttonModesLeftRight?.length > 0;
        this._dualConnection = modelData.dualConnection ?? false;
        this._hasRoutingIndicator = modelData.dualConnection?.hasRoutingIndicator ?? false;
        this._hasRoutingControl = modelData.dualConnection?.hasRoutingControl ?? false;
        this._hasActiveFix = modelData.dualConnection?.hasActiveFix ?? false;

        this._bgmProps = {active: false, distance: 0, mode: ListeningMode.STANDARD};

        this.startSocket();
    }

    _supports(funcType) {
        return this._supportedFunction?.includes(funcType);
    }

    _supportsV2(funcType) {
        return this._supportedFunctionV2?.includes(funcType);
    }

    _getProtocolInfo() {
        this._log.info('GET ProtocolInfo');

        const payload = [PTV2T1.CONNECT_GET_PROTOCOL_INFO, ValueType.FIXED];
        this.addMessageQueue(MessageType.COMMAND_1, payload, 'GetProtocolInfo');
    }

    _parseProtocolInfo(payload) {
        if (payload.length < 5)
            return;

        this._log.info('PARSE ProtocolInfo');

        const protocolVersionLE =
        payload[1] |
        payload[2] << 8 |
        payload[3] << 16 |
        payload[4] << 24;

        const protocolVersion =
        protocolVersionLE >> 24 & 0xFF |
        protocolVersionLE >> 8 & 0xFF00 |
        protocolVersionLE << 8 & 0xFF0000 |
        protocolVersionLE << 24 & 0xFF000000;

        const protocolMajor = protocolVersion >> 16 & 0xFFFF;
        const protocolMinor = protocolVersion & 0xFFFF;

        this._log.info(`Protocol Version: ${protocolMajor}.${protocolMinor}`);
    }

    _getDeviceInfoFirmware() {
        this._log.info('GET DeviceInfoFirmware');

        const payload = [PTV2T1.CONNECT_GET_DEVICE_INFO, ValueType.FW_VERSION];
        this.addMessageQueue(MessageType.COMMAND_1, payload, 'GetDeviceInfoFirmware');
    }

    _parseDeviceInfoFirmware(payload) {
        if (payload.length < 3)
            return;

        const len = payload[2];

        if (payload.length < 3 + len)
            return;

        const fwBytes = payload.slice(3, 3 + len);
        const fwVersion = new TextDecoder().decode(new Uint8Array(fwBytes));

        this._log.info('Device Firmware Version:', fwVersion);
        this._callbacks?.updateFirmwareVersion?.(fwVersion);
    }

    _getSupportInfo() {
        this._log.info('GET SupportInfo:');

        const payload = [PTV2T1.CONNECT_GET_SUPPORT_FUNCTION, ValueType.FIXED];
        this.addMessageQueue(MessageType.COMMAND_1, payload, 'GetSupportInfo');
    }

    _parseSupportFunctionInfo(payload) {
        if (payload.length < 3)
            return;

        this._log.info('PARSE SupportFunctionInfo');

        const numFunctions = payload[2];
        const requiredLen = 3 + numFunctions * 2;

        if (payload.length < requiredLen)
            return;


        const funcMap = Object.entries(FunctionTypeV2T1).reduce((acc, [name, value]) => {
            acc[value] = name;
            return acc;
        }, {});

        const availableFunctions = [];
        const supportedFunctionIds = [];

        for (let i = 0; i < numFunctions; i++) {
            const funcId = payload[3 + i * 2];
            const priority = payload[3 + i * 2 + 1];
            const funcName = funcMap[funcId] ?? `Unknown_0x${funcId.toString(16).padStart(2, '0')}`;
            availableFunctions.push(`${funcName} (priority=${priority})`);
            supportedFunctionIds.push(funcId);
        }

        this._supportedFunction = supportedFunctionIds;

        if (availableFunctions.length > 0)
            this._log.info(`Support Functions:\n${availableFunctions.join('\n')}`);
        else
            this._log.info('No supported functions found.');
    }

    _getSupportInfoV2() {
        this._log.info('GET SupportInfoV2:');

        const payload = [PTV2T2.CONNECT_GET_SUPPORT_FUNCTION, ValueType.FIXED];
        this.addMessageQueue(MessageType.COMMAND_2, payload, 'SupportInfoV2');
    }

    _parseSupportFunctionInfoV2(payload) {
        if (payload.length < 3)
            return;

        this._log.info('PARSE SupportFunctionInfoV2');

        const numFunctions = payload[2];
        const requiredLen = 3 + numFunctions * 2;

        if (payload.length < requiredLen)
            return;


        const funcMap = Object.entries(FunctionTypeV2T2).reduce((acc, [name, value]) => {
            acc[value] = name;
            return acc;
        }, {});

        const availableFunctions = [];
        const supportedFunctionIds = [];

        for (let i = 0; i < numFunctions; i++) {
            const funcId = payload[3 + i * 2];
            const priority = payload[3 + i * 2 + 1];
            const funcName = funcMap[funcId] ?? `Unknown_0x${funcId.toString(16).padStart(2, '0')}`;
            availableFunctions.push(`${funcName} (priority=${priority})`);
            supportedFunctionIds.push(funcId);
        }

        this._supportedFunctionV2 = supportedFunctionIds;

        if (availableFunctions.length > 0)
            this._log.info(`Support Functions:\n${availableFunctions.join('\n')}`);
        else
            this._log.info('No supported functions found.');
    }

    _getSingleThdBatteryRequest() {
        this._log.info('GET BatteryTypeSingleThd:');

        const payload = [PTV2T1.POWER_GET_STATUS, BatteryType.SINGLE_THD];
        const ackType = 'GetBatteryTypeSingleThd';
        this.pendingRequestQueue?.push(ackType);
        this.addMessageQueue(MessageType.COMMAND_1, payload, ackType);
    }

    _getSingleBatteryRequest() {
        this._log.info('GET GetBatteryTypeSingle:');

        const payload = [PTV2T1.POWER_GET_STATUS, BatteryType.SINGLE];
        const ackType = 'GetBatteryTypeSingle';
        this.pendingRequestQueue?.push(ackType);
        this.addMessageQueue(MessageType.COMMAND_1, payload, ackType);
    }

    _getDualThdBatteryRequest() {
        this._log.info('GET BatteryTypeDualThd:');

        const payload = [PTV2T1.POWER_GET_STATUS, BatteryType.DUAL_THD];
        const ackType = 'GetBatteryTypeDualThd';
        this.pendingRequestQueue?.push(ackType);
        this.addMessageQueue(MessageType.COMMAND_1, payload, ackType);
    }

    _getDualBatteryRequest() {
        this._log.info('GET BatteryTypeDual:');

        const payload = [PTV2T1.POWER_GET_STATUS, BatteryType.DUAL];
        const ackType = 'GetBatteryTypeDual';
        this.pendingRequestQueue?.push(ackType);
        this.addMessageQueue(MessageType.COMMAND_1, payload, ackType);
    }

    _getCaseThdBatteryRequest() {
        this._log.info('GET BatteryTypeCaseThd:');

        const payload = [PTV2T1.POWER_GET_STATUS, BatteryType.CASE_THD];
        const ackType = 'GetBatteryTypeCaseThd';
        this.pendingRequestQueue?.push(ackType);
        this.addMessageQueue(MessageType.COMMAND_1, payload, ackType);
    }

    _getCaseBatteryRequest() {
        this._log.info('GET BatteryTypeCase:');

        const payload = [PTV2T1.POWER_GET_STATUS, BatteryType.CASE];
        const ackType = 'GetBatteryTypeCase';
        this.pendingRequestQueue?.push(ackType);
        this.addMessageQueue(MessageType.COMMAND_1, payload, ackType);
    }

    _parseBatteryStatus(payload) {
        if (payload.length < 4)
            return;

        this._log.info(`PARSE BatteryStatus payload.length = ${payload.length}`);

        const type = payload[1];
        if (!Object.values(BatteryType).includes(type))
            return;

        const getStatus = state => {
            if (state === BatteryStatus.CHARGING || state === BatteryStatus.CHARGED)
                return 'charging';
            else
                return 'discharging';
        };

        if (type === BatteryType.SINGLE || type === BatteryType.CASE ||
            type === BatteryType.SINGLE_THD || type === BatteryType.CASE_THD) {
            const level = Math.max(0, Math.min(payload[2], 100));

            if (type === BatteryType.CASE || type === BatteryType.CASE_THD) {
                this._battProps.battery3Level = level;
                this._battProps.battery3Status = getStatus(payload[3]);
            } else {
                this._battProps.battery1Level = level;
                this._battProps.battery1Status = getStatus(payload[3]);
            }
        } else if (type === BatteryType.DUAL || type === BatteryType.DUAL_THD) {
            if (payload[2] > 0) {
                const level = Math.max(0, Math.min(payload[2], 100));
                this._battProps.battery1Level = level;
                this._battProps.battery1Status = getStatus(payload[3]);
            }

            if (payload[4] > 0) {
                const level = Math.max(0, Math.min(payload[4], 100));
                this._battProps.battery2Level = level;
                this._battProps.battery2Status = getStatus(payload[5]);
            }
        } else {
            return;
        }

        this._callbacks?.updateBatteryProps?.(this._battProps);
    }


    _getAmbientSoundControl() {
        this._log.info('GET AmbientSoundControl:');

        const payload = [PTV2T1.NCASM_GET_PARAM, this._asmType];
        const ackType = 'GetAmbientControl';
        this.pendingRequestQueue?.push(ackType);
        this.addMessageQueue(MessageType.COMMAND_1, payload, ackType);
    }

    _parseAmbientSoundControl(payload) {
        if (payload.length < 6 || payload.length > 9)
            return;

        this._log.info('PARSE AmbientSoundControl');

        const idx = payload[1];

        if (idx !== this._asmType) {
            this._log.info('ERROR: Asm Type mismatch');
            return;
        }

        const noNc = this._asmType === AsmType.ASM_SEAMLESS || this._asmType === AsmType.ASM_ON_OFF;

        const includesWind =
            this._asmType === AsmType.MODE_NC_ASM_AUTO_NC_MODE_SWITCH_AND_ASM_SEAMLESS;

        const autoAmbientType =
             this._asmType === AsmType.MODE_NC_ASM_DUAL_NC_MODE_SWITCH_AND_ASM_SEAMLESS_NA;

        let mode;
        if (payload[3] === 0x00) {
            mode = AmbientSoundMode.ANC_OFF;
        } else {
            if (includesWind) {
                const sub = payload[5];
                if (sub === 0x03 || sub === 0x05) {
                    mode = AmbientSoundMode.WIND;
                } else if (sub === 0x02) {
                    mode = payload[4] === 0x00
                        ? AmbientSoundMode.ANC_ON
                        : AmbientSoundMode.AMBIENT;
                }
            } else if (noNc) {
                mode = AmbientSoundMode.AMBIENT;
            } else {
                mode = payload[4] === 0x00
                    ? AmbientSoundMode.ANC_ON
                    : AmbientSoundMode.AMBIENT;
            }
            if (mode === null)
                return;
        }

        let i = payload.length - (autoAmbientType ? 4 : 2);
        const focusOnVoiceState = payload[i] === 0x01;

        i++;
        const level = payload[i];
        const ambientSoundLevel = level >= 0 && level <= 20 ? level : 10;
        let autoAmbient = false;
        let sensitivity = AutoAsmSensitivity.STANDARD;

        if (autoAmbientType) {
            i++;
            const val = payload[i];
            if (val === 0x00 || val === 0x01)
                autoAmbient = val === 0x01;

            i++;
            const autoAmbientSensitivity = payload[i];
            if (isValidByte(autoAmbientSensitivity, AutoAsmSensitivity))
                sensitivity = autoAmbientSensitivity;
        }

        this._callbacks?.updateAmbientSoundControl?.(mode, focusOnVoiceState,
            ambientSoundLevel, autoAmbient, sensitivity);
    }

    setAmbientSoundControl(mode, focusOnVoice, level, autoAmbient, sensitivity) {
        this._log.info(
            `SET AmbientSoundControl: Mode: ${mode} Voice: ${focusOnVoice} ` +
                `Level: ${level} AutoAmbient: ${autoAmbient} Sensitivity: ${sensitivity}`);

        if (!this._asmType) {
            this._log.info('ERROR: No supported NC/ASM mode found');
            return;
        }

        const noNc = this._asmType === AsmType.ASM_SEAMLESS || this._asmType === AsmType.ASM_ON_OFF;

        const includesWind =
            this._asmType === AsmType.MODE_NC_ASM_AUTO_NC_MODE_SWITCH_AND_ASM_SEAMLESS;

        const autoAmbientType =
             this._asmType === AsmType.MODE_NC_ASM_DUAL_NC_MODE_SWITCH_AND_ASM_SEAMLESS_NA;

        const payload = [PTV2T1.NCASM_SET_PARAM];
        payload.push(this._asmType);
        payload.push(0x01);
        payload.push(mode === AmbientSoundMode.ANC_OFF ? 0x00 : 0x01);

        if (!noNc)
            payload.push(mode === AmbientSoundMode.AMBIENT ? 0x01 : 0x00);

        if (includesWind)
            payload.push(mode === AmbientSoundMode.WIND ? 0x03 : 0x02);

        payload.push(focusOnVoice ? 0x01 : 0x00);
        payload.push(Math.max(1, level));

        if (autoAmbientType) {
            payload.push(autoAmbient ? 0x01 : 0x00);
            payload.push(sensitivity);
        }
        this.addMessageQueue(MessageType.COMMAND_1, payload, 'SetAmbientSoundControl');
    }

    _getSpeakToChatEnabled() {
        this._log.info('GET SpeakToChatEnabled');

        const payload = [PTV2T1.SYSTEM_GET_PARAM];
        payload.push(0x0C);
        const ackType = 'GetSpeakToChatEnable';
        this.pendingRequestQueue?.push(ackType);
        this.addMessageQueue(MessageType.COMMAND_1, payload, ackType);
    }

    _parseSpeakToChatEnable(payload) {
        if (payload.length !== 4)
            return;

        this._log.info('PARSE SpeakToChatEnable');

        const disable = booleanFromByte(payload[2]);
        if (disable === null)
            return;

        this._callbacks?.updateSpeakToChatEnable?.(!disable);
    }

    setSpeakToChatEnabled(enabled) {
        this._log.info(`SET SpeakToChatEnabled: ${enabled}`);

        const payload = [PTV2T1.SYSTEM_SET_PARAM];
        payload.push(0x0C);
        payload.push(enabled ? 0x00 : 0x01);
        payload.push(0x01);
        this.addMessageQueue(MessageType.COMMAND_1, payload, 'SetSpeakToChatEnabled');
    }

    _getSpeakToChatConfig() {
        this._log.info('GET SpeakToChatConfig');

        const payload = [PTV2T1.SYSTEM_GET_EXT_PARAM];
        payload.push(0x0C);
        const ackType = 'GetSpeakToChatConfig';
        this.pendingRequestQueue?.push(ackType);
        this.addMessageQueue(MessageType.COMMAND_1, payload, ackType);
    }

    _parseSpeakToChatConfig(payload) {
        if (payload.length < 4)
            return;

        this._log.info('PARSE SpeakToChatConfig');

        const sensCode = payload[2];
        if (!isValidByte(sensCode, Speak2ChatSensitivity))
            return;

        const timeoutCode = payload[3];
        if (!isValidByte(timeoutCode, Speak2ChatTimeout))
            return;

        this._speak2ChatSensitivity = sensCode;
        this._speak2ChatTimeout = timeoutCode;

        this._callbacks?.updateSpeakToChatConfig?.(
            this._speak2ChatSensitivity,
            this._speak2ChatTimeout
        );
    }

    setSpeakToChatConfig(sensitivity, timeout) {
        this._log.info(`SET SpeakToChatConfig: Sensitivity=${sensitivity}, Timeout=${timeout}`);

        const payload = [PTV2T1.SYSTEM_SET_EXT_PARAM];
        payload.push(0x0C);
        payload.push(sensitivity);
        payload.push(timeout);
        this.addMessageQueue(MessageType.COMMAND_1, payload, 'SetSpeakToChatConfig');
    }

    _getListeningMode() {
        this._log.info('GET ListeningMode:');

        const payloadBgm = [PTV2T1.AUDIO_GET_PARAM, 0x03];
        this.pendingRequestQueue?.push('GetListeningModeBgm');
        this.addMessageQueue(MessageType.COMMAND_1, payloadBgm, 'GetListeningModeBgm');

        const payloadNonBgm = [PTV2T1.AUDIO_GET_PARAM, 0x04];
        this.pendingRequestQueue?.push('GetListeningModeCinema');
        this.addMessageQueue(MessageType.COMMAND_1, payloadNonBgm, 'GetListeningModeCinema');
    }

    _parseBgmMode(payload) {
        if (payload.length < 4)
            return;

        this._log.info(`PARSE BgmMode: payload.length = ${payload.length}`);

        const disable = booleanFromByte(payload[2]);
        if (disable === null)
            return;

        const bgmDistanceMode = payload[3];
        if (!isValidByte(bgmDistanceMode, BgmDistance))
            return;

        this._callbacks?.updateBgmMode?.(!disable, bgmDistanceMode);
    }

    _parseCinemaMode(payload) {
        if (payload.length < 3)
            return;

        this._log.info(`PARSE CinemaMode: payload.length = ${payload.length}`);

        const disable = booleanFromByte(payload[2]);
        if (disable === null)
            return;

        this._callbacks?.updateCinemaMode?.(!disable);
    }

    setListeningMode(mode, distance) {
        const payload = [PTV2T1.AUDIO_SET_PARAM];
        if (mode === ListeningMode.BGM || mode === ListeningMode.STANDARD) {
            const bgmActive = mode === ListeningMode.BGM;
            payload.push(0x03);
            payload.push(bgmActive ? 0x00 : 0x01);
            payload.push(distance);
            this.addMessageQueue(MessageType.COMMAND_1, payload, 'SetBgmMode');
        } else {
            payload.push(0x04);
            payload.push(0x00);
            this.addMessageQueue(MessageType.COMMAND_1, payload, 'SetCinemaMode');
        }
    }

    _getEqualizer() {
        this._log.info('GET Equalizer');

        const payload = [PTV2T1.EQEBB_GET_PARAM];
        payload.push(this._eqInquiryType);
        const ackType = 'GetEqualizer';
        this.pendingRequestQueue?.push(ackType);
        this.addMessageQueue(MessageType.COMMAND_1, payload, ackType);
    }

    _parseEqualizer(payload) {
        if (this._equalizerTenBands && payload.length < 14 ||
                this._equalizerSixBands && payload.length < 10)
            return;

        this._log.info('PARSE Equalizer');

        const presetCode = payload[2];
        if (!isValidByte(presetCode, EqualizerPreset))
            return;

        const customBands = [];
        if (this._equalizerTenBands && payload[3] === 0x0A) {
            for (let i = 0; i < 10; i++)
                customBands.push(payload[4 + i] - 6);
        } else if (this._equalizerSixBands && payload[3] === 0x06) {
            for (let i = 0; i < 6; i++)
                customBands.push(payload[4 + i] - 10);
        } else {
            return;
        }

        this._callbacks?.updateEqualizer?.(presetCode, customBands);
    }

    setEqualizerPreset(presetCode) {
        this._log.info(`SET EqualizerPreset: PresetCode=${presetCode}`);

        if (!isValidByte(presetCode, EqualizerPreset))
            return;

        const payload = [PTV2T1.EQEBB_SET_PARAM];
        payload.push(this._eqInquiryType);
        payload.push(presetCode);
        payload.push(0x00);
        this.addMessageQueue(MessageType.COMMAND_1, payload, 'SetEqualizerPreset');
    }

    setEqualizer(presetCode, customBands) {
        this._log.info(
            `SET EqualizerCustomBands: Preset: ${presetCode} CustomBands=${customBands}`);

        const payload = [PTV2T1.EQEBB_SET_PARAM];
        payload.push(this._eqInquiryType);
        payload.push(presetCode);
        payload.push(this._equalizerTenBands ? 0x0A : 0x06);

        const bandCount = this._equalizerTenBands ? 10 : 6;
        const levelCompensator = this._equalizerTenBands ? 6 : 10;

        if (customBands.length !== bandCount) {
            this._log.info('setEqualizerCustomBands: invalid length');
            return;
        }

        for (let i = 0; i < bandCount; i++)
            payload.push(customBands[i] + levelCompensator);

        this.addMessageQueue(MessageType.COMMAND_1, payload, 'SetEqualizer');
    }

    _getAudioUpsampling() {
        this._log.info('GET AudioUpsampling');

        const payload = [PTV2T1.AUDIO_GET_PARAM];
        payload.push(0x01);
        const ackType = 'GetAudioUpsampling';
        this.pendingRequestQueue?.push(ackType);
        this.addMessageQueue(MessageType.COMMAND_1, payload, ackType);
    }

    _parseAudioUpsampling(payload) {
        if (payload.length !== 3)
            return;

        this._log.info('PARSE AudioUpsampling');

        const enabled = booleanFromByte(payload[2]);
        if (enabled === null)
            return;

        this._callbacks?.updateAudioSampling?.(enabled);
    }

    setAudioUpsampling(enabled) {
        this._log.info(`SET AudioUpsampling: ${enabled}`);

        const payload = [PTV2T1.AUDIO_SET_PARAM];
        payload.push(0x01);
        payload.push(enabled ? 0x01 : 0x00);
        this.addMessageQueue(MessageType.COMMAND_1, payload, 'SetAudioUpsampling');
        this._getUpscalingIndicator();
    }

    _getButtonModesLeftRight() {
        this._log.info('GET ButtonModesLeftRight');

        const payload = [PTV2T1.SYSTEM_GET_PARAM];
        payload.push(0x03);
        const ackType = 'GetButtonModesLeftRight';
        this.pendingRequestQueue?.push(ackType);
        this.addMessageQueue(MessageType.COMMAND_1, payload, ackType);
    }

    _parseButtonModesLeftRight(payload) {
        if (payload.length < 5)
            return;

        this._log.info('PARSE ButtonModesLeftRight');

        const leftMode = payload[3];
        const rightMode = payload[4];

        if (payload[2] !== 0x02 || !isValidByte(leftMode, ButtonModes) ||
                    !isValidByte(rightMode, ButtonModes))
            return;

        this._callbacks?.updateButtonModesLeftRight?.(leftMode, rightMode);
    }

    setButtonModesLeftRight(leftMode, rightMode) {
        this._log.info(`SET ButtonModesLeftRight: ${leftMode}, ${rightMode}`);

        const payload = [PTV2T1.SYSTEM_SET_PARAM];
        payload.push(0x03);
        payload.push(0x02);
        payload.push(leftMode);
        payload.push(rightMode);
        this.addMessageQueue(MessageType.COMMAND_1, payload, 'SetButtonModesLeftRight');
    }

    _getAmbientSoundButton() {
        this._log.info('GET AmbientSoundButton');

        const payload = [PTV2T1.NCASM_GET_PARAM];
        payload.push(0x30);
        const ackType = 'GetAmbientSoundButton';
        this.pendingRequestQueue?.push(ackType);
        this.addMessageQueue(MessageType.COMMAND_1, payload, ackType);
    }

    _parseAmbientSoundButton(payload) {
        if (payload.length < 3)
            return;

        this._log.info('PARSE AmbientSoundButton');

        let buttonValue;
        switch (payload[2]) {
            case AmbientButtonMode.NC_ASM_OFF:
                buttonValue = 0b111;
                break;
            case AmbientButtonMode.NC_ASM:
                buttonValue = 0b011;
                break;
            case AmbientButtonMode.NC_OFF:
                buttonValue = 0b101;
                break;
            case AmbientButtonMode.ASM_OFF:
                buttonValue = 0b110;
                break;
            default:
                return;
        }
        this._callbacks?.updateAmbientSoundButton?.(buttonValue);
    }

    setAmbientSoundButton(value) {
        let buttonMode;
        switch (value) {
            case 0b111:
                buttonMode = AmbientButtonMode.NC_ASM_OFF;
                break;
            case 0b011:
                buttonMode = AmbientButtonMode.NC_ASM;
                break;
            case 0b101:
                buttonMode = AmbientButtonMode.NC_OFF;
                break;
            case 0b110:
                buttonMode = AmbientButtonMode.ASM_OFF;
                break;
            default:
                return;
        }

        const payload = [PTV2T1.NCASM_SET_PARAM];
        payload.push(0x30);
        payload.push(buttonMode);
        this.addMessageQueue(MessageType.COMMAND_1, payload, 'SetAmbientSoundButton');
    }


    _getVoiceNotifications() {
        this._log.info('GET VoiceNotifications');

        const payload = [PTV2T2.VOICE_GUIDANCE_GET_PARAM];
        payload.push(0x03);
        const ackType = 'GetVoiceNotifications';
        this.pendingRequestQueue?.push(ackType);
        this.addMessageQueue(MessageType.COMMAND_2, payload, ackType);
    }

    _parseVoiceNotifications(payload) {
        if (payload.length !== 4 && payload[1] !== 0x03)
            return;

        this._log.info('PARSE VoiceNotifications');

        const disable = booleanFromByte(payload[2]);
        if (disable === null)
            return;

        this._callbacks?.updateVoiceNotifications?.(!disable);
    }

    setVoiceNotifications(enabled) {
        this._log.info(`SET VoiceNotifications: ${enabled}`);

        const payload = [PTV2T2.VOICE_GUIDANCE_SET_PARAM];
        payload.push(0x03);
        payload.push(enabled ? 0x00 : 0x01);
        this.addMessageQueue(MessageType.COMMAND_2, payload, 'SetVoiceNotifications');
    }

    _getVoiceNotificationsVolume() {
        this._log.info('GET VoiceNotificationsVolume');

        const payload = [PTV2T2.VOICE_GUIDANCE_GET_PARAM];
        payload.push(0x20);
        const ackType = 'GetVoiceNotificationsVolume';
        this.pendingRequestQueue?.push(ackType);
        this.addMessageQueue(MessageType.COMMAND_2, payload, ackType);
    }

    _parseVoiceNotificationsVolume(payload) {
        if (payload.length < 3)
            return;

        this._log.info('PARSE VoiceNotificationsVolume');

        const byte = payload[2];
        const vol = byte > 127 ? byte - 256 : byte;
        if (vol < -2 || vol > 2)
            return;

        this._callbacks?.updateVoiceNotificationsVolume?.(vol);
    }

    setVoiceNotificationsVolume(vol) {
        this._log.info(`SET VoiceNotificationsVolume: ${vol}`);

        const byte = vol < 0 ? 256 + vol : vol;
        const payload = [PTV2T2.VOICE_GUIDANCE_SET_PARAM];
        payload.push(0x20);
        payload.push(byte);
        this.addMessageQueue(MessageType.COMMAND_2, payload, 'SetVoiceNotificationsVolume');
    }

    _getPauseWhenTakenOff() {
        this._log.info('GET PauseWhenTakenOff');

        const payload = [PTV2T1.SYSTEM_GET_PARAM];
        payload.push(0x01);
        const ackType = 'GetPauseWhenTakenOff';
        this.pendingRequestQueue?.push(ackType);
        this.addMessageQueue(MessageType.COMMAND_1, payload, ackType);
    }

    _parsePauseWhenTakenOff(payload) {
        if (payload.length !== 3)
            return;

        this._log.info('PARSE PauseWhenTakenOff');

        const disabled = booleanFromByte(payload[2]);
        if (disabled === null)
            return;

        this._callbacks?.updatePauseWhenTakenOff?.(!disabled);
    }

    setPauseWhenTakenOff(enabled) {
        this._log.info(`SET PauseWhenTakenOff: ${enabled}`);

        const payload = [PTV2T1.SYSTEM_SET_PARAM];
        payload.push(0x01);
        payload.push(enabled ? 0x00 : 0x01);
        this.addMessageQueue(MessageType.COMMAND_1, payload, 'SetPauseWhenTakenOff');
    }

    _getAutomaticPowerOff() {
        this._log.info('GET AutomaticPowerOff');

        const payload = [PTV2T1.POWER_GET_PARAM];
        payload.push(0x05);
        const ackType = 'GetAutomaticPowerOff';
        this.pendingRequestQueue?.push(ackType);
        this.addMessageQueue(MessageType.COMMAND_1, payload, ackType);
    }

    _parseAutomaticPowerOff(payload) {
        if (payload.length < 4 || payload[1] !== 0x05)
            return;

        this._log.info('PARSE AutomaticPowerOff');

        const state = payload[2];
        const time = payload[3];

        if (!isValidByte(state, AutoPowerOffState)) {
            this._log.info(`Invalid Value for byte1 _parseAutomaticPowerOff: id=${state}`);
            return;
        }

        if (!isValidByte(time, AutoPowerOffTime)) {
            this._log.info(`Invalid Value for byte1 _parseAutomaticPowerOff: id=${time}`);
            return;
        }

        const enabled = state === AutoPowerOffState.ENABLE;
        this._currentAutoPowerTime = time;
        this._callbacks?.updateAutomaticPowerOff?.(enabled, time);
    }

    setAutomaticPowerOff(enabled, time) {
        this._log.info(`SET AutomaticPowerOff: enabled=${enabled} time: ${time}`);

        const state = enabled ? AutoPowerOffState.ENABLE : AutoPowerOffState.DISABLE;
        if (!isValidByte(time, AutoPowerOffTime)) {
            this._log.info(`Invalid Value for setAutomaticPowerOff: time: ${time}`);
            return;
        }

        const payload = [PTV2T1.POWER_SET_PARAM];
        payload.push(0x05);
        payload.push(state);
        payload.push(this._automaticPowerOffByTime ? time : 0x00);
        this.addMessageQueue(MessageType.COMMAND_1, payload, 'SetAutomaticPowerOff');
    }

    _getCodecIndicator() {
        this._log.info('GET CodecIndicator');

        const payload = [PTV2T1.COMMON_GET_STATUS];
        payload.push(0x02);
        const ackType = 'GetCodecIndicator';
        this.pendingRequestQueue?.push(ackType);
        this.addMessageQueue(MessageType.COMMAND_1, payload, ackType);
    }

    _parseCodecIndicator(payload) {
        this._log.info('PARSE CodecIndicator');

        const codec = payload[2];
        if (!isValidByte(codec, AudioCodec))
            return;

        this._callbacks?.updateCodecIndicator?.(codec);
    }

    _getUpscalingIndicator() {
        this._log.info('GET UpscalingIndicator');

        const payload = [PTV2T1.COMMON_GET_STATUS];
        payload.push(0x03);
        const ackType = 'GetUpscalingIndicator';
        this.pendingRequestQueue?.push(ackType);
        this.addMessageQueue(MessageType.COMMAND_1, payload, ackType);
    }

    _parseUpscalingIndicator(payload) {
        if (payload.length < 4)
            return;

        this._log.info('PARSE UpscalingIndicator');

        const mode = payload[2];
        const show = payload[3] !== 0x00;
        if (!isValidByte(mode, DseeType))
            return;

        this._callbacks?.updateUpscalingIndicator?.(mode, show);
    }

    _getPairingMode() {
        this._log.info('GET PairingMode');
        const payload = [PTV2T2.PERI_GET_STATUS, this._connectionType];
        const ackType = 'GetPairingMode';
        this.pendingRequestQueue?.push(ackType);
        this.addMessageQueue(MessageType.COMMAND_2, payload, ackType);
    }

    _parsePairingMode(payload) {
        if (payload.length < 4)
            return;

        this._log.info('PARSE PairingMode');

        const enabled = booleanFromByte(payload[2]);
        if (enabled === null)
            return;

        const valid = booleanFromByte(payload[3]);
        if (valid === null)
            return;

        this._callbacks?.updatePairingMode?.(valid && enabled);
    }

    setPairingMode(enabled) {
        this._log.info(`SET PairingMode: ${enabled}`);
        const payload = [PTV2T2.PERI_SET_STATUS, this._connectionType, enabled ? 0x01 : 0x00, 0x01];
        this.addMessageQueue(MessageType.COMMAND_2, payload, 'SetPairingMode');
    }

    _getDeviceList() {
        this._log.info('GET DeviceList');
        const payload = [PTV2T2.PERI_GET_PARAM, this._connectionType];
        const ackType = 'GetDeviceList';
        this.pendingRequestQueue?.push(ackType);
        this.addMessageQueue(MessageType.COMMAND_2, payload, ackType);
    }

    _parseDeviceList(payload) {
        this._log.info(`payload.length : ${payload.length}`);

        if (payload.length < 4)
            return;

        this._log.info('PARSE DeviceList');

        const deviceCount = payload[2];
        const playbackDevice = payload[payload.length - 1];

        let offset = 3;
        let playbackMac = '';
        const devices = [];

        for (let i = 0; i < deviceCount; i++) {
            if (payload.length < offset + 22)
                return;

            const macBytes = payload.slice(offset, offset + 17);
            const mac = new TextDecoder().decode(macBytes);
            offset += 17;

            const connectedStatus = payload[offset++];

            const bluetoothClassOfDevice =
            payload[offset] << 16 |
            payload[offset + 1] << 8 |
            payload[offset + 2];

            offset += 3;

            const nameLength = payload[offset++];

            if (payload.length < offset + nameLength)
                return;

            const nameBytes = payload.slice(offset, offset + nameLength);
            const name = new TextDecoder().decode(nameBytes);
            offset += nameLength;

            const connected = connectedStatus > 0;

            if (connectedStatus === playbackDevice)
                playbackMac = mac;

            devices.push({
                mac,
                name,
                connected,
                bluetoothClassOfDevice,
            });
        }

        if (payload.length !== offset + 1)
            return;

        this._callbacks?.updateDeviceList?.(devices, playbackMac);
    }

    _parseDeviceActionResult(payload) {
        if (payload.length < 21)
            return;

        this._log.info('PARSE DeviceActionResult');
        const action = payload[2];
        const result = payload[3];
        const macBytes = Uint8Array.from(payload.slice(4, 21));
        const mac = new TextDecoder().decode(macBytes);
        this._callbacks?.updateDeviceActionStatus?.(action, result, mac);
    }

    connectDevice(mac) {
        this._log.info('CONNECT Device');
        const macBytes = new TextEncoder().encode(mac);
        const payload = [PTV2T2.PERI_SET_EXTENDED_PARAM, this._connectionType, 0x01, ...macBytes];
        this.addMessageQueue(MessageType.COMMAND_2, payload, 'ConnectDevice');
    }

    disconnectDevice(mac) {
        this._log.info('DISCONNECT Device');
        const macBytes = new TextEncoder().encode(mac);
        const payload = [PTV2T2.PERI_SET_EXTENDED_PARAM, this._connectionType, 0x00, ...macBytes];
        this.addMessageQueue(MessageType.COMMAND_2, payload, 'DisconnectDevice');
    }

    unpairDevice(mac) {
        this._log.info('UNPAIR Device');
        const macBytes = new TextEncoder().encode(mac);
        const payload = [PTV2T2.PERI_SET_EXTENDED_PARAM, this._connectionType, 0x02, ...macBytes];
        this.addMessageQueue(MessageType.COMMAND_2, payload, 'UnpairDevice');
    }

    _parseSourceSwitch(payload) {
        if (payload.length < 19)
            return;

        this._log.info('PARSE SourceSwitch');
        const macBytes = Uint8Array.from(payload.slice(2, 19));
        const mac = new TextDecoder().decode(macBytes);
        this._callbacks?.updatePlaybackDevice?.(mac);
    }

    setSourceSwitch(mac) {
        this._log.info(`SET SourceSwitch: ${mac}`);
        const macBytes = new TextEncoder().encode(mac);
        const payload = [PTV2T2.PERI_SET_EXTENDED_PARAM, 0x01, ...macBytes];
        this.addMessageQueue(MessageType.COMMAND_2, payload, 'SourceSwitch');
    }

    _parseSourceSwitchFixed(payload) {
        if (payload.length < 3)
            return;

        this._log.info('PARSE SourceSwitchFixed');
        const enabled = payload[2] === 0x00;
        this._callbacks?.updateSourceSwitchFixed?.(enabled);
    }

    setSourceSwitchFixed(enabled) {
        this._log.info(`SET SourceSwitchFixed: ${enabled}`);
        const payload = [PTV2T2.PERI_SET_PARAM, 0x01, enabled ? 0x00 : 0x01];
        this.addMessageQueue(MessageType.COMMAND_2, payload, 'SourceSwitchFixed');
    }

    handleMessageType1(payload) {
        switch (payload[0]) {
            case PTV2T1.CONNECT_RET_PROTOCOL_INFO:
                this.emit('ack-received', 'protocolInfo');
                this._parseProtocolInfo(payload);
                break;

            case PTV2T1.CONNECT_RET_DEVICE_INFO:
                if (payload[1] === 0x01) {
                    this.emit('ack-received', 'deviceInfoModel');
                    this._parseDeviceInfoModel(payload);
                } else if (payload[1] === 0x02) {
                    this.emit('ack-received', 'deviceInfoFirmware');
                    this._parseDeviceInfoFirmware(payload);
                } else if (payload[1] === 0x03) {
                    this.emit('ack-received', 'deviceInfoSeriesColor');
                    this._parseDeviceInfoSeriesColor(payload);
                }
                break;

            case PTV2T1.CONNECT_RET_SUPPORT_FUNCTION:
                this.emit('ack-received', 'supportInfo');
                this._parseSupportFunctionInfo(payload);
                break;

            case PTV2T1.POWER_RET_STATUS:
            case PTV2T1.POWER_NTFY_STATUS:
                this.emit('ack-received', 'battery');
                this._parseBatteryStatus(payload);
                break;

            case PTV2T1.POWER_RET_PARAM:
            case PTV2T1.POWER_NTFY_PARAM:
                this.emit('ack-received', 'automaticPowerOff');
                this._parseAutomaticPowerOff(payload);
                break;

            case PTV2T1.NCASM_RET_PARAM:
            case PTV2T1.NCASM_NTFY_PARAM:
                if (payload[1] === 0x30) {
                    this.emit('ack-received', 'ambientSoundButton');
                    this._parseAmbientSoundButton(payload);
                } else {
                    this.emit('ack-received', 'ambientControl');
                    this._parseAmbientSoundControl(payload);
                }
                break;

            case PTV2T1.SYSTEM_RET_PARAM:
            case PTV2T1.SYSTEM_NTFY_PARAM:
                if (payload[1] === 0x01) {
                    this.emit('ack-received', 'pauseWhenTakenOff');
                    this._parsePauseWhenTakenOff(payload);
                } else if (payload[1] === 0x03) {
                    this.emit('ack-received', 'buttonModesLeftRight');
                    this._parseButtonModesLeftRight(payload);
                } else if (payload[1] === 0x0C) {
                    this.emit('ack-received', 'speakToChatEnable');
                    this._parseSpeakToChatEnable(payload);
                }
                break;

            case PTV2T1.SYSTEM_RET_EXT_PARAM:
            case PTV2T1.SYSTEM_NTFY_EXT_PARAM:
                if (payload[1] === 0x0C) {
                    this.emit('ack-received', 'speakToChatConfig');
                    this._parseSpeakToChatConfig(payload);
                }
                break;

            case PTV2T1.EQEBB_RET_PARAM:
            case PTV2T1.EQEBB_NTFY_PARAM:
                this.emit('ack-received', 'equalizer');
                this._parseEqualizer(payload);
                break;

            case PTV2T1.AUDIO_RET_PARAM:
            case PTV2T1.AUDIO_NTFY_PARAM:
                if (payload[1] === 0x01) {
                    this._parseAudioUpsampling(payload);
                    this.emit('ack-received', 'audioUpsampling');
                } else if (payload[1] === 0x03) {
                    this.emit('ack-received', 'bgmMode');
                    this._parseBgmMode(payload);
                } else if (payload[1] === 0x04) {
                    this._parseCinemaMode(payload);
                    this.emit('ack-received', 'cinemaMode');
                }
                break;

            case PTV2T1.COMMON_RET_STATUS:
            case PTV2T1.COMMON_NTFY_STATUS:
                if (payload[1] === 0x02) {
                    this._parseCodecIndicator(payload);
                    this.emit('ack-received', 'codecIndicator');
                } else if (payload[1] === 0x03) {
                    this._parseUpscalingIndicator(payload);
                    this.emit('ack-received', 'upsamplingIndicator');
                }
        }
    }

    handleMessageType2(payload) {
        switch (payload[0]) {
            case PTV2T2.CONNECT_RET_SUPPORT_FUNCTION:
                this.emit('ack-received', 'supportInfoV2');
                this._parseSupportFunctionInfoV2(payload);
                break;

            case PTV2T2.PERI_RET_STATUS:
            case PTV2T2.PERI_NTFY_STATUS:
                if (payload[1] === 0x00 || payload[1] === 0x02) {
                    this.emit('ack-received', 'pairingMode');
                    this._parsePairingMode(payload);
                }
                break;

            case PTV2T2.PERI_RET_PARAM:
            case PTV2T2.PERI_NTFY_PARAM:
                if (payload[1] === 0x00 || payload[1] === 0x02) {
                    this.emit('ack-received', 'deviceList');
                    this._parseDeviceList(payload);
                } else if (payload[1] === 0x01) {
                    this.emit('ack-received', 'sourceSwitchFixed');
                    this._parseSourceSwitchFixed(payload);
                }
                break;

            case PTV2T2.PERI_NTFY_EXTENDED_PARAM:
                if (payload[1] === 0x00 || payload[1] === 0x02) {
                    this.emit('ack-received', 'deviceAction');
                    this._parseDeviceActionResult(payload);
                } else if (payload[1] === 0x01) {
                    this.emit('ack-received', 'sourceSwitch');
                    this._parseSourceSwitch(payload);
                }
                break;

            case PTV2T2.VOICE_GUIDANCE_RET_PARAM:
            case PTV2T2.VOICE_GUIDANCE_NTFY_PARAM:
                if (payload[1] === 0x03) {
                    this.emit('ack-received', 'voiceNotifications');
                    this._parseVoiceNotifications(payload);
                } else if (payload[1] === 0x20) {
                    this.emit('ack-received', 'voiceNotificationsVolume');
                    this._parseVoiceNotificationsVolume(payload);
                }
                break;
        }
    }

    resendPendingRequest() {
        if (!this.pendingRequestQueue?.length)
            return;

        const pending = [...this.pendingRequestQueue];
        this.pendingRequestQueue.length = 0;

        for (const item of pending) {
            switch (item) {
                case 'GetBatteryTypeSingleThd':
                    this._getSingleThdBatteryRequest();
                    break;
                case 'GetBatteryTypeSingle':
                    this._getSingleBatteryRequest();
                    break;
                case 'GetBatteryTypeDualThd':
                    this._getDualThdBatteryRequest();
                    break;
                case 'GetBatteryTypeDual':
                    this._getDualBatteryRequest();
                    break;
                case 'GetBatteryTypeCaseThd':
                    this._getCaseThdBatteryRequest();
                    break;
                case 'GetBatteryTypeCase':
                    this._getCaseBatteryRequest();
                    break;
                case 'GetAmbientControl':
                    this._getAmbientSoundControl();
                    break;
                case 'GetAmbientSoundButton':
                    this._getAmbientSoundButton();
                    break;
                case 'GetSpeakToChatEnable':
                    this._getSpeakToChatEnabled();
                    break;
                case 'GetSpeakToChatConfig':
                    this._getSpeakToChatConfig();
                    break;
                case 'GetListeningModeBgm':
                case 'GetListeningModeCinema':
                    this._getListeningMode();
                    break;
                case 'GetEqualizer':
                    this._getEqualizer();
                    break;
                case 'GetAudioUpsampling':
                    this._getAudioUpsampling();
                    break;
                case 'GetUpscalingIndicator':
                    this._getUpscalingIndicator();
                    break;
                case 'GetCodecIndicator':
                    this._getCodecIndicator();
                    break;
                case 'GetButtonModesLeftRight':
                    this._getButtonModesLeftRight();
                    break;
                case 'GetVoiceNotifications':
                    this._getVoiceNotifications();
                    break;
                case 'GetVoiceNotificationsVolume':
                    this._getVoiceNotificationsVolume();
                    break;
                case 'GetPauseWhenTakenOff':
                    this._getPauseWhenTakenOff();
                    break;
                case 'GetAutomaticPowerOff':
                    this._getAutomaticPowerOff();
                    break;
                case 'GetPairingMode':
                    this._getPairingMode();
                    break;
                case 'GetDeviceList':
                    this._getDeviceList();
                    break;
                default:
                    this._log.info(`_resendPendingRequest: Unknown request type ${item}`);
                    break;
            }
        }

        this.tagEndOfGetMessage();
    }

    _getCurrentState() {
        this._log.info('GET CurrentState');

        if (this._supportedFunction.length === 0)
            return;

        const supportsCodecIndicator = this._supports(FunctionTypeV2T1.CODEC_INDICATOR);
        const supportsUpscalingIndicator = this._supports(FunctionTypeV2T1.UPSCALING_INDICATOR);
        this._callbacks?.updateCapabilities?.(supportsCodecIndicator, supportsUpscalingIndicator);

        if (supportsCodecIndicator)
            this._getCodecIndicator();

        if (supportsUpscalingIndicator)
            this._getUpscalingIndicator();

        if (this._supports(FunctionTypeV2T1.BATTERY_LEVEL_WITH_THRESHOLD))
            this._getSingleThdBatteryRequest(BatteryType.SINGLE_THD);
        else if (this._supports(FunctionTypeV2T1.BATTERY_LEVEL_INDICATOR))
            this._getSingleBatteryRequest(BatteryType.SINGLE);

        if (this._supports(FunctionTypeV2T1.LR_BATTERY_LEVEL_WITH_THRESHOLD))
            this._getDualThdBatteryRequest(BatteryType.DUAL_THD);
        else if (this._supports(FunctionTypeV2T1.LEFT_RIGHT_BATTERY_LEVEL_INDICATOR))
            this._getDualBatteryRequest(BatteryType.DUAL);

        if (this._supports(FunctionTypeV2T1.CRADLE_BATTERY_LEVEL_WITH_THRESHOLD))
            this._getCaseThdBatteryRequest(BatteryType.CASE_THD);
        else if (this._supports(FunctionTypeV2T1.CRADLE_BATTERY_LEVEL_INDICATOR))
            this._getCaseBatteryRequest(BatteryType.CASE);

        if (this._automaticPowerOffWhenTakenOff)
            this._getAutomaticPowerOff();

        if (this._supports(FunctionTypeV2T1.PRESET_EQ))
            this._eqInquiryType = EqInquiryType.PRESET_EQ;
        else if (this._supports(FunctionTypeV2T1.EBB))
            this._eqInquiryType = EqInquiryType.EBB;
        else if (this._supports(FunctionTypeV2T1.PRESET_EQ_NON_CUSTOMIZABLE))
            this._eqInquiryType = EqInquiryType.PRESET_EQ_NONCUSTOMIZABLE;
        else if (this._supports(FunctionTypeV2T1.PRESET_EQ_AND_ERRORCODE))
            this._eqInquiryType = EqInquiryType.PRESET_EQ_AND_ERRORCODE;
        else if (this._supports(FunctionTypeV2T1.CUSTOM_EQ))
            this._eqInquiryType = EqInquiryType.CUSTOM_EQ;
        else
            this._eqInquiryType = EqInquiryType.EBB;

        if (this._equalizerSixBands || this._equalizerTenBands)
            this._getEqualizer();

        if (this._audioUpsamplingSupported)
            this._getAudioUpsampling();

        /* eslint-disable max-len */
        if (this._supports(FunctionTypeV2T1.MODE_NC_ASM_NOISE_CANCELLING_DUAL_AMBIENT_SOUND_MODE_LEVEL_ADJUSTMENT_NOISE_ADAPTATION))
            this._asmType = AsmType.MODE_NC_ASM_DUAL_NC_MODE_SWITCH_AND_ASM_SEAMLESS_NA;
        else if (this._supports(FunctionTypeV2T1.MODE_NC_ASM_NOISE_CANCELLING_DUAL_AMBIENT_SOUND_MODE_LEVEL_ADJUSTMENT))
            this._asmType = AsmType.MODE_NC_ASM_DUAL_NC_MODE_SWITCH_AND_ASM_SEAMLESS;
        else if (this._supports(FunctionTypeV2T1.MODE_NC_ASM_NOISE_CANCELLING_DUAL_AUTO_AMBIENT_SOUND_MODE_LEVEL_ADJUSTMENT))
            this._asmType = AsmType.MODE_NC_ASM_AUTO_NC_MODE_SWITCH_AND_ASM_SEAMLESS;
        else if (this._supports(FunctionTypeV2T1.AMBIENT_SOUND_MODE_LEVEL_ADJUSTMENT))
            this._asmType = AsmType.ASM_SEAMLESS;
        else if (this._supports(FunctionTypeV2T1.AMBIENT_SOUND_MODE_ONOFF))
            this._asmType = AsmType.ASM_ON_OFF;
        /* eslint-enable max-len */

        if (this._asmType)
            this._getAmbientSoundControl();

        if (this._listeningModeSupported)
            this._getListeningMode();

        if (this._pauseWhenTakenOffSupported)
            this._getPauseWhenTakenOff();

        if (this._buttonModesLeftRight)
            this._getButtonModesLeftRight();

        if (this._speakToChatEnabledSupported)
            this._getSpeakToChatEnabled();

        if (this._speakToChatConfigSupported)
            this._getAmbientSoundButton();

        if (this._speakToChatConfigSupported)
            this._getSpeakToChatConfig();

        if (this._voiceNotifications)
            this._getVoiceNotifications();

        if (this._voiceNotificationsVolume)
            this._getVoiceNotificationsVolume();

        /* eslint-disable max-len */
        if (this._supports(FunctionTypeV2T2.PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT))
            this._connectionType = ConnectionType.PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT;
        else if (this._supports(FunctionTypeV2T2.PAIRING_DEVICE_MANAGEMENT_WITH_BLUETOOTH_CLASS_OF_DEVICE_CLASSIC_BT))
            this._connectionType = ConnectionType.PAIRING_DEVICE_MANAGEMENT_WITH_BLUETOOTH_CLASS_OF_DEVICE;
        else
            this._connectionType = ConnectionType.PAIRING_DEVICE_MANAGEMENT_WITH_BLUETOOTH_CLASS_OF_DEVICE;
        /* eslint-enable max-len */

        if (this._dualConnection) {
            this._getPairingMode();
            this._getDeviceList();
        }

        this.tagEndOfGetMessage();

        this._supportedFunction = null;
    }

    _requestDeviceInfoSupportFunctions() {
        this._getDeviceInfoFirmware();

        this.waitForResponse('supportInfo', () => this._getSupportInfo(), 5, 3)
            .then(() => this._requestDeviceInfoSupportFunctionsV2())
            .catch(err => this._log.error('supportInfo info initialization failed', err));
    }

    _requestDeviceInfoSupportFunctionsV2() {
        this.waitForResponse('supportInfoV2', () => this._getSupportInfoV2(), 5, 3)
            .then(() => this._getCurrentState())
            .catch(err => this._log.error('supportInfoV2 info initialization failed', err));
    }

    sendInit() {
        this.waitForResponse('protocolInfo', () => this._getProtocolInfo(), 5, 3)
            .then(() => this._requestDeviceInfoSupportFunctions())
            .catch(err => this._log.error('Protocol info initialization failed', err));
    }

    destroy() {
        super.destroy();
    }
});

