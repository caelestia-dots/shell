'use strict';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';

import {createLogger, getDeviceIdentifier, hexBytes} from '../logger.js';
import {SocketHandler} from '../socketByProfile.js';
import {booleanFromByte, isValidByte} from '../deviceUtils.js';
import {
    SenhBudsModelList, VendorType, CommandType, QcomCommandType
} from './senhBudsConfig.js';

/**
Reference Material and Credits
https://github.com/hatemosphere/hdb630-control-macos

https://github.com/nikita36078/sennheiser-desktop-client
**/

const HEADER = [0xFF, 0x03];

export const SenhBudsSocket = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_SenhSocket',
}, class SenhBudsSocket extends SocketHandler {
    _init(devicePath, profileManager, profile, callbacks) {
        super._init(devicePath, profileManager, profile);
        const identifier = getDeviceIdentifier(devicePath);
        const tag = `SenhSocket-${identifier}`;
        this._log = createLogger(tag);
        this._log.info('SenhSocket init');
        this._callbacks = callbacks;
        this._rxBuffer = [];
        this._txQueue = [];
        this._pendingRequest = null;
        this._pendingTimeout = null;
        this._modelData = null;
        this._battInfo = {
            battery1Level: 0,
            battery2Level: 0,
            battery3Level: 0,
            battery1Status: 'disconnected',
            battery2Status: 'disconnected',
            battery3Status: 'disconnected',
        };

        this.startSocket();
    }

    postConnectInitialization() {
        this._getModelId();
    }

    _queueRequest(vendor, command, payload, loginfo = '') {
        this._txQueue.push({vendor, command, payload, loginfo});
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

        this._encode(item.vendor, item.command, item.payload);
        this._pendingRequest = item;

        if (this._pendingTimeout) {
            GLib.source_remove(this._pendingTimeout);
            this._pendingTimeout = null;
        }

        this._pendingTimeout = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 250, () => {
            this._log.info(`Response Timeout type: ${hexBytes(item.command)}`);
            this._pendingRequest = null;
            this._processQueue();
            this._pendingTimeout = null;
            return GLib.SOURCE_REMOVE;
        });
    }

    _completePendingRequest(msg) {
        if (!this._pendingRequest)
            return;

        const pending = this._pendingRequest;

        if (msg.vendor !== pending.vendor)
            return;

        const requestCommand = pending.command;
        const responseCommand = requestCommand | 0x0100;
        const errorCommand = requestCommand | 0x0180;

        if (msg.command !== responseCommand && msg.command !== errorCommand)
            return;

        if (msg.command === errorCommand)
            log(`Command 0x${requestCommand.toString(16)} failed`);

        if (this._pendingTimeout)
            GLib.source_remove(this._pendingTimeout);

        this._pendingTimeout = null;
        this._pendingRequest = null;
        this._processQueue();
    }

    _encode(vendor, command, payload = []) {
        const payloadLength = payload.length;

        const out = [
            ...HEADER,
            payloadLength >> 8 & 0xFF,
            payloadLength & 0xFF,
            vendor >> 8 & 0xFF,
            vendor & 0xFF,
            command >> 8 & 0xFF,
            command & 0xFF,
            ...payload,
        ];

        this.sendMessage(out);
    }

    processData(bytes) {
        this._rxBuffer.push(...bytes);

        while (true) {
            const msg = this._extractMessage();
            if (!msg)
                break;

            if (msg.vendor === VendorType.QCOM)
                this._handleMessageQcom(msg);
            else if (msg.vendor === VendorType.SENH)
                this._handleMessageSenh(msg);
            else
                this._log.info(`Unknown vendor command tpye ${hexBytes(msg.vendor)}`);

            this._completePendingRequest(msg);
        }
    }

    _extractMessage() {
        const buf = this._rxBuffer;

        for (let i = 0; i <= buf.length - 8; i++) {
            if (buf[i] !== HEADER[0] || buf[i + 1] !== HEADER[1])
                continue;

            const payloadLength = buf[i + 2] << 8 | buf[i + 3];
            const totalLength = payloadLength + 8;

            if (i + totalLength > buf.length)
                return null;

            const raw = buf.slice(i, i + totalLength);

            let nextHeader = -1;
            for (let j = 8; j < raw.length - 1; j++) {
                if (raw[j] === HEADER[0] && raw[j + 1] === HEADER[1]) {
                    nextHeader = j;
                    break;
                }
            }

            if (nextHeader !== -1) {
                this._rxBuffer.splice(0, i + nextHeader);
                return this._extractMessage();
            }

            this._rxBuffer.splice(0, i + totalLength);
            return this._parseMessage(raw);
        }

        return null;
    }

    _parseMessage(raw) {
        const payloadLength = raw[2] << 8 | raw[3];
        const vendor = raw[4] << 8 | raw[5];
        const command = raw[6] << 8 | raw[7];
        const payload = raw.slice(8, 8 + payloadLength);
        return {vendor, command, payload};
    }

    _handleMessageQcom(msg) {
        this._log.info(`QCOM: CommandType: [${hexBytes(msg.command)}] ` +
            `payload: [${hexBytes(msg.payload)}]`);

        switch (msg.command) {
            case QcomCommandType.SERIAL_RET: {
                this._parseSerial(msg.payload);
                break;
            }

            default:
                this._log.info(`Unhandled QCOM command ${hexBytes(msg.command)}`);
        }
    }

    _handleMessageSenh(msg) {
        this._log.info(`SENH: CommandType: [${hexBytes(msg.command)}] ` +
            `payload: [${hexBytes(msg.payload)}]`);

        switch (msg.command) {
            case CommandType.MODELID_RET: {
                this._parseModelId(msg.payload);
                break;
            }

            case CommandType.FIRMWARE_RET: {
                this._parseFirmware(msg.payload);
                break;
            }

            case CommandType.BATT_LEVEL_RET:
            case CommandType.BATT_LEVEL_NOTI: {
                this._parseBatteryLevel(msg.payload);
                break;
            }

            case CommandType.BATT_STATUS_RET:
            case CommandType.BATT_STATUS_NOTI: {
                this._parseBatteryStatus(msg.payload);
                break;
            }

            case CommandType.INEAR_STATE_RET:
            case CommandType.INEAR_STATE_NOTI: {
                this._parseInEarState(msg.payload);
                break;
            }

            case CommandType.ANC_STATUS_RET:
            case CommandType.ANC_STATUS_RET2:
            case CommandType.ANC_STATUS_NOTI: {
                if (this._modelData?.noiseControl)
                    this._parseNoiseControl(msg.payload);
                break;
            }

            case CommandType.ANC_MODE_RET:
            case CommandType.ANC_MODE_RET2:
            case CommandType.ANC_MODE_NOTI: {
                if (this._modelData?.noiseControl)
                    this._parseNoiseControlMode(msg.payload);
                break;
            }

            case CommandType.ANC_TRANSP_LEVEL_RET:
            case CommandType.ANC_TRANSP_LEVEL_RET2:
            case CommandType.ANC_TRANSP_LEVEL_NOTI: {
                if (this._modelData?.noiseControl?.type === 2)
                    this._parseAncTransparencyLevel(msg.payload);
                break;
            }

            case CommandType.TRANSP_STATE_RET:
            case CommandType.TRANSP_STATE_RET2:
            case CommandType.TRANSP_STATE_NOTI: {
                this._log.info('Parse Type1 Transparency State');
                break;
            }

            case CommandType.TRANSP_LEVEL_RET:
            case CommandType.TRANSP_LEVEL_RET2:
            case CommandType.TRANSP_LEVEL_NOTI: {
                this._log.info('Parse Type1 Transparency Level');
                break;
            }

            case CommandType.AUDIO_MODE_RET:
            case CommandType.AUDIO_MODE_RET2:
            case CommandType.AUDIO_MODE_NOTI: {
                if (this._modelData?.audioMode)
                    this._parseAudioMode(msg.payload);
                break;
            }

            case CommandType.EQ_CONFIG_RET: {
                if (this._modelData?.eq)
                    this._parseEqConfig(msg.payload);
                break;
            }

            case CommandType.EQ_BAND_RET:
            case CommandType.EQ_BAND_RET2:
            case CommandType.EQ_BAND_NOTI: {
                if (this._modelData?.eq)
                    this._parseEqBand(msg.payload);
                break;
            }

            case CommandType.BASS_BOOST_RET:
            case CommandType.BASS_BOOST_RET2:
            case CommandType.BASS_BOOST_NOTI: {
                if (this._modelData?.eq?.bassBoost)
                    this._parseBassBoost(msg.payload);
                break;
            }

            case CommandType.PEQ_FREQ_RET:
            case CommandType.PEQ_FREQ_RET2:
            case CommandType.PEQ_FREQ_NOTI: {
                if (this._modelData?.peq)
                    this._parsePeqFreq(msg.payload);
                break;
            }

            case CommandType.PEQ_GAIN_RET:
            case CommandType.PEQ_GAIN_RET2:
            case CommandType.PEQ_GAIN_NOTI: {
                if (this._modelData?.peq)
                    this._parsePeqGain(msg.payload);
                break;
            }

            case CommandType.PEQ_Q_RET:
            case CommandType.PEQ_Q_RET2:
            case CommandType.PEQ_Q_NOTI: {
                if (this._modelData?.peq)
                    this._parsePeqQ(msg.payload);
                break;
            }

            case CommandType.PEQ_FILTER_RET:
            case CommandType.PEQ_FILTER_RET2:
            case CommandType.PEQ_FILTER_NOTI: {
                if (this._modelData?.peq)
                    this._parsePeqFilter(msg.payload);
                break;
            }

            case CommandType.PEQ_PREGAIN_RET:
            case CommandType.PEQ_PREGAIN_RET2: {
                if (this._modelData?.peq)
                    this._parsePeqPreGain(msg.payload);
                break;
            }

            case CommandType.PEQ_PREGAIN_NOTI: {
                if (this._modelData?.peq)
                    this._parsePeqPreGainNoti(msg.payload);
                break;
            }

            case CommandType.CROSSFEED_RET:
            case CommandType.CROSSFEED_NOTI: {
                if (this._modelData?.sideTone)
                    this._parseCrossfeed(msg.payload);
                break;
            }

            case CommandType.SIDETONE_RET:
            case CommandType.SIDETONE_RET2: {
                if (this._modelData?.sideTone)
                    this._parseSideTone(msg.payload);
                break;
            }

            case CommandType.COMFORT_CALL_RET:
            case CommandType.COMFORT_CALL_RET2: {
                if (this._modelData?.comfortCalls)
                    this._parseComfortCall(msg.payload);
                break;
            }

            case CommandType.PAUSE_ON_TRANS_RET:
            case CommandType.PAUSE_ON_TRANS_RET2: {
                if (this._modelData?.transPause)
                    this._parseTransPause(msg.payload);
                break;
            }

            case CommandType.INEAR_SETTING_RET:
            case CommandType.INEAR_SETTING_RET2: {
                if (this._modelData?.inEarDetection)
                    this._parseInEarSetting(msg.payload);
                break;
            }

            case CommandType.SMART_PAUSE_RET:
            case CommandType.SMART_PAUSE_RET2: {
                if (this._modelData?.smartPause)
                    this._parseSmartPause(msg.payload);
                break;
            }

            case CommandType.AUTO_CALL_RET:
            case CommandType.AUTO_CALL_RET2: {
                if (this._modelData?.autoAnswer)
                    this._parseAutoAnswer(msg.payload);
                break;
            }

            case CommandType.AUTO_POWER_OFF_RET:
            case CommandType.AUTO_POWER_OFF_RET2: {
                if (this._modelData?.autoPowerOff)
                    this._parseAutoPowerOff(msg.payload);
                break;
            }

            case CommandType.CODEC_RET:
            case CommandType.CODEC_NOTI: {
                if (this._modelData?.reportsCodec)
                    this._parseCodec(msg.payload);
                break;
            }

            case CommandType.PAIRED_DEVICEMAX_RET: {
                if (this._modelData?.dualConnection)
                    this._parsePairedDevMax(msg.payload);
                break;
            }

            case CommandType.PAIRED_OWN_DEVICE_RET: {
                if (this._modelData?.dualConnection)
                    this._parsePairedDevOwn(msg.payload);
                break;
            }

            case CommandType.PAIRED_DEVICELIST_RET: {
                if (this._modelData?.dualConnection)
                    this._parsePairedDevList(msg.payload);
                break;
            }

            case CommandType.PAIRED_DEVICEINFO_RET: {
                if (this._modelData?.dualConnection)
                    this._parsePairedDevInfo(msg.payload);
                break;
            }

            case CommandType.PAIRED_DEVICE_STATUS_RET:
            case CommandType.PAIRED_DEVICE_STATUS_NOTI: {
                if (this._modelData?.dualConnection)
                    this._parsePairedDevStatus(msg.payload);
                break;
            }

            case CommandType.PAIRED_DEVICE_CONNECT_RET: {
                if (this._modelData?.dualConnection)
                    this._parsePairedDevConnect();
                break;
            }

            case CommandType.PAIRED_DEVICE_CONNECT_ERR: {
                if (this._modelData?.dualConnection)
                    this._parsePairedDevConnectErr();
                break;
            }

            case CommandType.PAIRED_DEVICE_DISCONNECT_RET: {
                if (this._modelData?.dualConnection)
                    this._parsePairedDevDisconnect();
                break;
            }

            case CommandType.PAIRED_DEVICE_DISCONNECT_ERR: {
                if (this._modelData?.dualConnection)
                    this._parsePairedDevDisconnectErr();
                break;
            }

            case CommandType.PAIRED_DEVICE_REMOVE_RET: {
                if (this._modelData?.dualConnection)
                    this._parsePairedDevRemove();
                break;
            }

            case CommandType.PAIRED_DEVICE_REMOVE_ERR: {
                if (this._modelData?.dualConnection)
                    this._parsePairedDevRemoveErr();
                break;
            }

            default:
                this._log.info(`Unhandled command ${hexBytes(msg.command)}`);
        }
    }

    _encodeQcomm(command, loginfo, payload = []) {
        this._queueRequest(VendorType.QCOM, command, payload, loginfo);
    }

    _encodeSenh(command, loginfo, payload = []) {
        this._queueRequest(VendorType.SENH, command, payload, loginfo);
    }

    _getModelId() {
        this._log.info('Get Model ID');
        this._encode(VendorType.SENH, CommandType.MODELID_GET);
    }

    _parseModelId(payload) {
        if (this._initialized)
            return;

        this._initialized = true;
        const versionModelId = new TextDecoder().decode(Uint8Array.from(payload));
        const modelId = versionModelId.split(' ')[0];
        this._modelData = SenhBudsModelList.find(model => model.id?.includes(modelId));

        if (!this._modelData) {
            this._log.info(`No model matched for Model ID: ${modelId} ` +
                `payload: [${hexBytes(payload)}]`);
            return;
        }

        this._callbacks?.modelIntialized?.(this._modelData, modelId);
        this._sendInitializationRequests();
    }

    _sendInitializationRequests() {
        this._registerNotifications();
        this._getConfiguration();
    }

    _registerNotifications() {
        const notifications = this._modelData.registerNotification;

        for (const feature of notifications) {
            const payload = [feature];
            const loginfo = `Register notification feature: ${hexBytes(feature)}`;
            this._encodeSenh(CommandType.REGISTER_NOTI_SET, loginfo, payload);
        }
    }

    _getConfiguration() {
        this._getFirmware();
        this._getSerial();
        this._getBatteryLevel();
        this._getBatteryStatus();
        this._getInEarState();

        if (this._modelData.noiseControl)
            this._getNoiseControl();

        if (this._modelData.noiseControl)
            this._getNoiseControlMode();

        if (this._modelData.noiseControl?.type === 2)
            this._getAncTransparencyLevel();

        if (this._modelData.audioMode)
            this._getAudioMode();

        if (this._modelData.eq) {
            this._getEqAllBands();
            this._getEqConfig();
        }

        if (this._modelData.eq?.bassBoost)
            this._getBassBoost();

        if (this._modelData.peq)
            this._getAllBandParams();

        if (this._modelData.crossfeed)
            this._getCrossfeed();

        if (this._modelData.sideTone)
            this._getSideTone();

        if (this._modelData.comfortCalls)
            this._getComfortCall();

        if (this._modelData.transparencyPause)
            this._getTransPause();

        if (this._modelData.inEarDetection) {
            this._getInEarSetting();

            if (this._modelData.smartPause)
                this._getSmartPause();

            if (this._modelData.autoAnswer)
                this._getAutoAnswer();

            if (this._modelData.autoPowerOff)
                this._getAutoPowerOff();
        }

        if (this._modelData.reportsCodec)
            this._getCodec();

        if (this._modelData.dualConnection) {
            this._getPairedDevMax();
            this._getPairedDevOwn();
            this._getPairedDevList();
        }
    }

    _getFirmware() {
        const loginfo = 'Get Firmware';
        this._encodeSenh(CommandType.FIRMWARE_GET, loginfo);
    }

    _parseFirmware(payload) {
        if (payload.length < 6)
            return;

        const fw = `${payload[0]}.${payload[1]}.${payload[2]}`;
        this._callbacks?.updateFirmware?.(fw);
    }

    _getSerial() {
        const loginfo = 'Get Serial';
        this._encodeQcomm(QcomCommandType.SERIAL_GET, loginfo);
    }

    _parseSerial(payload) {
        if (!payload)
            return;

        const serial = new TextDecoder().decode(new Uint8Array(payload));
        this._callbacks?.updateSerial?.(serial);
    }

    _getBatteryLevel() {
        const loginfo = 'Get Battery Level';
        this._encodeSenh(CommandType.BATT_LEVEL_GET, loginfo);
    }

    _parseBatteryLevel(payload) {
        if (payload.length < 1)
            return;

        this._log.info('Parse Battery Level');
        this._battInfo.battery1Level = payload[0];
        if (this._modelData.batteryMultiple && payload.length >= 2)
            this._battInfo.battery2Level = payload[1];

        if (this._modelData.batteryCase && payload.length >= 3)
            this._battInfo.battery3Level = payload[2];

        this._callbacks?.updateBatteryProps?.(this._battInfo);
    }

    _getBatteryStatus() {
        const loginfo = 'Get Battery Status';
        this._encodeSenh(CommandType.BATT_STATUS_GET, loginfo);
    }

    _parseBatteryStatus(payload) {
        if (payload.length < 1)
            return;

        this._log.info('Parse Battery Status');
        const getBatteryState = byte => {
            if (byte === 1)
                return 'charging';

            return 'discharging';
        };

        this._battInfo.battery1Status = getBatteryState(payload[0]);
        if (this._modelData.batteryMultiple && payload.length >= 2)
            this._battInfo.battery2Status = getBatteryState(payload[1]);

        if (this._modelData.batteryCase && payload.length >= 3)
            this._battInfo.battery3Status = getBatteryState(payload[2]);

        this._callbacks?.updateBatteryProps?.(this._battInfo);
    }

    _getInEarState() {
        const loginfo = 'Get InEarState';
        this._encodeSenh(CommandType.INEAR_STATE_GET, loginfo);
    }

    _parseInEarState(payload) {
        if (payload.length < 1)
            return;

        const stateToString = state => {
            switch (state) {
                case 0:
                    return 'UNKNOWN';
                case 1:
                    return 'IN_CASE';
                case 2:
                    return 'NOT_ON_HEAD';
                case 3:
                    return 'ON_HEAD';
                default:
                    return `INVALID(${state})`;
            }
        };

        const bud1 = stateToString(payload[0]);
        let bud2 = bud1;
        if (this._modelData.type === 'earbuds' && payload.length >= 2)
            bud2 = stateToString(payload[1]);

        this._log.info(`Parse Buds1State: ${bud1} Buds2State: ${bud2}`);
        this._callbacks?.updateInEarStatus?.(bud1, bud2);
    }

    _getNoiseControl() {
        const loginfo = 'Get NoiseControl';
        this._encodeSenh(CommandType.ANC_STATUS_GET, loginfo);
    }

    _parseNoiseControl(payload) {
        if (payload.length < 1)
            return;

        this._log.info('Parse NoiseControl');
        const enable = booleanFromByte(payload[0]);
        if (enable === null)
            return;

        if (this._modelData.noiseControl?.type === 2)
            this._callbacks?.updateNoiseControl?.(enable);
    }

    setNoiseControl(enable) {
        const loginfo = 'Set NoiseControl';
        const payload = [enable ? 0x01 : 0x00];
        this._encodeSenh(CommandType.ANC_STATUS_SET, loginfo, payload);
    }

    _getNoiseControlMode() {
        const loginfo = 'Get NoiseControl Mode';
        this._encodeSenh(CommandType.ANC_MODE_GET, loginfo);
    }

    _parseNoiseControlMode(payload) {
        if (payload.length < 2)
            return;

        this._log.info('Parse NoiseControl Mode');
        const windMode = payload[1];
        const comfortState = payload[3] === 0x01;
        const adaptiveState = payload[5] === 0x01;

        if (this._modelData.noiseControl?.type === 2)
            this._callbacks?.updateNoiseControlMode?.(windMode, comfortState, adaptiveState);
    }

    setNoiseControlMode(mode, value) {
        const loginfo = 'Set NoiseControl Mode';
        let state;
        if (mode !== 1)
            state =  value ? 0x01 : 0x00;
        else
            state = value;
        const payload = [mode, state];
        this._encodeSenh(CommandType.ANC_MODE_SET, loginfo, payload);
    }

    _getAncTransparencyLevel() {
        const loginfo = 'Get AncTransparencyLevel';
        this._encodeSenh(CommandType.ANC_TRANSP_LEVEL_GET, loginfo);
    }

    _parseAncTransparencyLevel(payload) {
        if (payload.length < 1)
            return;

        this._log.info('Parse AncTransparencyLevel');
        const level = payload[0];

        if (this._modelData.noiseControl?.type === 2)
            this._callbacks?.updateAncTransparencyLevel?.(level);
    }

    setAncTransparencyLevel(level) {
        const loginfo = 'Set AncTransparencyLevel';
        const payload = [level];
        this._encodeSenh(CommandType.ANC_TRANSP_LEVEL_SET, loginfo, payload);
    }

    _getAudioMode() {
        const loginfo = 'Get AudioMode';
        this._encodeSenh(CommandType.AUDIO_MODE_GET, loginfo);
    }

    _parseAudioMode(payload) {
        if (payload.length < 2)
            return;

        this._log.info('Parse AudioMode');
        const mode = payload[1];
        if (!isValidByte(mode, this._modelData.audioMode)) {
            this._log.info(`Received invalid audio Mode level: ${mode} Supported?`);
            return;
        }
        this._callbacks?.updateAudioMode?.(mode);
    }

    setAudioMode(mode) {
        const loginfo = 'Set AudioMode';
        const payload = [0x00, mode];
        this._encodeSenh(CommandType.AUDIO_MODE_SET, loginfo, payload);
    }

    _getEqConfig() {
        const loginfo = 'Get EqConfig';
        this._encodeSenh(CommandType.EQ_CONFIG_GET, loginfo);
    }

    _parseEqConfig(payload) {
        if (payload.length < 5)
            return;

        const bandCount = payload[0];
        const minGain = payload[1];
        const maxGain = payload[2];
        const selPresets = payload[3];
        const userPresets = payload[4];

        this._log.info(`Parse EqConfig bandCount: ${bandCount} minGain: ${minGain} ` +
                `maxGain: ${maxGain} selPresets: ${selPresets} userPresets: ${userPresets} `);
    }

    _getEqAllBands() {
        const bands = this._modelData?.eq?.displayedBand;
        if (!bands || bands.length === 0)
            return;

        for (let index = 0; index < bands.length; index++) {
            const loginfo = `Get EqAllBands ${index}`;
            const payload = [index];
            this._encodeSenh(CommandType.EQ_BAND_GET, loginfo, payload);
        }
    }

    _decodeSignedBytes(arr) {
        return arr.map(v => (v > 127 ? v - 256 : v) / 10);
    }

    _encodeSignedByte(value) {
        const scaled = Math.round(value * 10);
        return scaled < 0 ? scaled + 256 : scaled;
    }

    _parseEqBand(payload) {
        const bandCount = this._modelData?.eq?.displayedBand?.length ?? 0;
        if (payload.length < bandCount)
            return;

        this._log.info('Parse EqBand');

        const arr = this._decodeSignedBytes(payload);
        this._callbacks?.updateEqBand?.(arr);
    }

    setEqBand(bandIndex, gain) {
        const loginfo = 'Set EqBand';
        const gainByte = this._encodeSignedByte(gain);
        const payload = [bandIndex, gainByte];
        this._encodeSenh(CommandType.EQ_BAND_SET, loginfo, payload);
    }

    _getBassBoost() {
        const loginfo = 'Get BassBoost';
        this._encodeSenh(CommandType.BASS_BOOST_GET, loginfo);
    }

    _parseBassBoost(payload) {
        if (payload.length < 1)
            return;

        this._log.info('Parse BassBoost');
        const enable = booleanFromByte(payload[0]);
        if (enable === null)
            return;
        this._callbacks?.updateBassBoost?.(enable);
    }

    setBassBoost(enable) {
        const loginfo = 'Set BassBoost';
        const payload = [enable ? 0x01 : 0x00];
        this._encodeSenh(CommandType.BASS_BOOST_SET, loginfo, payload);
    }

    _getPeqFreq(stage) {
        const loginfo = `Get PEQ Frequency Stage ${stage}`;
        this._encodeSenh(CommandType.PEQ_FREQ_GET, loginfo, [stage]);
    }

    _parsePeqFreq(payload) {
        if (payload.length < 3)
            return;

        this._log.info('Parse PEQ Frequency');
        const arr = [];
        for (let i = 0; i + 2 < payload.length; i += 3)
            arr.push({stage: payload[i], freq: payload[i + 1] << 8 | payload[i + 2]});


        this._callbacks?.updatePeqFreq?.(arr);
    }

    setPeqFreq(stage, freq) {
        const loginfo = `Set PEQ Frequency Stage ${stage}`;
        const payload = [stage, freq >> 8 & 0xFF, freq & 0xFF];
        this._encodeSenh(CommandType.PEQ_FREQ_SET, loginfo, payload);
    }

    _getPeqGain(stage) {
        const loginfo = `Get PEQ Gain Stage ${stage}`;
        this._encodeSenh(CommandType.PEQ_GAIN_GET, loginfo, [stage]);
    }

    _parsePeqGain(payload) {
        if (payload.length < 3)
            return;

        this._log.info('Parse PEQ Gain');
        const arr = [];
        for (let i = 0; i + 2 < payload.length; i += 3) {
            let raw = payload[i + 1] << 8 | payload[i + 2];
            if (raw & 0x8000)
                raw -= 0x10000;

            arr.push({stage: payload[i], gain: raw / 10.0});
        }

        this._callbacks?.updatePeqGain?.(arr);
    }

    setPeqGain(stage, gain) {
        const loginfo = `Set PEQ Gain Stage ${stage}`;

        let raw = Math.round(gain * 10);

        if (raw < 0)
            raw += 0x10000;

        const payload = [stage, raw >> 8 & 0xFF, raw & 0xFF];

        this._encodeSenh(CommandType.PEQ_GAIN_SET, loginfo, payload);
    }

    _getPeqQ(stage) {
        const loginfo = `Get PEQ Q Stage ${stage}`;
        this._encodeSenh(CommandType.PEQ_Q_GET, loginfo, [stage]);
    }

    _parsePeqQ(payload) {
        if (payload.length < 3)
            return;

        this._log.info('Parse PEQ Q');
        const arr = [];
        for (let i = 0; i + 2 < payload.length; i += 3) {
            const raw = payload[i + 1] << 8 | payload[i + 2];
            arr.push({stage: payload[i], q: raw / 4096.0});
        }

        this._callbacks?.updatePeqQ?.(arr);
    }

    setPeqQ(stage, q) {
        const loginfo = `Set PEQ Q Stage ${stage}`;
        const raw = Math.round(q * 4096);
        const payload = [stage, raw >> 8 & 0xFF, raw & 0xFF];
        this._encodeSenh(CommandType.PEQ_Q_SET, loginfo, payload);
    }

    _getPeqFilter(stage) {
        const loginfo = `Get PEQ Filter Stage ${stage}`;
        this._encodeSenh(CommandType.PEQ_FILTER_GET, loginfo, [stage]);
    }

    _parsePeqFilter(payload) {
        if (payload.length < 2)
            return;

        this._log.info('Parse PEQ Filter');
        const arr = [];
        for (let i = 0; i + 1 < payload.length; i += 2)
            arr.push({stage: payload[i], filter: payload[i + 1]});


        this._callbacks?.updatePeqFilter?.(arr);
    }

    setPeqFilter(stage, filterType) {
        const loginfo = `Set PEQ Filter Stage ${stage}`;
        const payload = [stage, filterType];
        this._encodeSenh(CommandType.PEQ_FILTER_SET, loginfo, payload);
    }

    _getPeqPreGain() {
        const loginfo = 'Get PEQ PreGain';
        this._encodeSenh(CommandType.PEQ_PREGAIN_GET, loginfo);
    }

    _parsePeqPreGain(payload) {
        if (payload.length < 2)
            return;

        this._log.info('Parse PEQ PreGain');
        let raw = payload[0] << 8 | payload[1];
        if (raw & 0x8000)
            raw -= 0x10000;

        this._callbacks?.updatePeqPreGain?.(raw / 10.0);
    }

    _parsePeqPreGainNoti(payload) {
        if (payload.length < 2)
            return;

        this._log.info('Parse PEQ PreGain Notification');
        let raw = payload[1] << 8 | payload[0];
        if (raw & 0x8000)
            raw -= 0x10000;

        this._callbacks?.updatePeqPreGain?.(raw / 10.0);
    }

    setPeqPreGain(gain) {
        const loginfo = 'Set PEQ PreGain';
        let raw = Math.round(gain * 10);
        if (raw < 0)
            raw += 0x10000;

        const payload = [raw >> 8 & 0xFF, raw & 0xFF];
        this._encodeSenh(CommandType.PEQ_PREGAIN_SET, loginfo, payload);
    }

    _getAllBandParams() {
        for (let stage = 0; stage < this._modelData.peq.maxBands; stage++) {
            this._getPeqFreq(stage);
            this._getPeqGain(stage);
            this._getPeqQ(stage);
            this._getPeqFilter(stage);
        }
        this._getPeqPreGain();
    }

    _getCrossfeed() {
        const loginfo = 'Get Crossfeed';
        this._encodeSenh(CommandType.CROSSFEED_GET, loginfo);
    }

    _parseCrossfeed(payload) {
        if (payload.length < 1)
            return;

        this._log.info('Parse Crossfeed');
        const level = payload[0];
        if (!isValidByte(level, this._modelData.crossfeed)) {
            this._log.info(`Received invalid CrossFeed level: ${level} Supported?`);
            return;
        }
        this._callbacks?.updateCrossfeed?.(level);
    }

    setCrossfeed(level) {
        const loginfo = 'Set Crossfeed';
        const payload = [level];
        this._encodeSenh(CommandType.CROSSFEED_SET, loginfo, payload);
    }

    _getSideTone() {
        const loginfo = 'Get SideTone';
        this._encodeSenh(CommandType.SIDETONE_GET, loginfo);
    }

    _parseSideTone(payload) {
        if (payload.length < 1)
            return;

        this._log.info('Parse SideTone');
        const level = payload[0];
        if (level > this._modelData.sideTone - 1) {
            this._log.info(`Received invalid side tone level: ${level} Supported?`);
            return;
        }
        this._callbacks?.updateSideTone?.(level);
    }

    setSideTone(level) {
        const loginfo = 'Set SideTone';
        const payload = [level];
        this._encodeSenh(CommandType.SIDETONE_SET, loginfo, payload);
    }

    _getComfortCall() {
        const loginfo = 'Get ComfortCall';
        this._encodeSenh(CommandType.COMFORT_CALL_GET, loginfo);
    }

    _parseComfortCall(payload) {
        if (payload.length < 1)
            return;

        this._log.info('Parse ComfortCall');
        const enable = booleanFromByte(payload[0]);
        if (enable === null)
            return;

        this._callbacks?.updateComfortCall?.(enable);
    }

    setComfortCall(enable) {
        const loginfo = 'Set ComfortCall';
        const payload = [enable ? 0x01 : 0x00];
        this._encodeSenh(CommandType.COMFORT_CALL_SET, loginfo, payload);
    }

    _getTransPause() {
        const loginfo = 'Get Transperancy Pause';
        this._encodeSenh(CommandType.PAUSE_ON_TRANS_GET, loginfo);
    }

    _parseTransPause(payload) {
        if (payload.length < 1)
            return;

        this._log.info('Parse Transperancy Pause');
        const enable = booleanFromByte(payload[0]);
        if (enable === null)
            return;

        this._callbacks?.updateTransPause?.(enable);
    }

    setTransPause(enable) {
        const loginfo = 'Set Transperancy Pause';
        const payload = [enable ? 0x01 : 0x00];
        this._encodeSenh(CommandType.PAUSE_ON_TRANS_SET, loginfo, payload);
    }

    _getInEarSetting() {
        const loginfo = 'Get InEarSetting';
        this._encodeSenh(CommandType.INEAR_SETTING_GET, loginfo);
    }

    _parseInEarSetting(payload) {
        if (payload.length < 1)
            return;

        this._log.info('Parse InEarSetting');
        const enable = booleanFromByte(payload[0]);
        if (enable === null)
            return;

        this._callbacks?.updateInEarSetting?.(enable);
    }

    setInEarSetting(enable) {
        const loginfo = 'Set InEarSetting';
        const payload = [enable ? 0x01 : 0x00];
        this._encodeSenh(CommandType.INEAR_SETTING_SET, loginfo, payload);
    }

    _getSmartPause() {
        const loginfo = 'Get SmartPause';
        this._encodeSenh(CommandType.SMART_PAUSE_GET, loginfo);
    }

    _parseSmartPause(payload) {
        if (payload.length < 1)
            return;

        this._log.info('Parse SmartPause');
        const enable = booleanFromByte(payload[0]);
        if (enable === null)
            return;

        this._callbacks?.updateSmartPause?.(enable);
    }

    setSmartPause(enable) {
        const loginfo = 'Set SmartPause';
        const payload = [enable ? 0x01 : 0x00];
        this._encodeSenh(CommandType.SMART_PAUSE_SET, loginfo, payload);
    }

    _getAutoAnswer() {
        const loginfo = 'Get AutoAnswer';
        this._encodeSenh(CommandType.AUTO_CALL_GET, loginfo);
    }

    _parseAutoAnswer(payload) {
        if (payload.length < 1)
            return;

        this._log.info('Parse AutoAnswer');
        const enable = booleanFromByte(payload[0]);
        if (enable === null)
            return;

        this._callbacks?.updateAutoAnswer?.(enable);
    }

    setAutoAnswer(enable) {
        const loginfo = 'Set AutoAnswer';
        const payload = [enable ? 0x01 : 0x00];
        this._encodeSenh(CommandType.AUTO_CALL_SET, loginfo, payload);
    }

    _getAutoPowerOff() {
        const loginfo = 'Get AutoPowerOff';
        const payload = [0x00];
        this._encodeSenh(CommandType.AUTO_POWER_OFF_GET, loginfo, payload);
    }

    _parseAutoPowerOff(payload) {
        if (payload.length < 3)
            return;

        this._log.info('Parse AutoPowerOff');

        const seconds = payload[1] << 8 | payload[2];
        const minutes = Math.floor(seconds / 60);

        if (!this._modelData.autoPowerOff.includes(minutes)) {
            this._log.info(`Invalid AutoPowerOff value: ${minutes} minutes`);
            return;
        }

        this._callbacks?.updateAutoPowerOff?.(minutes);
    }

    setAutoPowerOff(minutes) {
        const loginfo = 'Set AutoPowerOff';
        const seconds = minutes * 60;
        const payload = [0x00, seconds >> 8 & 0xFF, seconds & 0xFF];
        this._encodeSenh(CommandType.AUTO_POWER_OFF_SET, loginfo, payload);
    }

    _getCodec() {
        const loginfo = 'Get Codec';
        this._encodeSenh(CommandType.CODEC_GET, loginfo);
    }

    _parseCodec(payload) {
        if (payload.length < 1)
            return;

        this._log.info('Parse Codec');
        const codec = payload[0];
        this._callbacks?.updateCodec?.(codec);
    }

    _getPairedDevMax() {
        const loginfo = 'Get PairedDevMax';
        this._encodeSenh(CommandType.PAIRED_DEVICEMAX_GET, loginfo);
    }

    _parsePairedDevMax(payload) {
        if (payload.length < 1)
            return;

        this._log.info('Parse PairedDevMax');
        const size = payload[0];
        this._callbacks?.updatePairedDevMax?.(size);
    }

    _getPairedDevOwn() {
        const loginfo = 'Get PairedDevOwn';
        this._encodeSenh(CommandType.PAIRED_OWN_DEVICE_GET, loginfo);
    }

    _parsePairedDevOwn(payload) {
        if (payload.length < 1)
            return;

        this._log.info('Parse PairedDevOwn');
        const index = payload[0];
        this._callbacks?.updatePairedDevOwn?.(String(index));
    }

    _getPairedDevList() {
        const loginfo = 'Get PairedDevList';
        this._encodeSenh(CommandType.PAIRED_DEVICELIST_GET, loginfo);
    }

    _parsePairedDevList(payload) {
        if (payload.length < 2)
            return;

        this._log.info('Parse PairedDevList');
        const size = payload[0] << 8 | payload[1];
        this._callbacks?.updatePairedDevList?.(size);

        for (let index = 0; index < size; index++)
            this._getPairedDevInfo(index);
    }

    _getPairedDevInfo(index) {
        const loginfo = 'Get PairedDevList';
        const payload = [index];
        this._encodeSenh(CommandType.PAIRED_DEVICELIST_GET, loginfo, payload);
    }

    _parsePairedDevInfo(payload) {
        if (payload.length < 4)
            return;

        this._log.info('Parse PairedDevInfo');

        const id = String(payload[0]);
        const connected = payload[2] !== 0;

        const nameBytes = payload.slice(3);
        const nullIndex = nameBytes.indexOf(0);
        const nameData = nullIndex >= 0 ? nameBytes.slice(0, nullIndex) : nameBytes;
        const deviceName = new TextDecoder().decode(new Uint8Array(nameData));
        this._callbacks?.updatePairedDevInfo?.(id, deviceName, connected);
    }

    _getPairedDevStatus(index) {
        const loginfo = 'Get PairedDevStatus';
        const payload = [Number(index)];
        this._encodeSenh(CommandType.PAIRED_DEVICE_STATUS_GET, loginfo, payload);
    }

    _parsePairedDevStatus(payload) {
        if (payload.length < 2)
            return;

        this._log.info('Parse PairedDevStatus');
        const index = payload[0];
        const connected = payload[1];
        this._callbacks?.updatePairedDevStatus?.(String(index), connected);
    }

    _parsePairedDevConnect() {
        this._log.info('Parse PairedDevConnect');
    }

    _parsePairedDevConnectErr() {
        this._log.info('Parse PairedDevConnectErr');
        this._callbacks?.updatePairedDevConnectErr?.();
    }

    connectPairedDev(index) {
        const loginfo = 'Connect PairedDev';
        const payload = [Number(index)];
        this._encodeSenh(CommandType.PAIRED_DEVICE_CONNECT_SET, loginfo, payload);
    }

    _parsePairedDevDisconnect() {
        this._log.info('Parse PairedDevDisconnect');
    }

    _parsePairedDevDisconnectErr() {
        this._log.info('Parse PairedDevDisconnectErr');
        this._callbacks?.updatePairedDevDisconnectErr?.();
    }

    disconnectPairedDev(index) {
        const loginfo = 'Disconnect PairedDev';
        const payload = [Number(index)];
        this._encodeSenh(CommandType.PAIRED_DEVICE_DISCONNECT_SET, loginfo, payload);
    }

    _parsePairedDevRemove() {
        this._log.info('Parse PairedDevRemove');
        this._getPairedDevList();
    }

    _parsePairedDevRemoveErr() {
        this._log.info('Parse PairedDevRemoveErr');
        this._callbacks?.updatePairedDevRemoveErr?.();
        this._getPairedDevList();
    }

    removePairedDev(index) {
        const loginfo = 'Remove PairedDev';
        const payload = [Number(index)];
        this._encodeSenh(CommandType.PAIRED_DEVICE_REMOVE_SET, loginfo, payload);
    }

    destroy() {
        super.destroy?.();
    }
});
