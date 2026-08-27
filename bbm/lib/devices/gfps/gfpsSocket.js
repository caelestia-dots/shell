'use strict';

import GObject from 'gi://GObject';

import {createLogger, getDeviceIdentifier} from '../logger.js';
import {SocketHandler} from '../socketByProfile.js';
import {MessageGroup, DeviceInfoMessage, HearableControlMessage} from './gfpsConfig.js';

export const GfpsSocket = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_GfpsSocket',
}, class GfpsSocket extends SocketHandler {
    _init(devicePath, profileManager, profile, callbacks) {
        super._init(devicePath, profileManager, profile);
        const identifier = getDeviceIdentifier(devicePath);
        const tag = `GfpsSocket-${identifier}`;
        this._log = createLogger(tag);
        this._log.info('GfpsSocket init');

        this._devicePath = devicePath;
        this._callbacks = callbacks;
        this._initialized = false;
        this._halfPacket = new Uint8Array(0);

        this._lastVersion = 0x01; // GFPS ANC Protocol version (1 or 2)
        this._lastUiToggles = 0xE8; // Default to all supported: Transparency, Adaptive, Off, ANC
        this._lastSettableToggles = 0xE8;

        this.startSocket();
    }

    _isValidPacketStream(bytes) {
        let offset = 0;
        while (offset < bytes.length) {
            if (bytes.length - offset < 4)
                return false;

            const len = bytes[offset + 2] << 8 | bytes[offset + 3];
            const packetLength = 4 + len;
            if (bytes.length - offset < packetLength)
                return false;

            offset += packetLength;
        }

        return offset === bytes.length;
    }

    processData(bytes) {
        let packetToProcess = bytes;
        let isValid = this._isValidPacketStream(bytes);
        if (!isValid && this._halfPacket.length > 0) {
            const merged = new Uint8Array(this._halfPacket.length + bytes.length);
            merged.set(this._halfPacket, 0);
            merged.set(bytes, this._halfPacket.length);
            if (this._isValidPacketStream(merged)) {
                packetToProcess = merged;
                isValid = true;
            }
        }

        if (isValid) {
            let offset = 0;
            while (offset < packetToProcess.length) {
                const group = packetToProcess[offset];
                const code = packetToProcess[offset + 1];
                const len = packetToProcess[offset + 2] << 8 | packetToProcess[offset + 3];
                const payload = packetToProcess.slice(offset + 4, offset + 4 + len);
                this._parseData(group, code, payload);
                offset += 4 + len;
            }

            this._halfPacket = new Uint8Array(0);
        } else if (bytes.length <= 100) {
            this._halfPacket = bytes;
        } else {
            this._halfPacket = new Uint8Array(0);
        }
    }

    postConnectInitialization() {
        this._log.info('GFPS Socket Initialized');
    }

    _parseData(group, code, payload) {
        if (group === MessageGroup.DEVICE_INFO && code === DeviceInfoMessage.BATTERY_UPDATE) {
            const parseComponent = byte => {
                if ((byte & 0x7F) === 0x7F)
                    return {level: 0, status: 'disconnected'};

                const charging = (byte & 0x80) !== 0;
                const level = byte & 0x7F;
                return {
                    level,
                    status: charging ? 'charging' : 'discharging',
                };
            };

            const bat1 = parseComponent(payload[0]);
            let bat2, bat3;
            if (payload.length === 3) {
                bat2 = parseComponent(payload[1]);
                bat3 = parseComponent(payload[2]);
            } else if (payload.length === 1) {
                bat2 = {level: 0, status: 'disconnected'};
                bat3 = {level: 0, status: 'disconnected'};
            } else {
                this._log.info(`Unexpected GFPS battery payload length: ${payload.length}`);
                return;
            }

            this._log.info(
                `Parsed GFPS Battery: L=${bat1.level}% (${bat1.status}), ` +
                `R=${bat2.level}% (${bat2.status}), C=${bat3.level}% (${bat3.status})`
            );

            if (!this._initialized) {
                const battType = payload.length === 1 ? 1 : 3;
                this._initialize(battType);
            }

            this._callbacks.updateBatteryProps({
                battery1Level: bat1.level,
                battery1Status: bat1.status,
                battery2Level: bat2.level,
                battery2Status: bat2.status,
                battery3Level: bat3.level,
                battery3Status: bat3.status,
            });
        } else if (group === MessageGroup.HEARABLE_CONTROL &&
                 code === HearableControlMessage.NOTIFY_ANC_STATE) {
            if (payload.length < 4)
                return;

            const version = payload[0];
            const uiToggles = payload[1];
            const settableToggles = payload[2];
            const currentState = payload[3];

            this._log.info(
                `Parsed GFPS ANC Notification: Version=${version}, UI=${uiToggles.toString(16)}, ` +
                `Settable=${settableToggles.toString(16)}, State=${currentState.toString(16)}`
            );

            this._lastVersion = version;
            this._lastUiToggles = uiToggles;
            this._lastSettableToggles = settableToggles;

            this._callbacks.updateNoiseControl(currentState, settableToggles);
        }
    }

    _requestAncState() {
        this._log.info('GFPS connected, querying current ANC state');
        // Query the current ANC state: Group 0x08, Code 0x11, Length 0
        const queryBytes = new Uint8Array([MessageGroup.HEARABLE_CONTROL,
            HearableControlMessage.GET_ANC_STATE, 0x00, 0x00]);

        this.sendMessage(queryBytes);
    }

    _initialize(battType) {
        this._initialized = true;
        this._callbacks.updateInitDevice(battType);
        this._requestAncState();
    }

    sendAncState(targetState) {
        // Construct the 4-byte payload: [Version, UI toggles, Settable toggles, Target state]
        const payload = new Uint8Array([
            this._lastVersion,
            this._lastUiToggles,
            this._lastSettableToggles,
            targetState,
        ]);

        const header = new Uint8Array([
            MessageGroup.HEARABLE_CONTROL,
            HearableControlMessage.SET_ANC_STATE,
            0x00,
            payload.length,
        ]);

        const packet = new Uint8Array(header.length + payload.length);
        packet.set(header, 0);
        packet.set(payload, header.length);

        this.sendMessage(packet);
    }
});
