'use strict';

import {addressForChannel} from './googleBudsConfig.js';

const FRAME = 0x7e;
const ESCAPE = 0x7d;
const ESCAPE_MASK = 0x20;
const CONTROL = 0x03;

const CRC32_TABLE = (() => {
    const table = [];
    for (let i = 0; i < 256; i++) {
        let crc = i;
        for (let j = 0; j < 8; j++)
            crc = crc & 1 ? 0xedb88320 ^ crc >>> 1 : crc >>> 1;
        table.push(crc >>> 0);
    }
    return table;
})();

export class HdlcCodec {
    constructor() {
        this._buffer = [];
        this._inFrame = false;
        this._escaped = false;
    }

    decode(bytes) {
        const frames = [];

        for (const byte of bytes) {
            if (!this._inFrame) {
                if (byte === FRAME) {
                    this._inFrame = true;
                    this._buffer = [];
                    this._escaped = false;
                }
                continue;
            }

            if (byte === FRAME) {
                const frame = this._decodeBuffered();
                if (frame)
                    frames.push(frame);
                this._buffer = [];
                this._escaped = false;
                this._inFrame = true;
                continue;
            }

            if (this._escaped) {
                this._buffer.push(byte ^ ESCAPE_MASK);
                this._escaped = false;
                continue;
            }

            if (byte === ESCAPE) {
                this._escaped = true;
                continue;
            }

            this._buffer.push(byte);
        }

        return frames;
    }

    encode(channel, data) {
        const address = addressForChannel(channel);
        if (address === null)
            return null;

        const payload = [
            ...encodeAddress(address),
            CONTROL,
            ...data,
        ];
        const crc = crc32(payload);
        payload.push(crc & 0xff, crc >>> 8 & 0xff, crc >>> 16 & 0xff, crc >>> 24 & 0xff);

        const out = [FRAME];
        for (const byte of payload) {
            if (byte === FRAME || byte === ESCAPE)
                out.push(ESCAPE, byte ^ ESCAPE_MASK);
            else
                out.push(byte);
        }
        out.push(FRAME);

        return Uint8Array.from(out);
    }

    _decodeBuffered() {
        if (this._buffer.length < 6)
            return null;

        const body = this._buffer.slice(0, -4);
        const expected = this._buffer.at(-4) |
            this._buffer.at(-3) << 8 |
            this._buffer.at(-2) << 16 |
            this._buffer.at(-1) << 24;
        if ((crc32(body) | 0) !== (expected | 0))
            return null;

        const [address, offset] = decodeAddress(body, 0);
        if (address === null || body[offset] !== CONTROL)
            return null;

        return {
            address,
            data: body.slice(offset + 1),
        };
    }
}

export function encodeRpcPacket(packet) {
    const out = [];
    writeVarintField(out, 1, packet.type);
    writeVarintField(out, 2, packet.channelId);
    writeFixed32Field(out, 3, packet.serviceId);
    writeFixed32Field(out, 4, packet.methodId);
    writeBytesField(out, 5, packet.payload ?? []);
    writeVarintField(out, 6, packet.status ?? 0);
    writeVarintField(out, 7, packet.callId);
    return out;
}

export function decodeRpcPacket(bytes) {
    const packet = {
        type: 0,
        channelId: 0,
        serviceId: 0,
        methodId: 0,
        payload: [],
        status: 0,
        callId: 0,
    };

    for (const field of readFields(bytes)) {
        switch (field.number) {
            case 1:
                packet.type = readVarintValue(field);
                break;
            case 2:
                packet.channelId = readVarintValue(field);
                break;
            case 3:
                packet.serviceId = readFixed32Value(field);
                break;
            case 4:
                packet.methodId = readFixed32Value(field);
                break;
            case 5:
                packet.payload = field.value;
                break;
            case 6:
                packet.status = readVarintValue(field);
                break;
            case 7:
                packet.callId = readVarintValue(field);
                break;
        }
    }

    return packet;
}

export function decodeRuntimeInfo(bytes) {
    const props = {};

    const runtimeFields = readFields(bytes);
    const batteryField = runtimeFields.find(field => field.number === 6 && field.wireType === 2);
    if (!batteryField)
        return props;

    for (const field of readFields(batteryField.value)) {
        if (field.wireType !== 2)
            continue;

        const battery = decodeDeviceBatteryInfo(field.value);
        if (!battery)
            continue;

        const index = batteryFieldToIndex(field.number);
        if (!index)
            continue;

        props[`battery${index}Level`] = battery.level;
        props[`battery${index}Status`] = battery.status;
    }

    return props;
}

