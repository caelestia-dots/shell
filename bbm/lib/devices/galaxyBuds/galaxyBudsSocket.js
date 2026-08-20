'use strict';
import GObject from 'gi://GObject';

import {createLogger, getDeviceIdentifier} from '../logger.js';
import {SocketHandler} from '../socketByProfile.js';
import {booleanFromByte, isValidByte} from '../deviceUtils.js';
import {
    crc16Tab,
    GalaxyBudsModel,
    GalaxyBudsMsgIds,
    LegacyMsgIds,
    GalaxyBudsMsgTypes,
    GalaxyBudsAnc,
    GalaxyBudsEarDetectionState,
    GalaxyBudsLegacyEarDetectionState,
    EqPresets
} from './galaxyBudsConfig.js';

const AndroidSdkVersion = 34;
const ClientSamsungDevice = 1;

export const GalaxyBudsSocket = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_GalaxyBudsSocket',
}, class GalaxyBudsSocket extends SocketHandler {
    _init(devicePath, profileManager, profile, modelData, callbacks) {
        super._init(devicePath, profileManager, profile);
        const identifier = getDeviceIdentifier(devicePath);
        const tag = `GalaxyBudsSocket-${identifier}`;
        this._log = createLogger(tag);
        this._log.info('GalaxyBudsSocket init');

        this._modelId = modelData.modelId;
        this._features = modelData.features;
        this._firstExtendedStatusRecieved = false;

        const SOM_BUDS = 0xFE;
        const EOM_BUDS = 0xEE;
        const SOM_BUDS_PLUS = 0xFD;
        const EOM_BUDS_PLUS = 0xDD;

        this._startOfMessage = SOM_BUDS_PLUS;
        this._endOfMessage = EOM_BUDS_PLUS;

        if (this._modelId === GalaxyBudsModel.GalaxyBuds) {
            this._startOfMessage = SOM_BUDS;
            this._endOfMessage = EOM_BUDS;
        }

        this._callbacks = callbacks;

        this.startSocket();
    }

    _checksum(data) {
        let crc = 0;
        for (const b of data)
            crc = (crc16Tab[(crc >> 8 ^ b) & 0xFF] ^ crc << 8) & 0xFFFF;

        return crc;
    }

    _checksumMsg(msgId, payload) {
        const data = [msgId, ...payload];
        const crc = this._checksum(data);
        return [crc & 0xFF, crc >> 8];
    }

    _decode(buffer) {
        if (buffer.length < 6) {
            this._log.error(`buffer length too short: ${buffer.length}`);
            return null;
        }

        if (buffer[0] !== this._startOfMessage ||
            buffer[buffer.length - 1] !== this._endOfMessage) {
            const som = buffer[0].toString(16);
            const eom = buffer[buffer.length - 1].toString(16);
            const expectedSom = this._startOfMessage.toString(16);
            const expectedEom = this._endOfMessage.toString(16);
            this._log.error(
                `SOM/EOM mismatch: got ${som}/${eom}, expected ${expectedSom}/${expectedEom}`
            );
            return null;
        }


        let type, size;
        if (this._isLegacy) {
            type = buffer[1];
            size = buffer[2];
        } else {
            const header = buffer[2] << 8 | buffer[1];
            type = header & 0x1000 ? GalaxyBudsMsgTypes.Request : GalaxyBudsMsgTypes.Response;
            size = header & 0x3FF;
        }

        const id = buffer[3];
        const payloadSize = Math.max(size - 3, 0);
        const expectedLen = 4 + payloadSize + 2 + 1;
        if (buffer.length < expectedLen) {
            this._log.error(`buffer length too shot: ${buffer.length} < ${expectedLen}`);
            return null;
        }

        const payload = Array.from(buffer.slice(4, 4 + payloadSize));
        const crcLo = buffer[4 + payloadSize];
        const crcHi = buffer[5 + payloadSize];
        const expectedCrc = crcHi << 8 | crcLo;
        const actualCrc = this._checksum([id, ...payload]);
        if (actualCrc !== expectedCrc) {
            this._log.error('bad CRC');
            return null;
        }

        return {id, type, payload};
    }

    _encode(msgId, payload = []) {
        const size = 1 + payload.length + 2;
        const buf = [this._startOfMessage];

        if (this._isLegacy) {
            buf.push(GalaxyBudsMsgTypes.Request, size);
        } else {
            const headerLo = size & 0xFF;
            const headerHi = size >> 8 & 0xFF;
            buf.push(headerLo, headerHi);
        }

        buf.push(msgId, ...payload);
        const crc = this._checksum([msgId, ...payload]);
        buf.push(crc & 0xFF, crc >> 8 & 0xFF);
        buf.push(this._endOfMessage);
        return Uint8Array.from(buf);
    }

    _sendPacket(msgId, payload = []) {
        const pkt = this._encode(msgId, payload);
        this.sendMessage(pkt);
    }

    processData(bytes) {
        const resp = this._decode(bytes);
        if (!resp)
            return;

        const {id, payload} = resp;

        switch (id) {
            case GalaxyBudsMsgIds.FW_VERSION:
                this._log.info('Parse FirmwareVersion');
                this._parseFirmwareVersion(payload);
                break;

            case GalaxyBudsMsgIds.DEBUG_SERIAL:
                this._log.info('Parse DebugSerial');
                this._parseDebugSerial(payload);
                break;

            case GalaxyBudsMsgIds.CRADLE_SERIAL:
                this._log.info('Parse CradleSerial');
                this._parseCradleSerial(payload);
                break;

            case GalaxyBudsMsgIds.EXTENDED_STATUS_UPDATED:
                this._parseExtendedStatusUpdate(payload);
                if (!this._firstExtendedStatusRecieved) {
                    this._sendManagerInfo();
                    this._firstExtendedStatusRecieved = true;
                    this._getDebugSerial();
                }
                break;

            case GalaxyBudsMsgIds.STATUS_UPDATED:
                this._log.info('Parse StatusUpdate');
                this._parseStatusUpdate(payload);
                break;

            case GalaxyBudsMsgIds.AMBIENT_MODE_UPDATED:
                this._log.info('Parse AmbientModeUpdate');
                this._processAmbientMode(payload[0]);
                break;

            case LegacyMsgIds.AMBIENT_VOICE_FOCUS:
                this._log.info('Parse AmbientVoiceFocus');
                this._processAmbientVoiceFocusDecoder(payload[0]);
                break;

            case GalaxyBudsMsgIds.AMBIENT_VOLUME:
                this._log.info('Parse AmbientVolume');
                this._processAmbientVolume(payload[0]);
                break;

            case GalaxyBudsMsgIds.NOISE_REDUCTION_MODE_UPDATE:
                this._log.info('Parse NoiseReductionModeUpdate');
                this._processNCOnOff(payload[0]);
                break;

            case GalaxyBudsMsgIds.NOISE_CONTROLS_UPDATE:
                this._log.info('Parse NoiseControlUpdate');
                this._processNCModes(payload[0]);
                break;

            case GalaxyBudsMsgIds.SET_TOUCHPAD_OPTION:
                this._log.info('Parse TouchOptionUpdate');
                this._recvTouchpadOptionL(Boolean(payload[0]));
                this._recvTouchpadOptionR(Boolean(payload[1]));
                break;

            case GalaxyBudsMsgIds.LOCK_TOUCHPAD:
                this._log.info('Parse LockTouchUpdate');
                if (this._features.advancedTouchLock || this._features.advancedTouchIsPinch)
                    this._processAdvanceTouch(payload);
                else
                    this._processTouchLock(payload);
                break;
        }
    }

    postConnectInitialization() {
        this.sendMessage(this._encode(GalaxyBudsMsgIds.EXTENDED_STATUS_UPDATED));
    }

    _parseFirmwareVersion(payload) {
        if (!payload || payload.length < 14)
            return;

        const info = String.fromCharCode(...payload.slice(2, 14));

        this._log.info(`Firmware: ${info}`);
        this._callbacks?.updateFirmwareInfo?.(info);
    }

    _parseDebugSerial(payload) {
        if (!payload || payload.length < 22)
            return;

        const left = String.fromCharCode(...payload.slice(0, 11));
        const right = String.fromCharCode(...payload.slice(11, 22));
        this._callbacks?.updateLRSerial?.(left, right);
    }

    _parseCradleSerial(payload) {
        if (!payload || payload.length < 20)
            return;

        const serialNumber = String.fromCharCode(...payload.slice(9, 20));
        this._callbacks?.updateCaseSerial?.(serialNumber);
    }

    _processBattery(battery) {
        const l = battery.left;
        const r = battery.right;
        const c = battery.case ?? 255;
        const mask = battery.mask ?? 0;

        const caseLevel = c > 100 ? 0 : c;

        let leftStatus;
        if (l === 0)
            leftStatus = 'disconnected';
        else if (mask & 0b00010000)
            leftStatus = 'charging';
        else
            leftStatus = 'discharging';

        let rightStatus;
        if (r === 0)
            rightStatus = 'disconnected';
        else if (mask & 0b00000100)
            rightStatus = 'charging';
        else
            rightStatus = 'discharging';

        let caseStatus;
        if (caseLevel === 0)
            caseStatus = 'disconnected';
        else if (mask & 0b00000001)
            caseStatus = 'charging';
        else
            caseStatus = 'discharging';

        const props = {
            battery1Level: l,
            battery1Status: leftStatus,
            battery2Level: r,
            battery2Status: rightStatus,
            battery3Level: caseLevel,
            battery3Status: caseStatus,
        };

        this._callbacks?.updateBatteryProps?.(props);
    }

    _processEar(byte) {
        let left, right;

        if (this._modelId === GalaxyBudsModel.GalaxyBuds) {
            switch (byte) {
                case GalaxyBudsLegacyEarDetectionState.Both:
                    left = GalaxyBudsEarDetectionState.Wearing;
                    right = GalaxyBudsEarDetectionState.Wearing;
                    break;

                case GalaxyBudsLegacyEarDetectionState.L:
                    left = GalaxyBudsEarDetectionState.Wearing;
                    right = GalaxyBudsEarDetectionState.Idle;
                    break;

                case GalaxyBudsLegacyEarDetectionState.R:
                    left = GalaxyBudsEarDetectionState.Idle;
                    right = GalaxyBudsEarDetectionState.Wearing;
                    break;

                default:
                    left = GalaxyBudsEarDetectionState.Idle;
                    right = GalaxyBudsEarDetectionState.Idle;
                    break;
            }
        } else {
            left = byte >> 4;
            right = byte & 0x0F;
        }

        this._callbacks?.updateInEarState?.(left, right);
    }

    _processAmbientMode(byte) {
        if (!this._features.ambientSound || this._features.noiseControl)
            return;

        const enabled = booleanFromByte(byte);
        if (enabled === null)
            return;

        const mode = enabled ? GalaxyBudsAnc.AmbientSound : GalaxyBudsAnc.Off;

        this._callbacks?.updateNCModes?.(mode);
    }

    _processAmbientVoiceFocusDecoder(byte) {
        if (!this._features.ambientVoiceFocus)
            return;

        const enabled = booleanFromByte(byte);
        if (enabled === null)
            return;

        this._callbacks?.updateFocusOnVoice?.(enabled);
    }

    _processAmbientVolume(byte) {
        if (!this._features.ambientSoundVolume)
            return;

        this._callbacks?.updateAmbientVolume?.(byte);
    }

    _processNCOnOff(byte) {
        if (!this._features.noiseCancellation || this._features.noiseControl)
            return;

        const enabled = booleanFromByte(byte);
        if (enabled === null)
            return;

        const mode = enabled ? GalaxyBudsAnc.NoiseReduction : GalaxyBudsAnc.Off;

        this._callbacks?.updateNCModes?.(mode);
    }

    _processNCModes(byte) {
        if (!this._features.noiseControl)
            return;

        if (!isValidByte(byte, GalaxyBudsAnc))
            return;

        this._callbacks?.updateNCModes?.(byte);
    }

    _recvNoiseControlCycle(byte) {
        const ncCycleProps = {};
        const b = byte;
        if (this._features.adaptiveNoiseControl) {
            ncCycleProps.ambient = (b & 1 << 0) !== 0;
            ncCycleProps.adaptive = (b & 1 << 1) !== 0;
            ncCycleProps.off = (b & 1 << 2) !== 0;
            ncCycleProps.anc = (b & 1 << 3) !== 0;
            ncCycleProps.leftAmbient = (b & 1 << 4) !== 0;
            ncCycleProps.leftAdaptive = (b & 1 << 5) !== 0;
            ncCycleProps.leftOff = (b & 1 << 6) !== 0;
            ncCycleProps.leftAnc = (b & 1 << 7) !== 0;
        } else {
            ncCycleProps.off = (b & 1 << 0) !== 0;
            ncCycleProps.ambient = (b & 1 << 1) !== 0;
            ncCycleProps.anc = (b & 1 << 2) !== 0;

            if (this._features.noiseControlModeDualSide) {
                ncCycleProps.leftOff = (b & 1 << 4) !== 0;
                ncCycleProps.leftAmbient = (b & 1 << 5) !== 0;
                ncCycleProps.leftAnc = (b & 1 << 6) !== 0;
            }
        }
        this._callbacks?.updateNoiseControlCycle?.(ncCycleProps);
    }

    _recvNoiseReductionLevel(level) {
        this._callbacks?.updateNoiseReductionLevel?.(level);
    }

    _recvDetectConversations(enable) {
        this._callbacks?.updateDetectConversations?.(enable);
    }

    _recvDetectConversationsDuration(duration) {
        duration = duration > 2 ? 1 : duration;
        this._callbacks?.updateDetectConversationsDuration?.(duration);
    }

    _processEqPresets(byte, enabled) {
        let preset;
        if (this._modelId === GalaxyBudsModel.GalaxyBuds) {
            if (!enabled)
                preset = EqPresets.Off;
            else if (byte <= 9)
                preset = byte;
            else
                return;
        } else if (!isValidByte(byte, EqPresets)) {
            return;
        } else {
            preset = byte === 0 ? EqPresets.Off : byte - 1;
        }
        this._callbacks?.updateEqPresets?.(preset);
    }

    _recvStereoBal(bal) {
        this._callbacks?.updateStereoBal?.(bal);
    }

    _recvTouchpadLock(enable) {
        this._callbacks?.updateTouchpadLock?.(enable);
    }

    _recvAdvanceTouchpadLock(touchProps) {
        this._callbacks?.updateAdvanceTouchpadLock?.(touchProps);
    }

    _recvTouchpadOptionL(mode) {
        this._callbacks?.updateTouchpadOptionL?.(mode);
    }

    _recvTouchpadOptionR(mode) {
        this._callbacks?.updateTouchpadOptionR?.(mode);
    }

    _recvSideToneEnabled(enable) {
        this._callbacks?.updateSideToneEnabled?.(enable);
    }

    _recvNoiseControlsWithOneEarbud(enable) {
        this._callbacks?.updateNoiseControlsWithOneEarbud?.(enable);
    }

    _recvOutsideDoubleTap(enable) {
        this._callbacks?.updateOutsideDoubleTap?.(enable);
    }

    _recvLightingMode(mode) {
        this._callbacks?.updateLightingMode?.(mode);
    }

    _recvAmbientCustomization(volumeON, volumeLevels, soundtone) {
        const customAmbientProps = {};
        customAmbientProps.enable = volumeON === 1;
        customAmbientProps.leftVolume = (volumeLevels & 0xF0) >> 4;
        customAmbientProps.rightVolume = volumeLevels & 0x0F;
        customAmbientProps.soundtone = soundtone;
        this._callbacks?.updateAmbientCustomization?.(customAmbientProps);
    }

    _processTouchLock(payload) {
        const enable = Boolean(payload[0]);
        this._recvTouchpadLock(enable);
    }

    _processAdvanceTouch(payload) {
        const touchProps = {};

        touchProps.touchpadLock(Boolean(payload[0]));
        if (payload.length > 4) {
            touchProps.singleTapOn(Boolean(payload[1]));
            touchProps.doubleTapOn(Boolean(payload[2]));
            touchProps.tripleTapOn(Boolean(payload[3]));
            touchProps.touchHoldOn(Boolean(payload[4]));
        }

        if (payload.length > 6 && this._features.advancedTouchLockForCalls) {
            touchProps.touchHoldOnForCallOff(Boolean(payload[5]));
            touchProps.touchHoldOnForCallOff(Boolean(payload[6]));
        }

        this._recvAdvanceTouchpadLock(touchProps);
    }

    _parseStatusUpdate(payload) {
        const battery = {left: null, right: null, case: null, mask: null};
        const inearStatus = payload[5];

        if (this._modelId === GalaxyBudsModel.GalaxyBuds) {
            battery.left = payload[1];
            battery.right = payload[2];
        } else {
            battery.left = payload[1];
            battery.right = payload[2];
            battery.case = payload[6];

            if (this._features.chargingState)
                battery.mask = payload[7];
        }

        this._processEar(inearStatus);
    }

    _parseExtendedStatusUpdate(payload) {
        this._log.info(`Parse ExtendedStatusUpdate Payload length: ${payload.length}`);
        const battery = {left: null, right: null, case: null, mask: null};
        const EarlyExit = {};
        const readByte = i => {
            if (i >= payload.length)
                throw EarlyExit;
            return payload[i];
        };

        this._callbacks?.updateExtendedStatusStarted?.();
        try {
            const rev = readByte(0);

            battery.left = readByte(2);
            battery.right = readByte(3);
            this._processEar(readByte(6));

            if (this._modelId === GalaxyBudsModel.GalaxyBuds) {
                this._processAmbientMode(readByte(7));
                this._processAmbientVoiceFocusDecoder(readByte(8));
                this._processAmbientVolume(readByte(9));
                this._processEqPresets(readByte(11), readByte(10));

                const hasTouchpadExtra = payload.length > 13;
                if (hasTouchpadExtra) {
                    this._recvTouchpadLock(Boolean(readByte(12)));
                    const byte13 = readByte(13);
                    this._recvTouchpadOptionL((byte13 & 0xF0) >> 4);
                    this._recvTouchpadOptionR(byte13 & 0x0F);
                } else {
                    const byte12 = readByte(12);
                    this._recvTouchpadLock(Boolean((byte12 & 0xF0) >> 4));
                    this._recvTouchpadOptionL(byte12 & 0x0F);
                    this._recvTouchpadOptionR(byte12 & 0x0F);
                }
                return;
            } // GalaxyBuds

            battery.case = readByte(7);

            if (this._modelId === GalaxyBudsModel.GalaxyBudsPlus) {
                this._processAmbientMode(readByte(8));
                this._processAmbientVolume(readByte(9));
                this._processEqPresets(readByte(11));
                this._recvTouchpadLock(Boolean(readByte(12)));
                this._recvTouchpadOptionL((readByte(13) & 240) >> 4);
                this._recvTouchpadOptionR(readByte(13) & 15);
                this._recvOutsideDoubleTap(readByte(14) === 1);

                if (rev >= 8)
                    this._recvSideToneEnabled(readByte(19) === 1);

                return;
            } // GalaxyBudsPlus

            this._processEqPresets(readByte(9));

            if (this._features.advancedTouchLock) {
                const touchProps = {};
                touchProps.touchpadLock = (readByte(10) & 1 << 7) !== 128;
                touchProps.touchHoldOn = (readByte(10) & 1 << 0) === 1;
                touchProps.tripleTapOn = (readByte(10) & 1 << 1) === 2;
                touchProps.doubleTapOn = (readByte(10) & 1 << 2) === 4;
                touchProps.singleTapOn = (readByte(10) & 1 << 3) === 8;

                if (this._features.advancedTouchLockForCalls) {
                    touchProps.touchHoldOnForCallOff = (readByte(10) & 1 << 5) === 32;
                    touchProps.doubleTapForCallOn = (readByte(10) & 1 << 4) === 16;
                }

                if (this._features.AdvancedTouchLockSwipe)
                    touchProps.swipeOn = (readByte(10) & 1 << 6) === 64;


                this._recvAdvanceTouchpadLock(touchProps);
            } else {
                this._recvTouchpadLock(readByte(10) === 1);
            }

            this._recvTouchpadOptionL((readByte(11) & 0xF0) >> 4);
            this._recvTouchpadOptionR(readByte(11) & 0x0F);

            if (this._modelId === GalaxyBudsModel.GalaxyBudsLive) {
                this._processNCOnOff(readByte(12));
                if (rev >= 7)
                    this._recvStereoBal(readByte(22));

                return;
            }

            this._processNCModes(readByte(12));

            this._recvNoiseControlCycle(readByte(21));

            this._processAmbientVolume(readByte(23));
            this._recvNoiseReductionLevel(readByte(24));

            if (this._modelId !== GalaxyBudsModel.GalaxyBuds2) {
                this._recvDetectConversations(readByte(26) === 1);
                this._recvDetectConversationsDuration(readByte(27));
            }

            if (this._modelId === GalaxyBudsModel.GalaxyBudsPro) {
                if (rev >= 5)
                    this._recvStereoBal(readByte(29));

                if (rev >= 7)
                    this._recvOutsideDoubleTap(readByte(31) === 1);

                if (rev >= 8) {
                    this._recvNoiseControlsWithOneEarbud(readByte(32) === 1);
                    this._recvAmbientCustomization(readByte(33), readByte(34), readByte(35));
                }

                if (rev >= 9)
                    this._recvSideToneEnabled(readByte(36) === 1);
            } else if (this._modelId === GalaxyBudsModel.GalaxyBuds2) {
                this._recvStereoBal(readByte(25));

                if (rev >= 3)
                    this._recvNoiseControlsWithOneEarbud(readByte(28) === 1);

                if (rev >= 5) {
                    this._recvAmbientCustomization(readByte(29), readByte(30), readByte(31));
                    this._recvOutsideDoubleTap(readByte(32) === 1);
                }

                if (rev >= 6)
                    this._recvSideToneEnabled(readByte(33) === 1);

                if (rev >= 10)
                    battery.mask = readByte(36);
            } else if (this._modelId === GalaxyBudsModel.GalaxyBuds2Pro) {
                this._recvStereoBal(readByte(25));
                this._recvNoiseControlsWithOneEarbud(readByte(28) === 1);
                this._recvAmbientCustomization(readByte(29), readByte(30), readByte(31));
                this._recvOutsideDoubleTap(readByte(32) === 1);
                this._recvSideToneEnabled(readByte(33) === 1);

                if (rev >= 11)
                    battery.mask = readByte(43);
            } else {
                this._recvStereoBal(readByte(25));
                this._recvNoiseControlsWithOneEarbud(readByte(28) === 1);
                this._recvAmbientCustomization(readByte(29), readByte(30), readByte(31));
                this._recvOutsideDoubleTap(readByte(32) === 1);
                this._recvSideToneEnabled(readByte(33) === 1);

                if (this._modelId === GalaxyBudsModel.GalaxyBudsFe)
                    battery.mask = readByte(43);
                else
                    battery.mask = readByte(42);

                if (this._modelId === GalaxyBudsModel.GalaxyBuds3Pro)
                    this._recvLightingMode(readByte(50));
            }
        } catch (e) {
            if (e !== EarlyExit)
                throw e;
        } finally {
            this._processBattery(battery);
            this._callbacks?.updateExtendedStatusEnded?.();
        }
    }// _parseExtendedStatusUpdate

    _sendManagerInfo() {
        this._log.info('Set ManagerInfo');
        const payload = [1, ClientSamsungDevice,  AndroidSdkVersion];
        this._sendPacket(GalaxyBudsMsgIds.MANAGER_INFO, payload);
    }

    _getDebugSerial() {
        this._log.info('Get DebugSerial');
        this._sendPacket(GalaxyBudsMsgIds.DEBUG_SERIAL);
    }

    setAmbientSoundOnOff(mode) {
        this._log.info('Set AmbientSoundOnOff');
        const payload = [mode === GalaxyBudsAnc.AmbientSound ? 1 : 0];
        this._sendPacket(GalaxyBudsMsgIds.SET_AMBIENT_MODE, payload);
    }

    setFocusOnVoice(enabled) {
        this._log.info('Set FocusOnVoice');
        const payload = [enabled ? 1 : 0];
        this._sendPacket(LegacyMsgIds.AMBIENT_VOICE_FOCUS, payload);
    }

    setAmbientVolume(level) {
        this._log.info('Set AmbientVolume');
        const payload = [level];
        this._sendPacket(GalaxyBudsMsgIds.AMBIENT_VOLUME, payload);
    }

    setNCOnOff(mode) {
        this._log.info('Set NCOnOff');
        const payload = [mode === GalaxyBudsAnc.NoiseReduction ? 1 : 0];
        this._sendPacket(GalaxyBudsMsgIds.SET_NOISE_REDUCTION, payload);
    }

    setNCModes(mode) {
        this._log.info('Set NCModes');
        const payload = [mode];
        this._sendPacket(GalaxyBudsMsgIds.NOISE_CONTROLS, payload);
    }

    setNoiseCancellationLevel(level) {
        this._log.info('Set NoiseCancellationLevel');
        const payload = [level];
        this._sendPacket(GalaxyBudsMsgIds.NOISE_REDUCTION_LEVEL, payload);
    }

    setEqPresets(preset) {
        this._log.info('Set EqPresets');
        let payload;
        const enabled = preset !== EqPresets.Off;

        if (this._modelId === GalaxyBudsModel.GalaxyBuds)
            payload = [enabled ? 1 : 0, preset];
        else
            payload = [!enabled ? 0 : preset + 1];
        this._sendPacket(GalaxyBudsMsgIds.EQUALIZER, payload);
    }

    setStereoBalance(bal) {
        this._log.info('Set StereoBalance');
        const payload = [bal];
        this._sendPacket(GalaxyBudsMsgIds.SET_HEARING_ENHANCEMENTS, payload);
    }

    setTouchPadLock(enabled) {
        this._log.info('Set TouchPadLock');
        const payload = [enabled ? 1 : 0];
        this._sendPacket(GalaxyBudsMsgIds.LOCK_TOUCHPAD, payload);
    }

    setTouchPadAdvance(touchProps) {
        this._log.info('Set TouchPadAdvance');
        const payload = [];
        payload.push(touchProps.touchpadLock ? 1 : 0);
        payload.push(touchProps.singleTapOn ? 1 : 0);
        payload.push(touchProps.doubleTapOn ? 1 : 0);
        payload.push(touchProps.tripleTapOn ? 1 : 0);
        payload.push(touchProps.touchHoldOn ? 1 : 0);

        if (this._features.advancedTouchLockForCalls) {
            payload.push(touchProps.doubleTapForCallOn ? 1 : 0);
            payload.push(touchProps.touchHoldOnForCallOff ? 1 : 0);
        }
        if (this._features.advancedTouchIsPinch)
            payload.push(touchProps.singleTapOn ? 1 : 0); // Swipe byte

        if (this._features.lightingControl)
            payload.push(touchProps.lightingMode);

        if (this._features.quickLaunchAdvance)
            payload.push(0x00);

        this._sendPacket(GalaxyBudsMsgIds.LOCK_TOUCHPAD, payload);
    }

    setTouchAndHoldLRModes(touchAndHoldProps) {
        this._log.info('Set TouchAndHoldLRModes');
        const payload = [touchAndHoldProps.left, touchAndHoldProps.right];
        this._sendPacket(GalaxyBudsMsgIds.SET_TOUCHPAD_OPTION, payload);
    }

    setNcCycleLegacy(props) {
        this._log.info('Set NcCycleLegacy');
        const payload = [];

        const encodeSide = val => {
            const off = val >> 0 & 1;
            const ambient = val >> 1 & 1;
            const anc = val >> 2 & 1;
            return [off, ambient, anc];
        };

        if (this._features.noiseControlModeDualSide) {
            payload.push(...encodeSide(props.left));
            payload.push(...encodeSide(props.right));
        } else {
            payload.push(...encodeSide(props.right));
        }

        this._sendPacket(GalaxyBudsMsgIds.SET_TOUCH_AND_HOLD_NOISE_CONTROLS, payload);
    }

    setNcCycle(props) {
        this._log.info('Set NcCycle');
        const payload = [];

        const encodeByte = val => {
            let b = 0x00;

            if (val >> 2 & 1)
                b |= 0x08;

            if (val >> 0 & 1)
                b |= 0x04;

            if (this._features.adaptiveNoiseControl) {
                if (val >> 3 & 1)
                    b |= 0x02;
            }

            if (val >> 1 & 1)
                b |= 0x01;

            if (b === 0x00)
                b = 0x09;

            return b;
        };

        const leftVal = this._features.noiseControlModeDualSide ? props.left : props.right;

        payload.push(encodeByte(leftVal));
        payload.push(encodeByte(props.right));

        this._sendPacket(GalaxyBudsMsgIds.SET_TOUCH_AND_HOLD_NOISE_CONTROLS, payload);
    }

    setDetectConversations(enabled) {
        this._log.info('Set DetectConversations');
        const payload = [enabled ? 1 : 0];
        this._sendPacket(GalaxyBudsMsgIds.SET_DETECT_CONVERSATIONS, payload);
    }

    setDetectConversationsDuration(duration) {
        this._log.info('Set DetectConversationsDuration');
        const payload = [duration];
        this._sendPacket(GalaxyBudsMsgIds.SET_DETECT_CONVERSATIONS_DURATION, payload);
    }

    setSideTone(enabled) {
        this._log.info('Set SideTone');
        const payload = [enabled ? 1 : 0];
        this._sendPacket(GalaxyBudsMsgIds.SET_SIDETONE, payload);
    }

    setNoiseControlsWithOneEarbud(enabled) {
        this._log.info('Set NoiseControlsWithOneEarbud');
        const payload = [enabled ? 1 : 0];
        this._sendPacket(GalaxyBudsMsgIds.SET_ANC_WITH_ONE_EARBUD, payload);
    }

    setOutsideDoubleTap(enabled) {
        this._log.info('Set OutsideDoubleTap');
        const payload = [enabled ? 1 : 0];
        this._sendPacket(GalaxyBudsMsgIds.OUTSIDE_DOUBLE_TAP, payload);
    }

    setCustomizeAmbientSound(props) {
        this._log.info('Set CustomizeAmbientSound');
        const payload = [props.enable ? 1 : 0];
        payload.push(props.leftVolume);
        payload.push(props.rightVolume);
        payload.push(props.soundtone);
        this._sendPacket(GalaxyBudsMsgIds.CUSTOMIZE_AMBIENT_SOUND, payload);
    }

    setRingMyBuds(state) {
        this._log.info('Set RingMyBuds');

        if (state === 'playing') {
            if (this._features.fmgRingWhileWearing)
                this._sendPacket(GalaxyBudsMsgIds.FIND_MY_EARBUDS_ON_WEARING_START);
            else
                this._sendPacket(GalaxyBudsMsgIds.FIND_MY_EARBUDS_START);
        } else {
            this._sendPacket(GalaxyBudsMsgIds.FIND_MY_EARBUDS_STOP);
        }
    }

    destroy() {
        super.destroy();
    }
});


