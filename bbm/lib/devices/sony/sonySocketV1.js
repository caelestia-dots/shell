'use strict';
import GObject from 'gi://GObject';

import {createLogger, getDeviceIdentifier} from '../logger.js';
import {SonySocketBase} from './sonySocketBase.js';
import {isValidByte, booleanFromByte} from '../deviceUtils.js';

import {
    MessageType, PayloadTypeV1T1 as PTV1T1, ValueType, FunctionTypeV1T1, BatteryType, AudioCodec,
    DseeType, AmbientSoundMode, Speak2ChatSensitivity, Speak2ChatTimeout, EqualizerPreset,
    AutoPowerOffState, AutoPowerOffTime, PayloadTypeV1T2 as PTV1T2
} from './sonyConfig.js';

/**
Sony module for Bluetooth battery meter service to provide,
battery information, ANC and Convesational awareness on device that support it.

Reference and Credits: for V1
https://codeberg.org/Freeyourgadget/Gadgetbridge

https://github.com/aybruh00/SonyHeadphonesClient

https://github.com/Plutoberth/SonyHeadphonesClient

https://github.com/andreasolofsson/MDR-protocol
**/
export const SonySocketV1 = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_SonySocketV1',
}, class SonySocketV1 extends SonySocketBase {
    _init(devicePath, profileManager, profile, modelData, callbacks) {
        super._init(devicePath, profileManager, profile);
        const identifier = getDeviceIdentifier(devicePath);
        const tag = `SonySocketV1-${identifier}`;
        this._log = createLogger(tag);
        this._supportedFunction = [];
        this._callbacks = callbacks;

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
        this._windNoiseReductionSupported = modelData.windNoiseReduction ?? false;
        this._speakToChatEnabledSupported = modelData.speakToChatEnabled ?? false;
        this._speakToChatConfigSupported = modelData.speakToChatConfig ?? false;
        this._speakToChatFocusOnVoiceSupported = modelData.speakToChatFocusOnVoice ?? false;
        this._pauseWhenTakenOffSupported = modelData.pauseWhenTakenOff ?? false;
        this._equalizerSixBands = modelData.equalizerSixBands ?? false;
        this._voiceNotifications = modelData.voiceNotifications ?? false;
        this._audioUpsamplingSupported = modelData.audioUpsampling ?? false;
        this._automaticPowerOffWhenTakenOff = modelData.automaticPowerOffWhenTakenOff ?? false;
        this._automaticPowerOffByTime = modelData.automaticPowerOffByTime ?? false;

        this.startSocket();
    }

    _supports(funcType) {
        return this._supportedFunction?.includes(funcType);
    }

    _getProtocolInfo() {
        this._log.info('GET ProtocolInfo');

        const payload = [PTV1T1.CONNECT_GET_PROTOCOL_INFO, ValueType.FIXED];
        this.addMessageQueue(MessageType.COMMAND_1, payload, 'GetProtocolInfo');
    }

    _parseProtocolInfo(payload) {
        if (payload.length < 3)
            return;

        this._log.info('PARSE ProtocolInfo');

        const protocolVersionBE = payload[1] << 8 | payload[2];
        const protocolMajor = (protocolVersionBE & 0xFF00) >> 8;
        const protocolMinor = protocolVersionBE & 0x00FF;

        this._log.info(`Protocol Version: ${protocolMajor}.${protocolMinor}`);
    }

    _getDeviceInfoFirmware() {
        this._log.info('GET DeviceInfoFirmware');

        const payload = [PTV1T1.CONNECT_GET_DEVICE_INFO, ValueType.FW_VERSION];
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

        const payload = [PTV1T1.CONNECT_GET_SUPPORT_FUNCTION, ValueType.FIXED];
        this.addMessageQueue(MessageType.COMMAND_1, payload, 'GetSupportInfo');
    }

    _parseSupportFunctionInfo(payload) {
        this._log.info('PARSE SupportFunctionInfo');

        if (payload.length < 3)
            return;

        const numFunctions = payload[2];
        const requiredLen = 3 + numFunctions;

        if (payload.length < requiredLen)
            return;

        const funcMap = Object.entries(FunctionTypeV1T1).reduce((acc, [name, value]) => {
            acc[value] = name;
            return acc;
        }, {});

        const supportedFunctionIds = [];
        const availableFunctions = [];

        for (let i = 0; i < numFunctions; i++) {
            const funcId = payload[3 + i];
            supportedFunctionIds.push(funcId);

            const funcName = funcMap[funcId] ??
            `Unknown_0x${funcId.toString(16).padStart(2, '0')}`;
            availableFunctions.push(funcName);
        }

        this._supportedFunction = supportedFunctionIds;

        if (availableFunctions.length > 0)
            this._log.info(`Support Functions:\n${availableFunctions.join('\n')}`);
        else
            this._log.info('No supported functions found.');
    }


    _getSingleBatteryRequest() {
        this._log.info('GET BatteryRequest:');

        const payload = [PTV1T1.COMMON_GET_BATTERY_LEVEL, BatteryType.SINGLE];
        const ackType = 'GetBatteryTypeSingle';
        this.pendingRequestQueue?.push(ackType);
        this.addMessageQueue(MessageType.COMMAND_1, payload, ackType);
    }

    _getDualBatteryRequest() {
        this._log.info('GET BatteryRequest:');

        const payload = [PTV1T1.COMMON_GET_BATTERY_LEVEL, BatteryType.DUAL];
        const ackType = 'GetBatteryTypeDual';
        this.pendingRequestQueue?.push(ackType);
        this.addMessageQueue(MessageType.COMMAND_1, payload, ackType);
    }

    _getCaseBatteryRequest() {
        this._log.info('GET BatteryRequest:');

        const payload = [PTV1T1.COMMON_GET_BATTERY_LEVEL, BatteryType.CASE];
        const ackType = 'GetBatteryTypeCase';
        this.pendingRequestQueue?.push(ackType);
        this.addMessageQueue(MessageType.COMMAND_1, payload, ackType);
    }

    _parseBatteryStatus(payload) {
        this._log.info(`PARSE BatteryStatus payload.length = ${payload.length}`);

        if (payload.length < 4)
            return;

        const type = payload[1];
        if (!Object.values(BatteryType).includes(type))
            return;

        const hasCase = this._batteryCaseSupported;

        if (type === BatteryType.SINGLE || type === BatteryType.CASE) {
            const level = Math.max(0, Math.min(payload[2], 100));
            const charging = payload[3] === 0x01;
            const status = charging ? 'charging' : 'discharging';

            if (hasCase) {
                this._battProps.battery3Level = level;
                this._battProps.battery3Status = status;
            } else {
                this._battProps.battery1Level = level;
                this._battProps.battery1Status = status;
            }
        } else if (type === BatteryType.DUAL) {
            if (payload[2] > 0) {
                const level = Math.max(0, Math.min(payload[2], 100));
                const charging = payload[3] === 0x01;
                const status = charging ? 'charging' : 'discharging';

                this._battProps.battery1Level = level;
                this._battProps.battery1Status = status;
            }

            if (payload[4] > 0) {
                const level = Math.max(0, Math.min(payload[4], 100));
                const charging = payload[5] === 0x01;
                const status = charging ? 'charging' : 'discharging';

                this._battProps.battery2Level = level;
                this._battProps.battery2Status = status;
            }
        } else {
            return;
        }

        this._callbacks?.updateBatteryProps?.(this._battProps);
    }


    _getAmbientSoundControl() {
        this._log.info('GET AmbientSoundControl:');

        const payload = [PTV1T1.NC_ASM_GET_PARAM];
        payload.push(this._asmType);
        const ackType = 'GetAmbientControl';
        this.pendingRequestQueue?.push(ackType);
        this.addMessageQueue(MessageType.COMMAND_1, payload, ackType);
    }

    _parseAmbientSoundControl(payload) {
        if (payload.length !== 8)
            return;

        this._log.info('PARSE AmbientSoundControl');

        const m0 = payload[2], m1 = payload[3], m2 = payload[4];
        let mode = null;

        if (m0 === 0x00) {
            mode = AmbientSoundMode.ANC_OFF;
        } else if (m0 === 0x01) {
            if (m1 === 0x00) {
                mode = m2 === 0x00 ? AmbientSoundMode.AMBIENT : AmbientSoundMode.ANC_ON;
            } else if (m1 === 0x02) {
                if (m2 === 0x00)
                    mode = AmbientSoundMode.AMBIENT;
                else if (m2 === 0x01)
                    mode = AmbientSoundMode.WIND;
                else
                    mode = AmbientSoundMode.ANC_ON;
            }
        }

        if (!isValidByte(mode, AmbientSoundMode))
            return;

        const focusOnVoiceState = payload[6] === 0x01;
        const level = payload[7];
        const ambientSoundLevel = level >= 0 && level <= 20 ? level : 10;

        this._log.info(`PARSE AmbientSoundControl: Mode: ${mode} Voice: ${focusOnVoiceState} ` +
                `Level: ${level}`);

        this._callbacks?.updateAmbientSoundControl?.(mode, focusOnVoiceState, ambientSoundLevel);
    }

    setAmbientSoundControl(mode, focusOnVoice, level) {
        this._log.info(
            `SET AmbientSoundControl: Mode: ${mode} Voice: ${focusOnVoice} ` +
                `Level: ${level}`);
        const payload = [PTV1T1.NC_ASM_SET_PARAM];

        const modeIsOff = mode === AmbientSoundMode.ANC_OFF;
        const modeIsNC = mode === AmbientSoundMode.ANC_ON;
        const modeIsWNR = mode === AmbientSoundMode.WIND;
        const modeIsAmbient = mode === AmbientSoundMode.AMBIENT;

        payload.push(0x02);
        payload.push(modeIsOff ? 0x00 : 0x11);
        payload.push(this._windNoiseReductionSupported ? 0x02 : 0x00);

        let modeCode = 0x00;
        if (this._windNoiseReductionSupported) {
            if (modeIsNC)
                modeCode = 0x02;
            else if (modeIsWNR)
                modeCode = 0x01;
        } else {
            modeCode = modeIsNC ? 0x01 : 0x00;
        }

        payload.push(modeCode);
        payload.push(0x01);
        payload.push(focusOnVoice ? 0x01 : 0x00);

        const ambientSoundLevel = modeIsOff || modeIsAmbient ? Math.max(1, level) : 0x00;

        payload.push(ambientSoundLevel);
        this.addMessageQueue(MessageType.COMMAND_1, payload, 'SetAmbientSoundControl');
    }

    _getSpeakToChatEnabled() {
        this._log.info('GET SpeakToChatEnabled');

        const payload = [PTV1T1.SYSTEM_GET_PARAM];
        payload.push(0x05);
        const ackType = 'GetSpeakToChatEnable';
        this.pendingRequestQueue?.push(ackType);
        this.addMessageQueue(MessageType.COMMAND_1, payload, ackType);
    }

    _parseSpeakToChatEnable(payload) {
        if (payload.length !== 4 || payload[2] !== 0x01)
            return;

        this._log.info('PARSE SpeakToChatEnable');

        const enabled = booleanFromByte(payload[3]);
        if (enabled === null)
            return;

        this._callbacks?.updateSpeakToChatEnable?.(enabled);
    }

    setSpeakToChatEnabled(enabled) {
        this._log.info(`SET SpeakToChatEnabled: ${enabled}`);

        const payload = [PTV1T1.SYSTEM_SET_PARAM];
        payload.push(0x05);
        payload.push(0x01);
        payload.push(enabled ? 0x01 : 0x00);
        this.addMessageQueue(MessageType.COMMAND_1, payload, 'SetSpeakToChatEnabled');
    }

    _getSpeakToChatConfig() {
        this._log.info('GET SpeakToChatConfig');

        const payload = [PTV1T1.SYSTEM_GET_EXTENDED_PARAM];
        payload.push(0x05);
        const ackType = 'GetSpeakToChatConfig';
        this.pendingRequestQueue?.push(ackType);
        this.addMessageQueue(MessageType.COMMAND_1, payload, ackType);
    }

    _parseSpeakToChatConfig(payload) {
        if (payload.length !== 6)
            return;

        this._log.info('PARSE SpeakToChatConfig');

        const sensCode = payload[3];
        if (!isValidByte(sensCode, Speak2ChatSensitivity))
            return;

        const timeoutCode = payload[5];
        if (!isValidByte(timeoutCode, Speak2ChatTimeout))
            return;

        this._callbacks?.updateSpeakToChatConfig?.(sensCode, timeoutCode);
    }

    setSpeakToChatConfig(sensitivity, timeout) {
        this._log.info(`SET SpeakToChatConfig: Sensitivity=${sensitivity}, Timeout=${timeout}`);

        if (!isValidByte(sensitivity, Speak2ChatSensitivity))
            return;

        if (!isValidByte(timeout, Speak2ChatTimeout))
            return;

        const payload = [PTV1T1.SYSTEM_SET_EXTENDED_PARAM];
        payload.push(0x05);
        payload.push(0x00);
        payload.push(sensitivity);
        payload.push(0x00);
        payload.push(timeout);
        this.addMessageQueue(MessageType.COMMAND_1, payload, 'SetSpeakToChatConfig');
    }

    _getEqualizer() {
        this._log.info('GET Equalizer');

        const payload = [PTV1T1.EQ_EBB_GET_PARAM];
        payload.push(0x01);
        const ackType = 'GetEqualizer';
        this.pendingRequestQueue?.push(ackType);
        this.addMessageQueue(MessageType.COMMAND_1, payload, ackType);
    }

    _parseEqualizer(payload) {
        if (payload.length !== 10)
            return;

        this._log.info('PARSE Equalizer');

        const presetCode = payload[2];
        if (!isValidByte(presetCode, EqualizerPreset))
            return;

        const customBands = [];
        if (payload[3] === 6) {
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

        const payload = [PTV1T1.EQ_EBB_SET_PARAM];
        payload.push(0x01);
        payload.push(presetCode);
        payload.push(0x00);
        this.addMessageQueue(MessageType.COMMAND_1, payload, 'SetEqualizerPreset');
    }

    setEqualizer(presetCode, customBands) {
        this._log.info(
            `SET EqualizerCustomBands: Preset: ${presetCode} CustomBands=${customBands}`);

        const payload = [PTV1T1.EQ_EBB_SET_PARAM];
        payload.push(0x01);
        payload.push(presetCode);
        payload.push(0x06);

        if (customBands.length !== 6)
            return;


        for (let i = 0; i < 6; i++)
            payload.push(customBands[i] + 10);

        this.addMessageQueue(MessageType.COMMAND_1, payload, 'SetEqualizer');
    }

    _getVoiceNotifications() {
        this._log.info('GET VoiceNotifications');

        const payload = [PTV1T1.VPT_GET_PARAM];
        payload.push(0x01);
        payload.push(0x01);
        const ackType = 'GetVoiceNotifications';
        this.pendingRequestQueue?.push(ackType);
        this.addMessageQueue(MessageType.COMMAND_2, payload, ackType);
    }

    _parseVoiceNotifications(payload) {
        if (payload.length !== 4)
            return;

        this._log.info('PARSE VoiceNotifications');

        const enabled = booleanFromByte(payload[3]);
        if (enabled === null)
            return;

        this._callbacks?.updateVoiceNotifications?.(enabled);
    }

    setVoiceNotifications(enabled) {
        this._log.info(`SET VoiceNotifications: ${enabled}`);

        const payload = [PTV1T1.VPT_SET_PARAM];

        payload.push(0x01);
        payload.push(0x01);
        payload.push(enabled ? 0x01 : 0x00);
        this.addMessageQueue(MessageType.COMMAND_2, payload, 'SetVoiceNotifications');
    }

    _getAudioUpsampling() {
        this._log.info('GET AudioUpsampling');

        const payload = [PTV1T1.AUDIO_GET_PARAM];
        payload.push(0x02);
        const ackType = 'GetAudioUpsampling';
        this.pendingRequestQueue?.push(ackType);
        this.addMessageQueue(MessageType.COMMAND_1, payload, ackType);
    }

    _parseAudioUpsampling(payload) {
        if (payload.length !== 4)
            return;

        this._log.info('PARSE AudioUpsampling');

        const enabled = booleanFromByte(payload[3]);
        if (enabled === null)
            return;

        this._callbacks?.updateAudioSampling?.(enabled);
    }

    setAudioUpsampling(enabled) {
        this._log.info(`SET AudioUpsampling: ${enabled}`);

        const payload = [PTV1T1.AUDIO_SET_PARAM];
        payload.push(0x02);
        payload.push(0x00);
        payload.push(enabled ? 0x01 : 0x00);
        this.addMessageQueue(MessageType.COMMAND_1, payload, 'SetAudioUpsampling');
        this._getUpscalingIndicator();
    }

    _getPauseWhenTakenOff() {
        this._log.info('GET PauseWhenTakenOff');

        const payload = [PTV1T1.SYSTEM_GET_PARAM];
        payload.push(0x03);
        const ackType = 'GetPauseWhenTakenOff';
        this.pendingRequestQueue?.push(ackType);
        this.addMessageQueue(MessageType.COMMAND_1, payload, ackType);
    }

    _parsePauseWhenTakenOff(payload) {
        if (payload.length !== 4)
            return;

        this._log.info('PARSE PauseWhenTakenOff');

        const enabled = booleanFromByte(payload[3]);
        if (enabled === null)
            return;

        this._callbacks?.updatePauseWhenTakenOff?.(enabled);
    }

    setPauseWhenTakenOff(enabled) {
        this._log.info(`SET PauseWhenTakenOff: ${enabled}`);

        const payload = [PTV1T1.SYSTEM_SET_PARAM];
        payload.push(0x03);
        payload.push(0x00);
        payload.push(enabled ? 0x01 : 0x00);
        this.addMessageQueue(MessageType.COMMAND_1, payload, 'SetPauseWhenTakenOff');
    }

    _getAutomaticPowerOff() {
        this._log.info('GET AutomaticPowerOff');

        const payload = [PTV1T1.SYSTEM_GET_PARAM];
        payload.push(0x04);
        const ackType = 'GetAutomaticPowerOff';
        this.pendingRequestQueue?.push(ackType);
        this.addMessageQueue(MessageType.COMMAND_1, payload, ackType);
    }

    _parseAutomaticPowerOff(payload) {
        if (payload.length < 5)
            return;

        this._log.info('PARSE AutomaticPowerOff');

        const state = payload[3];
        const time = payload[4];

        if (this._automaticPowerOffByTime) {
            if (state !== AutoPowerOffState.DISABLE && !isValidByte(state, AutoPowerOffTime)) {
                this._log.info(`Invalid Value for byte1 _parseAutomaticPowerOff: id=${state}`);
                return;
            }

            if (!isValidByte(time, AutoPowerOffTime)) {
                this._log.info(`Invalid Value for byte2 _parseAutomaticPowerOff: id=${time}`);
                return;
            }
        } else {
            if (!isValidByte(state, AutoPowerOffState)) {
                this._log.info(`Invalid Value for byte1 _parseAutomaticPowerOff: id=${state}`);
                return;
            }
            if (time !== 0x00) {
                this._log.info(`Invalid Value for byte2 _parseAutomaticPowerOff: id=${time}`);
                return;
            }
        }

        const disabled = state === AutoPowerOffState.DISABLE;
        this._currentAutoPowerTime = time;
        this._callbacks?.updateAutomaticPowerOff?.(!disabled, time);
    }

    setAutomaticPowerOff(enabled, time) {
        this._log.info(`SET AutomaticPowerOff: enabled=${enabled} time: ${time}`);

        let state = AutoPowerOffState.DISABLE;

        if (this._automaticPowerOffByTime) {
            if (!isValidByte(time, AutoPowerOffTime)) {
                this._log.info(`Invalid Value for setAutomaticPowerOff: time: ${time}`);
                return;
            }

            if (enabled)
                state = time;
            else
                time = 0x00;
        } else {
            time = 0x00;
            if (enabled)
                state = AutoPowerOffState.ENABLE;
        }

        const payload = [PTV1T1.SYSTEM_SET_PARAM];
        payload.push(0x04);
        payload.push(0x01);
        payload.push(state);
        payload.push(time);
        this.addMessageQueue(MessageType.COMMAND_1, payload, 'SetAutomaticPowerOff');
    }

    _getCodecIndicator() {
        this._log.info('GET CodecIndicator');

        const payload = [PTV1T1.COMMON_GET_AUDIO_CODEC];
        payload.push(0x00);
        const ackType = 'GetCodecIndicator';
        this.pendingRequestQueue?.push(ackType);
        this.addMessageQueue(MessageType.COMMAND_1, payload, ackType);
    }

    _parseCodecIndicator(payload) {
        if (payload.length < 3)
            return;

        this._log.info('PARSE CodecIndicator');

        if (payload[1] !== 0x00)
            return;

        const codec = payload[2];
        if (!isValidByte(codec, AudioCodec))
            return;

        this._callbacks?.updateCodecIndicator?.(codec);
    }

    _getUpscalingIndicator() {
        this._log.info('GET UpscalingIndicator');

        const payload = [PTV1T1.COMMON_GET_UPSCALING_EFFECT];
        payload.push(0x00);
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
        const payload = [PTV1T2.PERI_GET_STATUS, 0x01];
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
        const payload = [PTV1T2.PERI_SET_STATUS, 0x01, enabled ? 0x01 : 0x00, 0x01];
        this.addMessageQueue(MessageType.COMMAND_2, payload, 'SetPairingMode');
    }

    _getDeviceList() {
        this._log.info('GET DeviceList');
        const payload = [PTV1T2.PERI_GET_PARAM, 0x01];
        const ackType = 'GetDeviceList';
        this.pendingRequestQueue?.push(ackType);
        this.addMessageQueue(MessageType.COMMAND_2, payload, ackType);
    }

    _parseDeviceList(payload) {
        this._log.info(`payload.length : ${payload.length}`);

        if (payload.length < 4)
            return;

        this._log.info('PARSE V1 DeviceList');

        const deviceCount = payload[2];

        let offset = 3;
        let playbackMac = '';
        const devices = [];

        for (let i = 0; i < deviceCount; i++) {
            if (payload.length < offset + 17)
                return;

            const macBytes = payload.slice(offset, offset + 17);
            const mac = new TextDecoder().decode(macBytes);
            offset += 17;

            if (payload.length < offset + 1)
                return;

            const connectedStatus = payload[offset++];

            if (payload.length < offset + 1)
                return;

            const nameLength = payload[offset++];

            if (payload.length < offset + nameLength)
                return;

            const nameBytes = payload.slice(offset, offset + nameLength);
            const name = new TextDecoder().decode(nameBytes);
            offset += nameLength;
            const connected = connectedStatus !== 0;

            if (connectedStatus === payload[payload.length - 1])
                playbackMac = mac;

            devices.push({mac, name, connected});
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
        this._log.info(`CONNECT Device: ${mac}`);
        const macBytes = new TextEncoder().encode(mac);
        const payload = [PTV1T2.PERI_SET_EX_PARAM, 0x00, 0x01, macBytes.length, ...macBytes];
        this.addMessageQueue(MessageType.COMMAND_2, payload, 'ConnectDevice');
    }

    disconnectDevice(mac) {
        this._log.info(`DISCONNECT Device: ${mac}`);
        const macBytes = new TextEncoder().encode(mac);
        const payload = [PTV1T2.PERI_SET_EX_PARAM, 0x00, 0x00, macBytes.length, ...macBytes];

        this.addMessageQueue(MessageType.COMMAND_2, payload, 'DisconnectDevice');
    }

    unpairDevice(mac) {
        this._log.info(`UNPAIR Device: ${mac}`);
        const macBytes = new TextEncoder().encode(mac);
        const payload = [PTV1T2.PERI_SET_EX_PARAM, 0x00, 0x02, macBytes.length, ...macBytes];
        this.addMessageQueue(MessageType.COMMAND_2, payload, 'UnpairDevice');
    }


    handleMessageType1(payload) {
        switch (payload[0]) {
            case PTV1T1.CONNECT_RET_PROTOCOL_INFO:
                this.emit('ack-received', 'protocolInfo');
                this._parseProtocolInfo(payload);
                break;

            case PTV1T1.CONNECT_RET_DEVICE_INFO:
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

            case PTV1T1.CONNECT_RET_SUPPORT_FUNCTION:
                this.emit('ack-received', 'supportInfo');
                this._parseSupportFunctionInfo(payload);
                break;

            case PTV1T1.COMMON_RET_BATTERY_LEVEL:
            case PTV1T1.COMMON_NTFY_BATTERY_LEVEL:
                this.emit('ack-received', 'battery');
                this._parseBatteryStatus(payload);
                break;

            case PTV1T1.NC_ASM_RET_PARAM:
            case PTV1T1.NC_ASM_NTFY_PARAM:
                this.emit('ack-received', 'ambientControl');
                this._parseAmbientSoundControl(payload);
                break;

            case PTV1T1.SYSTEM_RET_PARAM:
            case PTV1T1.SYSTEM_NTFY_PARAM:
                if (payload[1] === 0x03) {
                    this.emit('ack-received', 'pauseWhenTakenOff');
                    this._parsePauseWhenTakenOff(payload);
                } else if (payload[1] === 0x04) {
                    this.emit('ack-received', 'automaticPowerOff');
                    this._parseAutomaticPowerOff(payload);
                } else if (payload[1] === 0x05) {
                    this.emit('ack-received', 'speakToChatEnable');
                    this._parseSpeakToChatEnable(payload);
                }
                break;

            case PTV1T1.SYSTEM_RET_EXTENDED_PARAM:
            case PTV1T1.SYSTEM_NTFY_EXTENDED_PARAM:
                if (payload[1] === 0x05) {
                    this.emit('ack-received', 'speakToChatConfig');
                    this._parseSpeakToChatConfig(payload);
                }
                break;

            case PTV1T1.EQ_EBB_RET_PARAM:
            case PTV1T1.EQ_EBB_NTFY_PARAM:
                this.emit('ack-received', 'equalizer');
                this._parseEqualizer(payload);
                break;

            case PTV1T1.AUDIO_RET_PARAM:
            case PTV1T1.AUDIO_NTFY_PARAM:
                if (payload[1] === 0x01) {
                    this._parseAudioUpsampling(payload);
                    this.emit('ack-received', 'audioUpsampling');
                }
                break;

            case PTV1T1.COMMON_RET_UPSCALING_EFFECT:
            case PTV1T1.COMMON_NTFY_UPSCALING_EFFECT:
                this._parseUpscalingIndicator(payload);
                this.emit('ack-received', 'codecIndicator');
                break;

            case PTV1T1.COMMON_RET_AUDIO_CODEC:
            case PTV1T1.COMMON_NTFY_AUDIO_CODEC:
                this._parseCodecIndicator(payload);
                this.emit('ack-received', 'upscalingIndicator');
                break;
        }
    }


    handleMessageType2(payload) {
        switch (payload[0]) {
            case PTV1T1.VPT_RET_PARAM:
            case PTV1T1.VPT_NTFY_PARAM:
                this.emit('ack-received', 'voiceNotifications');
                this._parseVoiceNotifications(payload);
                break;

            case PTV1T2.PERI_RET_STATUS:
            case PTV1T2.PERI_NTFY_STATUS:
                if (payload[1] === 0x01) {
                    this.emit('ack-received', 'pairingMode');
                    this._parsePairingMode(payload);
                }
                break;

            case PTV1T2.PERI_RET_PARAM:
            case PTV1T2.PERI_NTFY_PARAM:
                if (payload[1] === 0x01) {
                    this.emit('ack-received', 'deviceList');
                    this._parseDeviceList(payload);
                }
                break;

            case PTV1T2.PERI_NTFY_EX_PARAM:
                if (payload[1] === 0x00) {
                    this.emit('ack-received', 'deviceList');
                    this._parseDeviceActionResult(payload);
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
            if (item === 'GetBatteryTypeSingle')
                this._getSingleBatteryRequest();
            else if (item === 'GetBatteryTypeDual')
                this._getDualBatteryRequest();
            else if (item === 'GetBatteryTypeCase')
                this._getCaseBatteryRequest();
            else if (item === 'GetAmbientControl')
                this._getAmbientSoundControl();
            else if (item === 'GetSpeakToChatEnable')
                this._getSpeakToChatEnabled();
            else if (item === 'GetSpeakToChatConfig')
                this._getSpeakToChatConfig();
            else if (item === 'GetEqualizer')
                this._getEqualizer();
            else if (item === 'GetVoiceNotifications')
                this._getVoiceNotifications();
            else if (item === 'GetAudioUpsampling')
                this._getAudioUpsampling();
            else if (item === 'GetPauseWhenTakenOff')
                this._getPauseWhenTakenOff();
            else if (item === 'GetAutomaticPowerOff')
                this._getAutomaticPowerOff();
        }
        this.tagEndOfGetMessage();
    }

    _getCurrentState() {
        this._log.info('GET CurrentState');

        if (this._supportedFunction.length === 0)
            return;

        const supportsCodecIndicator = this._supports(FunctionTypeV1T1.CODEC_INDICATOR);
        const supportsUpscalingIndicator = this._supports(FunctionTypeV1T1.UPSCALING_INDICATOR);
        this._callbacks?.updateCapabilities?.(supportsCodecIndicator, supportsUpscalingIndicator);

        if (this._supports(FunctionTypeV1T1.NOISE_CANCELLING_AND_AMBIENT_SOUND_MODE))
            this._asmType = 0x02;
        else if (this._supports(FunctionTypeV1T1.AMBIENT_SOUND_MODE))
            this._asmType = 0x03;
        else if (this._supports(FunctionTypeV1T1.NOISE_CANCELLING))
            this._asmType = 0x01;
        else
            this._asmType = 0x02;

        if (this._batterySingleSupported)
            this._getSingleBatteryRequest();

        if (this._batteryDualSupported)
            this._getDualBatteryRequest();

        if (this._batteryCaseSupported)
            this._getCaseBatteryRequest();

        if (supportsCodecIndicator)
            this._getUpscalingIndicator();

        if (supportsUpscalingIndicator)
            this._getCodecIndicator();

        if (this._voiceNotifications)
            this._getVoiceNotifications();

        if (this._equalizerSixBands)
            this._getEqualizer();

        if (this._ambientSoundControlSupported)
            this._getAmbientSoundControl();

        if (this._audioUpsamplingSupported)
            this._getAudioUpsampling();

        if (this._pauseWhenTakenOffSupported)
            this._getPauseWhenTakenOff();

        if (this._automaticPowerOffWhenTakenOffSupported)
            this._getAutomaticPowerOff();

        if (this._speakToChatEnabledSupported)
            this._getSpeakToChatEnabled();

        if (this._speakToChatConfigSupported)
            this._getSpeakToChatConfig();

        this.tagEndOfGetMessage();

        this._supportedFunction = null;
    }

    _requestDeviceInfoSupportFunctions() {
        this._getDeviceInfoFirmware();

        this.waitForResponse('supportInfo', () => this._getSupportInfo(), 5, 3)
            .then(() => this._getCurrentState())
            .catch(err => this._log.error('supportInfo info initialization failed', err));
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

