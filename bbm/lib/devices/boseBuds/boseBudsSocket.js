'use strict';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';

import {createLogger, getDeviceIdentifier, hexBytes} from '../logger.js';
import {bytesToHex, hexToBytes} from '../deviceUtils.js';
import {SocketHandler} from '../socketByProfile.js';
import {Operator, CommandType, BudId} from './boseBudsConfig.js';

/**
Reference Material and Credits
https://github.com/Denton-L/based-connect/tree/master

https://github.com/aaronsb/bosectl/blob/main/docs/architecture.md

https://github.com/myNameArnav/libreqc/tree/main/docs
**/

const MAX_BUFFER_SIZE = 2048;

export const BoseBudsSocket = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_BoseSocket',
}, class BoseBudsSocket extends SocketHandler {
    _init(devicePath, profileManager, profile, modelData, callbacks) {
        super._init(devicePath, profileManager, profile);
        const identifier = getDeviceIdentifier(devicePath);
        const tag = `BoseSocket-${identifier}`;
        this._log = createLogger(tag);
        this._log.info('BoseSocket init');
        this._callbacks = callbacks;
        this._rxBuffer = [];
        this._txQueue = [];
        this._pendingRequest = null;
        this._pendingTimeout = null;
        this._modelData = modelData;
        this._battInfo = {
            battery1Level: 0,
            battery2Level: 0,
            battery3Level: 0,
            battery1Status: 'discharging',
            battery2Status: 'discharging',
            battery3Status: 'discharging',
        };

        this.startSocket();
    }

    postConnectInitialization() {
        if (this._modelData.legacy)
            this._getInitPacket();

        this._getConfiguration();
    }

    _queueRequest(command, operator, payload, loginfo = '') {
        this._txQueue.push({command, operator, payload, loginfo});
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

        this._encodeBose(item.command, item.operator, item.payload);
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

        if (msg.command !== this._pendingRequest.command)
            return;

        if (this._pendingTimeout)
            GLib.source_remove(this._pendingTimeout);

        this._pendingTimeout = null;
        this._pendingRequest = null;
        this._processQueue();
    }

    _encodeBose(command, operator, payload = []) {
        const out = [
            command >> 8 & 0xFF,
            command & 0xFF,
            operator & 0x0F,
            payload.length & 0xFF,
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

            this._handleMessage(msg);
            this._completePendingRequest(msg);
        }
    }

    _extractMessage() {
        const buf = this._rxBuffer;

        if (buf.length > MAX_BUFFER_SIZE) {
            this._log.info('RX buffer overflow, clearing');
            buf.length = 0;
            return null;
        }

        if (buf.length < 4)
            return null;

        const payloadLength = buf[3];
        const totalLength = 4 + payloadLength;

        if (buf.length < totalLength)
            return null;

        return this._parseMessage(buf.splice(0, totalLength));
    }

    _parseMessage(raw) {
        return {
            command: raw[0] << 8 | raw[1],
            operator: raw[2] & 0x0F,
            payload: raw.slice(4),
        };
    }

    _handleMessage(msg) {
        this._log.info(`command: ${hexBytes(msg.command)} operator: ${hexBytes(msg.operator)} ` +
                `payload: [${hexBytes(msg.payload)}]`);

        if (msg.payload.length < 1)
            return;

        const isStatus = msg.operator === Operator.STATUS;
        const isResult = msg.operator === Operator.RESULT;
        const isProcessing = msg.operator === Operator.PROCESSING;

        switch (msg.command) {
            case CommandType.NOTIFICATION_BY_BLOCK: {
                if (isStatus)
                    this._parseNotificationByBlock(msg.payload);
                break;
            }

            case CommandType.FIRMWARE: {
                if (isStatus)
                    this._parseFirmware(msg.payload);
                break;
            }

            case CommandType.SERIAL: {
                if (isStatus)
                    this._parseSerial(msg.payload);
                break;
            }

            case CommandType.BATTERY: {
                if (isStatus)
                    this._parseBatteryLevel(msg.payload);
                break;
            }

            case CommandType.CHARGING_STATE: {
                if (isStatus)
                    this._parseBatteryStatus(msg.payload);
                break;
            }

            case CommandType.INEAR_STATE: {
                if (isStatus && !this._modelData.batterySingle)
                    this._parseInEarState(msg.payload);
                break;
            }

            case CommandType.EQ: {
                if (this._modelData.eq  && isStatus)
                    this._parseEq(msg.payload);
                break;
            }

            case CommandType.ANR: {
                if (this._modelData.anr)
                    this._parseAnr(msg.payload);
                break;
            }

            case CommandType.AUDIOMODE_CAPABILTY: {
                if (this._modelData.audioModes && isStatus)
                    this._parseAudioModesCapability(msg.payload);
                break;
            }

            case CommandType.AUDIOMODE_CURRENT: {
                if (this._modelData.audioModes && (isStatus || isResult))
                    this._parseAudioModeCurrent(msg.payload);
                break;
            }

            case CommandType.AUDIOMODE_RESTORE: {
                if (this._modelData.audioModes && isResult)
                    this._parseRestoreAudioMode(msg.payload);
                break;
            }

            case CommandType.AUDIOMODE_FAV: {
                if (this._modelData.audioModes && isStatus)
                    this._parseAudioModeFavorites(msg.payload);
                break;
            }

            case CommandType.AUDIOMODE_CONFIG: {
                if (this._modelData.audioModes && isStatus)
                    this._parseAudioMode(msg.payload);
                break;
            }

            case CommandType.CNC: {
                if (this._modelData.audioModes?.showNCInterface && isStatus)
                    this._parseCnc(msg.payload);
                break;
            }

            case CommandType.SPATIAL_AUDIO: {
                if (this._modelData.audioModes?.spatialMode && isStatus)
                    this._parseSpatialAudio(msg.payload);
                break;
            }

            case CommandType.DUALCONNECTION: {
                if (this._modelData.dualConnection && isStatus)
                    this._parseDualConnection(msg.payload);
                break;
            }

            case CommandType.SIDETONE: {
                if (this._modelData.sideTone && isStatus)
                    this._parseSideTone(msg.payload);
                break;
            }

            case CommandType.INEAR_SETTINGS: {
                if (this._modelData.inEarSettings)
                    this._parseInEarSettings(msg.payload);
                break;
            }

            case CommandType.AUTO_ANSWER: {
                if (!this._modelData.inEarSettings && this._modelData.autoAnswer && isStatus)
                    this._parseAutoAnswer(msg.payload);
                break;
            }

            case CommandType.AUTO_PAUSE: {
                if (!this._modelData.inEarSettings && this._modelData.autoPause && isStatus)
                    this._parseAutoPause(msg.payload);
                break;
            }

            case CommandType.AUTO_TRANSP: {
                if (!this._modelData.inEarSettings && this._modelData.autoTransparency && isStatus)
                    this._parseAutoTransparency(msg.payload);
                break;
            }

            case CommandType.VOICE_PROMPTS: {
                if (this._modelData.voicePrompt && isStatus)
                    this._parseVoicePrompt(msg.payload);
                break;
            }

            case CommandType.AUTO_POWER_OFF_TIME: {
                if (this._modelData.automaticPowerOffTimer && isStatus)
                    this._parseAutoPowerOffTimer(msg.payload);
                break;
            }

            case CommandType.BUTTONS: {
                if (this._modelData.gestureOptions && isStatus)
                    this._parseActionButton(msg.payload);
                break;
            }

            case CommandType.GET_ALL_DEVICES: {
                if (this._modelData.dualConnection && (isResult || isStatus))
                    this._parseAllBTDevices(msg.payload);
                break;
            }

            case CommandType.DEVICE_INFO: {
                if (this._modelData.dualConnection && (isResult || isStatus || isProcessing))
                    this._parseBTDeviceInfo(msg.payload);
                break;
            }

            case CommandType.PAIRING_MODE: {
                if (this._modelData.dualConnection)
                    this._parsePairingMode(msg.payload);
                break;
            }

            case CommandType.CONNECT_DEVICE: {
                if (this._modelData.dualConnection)
                    this._parseConnectBTDevice(msg);
                break;
            }

            case CommandType.DISCONNECT_DEVICE: {
                if (this._modelData.dualConnection)
                    this._parseDisconnectBTDevice(msg);
                break;
            }

            case CommandType.REMOVE_DEVICE: {
                if (this._modelData.dualConnection)
                    this._parseRemoveBTDevice(msg);
                break;
            }

            case CommandType.DEVICE_ROUTING: {
                if (this._modelData.dualConnection)
                    this._parseRoutingBTDevice(msg);
                break;
            }

            case CommandType.GET_OWN_DEVICE_ID: {
                if (this._modelData.dualConnection && isStatus)
                    this._parseOwnDeviceId(msg.payload);
                break;
            }

            default:
                this._log.info(`Unhandled command ${hexBytes(msg.command)}`);
        }
    }

    _encode(command, operator, loginfo, payload = []) {
        this._queueRequest(command, operator, payload, loginfo);
    }

    _getInitPacket() {
        const loginfo = 'Get Init';
        this._encode(CommandType.INIT, Operator.GET, loginfo);
    }

    _getConfiguration() {
        this._setNotificationByBlock();
        this._getFirmware();
        this._getSerial();
        this._getBatteryLevel();
        this._getBatteryStatus();

        if (!this._modelData.batterySingle)
            this._getInEarState();

        if (this._modelData.eq)
            this._getEq();

        if (this._modelData.anr)
            this._getAnr();

        if (this._modelData.audioModes) {
            this._getAudioModesCapability();
            this._getAllAudioModes();
            this._getAudioModeCurrent();
            this._getRestoreAudioMode();
            this._getAudioModeFavorites();
        }

        if (this._modelData.audioModes?.showNCInterface)
            this._getCnc();

        if (this._modelData.audioModes?.spatialMode)
            this._getSpatialAudio();

        if (this._modelData.dualConnection)
            this._getDualConnection();

        if (this._modelData.sideTone)
            this._getSideTone();

        if (this._modelData.inEarSettings)
            this._getInEarSettings();

        if (!this._modelData.inEarSettings && this._modelData.autoAnswer)
            this._getAutoAnswer();

        if (!this._modelData.inEarSettings && this._modelData.autoPause)
            this._getAutoPause();

        if (!this._modelData.inEarSettings && this._modelData.autoTransparency)
            this._getAutoTransparency();

        if (this._modelData.voicePrompt)
            this._getVoicePrompt();

        if (this._modelData.automaticPowerOffTimer)
            this._getAutoPowerOffTimer();

        if (this._modelData.gestureOptions)
            this._getActionButton();

        if (this._modelData.dualConnection) {
            this._getOwnDeviceId();
            this._getRoutingBTDevice();
            this._getPairingMode();
            this._getAllBTDevices();
        }
    }

    _setNotificationByBlock() {
        const loginfo = 'Set NotificationByBlock';
        const blocks = [0, 1, 5, 9];

        if (this._modelData.dualConnection)
            blocks.push(4);

        if (this._modelData.audioModes)
            blocks.push(31);

        blocks.sort((a, b) => a - b);
        const notification = new Uint8Array(4);

        for (const block of blocks) {
            const byteIndex = 3 - Math.floor(block / 8);
            const bitIndex = block % 8;

            notification[byteIndex] |= 1 << bitIndex;
        }

        const payload = [0x01, ...notification];
        this._encode(CommandType.NOTIFICATION_BY_BLOCK, Operator.SETGET, loginfo, payload);
    }

    _parseNotificationByBlock(payload) {
        if (payload.length < 4)
            return;

        this._log.info('Parse NotificationByBlock');
        const blocks = [];

        for (let block = 0; block < 32; block++) {
            const byteIndex = 3 - Math.floor(block / 8);
            const bitIndex = block % 8;

            if (payload[byteIndex] & 1 << bitIndex)
                blocks.push(block);
        }

        this._log.info(`Notification blocks: [${blocks.join(', ')}]`);
    }

    _getFirmware() {
        const loginfo = 'Get Firmware';
        this._encode(CommandType.FIRMWARE, Operator.GET, loginfo);
    }

    _parseFirmware(payload) {
        if (!payload.length)
            return;

        const decoder = new TextDecoder();
        const fw = decoder.decode(Uint8Array.from(payload));

        this._log.info(`Parse Firmware: ${fw}`);
        this._callbacks?.updateFirmware?.(fw);
    }

    _getSerial() {
        const loginfo = 'Get Serial';
        this._encode(CommandType.SERIAL, Operator.GET, loginfo);
    }

    _parseSerial(payload) {
        if (!payload.length)
            return;

        const decoder = new TextDecoder();
        const serial = decoder.decode(Uint8Array.from(payload));
        this._callbacks?.updateSerial?.(serial);
    }

    _getBatteryLevel() {
        const loginfo = 'Get Battery Level';
        this._encode(CommandType.BATTERY, Operator.GET, loginfo);
    }

    _parseBatteryLevel(payload) {
        if (this._modelData.legacy) {
            if (payload.length  < 1)
                return;

            this._battInfo.battery1Level = payload[0];
            this._callbacks?.updateBatteryProps?.(this._battInfo);
            return;
        }

        if (payload.length < 4)
            return;

        this._log.info('Parse Battery Level');

        for (let i = 0; i + 3 < payload.length; i += 4) {
            const level = payload[i];
            const budId = payload[i + 3];

            switch (budId) {
                case BudId.Left:
                    this._battInfo.battery1Level = level;
                    break;

                case BudId.Right:
                    this._battInfo.battery2Level = level;
                    break;

                case BudId.Case:
                    this._battInfo.battery3Level = level;
                    break;

                case BudId.Single:
                default:
                    this._battInfo.battery1Level = level;
                    break;
            }
        }

        this._callbacks?.updateBatteryProps?.(this._battInfo);
    }

    _getBatteryStatus() {
        const loginfo = 'Get Battery Status';
        this._encode(CommandType.CHARGING_STATE, Operator.GET, loginfo);
    }

    _parseBatteryStatus(payload) {
        if (payload.length < 1)
            return;

        this._log.info('Parse Battery Status');

        const status = payload[0] === 1 ? 'charging' : 'discharging';

        if (this._modelData.batterySingle)
            this._battInfo.battery1Status = status;
        else
            this._battInfo.battery3Status = status;

        this._callbacks?.updateBatteryProps?.(this._battInfo);
    }

    _getInEarState() {
        const loginfo = 'Get InEar State';
        this._encode(CommandType.INEAR_STATE, Operator.GET, loginfo);
    }

    _parseInEarState(payload) {
        if (payload.length < 1)
            return;

        this._log.info('Parse In Ear State');

        const left = (payload[0] & 0x01) === 0x01;
        const right = (payload[0] & 0x02) === 0x02;

        this._callbacks?.updateInEarState?.(left, right);
    }

    _getEq() {
        const loginfo = 'Get EqConfig';
        this._encode(CommandType.EQ, Operator.GET, loginfo);
    }

    _parseEq(payload) {
        const bands = this._modelData?.eq?.band ?? [];
        const range = this._modelData?.eq?.range ?? 0;
        const bandCount = bands.length;

        if (payload.length !== bandCount * 4) {
            this._log.info(`Parse EqBand: unexpected payload length ${payload.length}`);
            return;
        }

        this._log.info('Parse EqBand');

        const arr = [];

        for (let i = 0; i < bandCount; i++) {
            const offset = i * 4;

            let minVal = payload[offset];
            if (minVal >= 128)
                minVal -= 256;

            let maxVal = payload[offset + 1];
            if (maxVal >= 128)
                maxVal -= 256;

            if (Math.abs(minVal) !== range || Math.abs(maxVal) !== range)
                this._log.info(`EQ range mismatch ${minVal} - ${maxVal}, expected: ±${range}`);

            let current = payload[offset + 2];
            if (current >= 128)
                current -= 256;

            const band = payload[offset + 3];

            arr.push({current, band});
        }

        this._callbacks?.updateEq?.(arr);
    }

    setEq(current, band) {
        const loginfo = 'Set EqBand';
        const payload = [current  & 0xFF, band];
        this._encode(CommandType.EQ, Operator.SETGET, loginfo, payload);
    }

    _getAnr() {
        const loginfo = 'Get ANR';
        this._encode(CommandType.ANR, Operator.GET, loginfo);
    }

    _parseAnr(payload) {
        if (payload.length < 1)
            return;

        this._log.info('Parse Anr');
        const mode = payload[0];
        this._callbacks?.updateAnr?.(mode);
    }

    setAnr(mode) {
        const loginfo = 'Set ANR';
        const payload = [mode];
        this._encode(CommandType.ANR, Operator.SETGET, loginfo, payload);
    }

    _getAudioModesCapability() {
        const loginfo = 'Get AudioModes Capability';
        this._encode(CommandType.AUDIOMODE_CAPABILTY, Operator.GET, loginfo);
    }

    _parseAudioModesCapability(payload) {
        this._log.info('Parse AudioModes Capability');

        if (payload.length < 6) {
            this._log.warn(`AudioModes Capability payload too short: ${payload.length}`);
            return;
        }

        const boseModes = payload[0];
        const userModes = payload[1];
        const flags = payload[5];
        const minFavorites = payload.length >= 7 ? payload[6] : 0;

        this._log.info(
            `AudioModes: boseModes: ${boseModes}, ` +
            `userModes: ${userModes}, ` +
            `cnc: ${!!(flags & 0x01)}, ` +
            `autoCnc: ${!!(flags & 0x02)}, ` +
            `spatial: ${!!(flags & 0x04)}, ` +
            `wind: ${!!(flags & 0x08)}, ` +
            `favorites: ${!!(flags & 0x10)}, ` +
            `ancToggle: ${!!(flags & 0x20)}, ` +
            `minFavorites: ${minFavorites}`
        );
    }

    _getAudioModeCurrent() {
        const loginfo = 'Get AudioMode Current';
        this._encode(CommandType.AUDIOMODE_CURRENT, Operator.GET, loginfo);
    }

    _parseAudioModeCurrent(payload) {
        if (payload.length < 1)
            return;

        this._log.info('Parse AudioMode Current');
        const modeIndex = payload[0];
        this._callbacks?.updateAudioModeCurrent?.(modeIndex);
    }

    setCurrentAudioMode(modeIndex, playVoicePrompt = false) {
        const loginfo = 'Set AudioMode Current';
        const payload = [modeIndex, playVoicePrompt ? 0x01 : 0x00];
        this._encode(CommandType.AUDIOMODE_CURRENT, Operator.START, loginfo, payload);
    }

    _getRestoreAudioMode() {
        const loginfo = 'Get AudioMode Restore';
        this._encode(CommandType.AUDIOMODE_RESTORE, Operator.GET, loginfo);
    }

    _parseRestoreAudioMode(payload) {
        if (payload.length < 1)
            return;

        const enabled = payload[0] === 0x01;
        this._callbacks?.updateAudioModeRestore?.(enabled);
    }

    setRestoreAudioMode(enabled) {
        const loginfo = 'Set AudioMode Restore';
        const payload = [enabled ? 0x01 : 0x00];
        this._encode(CommandType.AUDIOMODE_RESTORE, Operator.SETGET, loginfo, payload);
    }

    _getAudioModeFavorites() {
        const loginfo = 'Get AudioMode Favorites';
        this._encode(CommandType.AUDIOMODE_FAV, Operator.GET, loginfo);
    }

    _parseAudioModeFavorites(payload) {
        if (payload.length < 1)
            return;

        this._log.info('Parse AudioMode Favorites');

        const modeCount = payload[0];
        const favorites = [];
        const maskBytes = Math.ceil(modeCount / 8);

        for (let byteIndex = maskBytes; byteIndex >= 1; byteIndex--) {
            const value = payload[byteIndex];

            for (let bit = 0; bit < 8; bit++) {
                if ((value >> bit & 0x01) === 1)
                    favorites.push((maskBytes - byteIndex) * 8 + bit);
            }
        }

        this._callbacks?.updateAudioModeFavorites?.(modeCount, favorites);
    }

    setAudioModeFavorites(modeCount, favorites) {
        const loginfo = 'Set AudioMode Favorites';
        const maskBytes = Math.ceil(modeCount / 8);
        const payload = new Array(maskBytes + 1).fill(0);

        payload[0] = modeCount;

        for (const mode of favorites) {
            const byteIndex = maskBytes - Math.floor(mode / 8);
            payload[byteIndex] |= 1 << mode % 8;
        }

        this._encode(CommandType.AUDIOMODE_FAV, Operator.SETGET, loginfo, payload);
    }

    _getAllAudioModes() {
        const loginfo = 'Get All AudioModes';
        this._encode(CommandType.AUDIOMODE_GETALL, Operator.START, loginfo);
    }

    _parseAudioMode(payload) {
        if (payload.length < 44)
            return;

        this._log.info('Parse AudioMode Config');

        const index = payload[0];
        const id = payload[2];
        const editable = payload[3] === 1;
        const added = payload[4] === 1;
        const fav = payload[5] === 1;

        let end = 6;
        while (end < 38 && payload[end] !== 0)
            end++;

        const name = new TextDecoder().decode(Uint8Array.from(payload.slice(6, end)));

        const config = {
            index,
            id,
            editable,
            added,
            fav,
            name,
            flag: payload[41],
            cnc: this._modelData.audioModes.nc.level - payload[42],
            autoCnc: payload[43] === 1,
            spatial: payload.length >= 45 ? payload[44] : 0,
            wind: payload.length >= 47 ? payload[46] : 0,
            anc: payload.length >= 48 ? payload[47] : 0,
        };

        this._log.info(`Parse AudioMode Config: ${JSON.stringify(config)}`);
        this._callbacks?.updateAudioMode?.(config);
    }

    setAudioMode(mode) {
        const nameBuf = new Uint8Array(32);
        nameBuf.set(new TextEncoder().encode(mode.name).slice(0, 31));

        const payload = [
            mode.index,
            0x00,
            mode.id,
            ...nameBuf,
            this._modelData.audioModes.nc.level - mode.cnc,
            mode.autoCnc,
            mode.spatial,
            mode.wind,
            mode.anc,
        ];

        const loginfo = 'Set AudioMode';
        this._encode(CommandType.AUDIOMODE_CONFIG, Operator.SETGET, loginfo, payload);
    }

    _getCnc() {
        const loginfo = 'Get Noise Cancellation';
        this._encode(CommandType.CNC, Operator.GET, loginfo);
    }

    _parseCnc(payload) {
        if (payload.length < 3)
            return;

        this._log.info('Parse Noise Cancellation');
        const level = this._modelData.audioModes.nc.level - payload[1];
        const enabled = (payload[2] & 0x01) !== 0;

        this._callbacks?.updateCnc?.(level, enabled);
    }

    setCnc(level, enabled) {
        const loginfo = 'Set Noise Cancellation';
        const payload = [this._modelData.audioModes.nc.level - level, enabled ? 1 : 0];
        this._encode(CommandType.CNC, Operator.SETGET, loginfo, payload);
    }

    _getSpatialAudio() {
        this._encode(CommandType.SPATIAL_AUDIO, Operator.GET, 'Get Spatial Audio');
    }

    _parseSpatialAudio(payload) {
        if (payload.length < 1)
            return;

        this._log.info('Parse SpatialAudio');
        const mode = payload[0];
        this._callbacks?.updateSpatialAudio?.(mode);
    }

    setSpatialAudio(mode) {
        const loginfo = 'Set Spatial Audio';
        const payload = [mode];
        this._encode(CommandType.SPATIAL_AUDIO, Operator.SETGET, loginfo, payload);
    }

    _getDualConnection() {
        const loginfo = 'Get DualConnection';
        this._encode(CommandType.DUALCONNECTION, Operator.GET, loginfo);
    }

    _parseDualConnection(payload) {
        if (payload.length < 1)
            return;

        this._log.info('Parse DualConnection');
        const enabled = (payload[0] & 0x01) !== 0;
        this._callbacks?.updateDualConnection?.(enabled);
    }

    setDualConnection(enabled) {
        const loginfo = 'Set DualConnection';
        const payload = [enabled ? 0x01 : 0x00];
        this._encode(CommandType.DUALCONNECTION, Operator.SETGET, loginfo, payload);
    }


    _getSideTone() {
        const loginfo = 'Get SideTone';
        this._encode(CommandType.SIDETONE, Operator.GET, loginfo);
    }

    _parseSideTone(payload) {
        if (payload.length < 2)
            return;

        this._log.info('Parse SideTone');
        const level = payload[1];
        this._callbacks?.updateSideTone?.(level);
    }

    setSideTone(level) {
        const loginfo = 'Set SideTone';
        const payload = [0x01, level];
        this._encode(CommandType.SIDETONE, Operator.SETGET, loginfo, payload);
    }

    _getInEarSettings() {
        const loginfo = 'Get InEarSettings';
        this._encode(CommandType.INEAR_SETTINGS, Operator.GET, loginfo);
    }

    _parseInEarSettings(payload) {
        if (payload.length < 2)
            return;

        this._log.info('Parse InEarSettings');

        const enabled = payload[0] === 1;
        const flags = payload[1];

        const autoPause = (flags & 0x01) !== 0;
        const autoAnswer = (flags & 0x02) !== 0;
        const autoTransparency = (flags & 0x04) !== 0;

        this._log.info(`Parse InEarSettings enabled: ${enabled} autoPause: ${autoPause} ` +
            `autoAnswer: ${autoAnswer} autoTransparency: ${autoTransparency}`);

        this._callbacks?.updateInEarSettings?.(enabled, autoPause, autoAnswer, autoTransparency);
    }

    setInEarSettings(enabled, autoPauseEnabled, autoAnswerEnabled, autoTransparencyEnabled) {
        const loginfo = 'Set InEarSettings';
        const payload = [
            enabled ? 0x01 : 0x00,
            (autoPauseEnabled ? 0x01 : 0x00) |
            (autoAnswerEnabled ? 0x02 : 0x00) |
            (autoTransparencyEnabled ? 0x04 : 0x00),
        ];
        this._encode(CommandType.INEAR_SETTINGS, Operator.SETGET, loginfo, payload);
    }

    _getAutoAnswer() {
        const loginfo = 'Get AutoAnswer';
        this._encode(CommandType.AUTO_ANSWER, Operator.GET, loginfo);
    }

    _parseAutoAnswer(payload) {
        if (payload.length < 1)
            return;

        this._log.info('Parse AutoAnswer');
        const enabled = (payload[0] & 0x01) !== 0;
        this._callbacks?.updateAutoAnswer?.(enabled);
    }

    setAutoAnswer(enabled) {
        const loginfo = 'Set AutoAnswer';
        const payload = [enabled ? 0x01 : 0x00];
        this._encode(CommandType.AUTO_ANSWER, Operator.SETGET, loginfo, payload);
    }

    _getAutoPause() {
        const loginfo = 'Get AutoPause';
        this._encode(CommandType.AUTO_PAUSE, Operator.GET, loginfo);
    }

    _parseAutoPause(payload) {
        if (payload.length < 1)
            return;

        this._log.info('Parse AutoPause');
        const enabled = payload[0] === 0x01;
        this._callbacks?.updateAutoPause?.(enabled);
    }

    setAutoPause(enabled) {
        const loginfo = 'Set AutoPause';
        const payload = [enabled ? 0x01 : 0x00];
        this._encode(CommandType.AUTO_PAUSE, Operator.SETGET, loginfo, payload);
    }

    _getAutoTransparency() {
        const loginfo = 'Get AutoTransparency';
        this._encode(CommandType.AUTO_TRANSP, Operator.GET, loginfo);
    }

    _parseAutoTransparency(payload) {
        if (payload.length < 1)
            return;

        this._log.info('Parse AutoTransparency');
        const enabled = payload[0] === 0x01;
        this._callbacks?.updateAutoTransparency?.(enabled);
    }

    setAutoTransparency(enabled) {
        const loginfo = 'Set AutoTransparency';
        const payload = [enabled ? 0x01 : 0x00];
        this._encode(CommandType.AUTO_TRANSP, Operator.SETGET, loginfo, payload);
    }

    _getAutoPowerOffTimer() {
        const loginfo = 'Get AutoPowerOffTimer';
        this._encode(CommandType.AUTO_POWER_OFF_TIME, Operator.GET, loginfo);
    }

    _parseAutoPowerOffTimer(payload) {
        if (payload.length < 1)
            return;

        this._log.info('Parse AutoPowerOffTimer');
        const minutes = payload[0];
        this._callbacks?.updateAutoPowerOffTimer?.(minutes);
    }

    setAutoPowerOffTimer(minutes) {
        const loginfo = 'Set AutoPowerOffTimer';
        const payload = [minutes];
        this._encode(CommandType.AUTO_POWER_OFF_TIME, Operator.SETGET, loginfo, payload);
    }

    _getVoicePrompt() {
        const loginfo = 'Get VoicePrompt';
        this._encode(CommandType.VOICE_PROMPTS, Operator.GET, loginfo);
    }

    _parseVoicePrompt(payload) {
        if (payload.length < 5)
            return;

        this._log.info('Parse VoicePrompt');
        const value = payload[0];
        const enabled = Boolean(value >> 5 & 0x01);
        const language = value & 0x1F;
        const supported = payload[1] << 24 | payload[2] << 16 | payload[3] << 8 | payload[4];

        let batSupported = false;
        let batEnabled = false;

        if (payload.length >= 7) {
            batSupported = payload[5] === 0x01;
            batEnabled = payload[6] === 0x01;
        }

        this._callbacks?.updateVoicePrompt?.(enabled, language, supported >>> 0,
            batSupported, batEnabled);
    }

    setVoicePrompt(enabled, language, batSupported, batEnabled) {
        const loginfo = 'Set VoicePrompt';
        const payload = [(enabled ? 1 : 0) << 5 | language & 0x1F];

        if (batSupported)
            payload.push(batEnabled ? 0x01 : 0x00);

        this._encode(CommandType.VOICE_PROMPTS, Operator.SETGET, loginfo, payload);
    }

    _getActionButton() {
        const loginfo = 'Get Action Button';
        this._encode(CommandType.BUTTONS, Operator.GET, loginfo);
    }

    _parseActionButton(payload) {
        if (payload.length < 3)
            return;

        this._log.info('Parse Action Button');

        const buttonId = payload[0];
        const eventType = payload[1];
        const action = payload[2];

        this._callbacks?.updateActionButton?.(buttonId, eventType, action);
    }

    setActionButton(id, eventType, action) {
        const loginfo = 'Set Action Button';
        const payload = [id, eventType, action];
        this._encode(CommandType.BUTTONS, Operator.SETGET, loginfo, payload);
    }

    _getAllBTDevices() {
        const loginfo = 'Get AllBTDevices';
        this._encode(CommandType.GET_ALL_DEVICES, Operator.GET, loginfo);
    }

    _parseAllBTDevices(payload) {
        this._log.info('Parse AllBTDevices');

        if (payload.length < 1)
            return;

        if (payload.length === 1) {
            this._callbacks?.updateBTDeviceList?.([]);
            return;
        }

        const devicesHex = [];
        const devicesBytes = [];

        for (let i = 1; i + 5 < payload.length; i += 6) {
            const mac = payload.slice(i, i + 6);

            devicesBytes.push(mac);
            devicesHex.push(bytesToHex(mac));
        }

        this._callbacks?.updateBTDeviceList?.(devicesHex);

        for (const mac of devicesBytes)
            this._getBTDeviceInfo(mac);
    }

    _getBTDeviceInfo(macAddress) {
        const loginfo = 'Get BTDevice Info';
        this._encode(CommandType.DEVICE_INFO, Operator.GET, loginfo, macAddress);
    }

    _parseBTDeviceInfo(payload) {
        if (payload.length < 9)
            return;

        this._log.info('Parse BTDevice Info');
        const macAddress = bytesToHex(payload.slice(0, 6));
        const flags = payload[6];
        const connected = (flags & 0x01) !== 0;
        const nameOffset = (flags & 0x04) !== 0 ? 10 : 9;
        const deviceName = new TextDecoder().decode(new Uint8Array(payload.slice(nameOffset)));

        this._callbacks?.updateBTDeviceInfo?.(macAddress, deviceName, connected);
    }

    _getPairingMode() {
        const loginfo = 'Get PairingMode';
        this._encode(CommandType.PAIRING_MODE, Operator.GET, loginfo);
    }

    _parsePairingMode(payload) {
        if (payload.length < 1)
            return;

        this._log.info('Parse PairingMode');

        const enabled = payload[0] === 0x01;
        this._callbacks?.updatePairingMode?.(enabled);
    }

    setPairingMode(enabled) {
        const loginfo = 'Set PairingMode';
        const payload = [enabled ? 0x01 : 0x00];
        this._encode(CommandType.PAIRING_MODE, Operator.START, loginfo, payload);
    }

    _parseConnectBTDevice(msg) {
        const isStatus = msg.operator === Operator.STATUS;
        const isError = msg.operator === Operator.ERROR;

        if (isError) {
            this._callbacks?.updateConnectError();
        } else if (msg.payload.length > 6 && isStatus) {
            this._log.info('Parse Connect Result');
            const macAddress = bytesToHex(msg.payload.slice(0, 6));
            const flags = msg.payload[6];
            const connected = (flags & 0x01) !== 0 || (flags & 0x02) !== 0;
            this._callbacks?.updateConnectStatus?.(macAddress, connected);
        }
    }

    connectBTDevice(macHex) {
        const loginfo = 'Connect BTDevice';
        const mac = hexToBytes(macHex);
        this._encode(CommandType.CONNECT_DEVICE, Operator.START, loginfo, [0x00, ...mac]);
    }

    _parseDisconnectBTDevice(msg) {
        const isStatus = msg.operator === Operator.STATUS;
        const isError = msg.operator === Operator.ERROR;

        if (isError) {
            this._callbacks?.updateDisconnectError?.();
        } else if (msg.payload.length >= 6 && isStatus) {
            this._log.info('Parse Disconnect Result');
            const macAddress = bytesToHex(msg.payload.slice(0, 6));
            this._callbacks?.updateDisconnectStatus?.(macAddress);
        }
    }

    disconnectBTDevice(macHex) {
        const loginfo = 'Disconnect BTDevice';
        const mac = hexToBytes(macHex);
        this._encode(CommandType.DISCONNECT_DEVICE, Operator.START, loginfo, mac);
    }

    _parseRemoveBTDevice(msg) {
        const isStatus = msg.operator === Operator.STATUS;
        const isError = msg.operator === Operator.ERROR;

        if (isError) {
            this._callbacks?.updateRemoveBTDeviceError?.();
        } else if (msg.payload.length >= 6 && isStatus) {
            this._log.info('Parse Remove BTDevice Result');
            const macAddress = bytesToHex(msg.payload.slice(0, 6));
            this._callbacks?.updateRemoveBTDeviceStatus?.(macAddress);
        }
    }

    removeBTDevice(macHex) {
        const loginfo = 'Remove BTDevice';
        const mac = hexToBytes(macHex);
        this._encode(CommandType.REMOVE_DEVICE, Operator.START, loginfo, mac);
    }

    _getRoutingBTDevice() {
        const loginfo = 'Get Routing BTDevice';
        this._encode(CommandType.DEVICE_ROUTING, Operator.GET, loginfo);
    }

    _parseRoutingBTDevice(msg) {
        const isStatus = msg.operator === Operator.STATUS;
        const isResult = msg.operator === Operator.RESULT;

        if (isResult && msg.payload.length >= 6 || isStatus && msg.payload.length >= 8) {
            this._log.info('Parse Routing BTDevice');
            const routingAddress = isResult ? msg.payload.slice(0, 6) : msg.payload.slice(2, 8);
            const mac = bytesToHex(routingAddress);
            this._callbacks?.updateRoutingStatus?.(mac);
        }
    }

    setRoutingBTDevice(macHex) {
        const loginfo = 'Set Routing BTDevice';
        const mac = hexToBytes(macHex);
        this._encode(CommandType.DEVICE_ROUTING, Operator.START, loginfo, mac);
    }

    _getOwnDeviceId() {
        const loginfo = 'Get OwnDeviceId';
        this._encode(CommandType.GET_OWN_DEVICE_ID, Operator.GET, loginfo);
    }

    _parseOwnDeviceId(payload) {
        if (payload.length !== 6)
            return;

        this._log.info('Parse OwnDeviceId');
        const macAddress = bytesToHex(payload);
        this._callbacks?.updateOwnDeviceId?.(macAddress);
    }

    destroy() {
        super.destroy?.();
    }
});