export function encodeReadSettingPayload(settingId) {
    const out = [];
    writeVarintField(out, 4, settingId);
    return out;
}

export function encodeWriteAncStatePayload(ancState) {
    const setting = [];
    writeVarintField(setting, 13, ancState);

    const out = [];
    writeBytesField(out, 4, setting);
    return out;
}

export function encodeWriteVolumeEqEnablePayload(enabled) {
    const setting = [];
    writeVarintField(setting, 15, enabled ? 1 : 0);

    const out = [];
    writeBytesField(out, 4, setting);
    return out;
}

export function encodeWriteEqPayload(eqBands) {
    const eq = [];
    for (let i = 0; i < 5; i++)
        writeFloatField(eq, i + 1, eqBands[i] ?? 0);

    const setting = [];
    writeBytesField(setting, 16, eq);

    const out = [];
    writeBytesField(out, 4, setting);
    return out;
}

export function decodeAncStateSettingsResponse(bytes) {
    const settingsRsp = readFields(bytes);
    const valueField = settingsRsp.find(field => field.number === 4 && field.wireType === 2);
    if (!valueField)
        return null;

    const settingValue = readFields(valueField.value);
    const ancField = settingValue.find(field => field.number === 13 && field.wireType === 0);
    if (!ancField)
        return null;

    return readVarintValue(ancField);
}

export function decodeAncGestureLoopSettingsResponse(bytes) {
    const settingsRsp = readFields(bytes);
    const valueField = settingsRsp.find(field => field.number === 4 && field.wireType === 2);
    if (!valueField)
        return null;

    const settingValue = readFields(valueField.value);
    const gestureLoopField =
        settingValue.find(field => field.number === 12 && field.wireType === 2);

    if (!gestureLoopField)
        return null;

    const loop = {
        active: false,
        off: false,
        aware: false,
        adaptive: false,
    };

    for (const field of readFields(gestureLoopField.value)) {
        if (field.wireType !== 0)
            continue;

        const enabled = readVarintValue(field) !== 0;
        if (field.number === 1)
            loop.active = enabled;
        else if (field.number === 2)
            loop.off = enabled;
        else if (field.number === 3)
            loop.aware = enabled;
        else if (field.number === 4)
            loop.adaptive = enabled;
    }

    return loop;
}

export function decodeVolumeEqEnableSettingsResponse(bytes) {
    const settingsRsp = readFields(bytes);
    const valueField = settingsRsp.find(field => field.number === 4 && field.wireType === 2);
    if (!valueField)
        return null;

    const settingValue = readFields(valueField.value);
    const volumeEqField = settingValue.find(field => field.number === 15 && field.wireType === 0);
    if (!volumeEqField)
        return null;

    return readVarintValue(volumeEqField) !== 0;
}

export function decodeEqSettingsResponse(bytes, fieldNumber = 16) {
    const settingsRsp = readFields(bytes);
    const valueField = settingsRsp.find(field => field.number === 4 && field.wireType === 2);
    if (!valueField)
        return null;

    const settingValue = readFields(valueField.value);
    const eqField =
        settingValue.find(field => field.number === fieldNumber && field.wireType === 2);

    if (!eqField)
        return null;

    const bands = [0, 0, 0, 0, 0];
    for (const field of readFields(eqField.value)) {
        if (field.wireType !== 5 || field.number < 1 || field.number > 5)
            continue;

        bands[field.number - 1] = readFloatValue(field);
    }

    return bands.map(value => Math.max(-6, Math.min(6, value)));
}

export function decodeFwVersion(bytes) {
    const versions = [];

    for (const field of readFields(bytes)) {
        if (field.wireType !== 2)
            continue;

        const inner = readFields(field.value);

        for (const sub of inner) {
            if (sub.wireType !== 2)
                continue;

            const text = new TextDecoder().decode(
                Uint8Array.from(sub.value)
            );

            const match = text.match(/\d+(?:\.\d+)+/);
            if (match)
                versions.push(match[0]);
        }
    }

    return versions;
}

