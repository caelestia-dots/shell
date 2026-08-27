'use strict';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';

import {createLogger, getDeviceIdentifier} from '../logger.js';
import {SocketHandler} from '../socketByProfile.js';

import {Checksum, MessageType} from './sonyConfig.js';

export const SonySocketBase = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_SonySocketBase',
    Signals: {'ack-received': {param_types: [GObject.TYPE_STRING]}},
}, class SonySocketBase extends SocketHandler {
    _init(devicePath, profileManager, profile) {
        super._init(devicePath, profileManager, profile);
        const identifier = getDeviceIdentifier(devicePath);
        const tag = `SonySocketBase-${identifier}`;
        this._log = createLogger(tag);
        this._messageQueue = [];
        this._initComplete = false;
        this._processingQueue = false;
        this._currentMessage = null;
        this.pendingRequestQueue = [];
        this._pendingRequestRetries = 4;
        this._seq = 0;
        this._frameBuf = new Uint8Array(0);
    }

    addMessageQueue(type, payload, ackType = 'unknown') {
        this._messageQueue.push({type, payload, ackType});

        if (!this._processingQueue)
            this._processNextQueuedMessage();
    }

    _processNextQueuedMessage() {
        if (this._messageQueue.length === 0) {
            this._processingQueue = false;
            return;
        }

        this._processingQueue = true;
        this._currentMessage = this._messageQueue.shift();
        this._sendAndWaitAck();
    }

    _sendAndWaitAck() {
        if (!this._currentMessage)
            return;

        const {type, payload} = this._currentMessage;
        if (this._currentMessage.ackType === 'EndOfGetMessage') {
            this._currentMessage = null;
            this._checkForPendingRequest();
            this._processNextQueuedMessage();
            return;
        }

        this._encodeSonyMessage(type, payload);

        if (this._ackTimeoutId) {
            GLib.source_remove(this._ackTimeoutId);
            this._ackTimeoutId = null;
        }

        this._ackTimeoutId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 300, () => {
            const ackType = this._currentMessage?.ackType ?? 'Unknown';
            this._log.info(`ACK not received after 300ms for ${ackType}, continuing.`);

            this._currentMessage = null;

            if (this._messageQueue.length === 0)
                this._processingQueue = false;
            else
                this._processNextQueuedMessage();

            this._ackTimeoutId = null;
            return GLib.SOURCE_REMOVE;
        });
    }

    _checkForPendingRequest() {
        this._log.info(`PendingRequestQueue = ${this.pendingRequestQueue}`);
        if (this._pendingRequestRetries > 0 && this.pendingRequestQueue?.length > 0) {
            this._pendingRequestRetries--;

            if (this._pendingTimeoutId)
                GLib.source_remove(this._pendingTimeoutId);

            this._pendingTimeoutId = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 4, () => {
                this.resendPendingRequest();
                this._pendingTimeoutId = null;
                return GLib.SOURCE_REMOVE;
            });
        } else {
            this._pendingRequestRetries = 0;
            delete this.pendingRequestQueue;
        }
    }

    _onAcknowledgeReceived(_, ackType) {
        if (ackType !== 'ack')
            return;

        const msg = this._currentMessage;

        if (!msg || !msg.ackType)
            this._log.info('ACK Received.');
        else
            this._log.info(`ACK Received for ${msg.ackType}`);

        if (msg?.ackType && this.pendingRequestQueue?.length > 0) {
            const index = this.pendingRequestQueue.indexOf(msg.ackType);
            if (index !== -1)
                this.pendingRequestQueue.splice(index, 1);
        }

        if (this._ackTimeoutId) {
            GLib.source_remove(this._ackTimeoutId);
            this._ackTimeoutId = null;
        }

        this._currentMessage = null;

        if (this._messageQueue.length === 0)
            this._processingQueue = false;
        else
            this._processNextQueuedMessage();
    }

    _encodeSonyMessage(messageType, payloadArr, seq) {
        const len = payloadArr.length;
        const headerBuf = new Uint8Array(6 + len);
        let sequence;
        if (seq !== undefined) {
            sequence = seq;
        } else {
            sequence = this._seq;
            this._seq = 1 - this._seq;
        }

        headerBuf[0] = messageType;
        headerBuf[1] = sequence;
        headerBuf[2] = len >>> 24 & 0xFF;
        headerBuf[3] = len >>> 16 & 0xFF;
        headerBuf[4] = len >>>  8 & 0xFF;
        headerBuf[5] = len & 0xFF;
        headerBuf.set(payloadArr, 6);

        const chksum = this._calcChecksum(headerBuf);
        const bodyEsc = this._escapeBytes(headerBuf);
        const chkEsc  = this._escapeBytes(new Uint8Array([chksum]));
        this.sendMessage(
            Uint8Array.from([Checksum.HEADER, ...bodyEsc, ...chkEsc, Checksum.TRAILER]));
    }

    _decodeSonyMessage(rawBytes) {
        if (rawBytes[0] !== Checksum.HEADER) {
            this._log.error(`Invalid header: ${rawBytes[0]}`);
            return null;
        }

        if (rawBytes.at(-1) !== Checksum.TRAILER) {
            this._log.error(`Invalid trailer: ${rawBytes.at(-1)}`);
            return null;
        }

        const unesc = this._unescapeBytes(rawBytes);
        const lenAll = unesc.length;
        const chksum = unesc[lenAll - 2];
        const exp    = this._calcChecksum(unesc.subarray(1, lenAll - 2));
        if (chksum !== exp) {
            this._log.error(`Checksum mismatch ${chksum} != ${exp}`);
            return null;
        }

        const payloadLen = unesc[3] << 24 | unesc[4] << 16 | unesc[5] << 8 | unesc[6];
        const payload = unesc.subarray(7, 7 + payloadLen);
        return {messageType: unesc[1], sequence: unesc[2], payload};
    }

    _calcChecksum(buf) {
        let sum = 0;
        for (const b of buf)
            sum = sum + b & 0xFF;
        return sum;
    }

    _escapeBytes(buf) {
        const out = [];
        for (const b of buf) {
            if (b === Checksum.HEADER || b === Checksum.TRAILER || b === Checksum.ESCAPE)
                out.push(Checksum.ESCAPE, b & Checksum.ESCAPE_MASK);
            else
                out.push(b);
        }
        return new Uint8Array(out);
    }

    _unescapeBytes(buf) {
        const out = [];
        for (let i = 0; i < buf.length; i++) {
            if (buf[i] === Checksum.ESCAPE) {
                i++;
                out.push(buf[i] | ~Checksum.ESCAPE_MASK);
            } else {
                out.push(buf[i]);
            }
        }
        return new Uint8Array(out);
    }

    waitForResponse(ackType, resendFn, timeoutSeconds = 5, maxRetries = 3) {
        return new Promise((resolve, reject) => {
            let retries = 0;

            const attempt = () => {
                if (retries >= maxRetries) {
                    this._log.error(`Failed to receive ${ackType} after ${maxRetries} retries`);
                    if (this._responseSignalId)
                        this.disconnect(this._responseSignalId);
                    this._responseSignalId = null;

                    if (this._responseTimeoutId)
                        GLib.source_remove(this._responseTimeoutId);
                    this._responseTimeoutId = null;

                    reject(new Error(`Timeout waiting for ${ackType}`));
                    return;
                }

                retries++;
                this._log.info(`Waiting for '${ackType}', attempt ${retries}`);

                if (this._responseSignalId)
                    this.disconnect(this._responseSignalId);

                this._responseSignalId = this.connect('ack-received', (_, receivedAck) => {
                    if (receivedAck === ackType) {
                        this._log.info(`'${ackType}' received`);
                        if (this._responseTimeoutId) {
                            GLib.source_remove(this._responseTimeoutId);
                            this._responseTimeoutId = null;
                        }
                        if (this._responseSignalId) {
                            this.disconnect(this._responseSignalId);
                            this._responseSignalId = null;
                        }
                        resolve();
                    }
                });

                resendFn();

                if (this._responseTimeoutId)
                    GLib.source_remove(this._responseTimeoutId);

                this._responseTimeoutId = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT,
                    timeoutSeconds, () => {
                        this._log.info(`'${ackType}' not received after ` +
                             `${timeoutSeconds}s, retrying...`);
                        attempt();
                        return GLib.SOURCE_REMOVE;
                    }
                );
            };

            attempt();
        });
    }

    _encodeAck(seq) {
        this._encodeSonyMessage(MessageType.ACK, [], 1 - seq);
    }

    tagEndOfGetMessage() {
        this._log.info('TAG EndOfGetMessage:');

        const payload = [0x00];
        const ackType = 'EndOfGetMessage';
        this.addMessageQueue(MessageType.COMMAND_1, payload, ackType);
    }

    processData(chunk) {
        const buf = new Uint8Array(this._frameBuf.length + chunk.length);
        buf.set(this._frameBuf, 0);
        buf.set(chunk, this._frameBuf.length);

        let frameStart = -1;
        const frames = [];
        for (let i = 0; i < buf.length; i++) {
            const b = buf[i];

            if (frameStart < 0) {
                if (b === Checksum.HEADER)
                    frameStart = i;
            } else if (b === Checksum.TRAILER) {
                frames.push(buf.slice(frameStart, i + 1));
                frameStart = -1;
            }
        }

        if (frameStart >= 0)
            this._frameBuf = buf.slice(frameStart);
        else
            this._frameBuf = new Uint8Array(0);


        for (const frame of frames)
            this._parseData(frame);
    }

    _parseData(rawData) {
        try {
            const data = this._decodeSonyMessage(rawData);
            if (!data)
                return;
            const {messageType, sequence, payload} = data;

            if (messageType === MessageType.ACK) {
                this.emit('ack-received', 'ack');
                return;
            }

            if (messageType === MessageType.COMMAND_1 || messageType === MessageType.COMMAND_2)
                this._encodeAck(sequence);

            if (messageType === MessageType.COMMAND_1)
                this.handleMessageType1(payload);

            if (messageType === MessageType.COMMAND_2)
                this.handleMessageType2(payload);
        } catch (e) {
            this._log.error('Failed to process socket data', e);
        }
    }

    postConnectInitialization() {
        this.ackSignalId = this.connect('ack-received', this._onAcknowledgeReceived.bind(this));
        this.sendInit();
    }

    destroy() {
        if (this.ackSignalId)
            this.disconnect(this.ackSignalId);
        this.ackSignalId = null;

        if (this._responseSignalId)
            this.disconnect(this._responseSignalId);
        this._responseSignalId = null;

        if (this._responseTimeoutId)
            GLib.source_remove(this._responseTimeoutId);
        this._responseTimeoutId = null;

        if (this._pendingTimeoutId)
            GLib.source_remove(this._pendingTimeoutId);
        this._pendingTimeoutId = null;

        if (this._ackTimeoutId)
            GLib.source_remove(this._ackTimeoutId);
        this._ackTimeoutId = null;

        this._seq = 0;

        super.destroy();
    }
});

