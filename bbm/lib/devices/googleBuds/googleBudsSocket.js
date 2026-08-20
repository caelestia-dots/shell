'use strict';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';

import {createLogger, getDeviceIdentifier} from '../logger.js';
import {SocketHandler} from '../socketByProfile.js';
import {
    CandidateChannels, MaestroMethod, MaestroService, PacketType, SettingId, Status
} from './googleBudsConfig.js';
import {
    HdlcCodec, decodeAncGestureLoopSettingsResponse, decodeAncStateSettingsResponse,
    decodeEqSettingsResponse, decodeRpcPacket, decodeRuntimeInfo, decodeFwVersion,
    decodeVolumeEqEnableSettingsResponse, encodeReadSettingPayload, encodeRpcPacket,
    encodeWriteAncStatePayload, encodeWriteEqPayload, encodeWriteVolumeEqEnablePayload
} from './googleBudsProtocol.js';

const SOFTWARE_INFO_CALL_ID = 0xffffffff;
const RUNTIME_INFO_CALL_ID = 1;
const READ_ANC_STATE_CALL_ID = 2;
const READ_ANC_GESTURE_LOOP_CALL_ID = 3;
const SETTINGS_CHANGES_CALL_ID = 4;
const READ_VOLUME_EQ_CALL_ID = 5;
const READ_EQ_CALL_ID = 6;
const READ_LAST_SAVED_EQ_CALL_ID = 7;
const WRITE_SETTING_CALL_ID_BASE = 100;
const WRITE_RESPONSE_TIMEOUT_MS = 3000;
const WRITE_REFRESH_TIMEOUT_MS = 3000;

