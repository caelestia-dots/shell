'use strict';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';

import {createLogger, getDeviceIdentifier, hexBytes} from '../logger.js';
import {SocketHandler} from '../socketByProfile.js';
import {booleanFromByte, isValidByte, isArrayEqual} from '../deviceUtils.js';
import {getRandomChallenge, computeChallengeResponse} from './redmiBudsAuthenticator.js';
import {
    RedmiBudsModelList, MessageType, Opcode, ConfigType, DeviceInfoRetType
} from './redmiBudsConfig.js';

/* eslint-disable max-len */

/**
Reference Material and Credits
https://codeberg.org/Freeyourgadget/Gadgetbridge/src/branch/master/app/src/main/java/nodomain/freeyourgadget/gadgetbridge/service/devices/redmibuds

https://github.com/web1n/android_packages_apps_XiaomiTWS
**/

/* eslint-enable max-len */

const HEADER = [0xFE, 0xDC, 0xBA];
const TRAILER = 0xEF;

export const RedmiBudsSocket = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_RedmiSocket',
}, class RedmiBudsSocket extends SocketHandler {
    _init(devicePath, profileManager, profile, callbacks) {
        super._init(devicePath, profileManager, profile);
        const identifier = getDeviceIdentifier(devicePath);
        const tag = `RedmiSocket-${identifier}`;
        this._log = createLogger(tag);
        this._log.info('RedmiSocket init');
        this._callbacks = callbacks;
        this._seq = 0;
        this._rxBuffer = [];
        this._txQueue = [];
        this._pendingRequest = null;
        this._pendingTimeout = null;
        this._allowStatusNotifyConfigRsp = false;
        this._initialized = false;

        this._modelData = null;
        this._challenge = [];

        this.startSocket();
    }

    _nextSeq() {
        const seq = this._seq;
        this._seq = this._seq + 1 & 0xFF;
        return seq;
    }

    postConnectInitialization() {
        this._challenge = getRandomChallenge();
        const payload = [0x01, ...this._challenge];
        this._encode(MessageType.PHONE_REQUEST, Opcode.AUTH_CHALLENGE, this._nextSeq(), payload);
    }

    processData(bytes) {
        this._rxBuffer.push(...bytes);

        while (true) {
            const msg = this._extractMessage();
            if (!msg)
                break;

            this._handleMessage(msg);
        }
    }

    _queueRequest(type, opcode, seq, payload, loginfo = '') {
        this._txQueue.push({type, opcode, seq, payload, loginfo});
        this._processQueue();
    }

    _processQueue() {
        if (this._pendingRequest)
            return;

        if (this._txQueue.length === 0)
            return;

        const item = this._txQueue.shift();

        if (item.loginfo)
            this._log.info(item.loginfo);

        if (item.type === 0xFF && item.opcode === 0xFF) {
            this._allowStatusNotifyConfigRsp = true;
            return;
        }

        this._encode(item.type, item.opcode, item.seq, item.payload);
        this._pendingRequest = item;

        if (this._pendingTimeout) {
            GLib.source_remove(this._pendingTimeout);
            this._pendingTimeout = null;
        }

        this._pendingTimeout = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 250, () => {
            this._log.info(`Response Timeout seq: ${item.seq} opcode: ${hexBytes(item.opcode)}`);
            this._pendingRequest = null;
            this._processQueue();
            this._pendingTimeout = null;
            return GLib.SOURCE_REMOVE;
        });
    }

    _completePendingRequest(msg) {
        if (!this._pendingRequest)
            return;

        if (msg.type !== MessageType.RESPONSE || msg.type !== MessageType.EARBUDS_RESPONSE)
            return;

        const pending = this._pendingRequest;

        if (msg.seq !== pending.seq)
            return;

        if (this._pendingTimeout)
            GLib.source_remove(this._pendingTimeout);

        this._pendingTimeout = null;
        this._pendingRequest = null;
        this._processQueue();
    }

    _encode(type, opcode, seq, payload) {
        const isRequest = (type & 0x40) !== 0;
        const payloadLength = payload.length + (isRequest ? 1 : 2);
        const out = [...HEADER, type, opcode, payloadLength >> 8 & 0xFF, payloadLength & 0xFF];

        if (!isRequest)
            out.push(0x00);

        out.push(seq & 0xFF);
        out.push(...payload);
        out.push(TRAILER);

        this.sendMessage(out);
    }

    _extractMessage() {
        const buf = this._rxBuffer;

        for (let i = 0; i <= buf.length - 8; i++) {
            if (buf[i] !== HEADER[0] || buf[i + 1] !== HEADER[1] || buf[i + 2] !== HEADER[2])
                continue;


            const payloadLength = buf[i + 5] << 8 | buf[i + 6];
            const totalLength = payloadLength + 8;

            if (i + totalLength > buf.length) {
                this._log.info('Decoder: Invalid length');
                return null;
            }

            if (buf[i + totalLength - 1] !== TRAILER) {
                this._log.info('Decoder: No trailer byte found');
                continue;
            }

            const raw = Uint8Array.from(buf.slice(i, i + totalLength));
            this._rxBuffer.splice(0, i + totalLength);

            return this._parseMessage(raw);
        }

        return null;
    }

    _parseMessage(raw) {
        const type = raw[3];
        const opcode = raw[4];
        const isRequest = (type & 0x40) !== 0;
        const seqIndex = isRequest ? 7 : 8;
        const seq = raw[seqIndex];
        const payloadStart = seqIndex + 1;
        const payload = raw.slice(payloadStart, raw.length - 1);

        return {type, opcode, seq, payload};
    }

    _handleMessage(msg) {
        this._log.info(`Opcode: [${hexBytes(msg.opcode)}] payload: [${hexBytes(msg.payload)}]`);
        switch (msg.opcode) {
            case Opcode.AUTH_CHALLENGE:
            case Opcode.AUTH_CONFIRM:
                this._handleAuthentication(msg);
                break;

            case Opcode.GET_DEVICE_INFO:
                this._log.info('Device info received');
                this._decodeDeviceInfo(msg.payload);
                break;

            case Opcode.GET_DEVICE_RUN_INFO:
                this._log.info('Runtime info received');
                this._decodeDeviceRunInfo(msg.payload);
                break;

            case Opcode.REPORT_STATUS:
                this._log.info('Report Status received');
                this._decodeDeviceUpdate(msg.payload);
                if (this._allowStatusNotifyConfigRsp)
                    this._encode(MessageType.RESPONSE, Opcode.REPORT_STATUS, msg.seq, []);

                break;

            case Opcode.GET_CONFIG:
                this._log.info('Get Config received');
                this._decodeGetConfig(msg.payload);
                break;

            case Opcode.NOTIFY_CONFIG:
                this._log.info('Notify Config received');
                this._decodeNotifyConfig(msg.payload);
                if (this._allowStatusNotifyConfigRsp)
                    this._encode(MessageType.RESPONSE, Opcode.NOTIFY_CONFIG, msg.seq, []);

                break;

            default:
                this._log.info(`Unhandled opcode 0x${msg.opcode.toString(16)}`);
        }
        this._completePendingRequest(msg);
    }

    _handleAuthentication(msg) {
        switch (msg.opcode) {
            case Opcode.AUTH_CHALLENGE: {
                if (msg.type === MessageType.RESPONSE ||
                            msg.type === MessageType.EARBUDS_RESPONSE) {
                    this._log.info('Received auth challenge response');

                    if (this._challenge.length > 0) {
                        const response = msg.payload.slice(1);
                        const expectedResponse = computeChallengeResponse(this._challenge);
                        const valid = isArrayEqual(response, expectedResponse);

                        if (valid) {
                            this._log.info('Authentication Validated');
                            this._challenge = [];
                            this._encode(MessageType.PHONE_REQUEST,
                                Opcode.AUTH_CONFIRM, this._nextSeq(), [0x01, 0x00]);
                        } else {
                            this._log.info('Authentication Not Valid');
                        }
                    }
                } else {
                    this._challenge = [];
                    this._log.info('Earbuds requested auth challenge response');
                    const challenge = msg.payload.slice(1);
                    const response = computeChallengeResponse(challenge);
                    const payload = [0x01, ...response];
                    this._encode(MessageType.RESPONSE, Opcode.AUTH_CHALLENGE, msg.seq, payload);
                }
                break;
            }
            case Opcode.AUTH_CONFIRM: {
                this._challenge = [];
                if (msg.type === MessageType.RESPONSE) {
                    this._log.info('Auth confirm acknowledged');
                } else {
                    this._log.info('Authentication completed');

                    this._encode(MessageType.RESPONSE, Opcode.AUTH_CONFIRM,
                        msg.seq, Uint8Array.from([0x01]));

                    this._getInfo();
                }
                break;
            }
        }
    }

    _getInfo() {
        this._requestDeviceInfo();

        let retries = 0;

        this._infoTimeout = GLib.timeout_add(
            GLib.PRIORITY_DEFAULT,
            300,
            () => {
                if (this._initialized) {
                    this._infoTimeout = null;
                    return GLib.SOURCE_REMOVE;
                }

                if (retries < 4) {
                    this._requestDeviceInfo();
                    retries++;
                    return GLib.SOURCE_CONTINUE;
                }

                this._log.info('No DeviceInfo response');
                this._infoTimeout = null;
                return GLib.SOURCE_REMOVE;
            }
        );
    }

    _requestDeviceInfo() {
        const loginfo = 'Get Device Info';
        this._queueRequest(MessageType.PHONE_REQUEST, Opcode.GET_DEVICE_INFO,
            this._nextSeq(), [0xFF, 0xFF, 0xFF, 0xFF], loginfo);
    }

    _requestDeviceRunInfo() {
        const loginfo = 'Get Device Run Info';
        this._queueRequest(MessageType.PHONE_REQUEST, Opcode.GET_DEVICE_RUN_INFO,
            this._nextSeq(), [0xFF, 0xFF, 0xFF, 0xFF], loginfo);
    }

    _sendInitializationRequests() {
        this._requestDeviceRunInfo();

        this._getSerial();

        if (this._modelData.gestureOptions)
            this._getGestures();

        if (this._modelData.autoAnswer)
            this._getAutoAnswer();

        if (this._modelData.dualConnection)
            this._getDualConnection();

        if (this._modelData.eqPreset)
            this._getEqPreset();

        if (this._modelData.gestureOptions?.noiseControlModes)
            this._getLongPressMode();

        if (this._modelData.noiseCancellationStrength ||
                this._modelData.transparencyStrength ||
                this._modelData.ancLevel)
            this._getNoiseControl();

        if (this._modelData.adaptiveNcSwitch)
            this._getAdaptiveNC();

        if (this._modelData.adaptiveSound)
            this._getAdaptiveSound();

        if (this._modelData.lowLatencyMode)
            this._getLowLatency();

        if (this._modelData.eqPreset?.custom)
            this._getCustomEq();

        this._queueRequest(0xFF, 0xFF, 0xFF, [], 'Init Query Complete');
    }

    _parseBatteryInfo(leftBatByte, rightBatByte, caseBatByte) {
        const props = {};

        const parse = (batteryInfo, index) => {
            if (batteryInfo === 0xFF) {
                props[`battery${index}Level`] = 0;
                props[`battery${index}Status`] = 'disconnected';
                return;
            }

            const level = batteryInfo & 0x7F;
            const charging = (batteryInfo & 0x80) !== 0;

            const statusStr = charging ? 'charging' : 'discharging';

            this._log.info(`Battery ${index}: ${level} : ${statusStr}`);

            props[`battery${index}Level`] = level;
            props[`battery${index}Status`] = statusStr;
        };

        parse(leftBatByte, 1);
        parse(rightBatByte, 2);
        parse(caseBatByte, 3);

        this._callbacks?.updateBatteryProps?.(props);
    }

    _parseFirmware(fw) {
        if (fw.length !== 4)
            return;

        const fwVersion1 = `${fw[0] >> 4 & 0xF}.${fw[0] & 0xF}.${fw[1] >> 4 & 0xF}.${fw[1] & 0xF}`;
        const fwVersion2 = `${fw[2] >> 4 & 0xF}.${fw[2] & 0xF}.${fw[3] >> 4 & 0xF}.${fw[3] & 0xF}`;
        this._log.info(`Firmware Version 1 = ${fwVersion1}, Firmware Version 2 = ${fwVersion2}`);

        this._callbacks?.updateFirmware?.(fwVersion1);
    }

    _parseVidPID(vidPid) {
        if (vidPid.length !== 4)
            return;

        if (this._initialized)
            return;

        this._initialized = true;

        const vid = vidPid[0] << 8 | vidPid[1];
        const pid = vidPid[2] << 8 | vidPid[3];

        this._log.info(`VID: ${hexBytes(vid)},  PID: ${hexBytes(pid)}`);

        this._modelData = RedmiBudsModelList.find(model => model.id.vid.includes(vid) &&
                model.id.pid.includes(pid));

        if (!this._modelData) {
            this._log.info(`No model matched for VID: ${hexBytes(vid)} PID: ${hexBytes(pid)}`);
            return;
        }

        this._callbacks?.modelIntialized?.(this._modelData, vid, pid);
        this._sendInitializationRequests();
    }

    _decodeDeviceInfo(payload) {
        let i = 0;
        while (i < payload.length) {
            const len = payload[i];
            if (i + 1 >= payload.length)
                break;

            const index = payload[i + 1];

            switch (index) {
                case DeviceInfoRetType.FIRMWARE: {
                    if (i + 6 <= payload.length)
                        this._parseFirmware(payload.slice(i + 2, i + 6));
                    break;
                }

                case DeviceInfoRetType.VID_PID: {
                    if (i + 6 <= payload.length)
                        this._parseVidPID(payload.slice(i + 2, i + 6));
                    break;
                }

                case DeviceInfoRetType.BATTERY: {
                    if (i + 5 <= payload.length)
                        this._parseBatteryInfo(payload[i + 2], payload[i + 3], payload[i + 4]);
                    break;
                }
            }

            i += len + 1;
        }
    }

    _decodeDeviceRunInfo(payload) {
        let i = 0;

        while (i < payload.length) {
            const len = payload[i];
            if (i + 1 >= payload.length)
                break;

            const index = payload[i + 1];
            switch (index) {
                case 0x09: {
                    if (i + 3 > payload.length)
                        break;

                    this._parseNoiseControl(payload.slice(i + 2, i + 4));
                    break;
                }
/*
                case 0x0A: {
                    if (i + 2 > payload.length)
                        break;

                    const enabled = payload[i + 2] === 0x00;
                    this._callbacks?.updateInEarSetting?.(enabled);
                    break;
                }
*/
            }

            i += len + 1;
        }
    }

    _decodeDeviceUpdate(payload) {
        let i = 0;

        while (i < payload.length) {
            const len = payload[i];
            if (i + 1 >= payload.length)
                break;

            const index = payload[i + 1];
            switch (index) {
                case 0x00: {
                    if (i + 4 >= payload.length)
                        break;

                    this._parseBatteryInfo(payload[i + 2], payload[i + 3], payload[i + 4]);
                    break;
                }

                case 0x04: {
                    if (i + 3 >= payload.length)
                        break;

                    this._parseNoiseControl(payload.slice(i + 2, i + 4));
                    break;
                }
            }

            i += len + 1;
        }
    }

    _decodeNotifyConfig(payload) {
        let i = 0;

        while (i < payload.length) {
            const len = payload[i];
            if (i + 2 >= payload.length)
                break;

            const index = payload[i + 2];
            switch (index) {
                case 0x0C: {
                    if (i + 3 >= payload.length)
                        break;

                    const state = payload[i + 3];
                    const left = (state & 0x08) !== 0;
                    const right = (state & 0x04) !== 0;
                    this._callbacks?.updateInEarState?.(left, right);
                    break;
                }

                case 0x0B: {
                    if (i + 4 >= payload.length)
                        break;

                    this._parseNoiseControl(payload.slice(i + 3, i + 5));
                    break;
                }
            }

            i += len + 1;
        }
    }

    _decodeGetConfig(payload) {
        if (payload.length < 4)
            return;

        const config = payload[2];
        const data = payload.slice(3);
        switch (config) {
            case ConfigType.SERIAL_NUMBER:
                this._parseSerial(data);
                break;

            case ConfigType.GESTURES:
                this._parseGestures(data);
                break;

            case ConfigType.AUTO_ANSWER:
                if (this._modelData.autoAnswer)
                    this._parseAutoAnswer(data);
                break;

            case ConfigType.DOUBLE_CONNECTION:
                if (this._modelData.dualConnection)
                    this._parseDualConnection(data);
                break;

            case ConfigType.EQ_PRESET:
                if (this._modelData.eqPreset)
                    this._parseEqPreset(data);
                break;

            case ConfigType.LONG_GESTURES:
                if (this._modelData.gestureOptions?.noiseControlModes)
                    this._parseLongPressMode(data);
                break;

            case ConfigType.ANC:
                if (this._modelData.noiseControl)
                    this._parseNoiseControl(data);
                break;

            case ConfigType.ADAPTIVE_ANC:
                if (this._modelData.adaptiveNcSwitch)
                    this._parseAdaptiveNC(data);
                break;

            case ConfigType.LOW_LATENCY:
                if (this._modelData.lowLatencyMode)
                    this._parseLowLatency(data);
                break;

            case ConfigType.ADAPTIVE_SOUND:
                if (this._modelData.adaptiveSound)
                    this._parseAdaptiveSound(data);
                break;

            case ConfigType.EQ_CURVE:
                if (this._modelData.eqPreset?.custom)
                    this._parseCustomEq(data);
                break;

            default:
                this._log.error(`Unhandled config: ${config.toString(16).padStart(2, '0')}`);
                break;
        }
    }

    _getConfig(configType, loginfo) {
        this._queueRequest(MessageType.PHONE_REQUEST, Opcode.GET_CONFIG,
            this._nextSeq(), [0x00, configType], loginfo);
    }

    _setConfig(configType, data, loginfo) {
        const configData = [0x00, configType, ...data];
        const payload = [configData.length, ...configData];
        this._queueRequest(MessageType.PHONE_REQUEST, Opcode.SET_CONFIG,
            this._nextSeq(), payload, loginfo);
    }

    _getNoiseControl() {
        this._getConfig(ConfigType.ANC, 'Get NoiseControl');
    }

    _parseNoiseControl(data) {
        if (data.length < 2)
            return;

        this._log.info('Parse NoiseControl');

        const mode = data[0];
        const strength = data[1];
        this._callbacks?.updateNoiseControl?.(mode);

        const hasNCStrength = this._modelData.noiseCancellationStrength ||
                this._modelData.ancLevel;

        const hasAmbientStrength = this._modelData.transparencyStrength;
        const ncByte = this._modelData.noiseControl.noiseCancellation;
        const ambByte = this._modelData.noiseControl.transparency;

        if (mode === ncByte && hasNCStrength)
            this._callbacks?.updateAncStrength?.(strength);
        else if (mode === ambByte && hasAmbientStrength)
            this._callbacks?.updateAmbientStrength?.(strength);
    }

    setNoiseControl(mode, strength) {
        const longinfo = `Set NoiseControl mode: ${mode}  strength: ${strength}`;
        this._setConfig(ConfigType.ANC, [mode, strength], longinfo);
    }

    _getAdaptiveNC() {
        this._getConfig(ConfigType.ANC, 'Get AdaptiveNC');
    }

    _parseAdaptiveNC(data) {
        this._log.info('Parse AdaptiveNC');
        const enable = booleanFromByte(data[0]);
        if (enable === null)
            return;

        this._callbacks?.updateAdaptiveNC?.(enable);
    }

    setAdaptiveNC(enabled) {
        const loginfo = `Set AdaptiveNC enabled: ${enabled}`;
        this._setConfig(ConfigType.ADAPTIVE_ANC, [enabled ? 0x01 : 0x00], loginfo);
    }

    _getEqPreset() {
        this._getConfig(ConfigType.EQ_PRESET, 'Get EqPreset');
    }

    _parseEqPreset(data) {
        this._log.info('Parse EqPreset');
        const preset = this._modelData.eqPreset;
        if (!preset) {
            this._log.info('No config available for Eq Preset');
            return;
        }

        const mode = data[0];

        if (!isValidByte(mode, preset))
            return;

        this._callbacks?.updateEqPreset?.(mode);
    }

    setEqPreset(mode) {
        const loginfo = `Set EqPreset mode: ${mode}`;
        this._setConfig(ConfigType.EQ_PRESET, [mode], loginfo);
    }

    _getCustomEq() {
        this._getConfig(ConfigType.EQ_CURVE, 'Get CustomEq');
    }

    _parseCustomEq(data) {
        this._log.info('Parse CustomEq');
        if (data.length < 37)
            return;

        const arr = [
            data[9],
            data[12],
            data[15],
            data[18],
            data[21],
            data[24],
            data[27],
            data[30],
            data[33],
            data[36],
        ].map(v => {
            if (v >= 129)
                return 128 - v;

            return v;
        });

        this._callbacks?.updateCustomEq?.(arr);
    }

    setCustomEq(eqArray) {
        const eqCurve = eqArray.map(v => {
            if (v < 0)
                return 128 - v;

            return v;
        });

        const data = [
            0x05, 0x01, 0x01, 0x0A,
            0x00, 0x3E, eqCurve[0],
            0x00, 0x7D, eqCurve[1],
            0x00, 0xFA, eqCurve[2],
            0x01, 0xF4, eqCurve[3],
            0x03, 0xE8, eqCurve[4],
            0x07, 0xD0, eqCurve[5],
            0x0F, 0xA0, eqCurve[6],
            0x1F, 0x40, eqCurve[7],
            0x2E, 0xE0, eqCurve[8],
            0x3E, 0x80, eqCurve[9],
        ];

        this._setConfig(ConfigType.EQ_CURVE, data, 'Set CustomEq');
    }

    _getSerial() {
        this._getConfig(ConfigType.SERIAL_NUMBER, 'Get Serial Number');
    }

    _parseSerial(payload) {
        if (!payload)
            return;

        const serial = new TextDecoder().decode(new Uint8Array(payload));
        this._callbacks?.updateSerial?.(serial);
    }

    _getAdaptiveSound() {
        this._getConfig(ConfigType.ADAPTIVE_SOUND, 'Get AdaptiveSound');
    }

    _parseAdaptiveSound(data) {
        this._log.info('Parse AdaptiveSound');
        const enable = booleanFromByte(data[0]);
        if (enable === null)
            return;

        this._callbacks?.updateAdaptiveSound?.(enable);
    }

    setAdaptiveSound(enabled) {
        const loginfo = `Set AdaptiveSound enabled: ${enabled}`;
        this._setConfig(ConfigType.ADAPTIVE_SOUND, [enabled ? 0x01 : 0x00], loginfo);
    }

    _getDualConnection() {
        this._getConfig(ConfigType.DOUBLE_CONNECTION, 'Get DualConnection');
    }

    _parseDualConnection(data) {
        this._log.info('Parse DualConnection');
        const enable = booleanFromByte(data[0]);
        if (enable === null)
            return;

        this._callbacks?.updateDualConnection?.(enable);
    }

    setDualConn(enabled) {
        const loginfo = `Set DualConnection enabled: ${enabled}`;
        this._setConfig(ConfigType.DOUBLE_CONNECTION, [enabled ? 0x01 : 0x00], loginfo);
    }

    _getAutoAnswer() {
        this._getConfig(ConfigType.AUTO_ANSWER, 'Get AutoAnswer');
    }

    _parseAutoAnswer(data) {
        this._log.info('Parse AutoAnswer');
        const enable = booleanFromByte(data[0]);
        if (enable === null)
            return;

        this._callbacks?.updateAutoAnswer?.(enable);
    }

    setAutoAnswer(enabled) {
        const loginfo = `Set AutoAnswer enabled: ${enabled}`;
        this._setConfig(ConfigType.AUTO_ANSWER, [enabled ? 0x01 : 0x00], loginfo);
    }

    _getLowLatency() {
        this._getConfig(ConfigType.LOW_LATENCY, 'Get LowLatency');
    }

    _parseLowLatency(data) {
        this._log.info('Parse LowLatency');
        const enable = booleanFromByte(data[0]);
        if (enable === null)
            return;

        this._callbacks?.updateLowLatency?.(enable);
    }

    setLowLatency(enabled) {
        const loginfo = `Set LowLatency enabled: ${enabled}`;
        this._setConfig(ConfigType.LOW_LATENCY, [enabled ? 0x01 : 0x00], loginfo);
    }

    _getGestures() {
        this._getConfig(ConfigType.GESTURES, 'Get Gestures');
    }

    _parseGestures(data) {
        this._log.info('Parse Gestures');

        const gestureTypes = this._modelData.gestureOptions?.gestureTypes;
        if (!gestureTypes)
            return;

        for (let i = 0; i + 2 < data.length; i += 3) {
            const type = data[i];
            const left = data[i + 1];
            const right = data[i + 2];

            if (type === 0x04) {
                if (gestureTypes.single === undefined)
                    this._log.error('Single-click gestures not supported');
                else
                    this._callbacks?.updateGestureSingle?.(left, right);

                continue;
            }

            if (type === 0x01) {
                if (gestureTypes.double === undefined)
                    this._log.error('Double-click gestures not supported');
                else
                    this._callbacks?.updateGestureDouble?.(left, right);

                continue;
            }

            if (type === 0x02) {
                if (gestureTypes.triple === undefined)
                    this._log.error('Triple-click gestures not supported');
                else
                    this._callbacks?.updateGestureTriple?.(left, right);

                continue;
            }

            if (type === 0x03) {
                if (gestureTypes['action-hold'] === undefined)
                    this._log.error('Long-press gestures not supported');
                else
                    this._callbacks?.updateGestureLong?.(left, right);

                continue;
            }

            if (type === 0x05) {
                if (gestureTypes.swipe === undefined)
                    this._log.error('Swipe gestures not supported');
                else
                    this._callbacks?.updateGestureSwipe?.(left, right);

                continue;
            }

            this._log.error(`Unknown gesture type: 0x${type.toString(16)}`);
        }
    }

    setGesture(type, position, value) {
        const loginfo = `Set Gesture type: ${type}, position: ${position}, value: ${value}`;
        const gestureTypes = this._modelData?.gestureOptions?.gestureTypes;
        const interactionType = gestureTypes[type];

        if (interactionType === undefined) {
            this._log.error(`Unknown gesture type: ${type}`);
            return;
        }

        const data = [interactionType, 0xFF, 0xFF];
        if (position === 'left')
            data[1] = value;
        else if (position === 'right')
            data[2] = value;

        this._setConfig(ConfigType.GESTURES, data, loginfo);
    }

    _getLongPressMode() {
        this._getConfig(ConfigType.LONG_GESTURES, 'Get LongPressMode');
    }

    _parseLongPressMode(data) {
        this._log.info('Parse LongPressMode');
        if (data.length < 2)
            return;

        const leftPressMode = data[0];
        const rightPressMode = data[1];
        this._callbacks?.updateLongGestures?.(leftPressMode, rightPressMode);
    }

    setLongPressMode(isleft, mode) {
        const loginfo = `Set LongPressMode isleft: ${isleft}, mode: ${mode}`;
        const data = [0xFF, 0xFF];
        if (isleft)
            data[0] = mode;
        else
            data[1] = mode;

        this._setConfig(ConfigType.LONG_GESTURES, data, loginfo);
    }

    setRingMyBuds(state, isLeft = false) {
        const loginfo = `Set RingMyBuds state: ${state}, isLeft: ${isLeft}`;
        const enabled = state === 'playing';
        let mask;

        if (!enabled)
            mask = 0x03;
        else
            mask = isLeft ? 0x01 : 0x02;

        const data = [enabled ? 0x01 : 0x00, mask];

        this._setConfig(ConfigType.RING_MY_BUDS, data, loginfo);
    }

    destroy() {
        if (this._pendingTimeout)
            GLib.source_remove(this._pendingTimeout);
        this._pendingTimeout = null;

        if (this._infoTimeout)
            GLib.source_remove(this._infoTimeout);
        this._infoTimeout = null;

        super.destroy?.();
    }
});