function decodeDeviceBatteryInfo(bytes) {
    let level = null;
    let state = null;

    for (const field of readFields(bytes)) {
        if (field.number === 1)
            level = readVarintValue(field);
        else if (field.number === 2)
            state = readVarintValue(field);
    }

    if (level === null)
        return null;

    return {
        level: Math.max(0, Math.min(level, 100)),
        status: state === 2 ? 'charging' : 'discharging',
    };
}

function batteryFieldToIndex(fieldNumber) {
    switch (fieldNumber) {
        case 2:
            return 1;
        case 3:
            return 2;
        case 1:
            return 3;
        default:
            return 0;
    }
}

function readFields(bytes) {
    const fields = [];
    let offset = 0;

    while (offset < bytes.length) {
        const [key, keyOffset] = decodeVarint(bytes, offset);
        if (key === null)
            break;

        offset = keyOffset;
        const number = key >>> 3;
        const wireType = key & 0x07;
        let value;

        if (wireType === 0) {
            const [val, next] = decodeVarint(bytes, offset);
            if (val === null)
                break;
            value = val;
            offset = next;
        } else if (wireType === 2) {
            const [len, next] = decodeVarint(bytes, offset);
            if (len === null || next + len > bytes.length)
                break;
            value = bytes.slice(next, next + len);
            offset = next + len;
        } else if (wireType === 5) {
            if (offset + 4 > bytes.length)
                break;
            value = bytes.slice(offset, offset + 4);
            offset += 4;
        } else {
            break;
        }

        fields.push({number, wireType, value});
    }

    return fields;
}

function readVarintValue(field) {
    return field.wireType === 0 ? field.value : null;
}

function readFixed32Value(field) {
    if (field.wireType !== 5 || field.value.length !== 4)
        return null;
    return (field.value[0] |
        field.value[1] << 8 |
        field.value[2] << 16 |
        field.value[3] << 24) >>> 0;
}

function readFloatValue(field) {
    if (field.wireType !== 5 || field.value.length !== 4)
        return null;

    const array = Uint8Array.from(field.value);
    return new DataView(array.buffer).getFloat32(0, true);
}

function writeVarintField(out, number, value) {
    out.push(...encodeVarint(number << 3), ...encodeVarint(value));
}

function writeFixed32Field(out, number, value) {
    out.push(...encodeVarint(number << 3 | 5), value & 0xff, value >>> 8 & 0xff,
        value >>> 16 & 0xff, value >>> 24 & 0xff);
}

function writeFloatField(out, number, value) {
    const buffer = new ArrayBuffer(4);
    new DataView(buffer).setFloat32(0, Math.max(-6, Math.min(6, value)), true);
    out.push(...encodeVarint(number << 3 | 5), ...new Uint8Array(buffer));
}

function writeBytesField(out, number, bytes) {
    out.push(...encodeVarint(number << 3 | 2), ...encodeVarint(bytes.length), ...bytes);
}

function encodeVarint(value) {
    let val = value >>> 0;
    const out = [];
    while (val >= 0x80) {
        out.push(val & 0x7f | 0x80);
        val >>>= 7;
    }
    out.push(val);
    return out;
}

function encodeAddress(value) {
    let val = value >>> 0;
    const out = [];
    while (val >>> 7 !== 0) {
        out.push((val & 0x7f) << 1);
        val >>>= 7;
    }
    out.push((val & 0x7f) << 1 | 1);
    return out;
}

function decodeVarint(bytes, offset) {
    let value = 0;
    let shift = 0;

    for (let i = offset; i < bytes.length && shift < 64; i++) {
        const byte = bytes[i];
        value += (byte & 0x7f) * 2 ** shift;
        if ((byte & 0x80) === 0)
            return [value, i + 1];
        shift += 7;
    }

    return [null, offset];
}

function decodeAddress(bytes, offset) {
    let value = 0;
    let shift = 0;

    for (let i = offset; i < bytes.length && shift < 35; i++) {
        const byte = bytes[i];
        value |= byte >>> 1 << shift;
        if ((byte & 0x01) === 0x01)
            return [value >>> 0, i + 1];
        shift += 7;
    }

    return [null, offset];
}

function crc32(bytes) {
    let crc = 0xffffffff;
    for (const byte of bytes)
        crc = CRC32_TABLE[(crc ^ byte) & 0xff] ^ crc >>> 8;
    return (crc ^ 0xffffffff) >>> 0;
}