export const GoogleBudsSocket = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_GoogleBudsSocket',
}, class GoogleBudsSocket extends SocketHandler {
    _init(devicePath, profileManager, profile, callbacks) {
        super._init(devicePath, profileManager, profile);
        const identifier = getDeviceIdentifier(devicePath);
        const tag = `GoogleBudsSocket-${identifier}`;
        this._log = createLogger(tag);
        this._log.info('GoogleBudsSocket init');

        this._codec = new HdlcCodec();
        this._callbacks = callbacks;
        this._channel = null;
        this._writeCallId = WRITE_SETTING_CALL_ID_BASE;
        this._ancReadAfterRuntime = false;
        this._pendingWriteSettings = new Map();
        this._writeQueue = [];
        this._writeInFlight = false;
        this._resumeWritesAfterReadCallId = null;
        this._resumeWritesAfterReadSetting = null;
        this._writeResponseTimeoutId = 0;
        this._writeRefreshTimeoutId = 0;

        this.startSocket();
    }

    postConnectInitialization() {
        this._log.info('Waiting for Maestro software-info response');
    }

    processData(bytes) {
        for (const frame of this._codec.decode(bytes)) {
            try {
                this._processPacket(decodeRpcPacket(frame.data));
            } catch (e) {
                this._log.error(e, 'Failed to decode Maestro packet');
            }
        }
    }

    _processPacket(packet) {
        if (this._channel === null && this._isSoftwareInfoResponse(packet)) {
            this._channel = packet.channelId;
            this._log.info(`Resolved Maestro channel ${this._channel}`);

            const fwVersions = decodeFwVersion(packet.payload);
            this._callbacks?.updateFirmwareInfo?.(fwVersions);

            this._subscribeRuntimeInfo();
            this._subscribeSettingsChanges();
            return;
        }

        if (this._channel !== null && packet.type === PacketType.SERVER_STREAM &&
                packet.channelId === this._channel &&
                packet.serviceId === MaestroService &&
                packet.methodId === MaestroMethod.SUBSCRIBE_RUNTIME_INFO &&
                packet.callId === RUNTIME_INFO_CALL_ID) {
            const props = decodeRuntimeInfo(packet.payload);
            if (Object.keys(props).length > 0)
                this._callbacks?.updateBatteryProps?.(props);
            if (!this._ancReadAfterRuntime) {
                this._ancReadAfterRuntime = true;
                this.readAncGestureLoop();
            }
            return;
        }

        if (this._channel !== null && packet.type === PacketType.RESPONSE &&
                packet.channelId === this._channel &&
                packet.serviceId === MaestroService &&
                packet.methodId === MaestroMethod.READ_SETTING &&
                packet.callId === this._resumeWritesAfterReadCallId) {
            this._processWriteRefreshResponse(packet);
            return;
        }

        if (this._channel !== null && packet.type === PacketType.RESPONSE &&
                packet.channelId === this._channel &&
                packet.serviceId === MaestroService &&
                packet.methodId === MaestroMethod.READ_SETTING &&
                packet.callId === READ_ANC_STATE_CALL_ID) {
            if (packet.status === Status.OK) {
                const ancState = decodeAncStateSettingsResponse(packet.payload);
                if (ancState !== null)
                    this._callbacks?.updateAncState?.(ancState);
            }
            if (this._resumeWritesAfterReadCallId === READ_ANC_STATE_CALL_ID) {
                this._completeWriteRefresh();
                return;
            }
            this.readVolumeEqEnable();
            return;
        }

        if (this._channel !== null && packet.type === PacketType.RESPONSE &&
                packet.channelId === this._channel &&
                packet.serviceId === MaestroService &&
                packet.methodId === MaestroMethod.READ_SETTING &&
                packet.callId === READ_ANC_GESTURE_LOOP_CALL_ID) {
            if (packet.status === Status.OK) {
                const gestureLoop = decodeAncGestureLoopSettingsResponse(packet.payload);
                if (gestureLoop !== null)
                    this._callbacks?.updateAncGestureLoop?.(gestureLoop);
            }
            this.readAncState();
            return;
        }

        if (this._channel !== null && packet.type === PacketType.RESPONSE &&
                packet.channelId === this._channel &&
                packet.serviceId === MaestroService &&
                packet.methodId === MaestroMethod.READ_SETTING &&
                packet.callId === READ_VOLUME_EQ_CALL_ID) {
            if (packet.status === Status.OK) {
                const enabled = decodeVolumeEqEnableSettingsResponse(packet.payload);
                if (enabled !== null)
                    this._callbacks?.updateVolumeEqEnable?.(enabled);
            }
            if (this._resumeWritesAfterReadCallId === READ_VOLUME_EQ_CALL_ID) {
                this._completeWriteRefresh();
                return;
            }
            this.readEq();
            return;
        }

        if (this._channel !== null && packet.type === PacketType.RESPONSE &&
                packet.channelId === this._channel &&
                packet.serviceId === MaestroService &&
                packet.methodId === MaestroMethod.READ_SETTING &&
                packet.callId === READ_EQ_CALL_ID) {
            if (packet.status === Status.OK) {
                const eq = decodeEqSettingsResponse(packet.payload);
                if (eq !== null)
                    this._callbacks?.updateEq?.(eq);
            }
            if (this._resumeWritesAfterReadCallId === READ_EQ_CALL_ID) {
                this._completeWriteRefresh();
                return;
            }
            this.readLastSavedEq();
            return;
        }

        if (this._channel !== null && packet.type === PacketType.RESPONSE &&
                packet.channelId === this._channel &&
                packet.serviceId === MaestroService &&
                packet.methodId === MaestroMethod.READ_SETTING &&
                packet.callId === READ_LAST_SAVED_EQ_CALL_ID) {
            if (packet.status === Status.OK) {
                const eq = decodeEqSettingsResponse(packet.payload, SettingId.LAST_SAVED_USER_EQ);
                if (eq !== null)
                    this._callbacks?.updateLastSavedEq?.(eq);
            } else {
                this._log.info(`Last saved EQ read failed with status ${packet.status}`);
            }
            return;
        }

        if (this._channel !== null && packet.type === PacketType.SERVER_STREAM &&
                packet.channelId === this._channel &&
                packet.serviceId === MaestroService &&
                packet.methodId === MaestroMethod.SUBSCRIBE_SETTINGS_CHANGES &&
                packet.callId === SETTINGS_CHANGES_CALL_ID) {
            this._processSettingsPayload(packet.payload);
            return;
        }

        if (this._channel !== null &&
                (packet.type === PacketType.RESPONSE || packet.type === PacketType.SERVER_ERROR) &&
                packet.channelId === this._channel &&
                packet.serviceId === MaestroService &&
                packet.methodId === MaestroMethod.WRITE_SETTING &&
                packet.callId >= WRITE_SETTING_CALL_ID_BASE) {
            if (packet.status !== Status.OK)
                this._log.info(`Maestro setting write failed with status ${packet.status}`);
            this._refreshWrittenSetting(packet.callId);
            return;
        }

        if (packet.type === PacketType.SERVER_STREAM)
            this._sendClientError(packet, Status.FAILED_PRECONDITION);
    }

    _isSoftwareInfoResponse(packet) {
        return packet.type === PacketType.RESPONSE &&
            CandidateChannels.includes(packet.channelId) &&
            packet.serviceId === MaestroService &&
            packet.methodId === MaestroMethod.GET_SOFTWARE_INFO &&
            packet.callId === SOFTWARE_INFO_CALL_ID;
    }

    _subscribeRuntimeInfo() {
        this._sendRpcPacket({
            type: PacketType.REQUEST,
            channelId: this._channel,
            serviceId: MaestroService,
            methodId: MaestroMethod.SUBSCRIBE_RUNTIME_INFO,
            payload: [],
            status: Status.OK,
            callId: RUNTIME_INFO_CALL_ID,
        });
    }

    _subscribeSettingsChanges() {
        this._sendRpcPacket({
            type: PacketType.REQUEST,
            channelId: this._channel,
            serviceId: MaestroService,
            methodId: MaestroMethod.SUBSCRIBE_SETTINGS_CHANGES,
            payload: [],
            status: Status.OK,
            callId: SETTINGS_CHANGES_CALL_ID,
        });
    }

    readAncState() {
        if (this._channel === null)
            return;

        this._sendRpcPacket({
            type: PacketType.REQUEST,
            channelId: this._channel,
            serviceId: MaestroService,
            methodId: MaestroMethod.READ_SETTING,
            payload: encodeReadSettingPayload(SettingId.CURRENT_ANCR_STATE),
            status: Status.OK,
            callId: READ_ANC_STATE_CALL_ID,
        });
    }

    readAncGestureLoop() {
        if (this._channel === null)
            return;

        this._sendRpcPacket({
            type: PacketType.REQUEST,
            channelId: this._channel,
            serviceId: MaestroService,
            methodId: MaestroMethod.READ_SETTING,
            payload: encodeReadSettingPayload(SettingId.ANCR_GESTURE_LOOP),
            status: Status.OK,
            callId: READ_ANC_GESTURE_LOOP_CALL_ID,
        });
    }

    readVolumeEqEnable() {
        if (this._channel === null)
            return;

        this._sendRpcPacket({
            type: PacketType.REQUEST,
            channelId: this._channel,
            serviceId: MaestroService,
            methodId: MaestroMethod.READ_SETTING,
            payload: encodeReadSettingPayload(SettingId.VOLUME_EQ_ENABLE),
            status: Status.OK,
            callId: READ_VOLUME_EQ_CALL_ID,
        });
    }

    readEq() {
        if (this._channel === null)
            return;

        this._sendRpcPacket({
            type: PacketType.REQUEST,
            channelId: this._channel,
            serviceId: MaestroService,
            methodId: MaestroMethod.READ_SETTING,
            payload: encodeReadSettingPayload(SettingId.CURRENT_USER_EQ),
            status: Status.OK,
            callId: READ_EQ_CALL_ID,
        });
    }

    readLastSavedEq() {
        if (this._channel === null)
            return;

        this._readSetting(SettingId.LAST_SAVED_USER_EQ, READ_LAST_SAVED_EQ_CALL_ID);
    }

    _readSetting(settingId, callId) {
        this._sendRpcPacket({
            type: PacketType.REQUEST,
            channelId: this._channel,
            serviceId: MaestroService,
            methodId: MaestroMethod.READ_SETTING,
            payload: encodeReadSettingPayload(settingId),
            status: Status.OK,
            callId,
        });
    }

    setAncState(ancState) {
        if (this._channel === null)
            return;

        this._queueWriteSetting('anc', encodeWriteAncStatePayload(ancState));
    }

    setVolumeEqEnable(enabled) {
        if (this._channel === null)
            return;

        this._queueWriteSetting('volumeEq', encodeWriteVolumeEqEnablePayload(enabled));
    }

    setEq(eqBands) {
        if (this._channel === null)
            return;

        this._queueWriteSetting('eq', encodeWriteEqPayload(eqBands));
    }

    _queueWriteSetting(setting, payload) {
        this._writeQueue.push({setting, payload});
        this._sendNextWriteSetting();
    }

    _sendNextWriteSetting() {
        if (this._writeInFlight || this._resumeWritesAfterReadCallId !== null ||
                this._writeQueue.length === 0 || this._channel === null)
            return;

        const {setting, payload} = this._writeQueue.shift();
        this._writeCallId++;
        this._pendingWriteSettings.set(this._writeCallId, setting);
        this._writeInFlight = true;
        this._startWriteResponseTimeout(this._writeCallId, setting);
        this._sendRpcPacket({
            type: PacketType.REQUEST,
            channelId: this._channel,
            serviceId: MaestroService,
            methodId: MaestroMethod.WRITE_SETTING,
            payload,
            status: Status.OK,
            callId: this._writeCallId,
        });
    }

    _refreshWrittenSetting(callId) {
        if (!this._pendingWriteSettings.has(callId)) {
            this._log.info(`Ignoring stale Maestro setting write response callId=${callId}`);
            return;
        }

        this._clearWriteResponseTimeout();
        const setting = this._pendingWriteSettings.get(callId);
        this._pendingWriteSettings.delete(callId);
        this._writeInFlight = false;

        this._resumeWritesAfterReadCallId = ++this._writeCallId;
        this._resumeWritesAfterReadSetting = setting;

        if (setting === 'anc') {
            this._startWriteRefreshTimeout(this._resumeWritesAfterReadCallId, setting);
            this._readSetting(SettingId.CURRENT_ANCR_STATE, this._resumeWritesAfterReadCallId);
        } else if (setting === 'volumeEq') {
            this._startWriteRefreshTimeout(this._resumeWritesAfterReadCallId, setting);
            this._readSetting(SettingId.VOLUME_EQ_ENABLE, this._resumeWritesAfterReadCallId);
        } else if (setting === 'eq') {
            this._startWriteRefreshTimeout(this._resumeWritesAfterReadCallId, setting);
            this._readSetting(SettingId.CURRENT_USER_EQ, this._resumeWritesAfterReadCallId);
        } else {
            this._resumeWritesAfterReadCallId = null;
            this._resumeWritesAfterReadSetting = null;
            this._sendNextWriteSetting();
        }
    }

    _startWriteResponseTimeout(callId, setting) {
        this._clearWriteResponseTimeout();
        this._writeResponseTimeoutId = GLib.timeout_add(
            GLib.PRIORITY_DEFAULT,
            WRITE_RESPONSE_TIMEOUT_MS,
            () => {
                this._writeResponseTimeoutId = 0;
                if (!this._pendingWriteSettings.has(callId))
                    return GLib.SOURCE_REMOVE;

                this._pendingWriteSettings.delete(callId);
                this._writeInFlight = false;
                this._log.info(
                    `Maestro setting write timed out setting=${setting} callId=${callId}`
                );
                this._sendNextWriteSetting();
                return GLib.SOURCE_REMOVE;
            }
        );
    }

    _clearWriteResponseTimeout() {
        if (this._writeResponseTimeoutId) {
            GLib.Source.remove(this._writeResponseTimeoutId);
            this._writeResponseTimeoutId = 0;
        }
    }

    _startWriteRefreshTimeout(readCallId, setting) {
        this._clearWriteRefreshTimeout();
        this._writeRefreshTimeoutId = GLib.timeout_add(
            GLib.PRIORITY_DEFAULT,
            WRITE_REFRESH_TIMEOUT_MS,
            () => {
                this._writeRefreshTimeoutId = 0;
                if (this._resumeWritesAfterReadCallId !== readCallId)
                    return GLib.SOURCE_REMOVE;

                this._resumeWritesAfterReadCallId = null;
                this._resumeWritesAfterReadSetting = null;
                this._log.info(
                    `Maestro setting refresh timed out setting=${setting} callId=${readCallId}`
                );
                this._sendNextWriteSetting();
                return GLib.SOURCE_REMOVE;
            }
        );
    }

    _clearWriteRefreshTimeout() {
        if (this._writeRefreshTimeoutId) {
            GLib.Source.remove(this._writeRefreshTimeoutId);
            this._writeRefreshTimeoutId = 0;
        }
    }

    _completeWriteRefresh() {
        this._clearWriteRefreshTimeout();
        this._resumeWritesAfterReadCallId = null;
        this._resumeWritesAfterReadSetting = null;
        this._sendNextWriteSetting();
    }

    _processWriteRefreshResponse(packet) {
        if (packet.status === Status.OK) {
            if (this._resumeWritesAfterReadSetting === 'anc') {
                const ancState = decodeAncStateSettingsResponse(packet.payload);
                if (ancState !== null)
                    this._callbacks?.updateAncState?.(ancState);
            } else if (this._resumeWritesAfterReadSetting === 'volumeEq') {
                const enabled = decodeVolumeEqEnableSettingsResponse(packet.payload);
                if (enabled !== null)
                    this._callbacks?.updateVolumeEqEnable?.(enabled);
            } else if (this._resumeWritesAfterReadSetting === 'eq') {
                const eq = decodeEqSettingsResponse(packet.payload);
                if (eq !== null)
                    this._callbacks?.updateEq?.(eq);
            }
        }
        this._completeWriteRefresh();
    }

    _processSettingsPayload(payload) {
        const ancState = decodeAncStateSettingsResponse(payload);
        if (ancState !== null)
            this._callbacks?.updateAncState?.(ancState);

        const volumeEq = decodeVolumeEqEnableSettingsResponse(payload);
        if (volumeEq !== null)
            this._callbacks?.updateVolumeEqEnable?.(volumeEq);

        const eq = decodeEqSettingsResponse(payload);
        if (eq !== null)
            this._callbacks?.updateEq?.(eq);
    }

    _sendClientError(packet, status) {
        this._sendRpcPacket({
            type: PacketType.CLIENT_ERROR,
            channelId: packet.channelId,
            serviceId: packet.serviceId,
            methodId: packet.methodId,
            payload: [],
            status,
            callId: packet.callId,
        });
    }

    _sendRpcPacket(packet) {
        const bytes = encodeRpcPacket(packet);
        const frame = this._codec.encode(packet.channelId, bytes);
        if (frame)
            this.sendMessage(frame);
    }

    destroy() {
        this._clearWriteResponseTimeout();
        this._clearWriteRefreshTimeout();
        this._writeQueue = [];
        this._pendingWriteSettings.clear();
        super.destroy();
        this._codec = null;
    }
});
